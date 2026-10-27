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

  // Phong cách "cuốn sổ": giấy kem, mực xanh, đường kẻ mảnh (xem AppColors)
  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final ink = isDark ? const Color(0xFFE9EBF5) : const Color(0xFF1E2A5A);
    final primary = isDark ? const Color(0xFF4757A6) : const Color(0xFF1E2A5A);
    final paper = isDark ? const Color(0xFF15161D) : const Color(0xFFFAF8F1);
    final sheet = isDark ? const Color(0xFF1D1F29) : const Color(0xFFFFFDF8);
    final rule = isDark ? const Color(0xFF2E3247) : const Color(0xFFDDDFEC);
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1E2A5A),
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      surface: paper,
      onSurface: ink,
      outlineVariant: rule,
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: paper,
      dividerColor: rule,
      dividerTheme: DividerThemeData(color: rule, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: sheet,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: rule)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: ink)),
      tabBarTheme: TabBarThemeData(
        labelColor: ink,
        unselectedLabelColor: isDark ? const Color(0xFF7D8197) : const Color(0xFF9EA2B8),
        indicatorColor: ink,
        dividerColor: rule,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? primary : null),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: sheet,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: sheet, surfaceTintColor: Colors.transparent),
      inputDecorationTheme: InputDecorationTheme(
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: rule)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: ink, width: 1.5)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
    );
  }
}
