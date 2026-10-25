/// Cấu hình kết nối tới backend FastAPI.
///
/// Đổi địa chỉ khi build/chạy:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
///   flutter build apk --dart-define=API_BASE_URL=https://api.mousey.vn
/// Mặc định 10.0.2.2 là localhost của máy tính khi chạy trên Android emulator.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  // Gói free của Render ngủ sau 15 phút không có request; lần gọi đầu mất ~30-60s để khởi động
  static const Duration timeout = Duration(seconds: 60);
}
