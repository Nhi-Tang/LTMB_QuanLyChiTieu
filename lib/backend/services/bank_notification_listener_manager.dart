import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bank_parser/bank_notification_parser.dart';
import 'category_suggestion_service.dart';
import 'daily_reminder_service.dart';

class BankNotificationListenerManager {
  static final BankNotificationListenerManager instance = BankNotificationListenerManager._();
  BankNotificationListenerManager._();

  static const _eventChannel = EventChannel('com.mousey.app/notifications');
  StreamSubscription? _subscription;
  bool _isListening = false;

  void startListening({String? uid}) {
    if (_isListening) {
      stopListening();
    }

    // Lên lịch nhắc nhở tổng hợp hàng ngày lúc 20:30
    DailyReminderService.instance.scheduleDailyEveningReminder(uid: uid);

    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) async {
        if (event is Map) {
          final prefs = await SharedPreferences.getInstance();
          final enabled = prefs.getBool('bank_notifications_enabled') ?? true;
          if (!enabled) return;

          final packageName = event['packageName']?.toString() ?? '';
          final title = event['title']?.toString() ?? '';
          final text = event['text']?.toString() ?? '';
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
  }
}
