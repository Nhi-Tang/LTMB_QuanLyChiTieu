import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanlychitieu/frontend/theme/app_colors.dart';
import 'package:quanlychitieu/frontend/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => AppTheme.instance.value = ThemeMode.light);

  test('chế độ sáng dùng bảng màu sổ tay: giấy kem, mực xanh navy', () {
    AppTheme.instance.value = ThemeMode.light;
    expect(AppColors.isDark, isFalse);
    expect(AppColors.tealDark, const Color(0xFF1E2A5A));
    expect(AppColors.tealPale, const Color(0xFFE9EBF6));
    expect(AppColors.background, const Color(0xFFFAF8F1));
    expect(AppColors.surface, const Color(0xFFFFFDF8));
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

  test('chữ trên nền màu chính luôn trắng; thu xanh lá, chi đỏ', () {
    AppTheme.instance.value = ThemeMode.light;
    expect(AppColors.income, const Color(0xFF2E7D4F));
    expect(AppColors.expense, const Color(0xFFC0392B));
    AppTheme.instance.value = ThemeMode.dark;
    expect(AppColors.onTeal, Colors.white);
  });
}
