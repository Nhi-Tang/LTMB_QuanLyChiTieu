import 'package:flutter/material.dart';
import 'mousey_colors.dart';
import '../../utils/app_language.dart';

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
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: MouseyColors.borderBeige,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _buildTab(0, context.t('Chi tiêu'), Icons.arrow_downward_rounded, MouseyColors.expenseRed),
          _buildTab(1, context.t('Thu nhập'), Icons.arrow_upward_rounded, MouseyColors.incomeGreen),
          _buildTab(2, context.t('Ngân sách'), Icons.pie_chart_outline_rounded, const Color(0xFF00463E)),
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
            color: isSelected ? MouseyColors.cardCream : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: isSelected ? Border.all(color: MouseyColors.selectedBorder, width: 1.5) : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
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
              Icon(icon, size: 15, color: isSelected ? color : MouseyColors.textSub),
              const SizedBox(width: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? MouseyColors.textMain : MouseyColors.textSub,
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
