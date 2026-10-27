import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Toàn bộ màu giao diện của app. Mỗi màu có một giá trị cho chế độ sáng và
/// một cho chế độ tối.
///
/// Phong cách "cuốn sổ": nền giấy kem, chữ và nút màu mực xanh, danh sách chỉ dùng
/// đường kẻ mảnh, số tổng tô như bút dạ quang. Tên các màu teal* được giữ lại để
/// code cũ không phải sửa, nhưng giờ là thang màu mực xanh / giấy.
class AppColors {
  static bool get isDark => AppTheme.instance.isDark;
  static Color _c(Color light, Color dark) => isDark ? dark : light;

  // Thang màu mực xanh (đậm) -> giấy (nhạt). Ở chế độ tối thang màu đảo lại:
  // màu đậm dùng cho chữ thành màu sáng, màu nền nhạt thành màu tối.
  static Color get tealDark => _c(const Color(0xFF1E2A5A), const Color(0xFFC9D0F2));
  static Color get teal => _c(const Color(0xFF1E2A5A), const Color(0xFF4757A6));
  static Color get tealBright => _c(const Color(0xFF1E2A5A), const Color(0xFF4757A6));
  static Color get mint => _c(const Color(0xFFF6DE7E), const Color(0xFF8A7630));
  static Color get tealLight => _c(const Color(0xFFC9CFEA), const Color(0xFF3A4170));
  static Color get tealPale => _c(const Color(0xFFE9EBF6), const Color(0xFF262B45));
  static Color get tealMist => _c(const Color(0xFFF2EFE4), const Color(0xFF1E2030));
  static Color get tealWhite => _c(const Color(0xFFFAF8F1), const Color(0xFF15161D));

  /// Chữ/icon đặt trên nền mực xanh (nút chính): luôn trắng ở cả hai chế độ.
  static const Color onTeal = Colors.white;

  // Màu riêng của phong cách sổ
  /// Bút dạ quang tô số tổng
  static Color get highlight => _c(const Color(0xFFFBEA9E), const Color(0xFF5E5220));
  /// Tờ giấy nhớ (thẻ nâng cấp PRO) và viền của nó
  static Color get note => _c(const Color(0xFFFCEFB4), const Color(0xFF3D3720));
  static Color get noteBorder => _c(const Color(0xFFE6C95C), const Color(0xFF8A7630));
  /// Đường kẻ dòng của sổ
  static Color get rule => _c(const Color(0xFFDDDFEC), const Color(0xFF2E3247));
  /// Đường kẻ lề đỏ của sổ
  static Color get margin => _c(const Color(0xFFE3A3A3), const Color(0xFF7A3B3B));
  /// Bìa sổ (thẻ thông tin cá nhân)
  static Color get cover => _c(const Color(0xFF1E2A5A), const Color(0xFF2A3466));
  static Color get coverSpine => _c(const Color(0xFF141D44), const Color(0xFF1D2550));

  // Màu trung tính
  static Color get ink => _c(const Color(0xFF1E2A5A), const Color(0xFFE9EBF5));
  static Color get textPrimary => _c(const Color(0xFF1E2A5A), const Color(0xFFE9EBF5));
  static Color get textSecondary => _c(const Color(0xFF4A5175), const Color(0xFFB8BCD3));
  static Color get textMuted => _c(const Color(0xFF8A8678), const Color(0xFF9A9CAD));
  static Color get background => _c(const Color(0xFFFAF8F1), const Color(0xFF15161D));
  static Color get surface => _c(const Color(0xFFFFFDF8), const Color(0xFF1D1F29));
  static Color get border => _c(const Color(0xFFE4E0D2), const Color(0xFF33364A));
  static Color get unselectedTab => _c(const Color(0xFF9EA2B8), const Color(0xFF7D8197));

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
  static Color get income => _c(const Color(0xFF2E7D4F), const Color(0xFF6CC08B));
  static Color get incomeLight => _c(const Color(0xFF3F9463), const Color(0xFF8BD0A3));
  static Color get expense => _c(const Color(0xFFC0392B), const Color(0xFFE57368));
  static Color get expenseStrong => _c(const Color(0xFFA93226), const Color(0xFFEC8C82));

  // Nền nhạt cho icon/thẻ thu, chi, cảnh báo và nền trang đăng nhập
  static Color get expenseBg => _c(const Color(0xFFFBECEA), const Color(0x33E57368));
  static Color get incomeBg => _c(const Color(0xFFE8F3EC), const Color(0x336CC08B));
  static Color get warningBg => _c(const Color(0xFFFCF3D6), const Color(0x33E6C95C));
  static Color get pageBg => background;

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

  static Color get primaryGreen => teal;
  static Color get unlinkRed => expense;
  static Color get editYellow => mint;
  static Color get linkedBadge => tealPale;

  static Color get cardGradientStart => teal;
  static Color get cardGradientEnd => tealLight;

  static Color get darkBeige => textPrimary;
  static Color get accentBeige => tealBright;
  static Color get primaryBeige => tealPale;
}
