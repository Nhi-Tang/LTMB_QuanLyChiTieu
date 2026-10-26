import 'package:flutter/material.dart';
import '../../backend/services/budget_service.dart';
import '../../core/widgets/money_text.dart';
import '../../core/widgets/category_icon.dart';
import '../utils/app_language.dart';
import '../theme/app_colors.dart';

class BudgetCard extends StatelessWidget {
  final BudgetStatus status;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const BudgetCard({
    super.key,
    required this.status,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  Color _getProgressColor(String level) {
    switch (level) {
      case 'exceeded':
        return AppColors.expense; // Đỏ
      case 'reached':
        return const Color(0xFFF4511E); // Cam đậm
      case 'warning':
        return const Color(0xFFF57C00); // Vàng/Cam
      case 'ok':
      default:
        return AppColors.incomeLight; // Xanh lá
    }
  }

  @override
  Widget build(BuildContext context) {
    final budget = status.budget;
    final categoryName = budget.categoryId == null || budget.categoryId!.isEmpty
        ? context.t('Tổng ngân sách tháng')
        : context.tCategory(budget.categoryId!);
    final progressColor = _getProgressColor(status.level);
    final progressVal = (status.percent / 100.0).clamp(0.0, 1.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.tealDark.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Icon, Category Name, Actions (Edit/Delete)
            Row(
              children: [
                CategoryIcon(
                  categoryOrIconKey: budget.categoryId ?? 'total',
                  size: 42,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.tealDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (budget.isRecurring)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                context.t('Định kỳ'),
                                style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              budget.month != null ? context.t('Tháng {month}', {'month': budget.month}) : context.t('Mọi tháng'),
                              style: TextStyle(fontSize: 12, color: AppColors.grey600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    icon: Icon(Icons.edit_rounded, size: 18, color: AppColors.grey500),
                    onPressed: onEdit,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.redAccent),
                    onPressed: onDelete,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Spent / Limit & Percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: MoneyText(
                    amount: status.spent,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: MoneyText(
                    amount: status.limit,
                    prefix: context.t('Hạn mức: '),
                    alignment: Alignment.centerRight,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.grey700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progressVal,
                minHeight: 10,
                backgroundColor: AppColors.grey200,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 10),

            // Bottom stats: Remaining & Daily budget / Percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: MoneyText(
                    amount: status.remaining.abs(),
                    prefix: status.remaining >= 0 ? context.t('Còn lại: ') : context.t('Vượt: '),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: status.remaining >= 0 ? AppColors.grey600 : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: MoneyText(
                    amount: status.dailyRemaining,
                    prefix: context.t('Chi tiêu/ngày: '),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${status.percent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
