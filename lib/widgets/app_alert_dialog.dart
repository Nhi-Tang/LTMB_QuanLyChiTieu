import 'package:flutter/material.dart';

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
            color: isSuccess ? const Color(0xFFE5D3AF) : Colors.red,
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
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSuccess ? const Color(0xFFE5D3AF) : Colors.red,
            foregroundColor: isSuccess ? const Color(0xFF5D4222) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.pop(ctx),
          child: Text('OK', style: TextStyle(color: isSuccess ? const Color(0xFF5D4222) : Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
