import 'package:flutter/material.dart';
import '../../utils/app_language.dart';
import '../../theme/app_colors.dart';

/// Tab Chi tiêu | Thu nhập | Ngân sách kiểu sổ: chữ thường, tab đang chọn gạch chân bằng mực
class TransactionTypeSwitcher extends StatelessWidget {
  final int selectedIndex; // 0: Chi tiêu, 1: Thu nhập, 2: Ngân sách
  final ValueChanged<int> onTabChanged;

  const TransactionTypeSwitcher({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.rule))),
      child: Row(
        children: [
          _buildTab(0, context.t('Chi tiêu')),
          _buildTab(1, context.t('Thu nhập')),
          _buildTab(2, context.t('Ngân sách')),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTabChanged(index),
      child: Container(
        margin: const EdgeInsets.only(right: 24),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: isSelected ? AppColors.ink : Colors.transparent, width: 2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.ink : AppColors.unselectedTab,
          ),
        ),
      ),
    );
  }
}
