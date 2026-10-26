import 'package:flutter/material.dart';
import '../../backend/models/budget_model.dart';
import '../../backend/services/budget_service.dart';
import '../../backend/services/transaction_service.dart';
import '../utils/app_translations.dart';
import '../widgets/budget_card.dart';
import '../widgets/budget_form_sheet.dart';
import '../utils/app_language.dart';
import '../theme/app_colors.dart';

class BudgetsScreen extends StatefulWidget {
  final String ledgerId;

  const BudgetsScreen({
    super.key,
    this.ledgerId = 'default_ledger',
  });

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    BudgetService.instance.addListener(_onBudgetsUpdated);
    BudgetService.instance.loadBudgets(_monthStr);
  }

  void _onBudgetsUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    BudgetService.instance.removeListener(_onBudgetsUpdated);
    super.dispose();
  }

  String get _monthStr {
    return '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';
  }

  String get _activeLedgerId {
    return widget.ledgerId != 'default_ledger'
        ? widget.ledgerId
        : TransactionService.instance.currentLedgerId;
  }

  void _showAddEditBudget({BudgetModel? editingBudget}) {
    BudgetFormSheet.show(
      context: context,
      ledgerId: _activeLedgerId,
      currentMonth: _monthStr,
      editingBudget: editingBudget,
      existingBudgets: BudgetService.instance.currentBudgets.map((b) => b.budget).toList(),
      onSave: (budget) async {
        try {
          if (budget.id == null || budget.id!.isEmpty) {
            await BudgetService.instance.insertBudget(budget);
          } else {
            await BudgetService.instance.updateBudget(budget);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.t('Đã lưu ngân sách thành công!')), backgroundColor: Colors.green),
            );
          }
        } catch (e) {
          debugPrint('Error saving budget: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.t('Lỗi lưu ngân sách: {e}', {'e': e})), backgroundColor: Colors.red),
            );
          }
        }
      },
    );
  }

  Future<void> _deleteBudget(String budgetId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.t('Xác nhận xóa')),
        content: Text(context.t('Bạn có chắc chắn muốn xóa ngân sách này?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.t('Hủy'), style: TextStyle(color: AppColors.grey500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.t('Xóa'), style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await BudgetService.instance.deleteBudget(budgetId);
    }
  }

  String _formatMonthYear(DateTime date) {
    return AppTranslations.formatMonthYear(context.lang, date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tealWhite,
      appBar: AppBar(
        backgroundColor: AppColors.tealPale,
        elevation: 0,
        centerTitle: true,
        title: Text(
          context.t('Quản Lý Ngân Sách'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.tealDark,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: IconThemeData(color: AppColors.tealDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 28),
            onPressed: () => _showAddEditBudget(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month Selector Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppColors.tealPale.withValues(alpha: 0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    context.t('Tháng chi tiêu'),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.tealDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedMonth,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null && mounted) {
                        setState(() {
                          _selectedMonth = DateTime(picked.year, picked.month, 1);
                        });
                        BudgetService.instance.loadBudgets(_monthStr);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.tealDark.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _formatMonthYear(_selectedMonth),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.tealDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.tealDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Budget List
          Expanded(
            child: ListenableBuilder(
              listenable: BudgetService.instance,
              builder: (context, _) {
                final isLoading = BudgetService.instance.isLoading;
                final budgetStatuses = BudgetService.instance.currentBudgets;

                if (isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (budgetStatuses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pie_chart_outline_rounded, size: 64, color: AppColors.teal),
                        const SizedBox(height: 16),
                        Text(
                          context.t('Chưa có ngân sách nào trong tháng này'),
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.tealDark),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.tealDark,
                            foregroundColor: AppColors.tealPale,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          onPressed: () => _showAddEditBudget(),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(context.t('Thêm Ngân Sách Ngay'), style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: budgetStatuses.length,
                  itemBuilder: (context, index) {
                    final status = budgetStatuses[index];
                    return BudgetCard(
                      status: status,
                      onEdit: () => _showAddEditBudget(editingBudget: status.budget),
                      onDelete: () => status.budget.id != null ? _deleteBudget(status.budget.id!) : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
