import 'package:flutter/material.dart';

/// Toàn bộ màu giao diện của app. Muốn đổi màu chủ đạo thì chỉ sửa bảng
/// màu teal bên dưới, các tên còn lại đều trỏ về đây.
class AppColors {
  // Bảng màu teal (colorhub.app), từ đậm đến nhạt
  static const Color tealDark = Color(0xFF00463E);
  static const Color teal = Color(0xFF00BFB5);
  static const Color tealBright = Color(0xFF00D1CC);
  static const Color mint = Color(0xFF33DEBF);
  static const Color tealLight = Color(0xFF66EBE5);
  static const Color tealPale = Color(0xFFCCF7F7);
  static const Color tealMist = Color(0xFFE6FBFB);
  static const Color tealWhite = Color(0xFFF5FDFD);

  // Màu trung tính
  static const Color ink = Color(0xFF222222);
  static const Color textPrimary = Color(0xFF171827);
  static const Color textSecondary = Color(0xFF373743);
  static const Color textMuted = Color(0xFF706C66);
  static const Color background = Color(0xFFF2F2F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE0E0E0);
  static const Color unselectedTab = Color(0xFF9E9E9E);

  // Màu mang ý nghĩa: thu, chi
  static const Color income = Color(0xFF2E7D32);
  static const Color incomeLight = Color(0xFF43A047);
  static const Color expense = Color(0xFFE53935);
  static const Color expenseStrong = Color(0xFFC62828);

  // Tên theo vai trò (giữ lại cho code cũ)
  static const Color primary = teal;
  static const Color primaryDark = textPrimary;
  static const Color accent = tealBright;
  static const Color accentDark = tealDark;
  static const Color cardCream = surface;
  static const Color backgroundCream = background;
  static const Color textMain = textPrimary;
  static const Color textSub = textSecondary;

  static const Color borderBeige = border;
  static const Color selectedCream = tealPale;
  static const Color selectedBorder = tealBright;

  static const Color primaryGreen = income;
  static const Color unlinkRed = expense;
  static const Color editYellow = mint;
  static const Color linkedBadge = tealPale;

  static const Color cardGradientStart = teal;
  static const Color cardGradientEnd = tealLight;

  static const Color darkBeige = textPrimary;
  static const Color accentBeige = tealBright;
  static const Color primaryBeige = tealPale;
}
