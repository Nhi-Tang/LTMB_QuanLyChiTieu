import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Toàn bộ màu giao diện của app. Mỗi màu có một giá trị cho chế độ sáng và
/// một cho chế độ tối; muốn đổi màu chủ đạo thì chỉ sửa bảng màu teal.
class AppColors {
  static bool get isDark => AppTheme.instance.isDark;
  static Color _c(Color light, Color dark) => isDark ? dark : light;

  // Bảng màu teal (colorhub.app), từ đậm đến nhạt. Ở chế độ tối thang màu
  // đảo lại: màu đậm dùng cho chữ thành màu sáng, màu nền nhạt thành màu tối.
  static Color get tealDark => _c(const Color(0xFF00463E), const Color(0xFFB3F3F0));
  static Color get teal => const Color(0xFF00BFB5);
  static Color get tealBright => const Color(0xFF00D1CC);
  static Color get mint => const Color(0xFF33DEBF);
  static Color get tealLight => _c(const Color(0xFF66EBE5), const Color(0xFF1E6B65));
  static Color get tealPale => _c(const Color(0xFFCCF7F7), const Color(0xFF0F3A37));
  static Color get tealMist => _c(const Color(0xFFE6FBFB), const Color(0xFF16302E));
  static Color get tealWhite => _c(const Color(0xFFF5FDFD), const Color(0xFF121A1A));

  /// Chữ/icon đặt trên nền teal: luôn đậm ở cả hai chế độ.
  static const Color onTeal = Color(0xFF00463E);

  // Màu trung tính
  static Color get ink => _c(const Color(0xFF222222), const Color(0xFFEDEDED));
  static Color get textPrimary => _c(const Color(0xFF171827), const Color(0xFFF2F2F5));
  static Color get textSecondary => _c(const Color(0xFF373743), const Color(0xFFC8C8D0));
  static Color get textMuted => _c(const Color(0xFF706C66), const Color(0xFFA8A39C));
  static Color get background => _c(const Color(0xFFF2F2F2), const Color(0xFF121212));
  static Color get surface => _c(const Color(0xFFFFFFFF), const Color(0xFF1E1E1E));
  static Color get border => _c(const Color(0xFFE0E0E0), const Color(0xFF3A3A3A));
  static Color get unselectedTab => _c(const Color(0xFF9E9E9E), const Color(0xFF8A8A8A));

  // Thang xám (thay cho Colors.grey[...]); chế độ tối dùng bậc đối xứng
  static Color get grey50 => _c(Colors.grey.shade50, Colors.grey.shade900);
  static Color get grey100 => _c(Colors.grey.shade100, Colors.grey.shade800);
  static Color get grey200 => _c(Colors.grey.shade200, Colors.grey.shade700);
  static Color get grey300 => _c(Colors.grey.shade300, Colors.grey.shade600);
  static Color get grey400 => _c(Colors.grey.shade400, Colors.grey.shade600);
  static Color get grey500 => Colors.grey.shade500;
  static Color get grey600 => _c(Colors.grey.shade600, Colors.grey.shade400);
  static Color get grey700 => _c(Colors.grey.shade700, Colors.grey.shade300);
  static Color get grey800 => _c(Colors.grey.shade800, Colors.grey.shade200);
  static Color get grey900 => _c(Colors.grey.shade900, Colors.grey.shade100);

  // Chữ đen trong suốt (thay cho Colors.black87...); chế độ tối thành trắng
  static Color get black => _c(Colors.black, Colors.white);
  static Color get black87 => _c(Colors.black87, Colors.white.withValues(alpha: 0.87));
  static Color get black54 => _c(Colors.black54, Colors.white.withValues(alpha: 0.6));
  static Color get black45 => _c(Colors.black45, Colors.white.withValues(alpha: 0.5));
  static Color get black38 => _c(Colors.black38, Colors.white.withValues(alpha: 0.4));
  static Color get black26 => _c(Colors.black26, Colors.white.withValues(alpha: 0.3));
  static Color get black12 => _c(Colors.black12, Colors.white.withValues(alpha: 0.12));

  // Màu mang ý nghĩa: thu, chi
  static Color get income => _c(const Color(0xFF2E7D32), const Color(0xFF66BB6A));
  static Color get incomeLight => _c(const Color(0xFF43A047), const Color(0xFF81C784));
  static Color get expense => _c(const Color(0xFFE53935), const Color(0xFFEF5350));
  static Color get expenseStrong => _c(const Color(0xFFC62828), const Color(0xFFE57373));

  // Nền nhạt cho icon/thẻ thu, chi, cảnh báo và nền trang đăng nhập
  static Color get expenseBg => _c(const Color(0xFFFFEBEE), const Color(0x33EF5350));
  static Color get incomeBg => _c(const Color(0xFFE8F5E9), const Color(0x3366BB6A));
  static Color get warningBg => _c(const Color(0xFFFFF3E0), const Color(0x33FB8C00));
  static Color get pageBg => _c(const Color(0xFFF8F9FA), const Color(0xFF121212));

  /// Màu riêng cho từng chế độ, dùng cho các chỗ lẻ chưa có tên.
  static Color pick(Color light, Color dark) => _c(light, dark);

  // Tên theo vai trò (giữ lại cho code cũ)
  static Color get primary => teal;
  static Color get primaryDark => textPrimary;
  static Color get accent => tealBright;
  static Color get accentDark => tealDark;
  static Color get cardCream => surface;
  static Color get backgroundCream => background;
  static Color get textMain => textPrimary;
  static Color get textSub => textSecondary;

  static Color get borderBeige => border;
  static Color get selectedCream => tealPale;
  static Color get selectedBorder => tealBright;

  static Color get primaryGreen => income;
  static Color get unlinkRed => expense;
  static Color get editYellow => mint;
  static Color get linkedBadge => tealPale;

  static Color get cardGradientStart => teal;
  static Color get cardGradientEnd => tealLight;

  static Color get darkBeige => textPrimary;
  static Color get accentBeige => tealBright;
  static Color get primaryBeige => tealPale;
}
