import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';

/// Chế độ giao diện (sáng / tối / theo hệ thống) của toàn app.
/// [AppColors] đọc [isDark] từ đây nên khi đổi chế độ mọi màn hình đổi theo.
class AppTheme extends ValueNotifier<ThemeMode> {
  AppTheme._() : super(ThemeMode.light);

  static final AppTheme instance = AppTheme._();

  static const String _key = 'mousey_theme_mode';

  bool get isDark {
    switch (value) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    value = _fromName(prefs.getString(_key));
  }

  Future<void> change(ThemeMode mode) async {
    value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  /// Báo cho các listener khi hệ thống đổi sáng/tối (chỉ có tác dụng ở chế độ theo hệ thống).
  void onPlatformBrightnessChanged() {
    if (value == ThemeMode.system) notifyListeners();
  }

  static ThemeMode _fromName(String? name) =>
      ThemeMode.values.firstWhere((m) => m.name == name, orElse: () => ThemeMode.light);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00BFB5),
      brightness: brightness,
    );
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : null,
      dialogTheme: DialogThemeData(backgroundColor: isDark ? const Color(0xFF1E1E1E) : null),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: isDark ? const Color(0xFF1E1E1E) : null),
    );
  }
}
