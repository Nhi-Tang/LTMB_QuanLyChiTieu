/// Cấu hình kết nối tới backend FastAPI.
///
/// Mặc định dùng server thật trên Render (https).
/// Chạy với backend trên máy tính (emulator Android, 10.0.2.2 = localhost của máy tính):
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mousey-api.onrender.com',
  );

  // Gói free của Render ngủ sau 15 phút không có request; lần gọi đầu mất ~30-60s để khởi động
  static const Duration timeout = Duration(seconds: 60);
}
