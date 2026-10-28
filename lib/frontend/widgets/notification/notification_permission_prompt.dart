import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../backend/services/pro_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_language.dart';

/// Lần đầu dùng app: xin quyền gửi thông báo (hộp hỏi của hệ thống, như quyền camera) cho mọi tài khoản,
/// để nhắc ghi chi tiêu hằng ngày và cảnh báo ngân sách hiện được trên Android 13+.
/// Tài khoản PRO được mời thêm quyền đọc thông báo ngân hàng (Android chỉ cho bật trong Cài đặt).
/// Mỗi tài khoản hỏi mỗi loại một lần.
class NotificationPermissionPrompt {
  NotificationPermissionPrompt._();

  static const _channel = MethodChannel('com.mousey.app/notifications_control');
  static bool _running = false;

  static Future<void> maybeAsk(BuildContext context, {required String uid}) async {
    if (_running) return;
    final prefs = await SharedPreferences.getInstance();
    final postKey = 'notification_post_asked_$uid';
    // Khoá cũ, trước đây chỉ PRO được hỏi và hỏi cả hai quyền cùng lúc
    final listenerKey = 'notification_permission_asked_$uid';
    final listenerAsked = prefs.getBool(listenerKey) ?? false;
    final askPost = !(prefs.getBool(postKey) ?? false) && !listenerAsked;
    final askListener = ProService.instance.isPro && !listenerAsked;
    if (!askPost && !askListener) return;

    _running = true;
    try {
      if (askPost) {
        await prefs.setBool(postKey, true);
        // Android 13+ / iOS: hiện hộp hỏi của hệ thống; máy cũ hơn coi như đã có quyền
        await Permission.notification.request();
      }

      if (!askListener) return;
      await prefs.setBool(listenerKey, true);
      if (defaultTargetPlatform != TargetPlatform.android || !context.mounted) return;
      final bool granted = await _channel.invokeMethod('isNotificationPermissionGranted') ?? false;
      if (granted || !context.mounted) return;

      final open = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 32),
          title: Text(ctx.t('Tự động ghi giao dịch ngân hàng')),
          content: Text(
            ctx.t('Mousey có thể đọc thông báo biến động số dư từ app ngân hàng để tự ghi giao dịch. Hãy bật quyền "Truy cập thông báo" cho Mousey ở màn cài đặt sắp mở nhé.'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.t('Để sau'), style: TextStyle(color: AppColors.grey500)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                ctx.t('Mở cài đặt'),
                style: const TextStyle(color: AppColors.onTeal, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      if (open == true) await _channel.invokeMethod('requestNotificationPermission');
    } catch (e) {
      debugPrint('Xin quyền thông báo lỗi: $e');
    } finally {
      _running = false;
    }
  }
}
