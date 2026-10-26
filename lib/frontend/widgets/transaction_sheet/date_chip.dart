import 'package:flutter/material.dart';
import '../../utils/app_language.dart';
import '../../theme/app_colors.dart';

class DateChip extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onTap;

  const DateChip({
    super.key,
    required this.selectedDate,
    required this.onTap,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return AppLanguage.instance.t('Hôm nay');
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.tealWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.tealLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.tealDark),
            const SizedBox(width: 4),
            Text(
              _formatDate(selectedDate),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.tealDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
