import 'package:flutter/material.dart';
import '../../backend/database/db_helper.dart';
import '../../backend/models/transaction_model.dart';
import '../../backend/models/user_model.dart';
import '../../backend/services/budget_service.dart';
import '../../backend/services/in_app_notification_service.dart';
import '../../backend/services/transaction_service.dart';
import '../../core/widgets/money_text.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/utils/money_input_formatter.dart';
import '../theme/app_colors.dart';
import '../utils/app_translations.dart';
import '../widgets/budget_form_sheet.dart';
import '../widgets/notification/notification_center_sheet.dart';
import 'all_transactions_screen.dart';
import 'budgets_screen.dart';
import '../utils/app_language.dart';

class HomeTab extends StatefulWidget {
  final UserModel currentUser;
  final String selectedAvatarKey;
  final DateTime selectedMonth;
  final double totalIncome;
  final double totalExpense;
  final double totalBalance;
  final List<TransactionItem> transactions;
  final VoidCallback onLogout;
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;

  static Color get primaryBeige => AppColors.primaryBeige;
  static Color get darkBeige => AppColors.darkBeige;
  static Color get accentBeige => AppColors.accentBeige;

  const HomeTab({
    super.key,
    required this.currentUser,
    required this.selectedAvatarKey,
    required this.selectedMonth,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalBalance,
    required this.transactions,
    required this.onLogout,
    required this.onAddIncome,
    required this.onAddExpense,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int _unreadNotifCount = 0;
  int _pendingDraftCount = 0;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
    _loadNotificationCounts();
    InAppNotificationService.instance.addListener(_loadNotificationCounts);
    TransactionService.instance.addListener(_onDataUpdated);
  }

  void _onDataUpdated() {
    BudgetService.instance.loadBudgets(_monthStr);
    _loadNotificationCounts();
  }

  @override
  void dispose() {
    InAppNotificationService.instance.removeListener(_loadNotificationCounts);
    TransactionService.instance.removeListener(_onDataUpdated);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth != widget.selectedMonth) {
      BudgetService.instance.loadBudgets(_monthStr);
    }
  }

  String get _monthStr {
    return '${widget.selectedMonth.year}-${widget.selectedMonth.month.toString().padLeft(2, '0')}';
  }

  Future<void> _loadBudgets() async {
    await BudgetService.instance.loadBudgets(_monthStr);
  }

  Future<void> _loadNotificationCounts() async {
    try {
      final unread = await InAppNotificationService.instance.getUnreadCount();
      final drafts = await DatabaseHelper.instance.getPendingTransactionsCount();
      if (mounted) {
        setState(() {
          _unreadNotifCount = unread;
          _pendingDraftCount = drafts;
        });
      }
    } catch (_) {}
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$hour:$minute - $day/$month/$year';
  }

  void _showTransactionDetailSheet(TransactionItem item) {
    final isExpense = item.isExpense;
    final dt = item.date;
    final formattedDateTime = _formatDateTime(dt);

    final titleController = TextEditingController(text: item.title.isNotEmpty ? item.title : item.category);
    final amountController = TextEditingController(text: formatMoney(item.amount));
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.grey400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header Icon & Category (Fixed)
                    Row(
                      children: [
                        CategoryIcon(
                          categoryOrIconKey: item.category,
                          size: 48,
                          bgColor: isExpense ? AppColors.expenseBg : AppColors.incomeBg,
                          iconColor: isExpense ? AppColors.expenseStrong : AppColors.income,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tCategory(item.category),
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: HomeTab.darkBeige),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                context.t('Danh mục cố định'),
                                style: TextStyle(fontSize: 12, color: AppColors.grey500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Editable Fields Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.rule),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Tên ghi chú (Editable)
                          Text(context.t('Ghi chú / Tên giao dịch:'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.grey500)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: titleController,
                            decoration: InputDecoration(
                              hintText: context.t('Nhập tên ghi chú...'),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 2. Số tiền (Editable)
                          Text(context.t('Số tiền (đ):'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.grey500)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [MoneyInputFormatter()],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isExpense ? AppColors.expenseStrong : AppColors.income,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              prefixText: isExpense ? '- ' : '+ ',
                              prefixStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isExpense ? AppColors.expenseStrong : AppColors.income,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 3. Thời gian & Loại
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(context.t('Thời gian:'), style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                              Text(
                                formattedDateTime,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: HomeTab.darkBeige),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons (Xóa / Lưu)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    Navigator.pop(sheetCtx);
                                    await TransactionService.instance.removeTransaction(item.id, uid: item.uid, date: item.date);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(context.t('Đã xóa giao dịch thành công!')), backgroundColor: Colors.red),
                                    );
                                  },
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: Text(context.t('Xóa'), style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final newTitle = titleController.text.trim();
                                    final newAmount = parseMoney(amountController.text).toDouble();
                                    if (newAmount <= 0) {
                                      ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                        SnackBar(content: Text(context.t('Vui lòng nhập số tiền hợp lệ!')), backgroundColor: Colors.orange),
                                      );
                                      return;
                                    }

                                    setSheetState(() => isSaving = true);
                                    final updatedTx = item.copyWith(
                                      title: newTitle.isNotEmpty ? newTitle : item.category,
                                      amount: newAmount,
                                    );

                                    await TransactionService.instance.updateTransaction(updatedTx, uid: item.uid);

                                    if (!sheetCtx.mounted) return;
                                    Navigator.pop(sheetCtx);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(context.t('Đã lưu thay đổi giao dịch!')), backgroundColor: Colors.green),
                                    );
                                  },
                            icon: isSaving
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.save_rounded),
                            label: Text(context.t('Lưu thay đổi'), style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openNotificationCenter() {
    NotificationCenterSheet.show(
      context,
      ledgerId: TransactionService.instance.currentLedgerId,
      onTransactionsUpdated: () {
        _loadBudgets();
        _loadNotificationCounts();
      },
    );
  }

  /// Các giao dịch trong tháng đang xem, mới nhất trước (danh sách đã được sắp xếp sẵn)
  List<TransactionItem> get _monthTransactions => widget.transactions
      .where((t) =>
          !t.isDeleted &&
          t.date.year == widget.selectedMonth.year &&
          t.date.month == widget.selectedMonth.month)
      .toList();

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final totalBadge = _unreadNotifCount + _pendingDraftCount;
    final remaining = widget.totalIncome - widget.totalExpense;
    final monthTxs = _monthTransactions;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề sổ: "Sổ chi tiêu  Tháng 10/2026" + chuông thông báo
          Row(
            children: [
              Text(
                context.t('Sổ chi tiêu'),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.t('Tháng {month}/{year}', {
                    'month': widget.selectedMonth.month,
                    'year': widget.selectedMonth.year,
                  }),
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _NotificationBell(count: totalBadge, onTap: _openNotificationCenter),
            ],
          ),
          const SizedBox(height: 20),

          // Thu | Chi của tháng, ngăn bằng một đường kẻ dọc
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _SummaryCell(
                    label: context.t('Thu'),
                    amount: widget.totalIncome,
                    color: AppColors.income,
                    onTap: widget.onAddIncome,
                  ),
                ),
                VerticalDivider(width: 24, thickness: 1, color: AppColors.rule),
                Expanded(
                  child: _SummaryCell(
                    label: context.t('Chi'),
                    amount: widget.totalExpense,
                    color: AppColors.expense,
                    onTap: widget.onAddExpense,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: AppColors.rule),
          const SizedBox(height: 14),

          // Còn lại: số lớn, gạch chân đôi như dòng tổng trong sổ
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(context.t('Còn lại'), style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
              const SizedBox(width: 16),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 3),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.ink, width: 1.2)),
                    ),
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 2),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.ink, width: 1.2)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: MoneyText(
                          amount: remaining,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Ngân sách: danh sách kẻ dòng, thanh tiến độ mảnh
          ListenableBuilder(
            listenable: BudgetService.instance,
            builder: (context, _) {
              final budgetStatuses = BudgetService.instance.currentBudgets;
              if (budgetStatuses.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: AppTranslations.tr(lang, 'budget_overview'),
                    actionLabel: AppTranslations.tr(lang, 'view_all'),
                    onAction: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BudgetsScreen(ledgerId: TransactionService.instance.currentLedgerId),
                        ),
                      );
                    },
                  ),
                  ...budgetStatuses.take(2).map((s) {
                    final name = s.budget.categoryId != null ? context.tCategory(s.budget.categoryId!) : context.t('Tổng ngân sách tháng');
                    final pct = s.percent.clamp(0.0, 100.0);
                    final overLimit = s.level == 'exceeded' || s.level == 'reached';
                    final barColor = overLimit
                        ? AppColors.expense
                        : (s.level == 'warning' ? AppColors.noteBorder : AppColors.ink);

                    return InkWell(
                      onTap: () {
                        BudgetFormSheet.show(
                          context: context,
                          ledgerId: TransactionService.instance.currentLedgerId,
                          currentMonth: _monthStr,
                          editingBudget: s.budget,
                          existingBudgets: budgetStatuses.map((b) => b.budget).toList(),
                          onSave: (updatedBudget) async {
                            final scaffold = ScaffoldMessenger.of(context);
                            try {
                              if (updatedBudget.id == null || updatedBudget.id!.isEmpty) {
                                await BudgetService.instance.insertBudget(updatedBudget);
                              } else {
                                await BudgetService.instance.updateBudget(updatedBudget);
                              }
                              if (!mounted) return;
                              scaffold.showSnackBar(
                                SnackBar(content: Text(AppLanguage.instance.t('Đã cập nhật ngân sách!')), backgroundColor: AppColors.income),
                              );
                            } catch (e) {
                              debugPrint('Error updating budget: $e');
                            }
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.rule))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(fontSize: 14, color: AppColors.ink),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                MoneyText(
                                  amount: s.spent,
                                  suffix: ' / ${formatMoney(s.limit)} đ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: overLimit ? AppColors.expense : AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: (pct / 100.0).clamp(0.0, 1.0),
                                minHeight: 4,
                                backgroundColor: AppColors.tealPale,
                                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 28),
                ],
              );
            },
          ),

          // Bảng sổ: Ngày | Nội dung | Số tiền, có đường kẻ lề đỏ
          _LedgerHeader(
            date: context.t('Ngày'),
            content: context.t('Nội dung'),
            amount: context.t('Số tiền'),
          ),
          if (monthTxs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  context.t('Chưa có ghi chép nào trong tháng này'),
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
              ),
            )
          else
            ...monthTxs.take(10).map((item) => _LedgerRow(
                  date: '${item.date.day.toString().padLeft(2, '0')}/${item.date.month.toString().padLeft(2, '0')}',
                  content: item.title.isNotEmpty ? item.title : context.tCategory(item.category),
                  amount: item.amount,
                  isExpense: item.isExpense,
                  onTap: () => _showTransactionDetailSheet(item),
                )),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllTransactionsScreen(
                      transactions: widget.transactions,
                    ),
                  ),
                );
              },
              child: Text(
                '${AppTranslations.tr(lang, 'view_all')} →',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cột Ngày của bảng sổ rộng cố định, ngay sau là đường kẻ lề đỏ
const double _ledgerDateWidth = 56;

class _LedgerHeader extends StatelessWidget {
  final String date;
  final String content;
  final String amount;

  const _LedgerHeader({required this.date, required this.content, required this.amount});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary);
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.ink, width: 1.2))),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _ledgerDateWidth,
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(date, style: style)),
            ),
            Container(width: 1.2, color: AppColors.margin),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 0, 8),
                child: Text(content, style: style),
              ),
            ),
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(amount, style: style)),
          ],
        ),
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final String date;
  final String content;
  final double amount;
  final bool isExpense;
  final VoidCallback onTap;

  const _LedgerRow({
    required this.date,
    required this.content,
    required this.amount,
    required this.isExpense,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.rule))),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: _ledgerDateWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Text(date, style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
                ),
              ),
              Container(width: 1.2, color: AppColors.margin),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 13, 8, 13),
                  child: Text(
                    content,
                    style: TextStyle(fontSize: 15, color: AppColors.ink),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: MoneyText(
                  amount: amount,
                  prefix: isExpense ? '-' : '+',
                  suffix: '',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isExpense ? AppColors.expense : AppColors.income,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final VoidCallback onTap;

  const _SummaryCell({required this.label, required this.amount, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: MoneyText(
                amount: amount,
                suffix: '',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({required this.title, required this.actionLabel, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.ink, width: 1.2))),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
          ),
          GestureDetector(
            onTap: onAction,
            child: Text(actionLabel, style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _NotificationBell({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Badge(
        isLabelVisible: count > 0,
        backgroundColor: AppColors.expense,
        label: Text(count > 9 ? '9+' : '$count'),
        child: Icon(Icons.notifications_none_rounded, color: AppColors.ink, size: 24),
      ),
    );
  }
}
