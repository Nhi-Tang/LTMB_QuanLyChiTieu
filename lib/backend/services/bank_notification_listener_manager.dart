import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bank_parser/bank_notification_parser.dart';
import 'category_suggestion_service.dart';
import 'daily_reminder_service.dart';
import 'pro_service.dart';

class BankNotificationListenerManager {
  static final BankNotificationListenerManager instance = BankNotificationListenerManager._();
  BankNotificationListenerManager._();

  static const _eventChannel = EventChannel('com.mousey.app/notifications');
  StreamSubscription? _subscription;
  bool _isListening = false;
  bool _isAdmin = false;

  /// Đọc thông báo ngân hàng là tính năng PRO (admin luôn được dùng)
  bool get _canUseBankNotifications => _isAdmin || ProService.instance.isPro;

  void startListening({String? uid, bool isAdmin = false}) {
    if (_isListening) {
      stopListening();
    }
    _isAdmin = isAdmin;

    // Lên lịch nhắc nhở tổng hợp hàng ngày lúc 20:30
    DailyReminderService.instance.scheduleDailyEveningReminder(uid: uid);

    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) async {
        if (event is Map) {
          // Chỉ ghi cho đúng tài khoản đang đăng nhập và tài khoản đó phải là PRO
          if (uid == null || FirebaseAuth.instance.currentUser?.uid != uid) return;
          if (!_canUseBankNotifications) return;

          final prefs = await SharedPreferences.getInstance();
          final enabled = prefs.getBool('bank_notifications_enabled') ?? true;
          if (!enabled) return;

          final packageName = event['packageName']?.toString() ?? '';
          final title = event['title']?.toString() ?? '';
          final rawText = event['text']?.toString() ?? '';
          final bigText = event['bigText']?.toString() ?? '';
          final text = bigText.length > rawText.length ? bigText : rawText;

          final timestampMs = event['timestamp'] as num?;
          final timestamp = timestampMs != null
              ? DateTime.fromMillisecondsSinceEpoch(timestampMs.toInt())
              : DateTime.now();

          final parsed = BankNotificationParser.parseNotification(
            packageName: packageName,
            title: title,
            text: text,
            timestamp: timestamp,
          );

          if (parsed != null) {
            await CategorySuggestionService.instance.processIncomingNotification(
              parsed,
              uid: uid,
            );
            // Cập nhật lại lịch nhắc nhở nếu có bản nháp mới
            DailyReminderService.instance.scheduleDailyEveningReminder(uid: uid);
          }
        }
      },
      onError: (error) {
        // Log channel error nếu xảy ra
      },
    );

    _isListening = true;
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    _isAdmin = false;
  }
}
