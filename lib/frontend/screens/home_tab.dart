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
import '../widgets/mousey_avatar.dart';
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
                color: AppColors.tealBright,
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
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.mint),
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

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final totalBadge = _unreadNotifCount + _pendingDraftCount;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    buildUserAvatar(
                      avatarKey: widget.selectedAvatarKey,
                      userName: widget.currentUser.name,
                      size: 44,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.currentUser.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: HomeTab.darkBeige,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            AppTranslations.tr(lang, 'welcome_back'),
                            style: TextStyle(
                              fontSize: 12,
                              color: HomeTab.darkBeige.withValues(alpha: 0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bell icon with dynamic badge
                    GestureDetector(
                      onTap: _openNotificationCenter,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.tealPale),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(Icons.notifications_none_rounded, color: HomeTab.darkBeige, size: 22),
                            if (totalBadge > 0)
                              Positioned(
                                right: 2,
                                top: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    totalBadge > 9 ? '9+' : '$totalBadge',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Total Balance Hero Card (Gradient theme)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.tealBright, AppColors.teal],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppTranslations.tr(lang, 'total_balance').toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                MoneyText(
                  amount: widget.totalBalance,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Income & Expense summary row (Tappable Buttons)
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: widget.onAddIncome,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.income,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_downward_rounded, size: 14, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppTranslations.tr(lang, 'income'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.tealDark,
                                      ),
                                    ),
                                    MoneyText(
                                      amount: widget.totalIncome,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.income,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: widget.onAddExpense,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.tealPale),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.expenseStrong,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_upward_rounded, size: 14, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppTranslations.tr(lang, 'expense'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.tealDark,
                                      ),
                                    ),
                                    MoneyText(
                                      amount: widget.totalExpense,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.expenseStrong,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Budget Overview Widget
          ListenableBuilder(
            listenable: BudgetService.instance,
            builder: (context, _) {
              final budgetStatuses = BudgetService.instance.currentBudgets;
              if (budgetStatuses.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppTranslations.tr(lang, 'budget_overview').toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BudgetsScreen(ledgerId: TransactionService.instance.currentLedgerId),
                            ),
                          );
                        },
                        child: Text(
                          AppTranslations.tr(lang, 'view_all'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: HomeTab.darkBeige,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.tealPale),
                    ),
                    child: Column(
                      children: budgetStatuses.take(2).map((s) {
                        final name = s.budget.categoryId != null ? context.tCategory(s.budget.categoryId!) : context.t('Tổng ngân sách tháng');
                        final pct = s.percent.clamp(0.0, 100.0);
                        Color barColor = const Color(0xFF4CAF50);
                        if (s.level == 'exceeded') {
                          barColor = Colors.red;
                        } else if (s.level == 'reached') {
                          barColor = Colors.deepOrange;
                        } else if (s.level == 'warning') {
                          barColor = Colors.orange;
                        }

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
                                    SnackBar(content: Text(AppLanguage.instance.t('Đã cập nhật ngân sách!')), backgroundColor: Colors.green),
                                  );
                                } catch (e) {
                                  debugPrint('Error updating budget: $e');
                                }
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: HomeTab.darkBeige,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    MoneyText(
                                      amount: s.spent,
                                      prefix: '',
                                      suffix: ' / ${formatMoney(s.limit)} đ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: HomeTab.darkBeige,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: (pct / 100.0).clamp(0.0, 1.0),
                                    minHeight: 8,
                                    backgroundColor: AppColors.tealMist,
                                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),

          // Recent Transactions Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTranslations.tr(lang, 'recent_transactions').toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: HomeTab.darkBeige,
                  letterSpacing: 0.8,
                ),
              ),
              GestureDetector(
                onTap: () {
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
                  AppTranslations.tr(lang, 'view_all'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: HomeTab.darkBeige,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Recent Transactions List
          widget.transactions.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.tealPale),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 48, color: AppColors.tealLight),
                      const SizedBox(height: 8),
                      Text(
                        AppTranslations.tr(lang, 'no_recent_transactions'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: HomeTab.darkBeige,
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.tealPale),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.transactions.take(5).length,
                    separatorBuilder: (ctx, i) => Divider(height: 1, indent: 56, color: AppColors.tealMist),
                    itemBuilder: (ctx, index) {
                      final item = widget.transactions[index];

                      return ListTile(
                        onTap: () => _showTransactionDetailSheet(item),
                        leading: CategoryIcon(
                          categoryOrIconKey: item.category,
                          size: 40,
                          bgColor: item.isExpense ? AppColors.expenseBg : AppColors.incomeBg,
                          iconColor: item.isExpense ? AppColors.expense : const Color(0xFF4CAF50),
                        ),
                        title: Text(
                          item.title.isNotEmpty ? item.title : context.tCategory(item.category),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          _formatDateTime(item.date),
                          style: TextStyle(fontSize: 12, color: AppColors.grey500),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: MoneyText(
                          amount: item.amount,
                          prefix: item.isExpense ? '-' : '+',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: item.isExpense ? AppColors.expense : const Color(0xFF4CAF50),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                ),
        ],
      ),
    );
  }
}
