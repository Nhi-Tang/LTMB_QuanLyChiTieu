import 'package:flutter/material.dart';

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
      return 'Hôm nay';
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
          color: const Color(0xFFFAF7EE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5D3AF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF5D4222)),
            const SizedBox(width: 4),
            Text(
              _formatDate(selectedDate),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D4222),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
