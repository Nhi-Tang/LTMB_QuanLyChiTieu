import 'package:flutter/material.dart';
import '../../../backend/database/db_helper.dart';
import '../../../backend/services/transaction_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_language.dart';
import '../app_alert_dialog.dart';

void showDeleteMyDataDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
          const SizedBox(width: 8),
          Text(context.t('Cảnh báo xóa dữ liệu'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Text(
        context.t('Bạn có chắc chắn muốn xóa toàn bộ giao dịch, tài khoản và danh mục tùy chỉnh? Hành động này không thể hoàn tác!'),
        style: TextStyle(fontSize: 14, color: AppColors.black87),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(context.t('Hủy'), style: TextStyle(color: AppColors.grey500)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            Navigator.pop(ctx);
            await DatabaseHelper.instance.clearTransactions();
            TransactionService.instance.notifyUpdated();
            if (!context.mounted) return;
            showAppAlertDialog(
              context: context,
              title: context.t('Đã xóa dữ liệu'),
              message: context.t('Toàn bộ dữ liệu tài chính cá nhân đã được làm sạch thành công.'),
              isSuccess: true,
            );
          },
          child: Text(context.t('Xác nhận Xóa'), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}
