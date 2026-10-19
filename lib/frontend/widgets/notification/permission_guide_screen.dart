import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../theme/app_colors.dart';

class PermissionGuideScreen extends StatefulWidget {
  const PermissionGuideScreen({super.key});

  @override
  State<PermissionGuideScreen> createState() => _PermissionGuideScreenState();
}

class _PermissionGuideScreenState extends State<PermissionGuideScreen> with WidgetsBindingObserver {
  static const _channel = MethodChannel('com.mousey.app/notifications_control');
  bool _isNotificationPermissionGranted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    try {
      final bool granted = await _channel.invokeMethod('isNotificationPermissionGranted');
      if (mounted) {
        setState(() {
          _isNotificationPermissionGranted = granted;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      await _channel.invokeMethod('requestNotificationPermission');
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      await openAppSettings();
    }
  }

  Future<void> _openBatteryOptimizationSettings() async {
    try {
      await _channel.invokeMethod('openBatteryOptimizationSettings');
    } catch (e) {
      debugPrint('Error opening battery settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7EB),
      appBar: AppBar(
        title: const Text('Hướng dẫn cấp quyền & Tối ưu pin'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Overview Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isNotificationPermissionGranted
                          ? Colors.green.shade50
                          : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isNotificationPermissionGranted
                            ? Colors.green.shade300
                            : Colors.amber.shade400,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isNotificationPermissionGranted
                              ? Icons.check_circle_rounded
                              : Icons.warning_amber_rounded,
                          color: _isNotificationPermissionGranted
                              ? Colors.green.shade700
                              : Colors.amber.shade800,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isNotificationPermissionGranted
                                    ? 'Đã cấp quyền đọc thông báo'
                                    : 'Chưa cấp quyền truy cập thông báo',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: _isNotificationPermissionGranted
                                      ? Colors.green.shade900
                                      : Colors.amber.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isNotificationPermissionGranted
                                    ? 'Mousey đã sẵn sàng tự động ghi nhận giao dịch ngân hàng.'
                                    : 'Vui lòng hoàn thành Hướng dẫn bên dưới để bật tính năng.',
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Step 1 Section
                  _buildStepSection(
                    stepNumber: '1',
                    title: 'Quyền đọc thông báo (Notification Access)',
                    description:
                        'Cho phép Mousey lắng nghe thông báo biến động số dư từ ứng dụng ngân hàng (Vietcombank, MB Bank, Techcombank, MoMo,...).',
                    buttonText: 'Mở Cài Đặt Quyền Thông Báo',
                    buttonIcon: Icons.notifications_active_rounded,
                    onPressed: _requestNotificationPermission,
                    isDone: _isNotificationPermissionGranted,
                  ),

                  const SizedBox(height: 20),

                  // Android 13+ Restricted Settings Guide Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: Colors.orange.shade900, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Android 13+ "Cài đặt bị hạn chế"?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nếu công tắc gạt bị ẩn/xám do tính năng bảo vệ Android 13+:\n'
                          '1. Vào Cài đặt máy -> Ứng dụng -> Chọn Mousey.\n'
                          '2. Nhấn biểu tượng 3 chấm ở góc trên bên phải màn hình.\n'
                          '3. Chọn "Cho phép cài đặt bị hạn chế" (Allow restricted settings).\n'
                          '4. Quay lại đây và bấm nút mở quyền ở Bước 1.',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade900, height: 1.45),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Step 2 Section: Battery Optimization
                  _buildStepSection(
                    stepNumber: '2',
                    title: 'Tắt tối ưu hóa pin (Battery Optimization)',
                    description:
                        'Hệ điều hành Android có thể tự động ngắt các dịch vụ ngầm. Tắt tối ưu hóa pin để Mousey không bị bỏ lỡ thông báo khi khóa màn hình.',
                    buttonText: 'Mở Cài Đặt Tối Ưu Pin',
                    buttonIcon: Icons.battery_saver_rounded,
                    onPressed: _openBatteryOptimizationSettings,
                    isDone: false,
                  ),

                  const SizedBox(height: 20),

                  // OEM Autostart Guide Card (Xiaomi / Oppo / Vivo / Samsung)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFECE7DB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.phone_android_rounded, color: AppColors.primary, size: 22),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Hướng dẫn theo từng hãng điện thoại',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.darkBeige,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildOemGuideItem('Xiaomi / Poco (MIUI / HyperOS)', 'Vào Bảo mật -> Quản lý ứng dụng -> Mousey -> Bật "Tự khởi chạy" (Autostart) & Chọn Tắt hạn chế pin.'),
                        _buildOemGuideItem('Oppo / Realme / OnePlus', 'Vào Quản lý ứng dụng -> Mousey -> Bật "Cho phép hoạt động chạy ngầm" & Bật Tự khởi chạy.'),
                        _buildOemGuideItem('Vivo / iQOO', 'Vào Cài đặt -> Pin -> Quản lý mức tiêu thụ điện năng ngầm -> Chọn Mousey -> Cho phép chạy ngầm.'),
                        _buildOemGuideItem('Samsung Galaxy', 'Vào Cài đặt -> Ứng dụng -> Mousey -> Pin -> Chọn "Không hạn chế" (Unrestricted).'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Security & Privacy Note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_rounded, color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bảo mật & Quyền riêng tư',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.darkBeige,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Mousey chỉ đọc thông báo từ danh sách các ứng dụng ngân hàng được hỗ trợ. Dữ liệu số dư và giao dịch được xử lý hoàn toàn trên thiết bị và lưu trữ trong cơ sở dữ liệu SQLite của bạn.',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
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

  Widget _buildOemGuideItem(String brand, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(brand, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
          const SizedBox(height: 2),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildStepSection({
    required String stepNumber,
    required String title,
    required String description,
    required String buttonText,
    required IconData buttonIcon,
    required VoidCallback onPressed,
    required bool isDone,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isDone ? Colors.green : AppColors.primary,
                child: isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        stepNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBeige,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDone ? Colors.green : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onPressed,
              icon: Icon(buttonIcon, size: 18),
              label: Text(
                isDone ? 'Đã cấp quyền - Cài đặt lại' : buttonText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
