import 'package:flutter/material.dart';
import '../../utils/app_language.dart';
import '../../theme/app_colors.dart';

class TransactionTypeTabs extends StatelessWidget {
  final int selectedIndex; // 0: Chi tiêu, 1: Thu nhập, 2: Chuyển khoản
  final ValueChanged<int> onTabChanged;

  const TransactionTypeTabs({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.tealPale,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _buildTab(0, context.t('Chi tiêu'), Icons.arrow_downward_rounded, AppColors.expense),
          _buildTab(1, context.t('Thu nhập'), Icons.arrow_upward_rounded, AppColors.incomeLight),
          _buildTab(2, context.t('Chuyển khoản'), Icons.swap_horiz_rounded, const Color(0xFF1E88E5)),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, IconData icon, Color color) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? color : Colors.grey[700]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.black87 : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
