import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class MouseyColors {
  static Color get backgroundCream => AppColors.tealWhite;
  static Color get cardCream => AppColors.tealWhite;
  static Color get borderBeige => AppColors.tealPale;
  static Color get selectedCream => AppColors.tealPale;
  static Color get selectedBorder => AppColors.tealBright;
  static Color get keypadBackground => AppColors.tealMist;
  static Color get keypadKey => AppColors.surface;
  static Color get keypadOperator => AppColors.tealPale;
  static Color get primaryGreen => AppColors.teal;
  static Color get expenseRed => AppColors.expense;
  static Color get incomeGreen => AppColors.income;
  static Color get textMain => AppColors.pick(const Color(0xFF2B2118), const Color(0xFFEDEDED));
  static Color get textSub => AppColors.pick(const Color(0xFF7A6F62), const Color(0xFFA8A39C));

  // Thêm các màu theo yêu cầu thiết kế PRO / Mousey
  static Color get background => AppColors.tealWhite;
  static Color get surface => AppColors.surface;
  static Color get primary => AppColors.tealDark;
  static Color get cardGradientStart => AppColors.tealPale;
  static Color get cardGradientEnd => AppColors.tealLight;
  static Color get accent => AppColors.tealLight;
  static Color get accentDark => AppColors.mint;
  static Color get textPrimary => AppColors.pick(const Color(0xFF3B2A17), const Color(0xFFEDEDED));
  static Color get textSecondary => AppColors.pick(const Color(0xFF8A7A66), const Color(0xFFA8A39C));
  static Color get income => const Color(0xFF3E8E41);
  static Color get expense => const Color(0xFFE5646E);
  static Color get border => AppColors.tealPale;
}
