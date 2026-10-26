import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';

import '../../frontend/utils/app_language.dart';
class DailyReminderService {
  static final DailyReminderService instance = DailyReminderService._();
  DailyReminderService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await _notificationsPlugin.initialize(initSettings);
    _isInitialized = true;
  }

  Future<void> scheduleDailyEveningReminder({String? uid}) async {
    await init();

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('daily_reminder_enabled') ?? true;
    final hour = prefs.getInt('daily_reminder_hour') ?? 20;
    final minute = prefs.getInt('daily_reminder_minute') ?? 30;

    if (!enabled) {
      await cancelDailyReminder();
      return;
    }

    final pendingCount = await DatabaseHelper.instance.getPendingTransactionsCount(uid: uid);

    // Xoá thông báo cũ để đặt lịch mới
    await _notificationsPlugin.cancel(888);

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
    final formattedTime = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    final androidDetails = AndroidNotificationDetails(
      'mousey_bank_reminder',
      AppLanguage.instance.t('Nhắc nhở thu chi ngân hàng'),
      channelDescription: AppLanguage.instance.t('Nhắc nhở tổng hợp giao dịch chờ xác nhận lúc {formattedTime}', {'formattedTime': formattedTime}),
      importance: Importance.high,
      priority: Priority.high,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    final message = pendingCount > 0
        ? AppLanguage.instance.t('Bạn có {pendingCount} giao dịch ngân hàng chờ xác nhận trong ngày. Hãy kiểm tra ngay!', {'pendingCount': pendingCount})
        : AppLanguage.instance.t('Hãy mở Mousey để kiểm tra và cập nhật thu chi trong ngày hôm nay nhé!');

    try {
      await _notificationsPlugin.zonedSchedule(
        888,
        AppLanguage.instance.t('Mousey - Nhắc nhở thu chi'),
        message,
        tzScheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      // Fallback nếu exact alarm chưa được cấp quyền
      await _notificationsPlugin.zonedSchedule(
        888,
        AppLanguage.instance.t('Mousey - Nhắc nhở thu chi'),
        message,
        tzScheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelDailyReminder() async {
    await _notificationsPlugin.cancel(888);
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    int id = 999,
  }) async {
    await init();

    final androidDetails = AndroidNotificationDetails(
      'mousey_bank_transactions',
      AppLanguage.instance.t('Biến động số dư ngân hàng'),
      channelDescription: AppLanguage.instance.t('Thông báo khi có biến động số dư từ các ứng dụng ngân hàng'),
      importance: Importance.max,
      priority: Priority.high,
      ticker: AppLanguage.instance.t('Biến động số dư'),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
      );
    } catch (_) {}
  }
}
