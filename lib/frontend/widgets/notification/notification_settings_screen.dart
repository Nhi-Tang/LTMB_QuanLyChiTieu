import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../backend/services/daily_reminder_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_language.dart';
import '../../utils/app_translations.dart';

class NotificationSettingsScreen extends StatefulWidget {

  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _bankNotificationsEnabled = true;
  bool _autoConfirmHighConfidence = false;
  bool _dailyReminderEnabled = true;
  int _reminderHour = 20;
  int _reminderMinute = 30;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _bankNotificationsEnabled = prefs.getBool('bank_notifications_enabled') ?? true;
        _autoConfirmHighConfidence = prefs.getBool('auto_confirm_high_confidence') ?? false;
        _dailyReminderEnabled = prefs.getBool('daily_reminder_enabled') ?? true;
        _reminderHour = prefs.getInt('daily_reminder_hour') ?? 20;
        _reminderMinute = prefs.getInt('daily_reminder_minute') ?? 30;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (key == 'daily_reminder_enabled') {
      if (value) {
        DailyReminderService.instance.scheduleDailyEveningReminder();
      } else {
        DailyReminderService.instance.cancelDailyReminder();
      }
    }
  }

  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.darkBeige,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _reminderHour = picked.hour;
        _reminderMinute = picked.minute;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('daily_reminder_hour', picked.hour);
      await prefs.setInt('daily_reminder_minute', picked.minute);

      if (_dailyReminderEnabled) {
        DailyReminderService.instance.scheduleDailyEveningReminder();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = '${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      // Dùng AppBar theo theme sổ (nền giấy, chữ mực) như các màn con khác
      appBar: AppBar(
        title: Text(
          AppTranslations.tr(AppLanguage.instance.value, 'bank_notification_settings'),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Toggles Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        SwitchListTile(
                          activeTrackColor: AppColors.primary,
                          secondary: Icon(Icons.notifications_active_rounded, color: AppColors.darkBeige),
                          title: Text(context.t('Tự động đọc thông báo ngân hàng'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(context.t('Tự động quét thông báo từ Vietcombank, MB, Techcombank, MoMo,...'), style: TextStyle(fontSize: 12)),
                          value: _bankNotificationsEnabled,
                          onChanged: (val) {
                            setState(() => _bankNotificationsEnabled = val);
                            _saveSetting('bank_notifications_enabled', val);
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          activeTrackColor: AppColors.primary,
                          secondary: Icon(Icons.verified_rounded, color: AppColors.darkBeige),
                          title: Text(context.t('Tự động xác nhận khi độ tin cậy cao'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(context.t('Khi phát hiện danh mục khớp 3+ lần trong lịch sử, tự động ghi nhận giao dịch'), style: TextStyle(fontSize: 12)),
                          value: _autoConfirmHighConfidence,
                          onChanged: (val) {
                            setState(() => _autoConfirmHighConfidence = val);
                            _saveSetting('auto_confirm_high_confidence', val);
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.alarm_rounded, color: AppColors.darkBeige),
                          title: Text(
                            context.t('Nhắc nhở tổng hợp lúc {formattedTime}', {'formattedTime': formattedTime}),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(context.t('Thông báo nhắc bạn kiểm tra các giao dịch chờ xác nhận mỗi ngày'), style: TextStyle(fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: _selectReminderTime,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    formattedTime,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Switch(
                                activeTrackColor: AppColors.primary,
                                value: _dailyReminderEnabled,
                                onChanged: (val) {
                                  setState(() => _dailyReminderEnabled = val);
                                  _saveSetting('daily_reminder_enabled', val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
