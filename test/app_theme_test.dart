import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlychitieu/frontend/theme/app_colors.dart';
import 'package:quanlychitieu/frontend/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => AppTheme.instance.value = ThemeMode.light);

  test('chế độ sáng giữ nguyên bảng màu cũ', () {
    AppTheme.instance.value = ThemeMode.light;
    expect(AppColors.isDark, isFalse);
    expect(AppColors.tealDark, const Color(0xFF00463E));
    expect(AppColors.tealPale, const Color(0xFFCCF7F7));
    expect(AppColors.surface, const Color(0xFFFFFFFF));
    expect(AppColors.grey600, Colors.grey.shade600);
  });

  test('chế độ tối đổi nền thành tối và chữ thành sáng', () {
    AppTheme.instance.value = ThemeMode.dark;
    expect(AppColors.isDark, isTrue);
    expect(AppColors.surface.computeLuminance(), lessThan(0.05));
    expect(AppColors.tealWhite.computeLuminance(), lessThan(0.05));
    expect(AppColors.textPrimary.computeLuminance(), greaterThan(0.8));
    expect(AppColors.tealDark.computeLuminance(), greaterThan(0.6));
  });

  test('màu nhấn và chữ trên nền teal không đổi theo chế độ', () {
    AppTheme.instance.value = ThemeMode.dark;
    expect(AppColors.teal, const Color(0xFF00BFB5));
    expect(AppColors.onTeal, const Color(0xFF00463E));
  });
}
