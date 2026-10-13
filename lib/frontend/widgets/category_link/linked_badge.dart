import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class LinkedBadge extends StatelessWidget {
  final bool isLinked;

  const LinkedBadge({
    super.key,
    required this.isLinked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLinked ? AppColors.linkedBadge : AppColors.borderBeige.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLinked ? AppColors.primaryGreen.withValues(alpha: 0.3) : AppColors.unselectedTab,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLinked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: isLinked ? AppColors.primaryGreen : AppColors.textSub,
          ),
          const SizedBox(width: 4),
          Text(
            isLinked ? 'Đã liên kết' : 'Chưa liên kết',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isLinked ? AppColors.primaryGreen : AppColors.textSub,
            ),
          ),
        ],
      ),
    );
  }
}
