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

class HomeTab extends StatefulWidget {
  final UserModel currentUser;
  final String selectedAvatarKey;
  final String selectedLanguage;
  final DateTime selectedMonth;
  final double totalIncome;
  final double totalExpense;
  final double totalBalance;
  final List<TransactionItem> transactions;
  final VoidCallback onLogout;
  final VoidCallback onSelectMonth;
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;

  static const Color primaryBeige = Color(0xFFFCF1D0);
  static const Color darkBeige = Color(0xFF5D4222);
  static const Color accentBeige = Color(0xFFE5D3AF);

  const HomeTab({
    super.key,
    required this.currentUser,
    required this.selectedAvatarKey,
    required this.selectedLanguage,
    required this.selectedMonth,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalBalance,
    required this.transactions,
    required this.onLogout,
    required this.onSelectMonth,
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

  String _formatMonthYear(DateTime date) {
    return AppTranslations.formatMonthYear(widget.selectedLanguage, date);
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
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7EB),
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
                          color: Colors.grey.shade400,
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
                          bgColor: isExpense ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                          iconColor: isExpense ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.category,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: HomeTab.darkBeige),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'Danh mục cố định',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFECE7DB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Tên ghi chú (Editable)
                          const Text('Ghi chú / Tên giao dịch:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: titleController,
                            decoration: InputDecoration(
                              hintText: 'Nhập tên ghi chú...',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // 2. Số tiền (Editable)
                          const Text('Số tiền (đ):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [MoneyInputFormatter()],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isExpense ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              prefixText: isExpense ? '- ' : '+ ',
                              prefixStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isExpense ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
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
                              const Text('Thời gian:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(
                                formattedDateTime,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: HomeTab.darkBeige),
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
                                    await DatabaseHelper.instance.deleteTransaction(item.id);
                                    TransactionService.instance.notifyUpdated();
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã xóa giao dịch thành công!'), backgroundColor: Colors.red),
                                    );
                                  },
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Xóa', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ!'), backgroundColor: Colors.orange),
                                      );
                                      return;
                                    }

                                    setSheetState(() => isSaving = true);
                                    final updatedTx = item.copyWith(
                                      title: newTitle.isNotEmpty ? newTitle : item.category,
                                      amount: newAmount,
                                    );

                                    await DatabaseHelper.instance.insertTransaction(updatedTx, uid: item.uid);
                                    TransactionService.instance.notifyUpdated();

                                    if (!sheetCtx.mounted) return;
                                    Navigator.pop(sheetCtx);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã lưu thay đổi giao dịch!'), backgroundColor: Colors.green),
                                    );
                                  },
                            icon: isSaving
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.save_rounded),
                            label: const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.bold)),
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
      selectedLanguage: widget.selectedLanguage,
      ledgerId: TransactionService.instance.currentLedgerId,
      onTransactionsUpdated: () {
        _loadBudgets();
        _loadNotificationCounts();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.selectedLanguage;
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
                            style: const TextStyle(
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

              Row(
                children: [
                  // Month Picker
                  GestureDetector(
                    onTap: widget.onSelectMonth,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFECE7DB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 14, color: HomeTab.darkBeige),
                          const SizedBox(width: 6),
                          Text(
                            _formatMonthYear(widget.selectedMonth),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: HomeTab.darkBeige,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 18, color: HomeTab.darkBeige),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Bell icon with dynamic badge
                  GestureDetector(
                    onTap: _openNotificationCenter,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFECE7DB)),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.notifications_none_rounded, color: HomeTab.darkBeige, size: 22),
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
            ],
          ),

          const SizedBox(height: 16),

          // Total Balance Hero Card (Accent Beige theme)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF3E0), Color(0xFFFBEAD2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEAD8BA)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8C6D4A),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                MoneyText(
                  amount: widget.totalBalance,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF5D4222),
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
                            color: Colors.white.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF0E2CD)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2E7D32),
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
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF5D4222),
                                      ),
                                    ),
                                    MoneyText(
                                      amount: widget.totalIncome,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E7D32),
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
                            color: Colors.white.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF0E2CD)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFC62828),
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
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF5D4222),
                                      ),
                                    ),
                                    MoneyText(
                                      amount: widget.totalExpense,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFC62828),
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
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF706C66),
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
                          style: const TextStyle(
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFECE7DB)),
                    ),
                    child: Column(
                      children: budgetStatuses.take(2).map((s) {
                        final name = s.budget.categoryId ?? 'Tổng ngân sách tháng';
                        final pct = s.percent.clamp(0.0, 100.0);
                        Color barColor = const Color(0xFF4CAF50);
                        if (s.level == 'exceeded') {
                          barColor = Colors.red;
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
                                try {
                                  if (updatedBudget.id == null || updatedBudget.id!.isEmpty) {
                                    await BudgetService.instance.insertBudget(updatedBudget);
                                  } else {
                                    await BudgetService.instance.updateBudget(updatedBudget);
                                  }
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã cập nhật ngân sách!'), backgroundColor: Colors.green),
                                    );
                                  }
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
                                        style: const TextStyle(
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
                                      suffix: ' / ${s.limit.toInt()} đ',
                                      style: const TextStyle(
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
                                    backgroundColor: const Color(0xFFF2EFE6),
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
                style: const TextStyle(
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
                        selectedLanguage: widget.selectedLanguage,
                      ),
                    ),
                  );
                },
                child: Text(
                  AppTranslations.tr(lang, 'view_all'),
                  style: const TextStyle(
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFECE7DB)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long_rounded, size: 48, color: Color(0xFFE5D3AF)),
                      const SizedBox(height: 8),
                      Text(
                        AppTranslations.tr(lang, 'no_recent_transactions'),
                        style: const TextStyle(
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFECE7DB)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.transactions.take(5).length,
                    separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 56, color: Color(0xFFF2EFE6)),
                    itemBuilder: (ctx, index) {
                      final item = widget.transactions[index];

                      return ListTile(
                        onTap: () => _showTransactionDetailSheet(item),
                        leading: CategoryIcon(
                          categoryOrIconKey: item.category,
                          size: 40,
                          bgColor: item.isExpense ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                          iconColor: item.isExpense ? const Color(0xFFE53935) : const Color(0xFF4CAF50),
                        ),
                        title: Text(
                          item.title.isNotEmpty ? item.title : item.category,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222222),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          _formatDateTime(item.date),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: MoneyText(
                          amount: item.amount,
                          prefix: item.isExpense ? '-' : '+',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: item.isExpense ? const Color(0xFFE53935) : const Color(0xFF4CAF50),
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
