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

  static const Duration timeout = Duration(seconds: 15);
}
