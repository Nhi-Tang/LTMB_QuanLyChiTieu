import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../backend/services/bank_parser/bank_notification_parser.dart';
import '../../../backend/services/category_suggestion_service.dart';
import '../../../backend/services/daily_reminder_service.dart';
import '../../theme/app_colors.dart';

import 'pending_inbox.dart';
import 'permission_guide_screen.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final String selectedLanguage;

  const NotificationSettingsScreen({super.key, this.selectedLanguage = 'Tiếng Việt'});

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

  final TextEditingController _customTitleController = TextEditingController(text: 'Vietcombank');
  final TextEditingController _customTextController = TextEditingController(
    text: 'SD TK 0011001234567 -150,000 VND luc 12:30. So du 5,000,000 VND. Ref: Mua do an tai Highlands Coffee',
  );
  String _selectedSampleBank = 'Vietcombank';

  final Map<String, Map<String, String>> _sampleNotifications = {
    'Vietcombank': {
      'pkg': 'com.VCB',
      'title': 'Vietcombank',
      'text': 'SD TK 0011001234567 -150,000 VND luc 12:30. So du 5,000,000 VND. Ref: Mua do an tai Highlands Coffee',
    },
    'MB Bank': {
      'pkg': 'com.mbmobile',
      'title': 'MB Bank',
      'text': 'TK 123456789 GD: +2,000,000VND 12/05/23 15:30. So du 12,500,000VND. ND: Nhan luong thang 5',
    },
    'Techcombank': {
      'pkg': 'vn.com.techcombank.bb.app',
      'title': 'Techcombank',
      'text': 'TCB: TK 19031234567890 GD: -50,000VND. So du 1,200,000VND. Noi dung: Thanh toan tien gui xe',
    },
    'MoMo': {
      'pkg': 'com.mservice.momopay',
      'title': 'MoMo',
      'text': 'Thanh toán thành công 85.000đ cho Circle K. Mã GD 12345678',
    },
    'BIDV': {
      'pkg': 'com.vnpay.bidv',
      'title': 'BIDV',
      'text': 'BIDV: TK 123456789 -300,000VND. So du: 3,500,000VND. ND: Thanh toan tien dien Thang 5',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _customTitleController.dispose();
    _customTextController.dispose();
    super.dispose();
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
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.darkBeige,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
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

  void _selectSample(String bankName) {
    final sample = _sampleNotifications[bankName];
    if (sample != null) {
      setState(() {
        _selectedSampleBank = bankName;
        _customTitleController.text = sample['title']!;
        _customTextController.text = sample['text']!;
      });
    }
  }

  Future<void> _testSampleNotification() async {
    final sample = _sampleNotifications[_selectedSampleBank] ?? {
      'pkg': 'com.VCB',
      'title': _customTitleController.text,
      'text': _customTextController.text,
    };

    final title = _customTitleController.text.trim();
    final text = _customTextController.text.trim();
    final pkg = sample['pkg'] ?? 'com.VCB';

    final parsed = BankNotificationParser.parseNotification(
      packageName: pkg,
      title: title,
      text: text,
      timestamp: DateTime.now(),
    );

    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể phân tích giao dịch! Thông báo bị bỏ qua hoặc không chứa số tiền.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Xử lý lưu nháp & gợi ý danh mục (chế độ thử nghiệm test mode)
    final pendingItem = await CategorySuggestionService.instance.processIncomingNotification(
      parsed,
      isTestMode: true,
    );

    if (!mounted) return;

    if (pendingItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giao dịch mẫu bị trùng lặp fingerprint (đã tồn tại trong 10 phút gần đây).'),
          backgroundColor: Colors.blueGrey,
        ),
      );
      return;
    }

    // Hiển thị kết quả thử nghiệm
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Thử nghiệm thành công!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResultRow('Ngân hàng', parsed.bankName),
              _buildResultRow('Loại giao dịch', parsed.type == 'expense' ? 'Chi tiêu (-)' : 'Thu nhập (+)'),
              _buildResultRow('Số tiền', '${parsed.amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ'),
              _buildResultRow('Số tài khoản', 'TK ***${parsed.accountLast4}'),
              _buildResultRow('Mô tả trích xuất', parsed.description),
              _buildResultRow('Danh mục gợi ý', pendingItem.suggestedCategoryId ?? 'Chưa phân loại'),
              _buildResultRow('Độ tin cậy', pendingItem.suggestionConfidence.toUpperCase()),
              _buildResultRow('Trạng thái', pendingItem.status == 'confirmed' ? 'Đã tự động xác nhận' : 'Đã tạo bản nháp (Chờ xác nhận)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              PendingInboxSheet.show(
      context,
      selectedLanguage: widget.selectedLanguage,
    );
            },
            child: const Text('Xem Hộp thư Chờ xác nhận'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkBeige),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = '${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7EB),
      appBar: AppBar(
        title: const Text('Tự động đọc thông báo ngân hàng'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                          secondary: const Icon(Icons.notifications_active_rounded, color: AppColors.darkBeige),
                          title: const Text('Tự động đọc thông báo ngân hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('Tự động quét thông báo từ Vietcombank, MB, Techcombank, MoMo,...', style: TextStyle(fontSize: 12)),
                          value: _bankNotificationsEnabled,
                          onChanged: (val) {
                            setState(() => _bankNotificationsEnabled = val);
                            _saveSetting('bank_notifications_enabled', val);
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          activeTrackColor: AppColors.primary,
                          secondary: const Icon(Icons.verified_rounded, color: AppColors.darkBeige),
                          title: const Text('Tự động xác nhận khi độ tin cậy cao', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('Khi phát hiện danh mục khớp 3+ lần trong lịch sử, tự động ghi nhận giao dịch', style: TextStyle(fontSize: 12)),
                          value: _autoConfirmHighConfidence,
                          onChanged: (val) {
                            setState(() => _autoConfirmHighConfidence = val);
                            _saveSetting('auto_confirm_high_confidence', val);
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.alarm_rounded, color: AppColors.darkBeige),
                          title: Text(
                            'Nhắc nhở tổng hợp lúc $formattedTime',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: const Text('Thông báo nhắc bạn kiểm tra các giao dịch chờ xác nhận mỗi ngày', style: TextStyle(fontSize: 12)),
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
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
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
                  const SizedBox(height: 16),

                  // Permission Guide Link Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.accentBeige,
                        child: Icon(Icons.security_rounded, color: AppColors.darkBeige),
                      ),
                      title: const Text('Hướng dẫn cấp quyền & Tối ưu pin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Bật quyền truy cập thông báo và duy trì chạy ngầm', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.darkBeige),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PermissionGuideScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Test Tool Section: "Thử với thông báo mẫu"
                  const Text(
                    'Thử với thông báo mẫu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkBeige),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chọn ngân hàng hoặc nhập nội dung thông báo bất kỳ để kiểm tra bộ lọc tự động:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),

                  // Preset Bank Chips
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _sampleNotifications.keys.map((bank) {
                        final isSelected = bank == _selectedSampleBank;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(bank),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.darkBeige,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (_) => _selectSample(bank),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sample Input Fields
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _customTitleController,
                            decoration: const InputDecoration(
                              labelText: 'Tiêu đề thông báo',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _customTextController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Nội dung thông báo',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.all(12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _testSampleNotification,
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text(
                                'Thử nghiệm ngay',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
