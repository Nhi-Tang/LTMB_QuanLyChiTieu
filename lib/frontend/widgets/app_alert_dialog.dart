import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

Future<void> showAppAlertDialog({
  required BuildContext context,
  required String title,
  required String message,
  bool isSuccess = true,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
            color: isSuccess ? AppColors.teal : Colors.red,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(fontSize: 14, color: AppColors.black87),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSuccess ? AppColors.teal : Colors.red,
            foregroundColor: isSuccess ? AppColors.onTeal : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.pop(ctx),
          child: Text('OK', style: TextStyle(color: isSuccess ? AppColors.onTeal : Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
