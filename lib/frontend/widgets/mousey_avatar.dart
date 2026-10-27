import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MouseyAvatar extends StatelessWidget {
  final double size;

  const MouseyAvatar({super.key, this.size = 50});

  @override
  Widget build(BuildContext context) {
    final primaryBeige = AppColors.tealPale;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: primaryBeige, width: 2),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/avatar/avatar_moi.jpg',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => CircleAvatar(
            radius: size / 2,
            backgroundColor: primaryBeige,
            child: Icon(Icons.person, size: size * 0.6, color: AppColors.tealDark),
          ),
        ),
      ),
    );
  }
}

Widget buildUserAvatar({
  required String avatarKey,
  required String userName,
  double size = 50,
}) {
  final primaryPurple = AppColors.tealPale;

  if (avatarKey.isNotEmpty &&
      (avatarKey.contains('/') || avatarKey.contains('\\')) &&
      File(avatarKey).existsSync()) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: primaryPurple, width: 2),
      ),
      child: ClipOval(
        child: Image.file(
          File(avatarKey),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => MouseyAvatar(size: size),
        ),
      ),
    );
  }

  switch (avatarKey) {
    case 'piggy': // key avatar cũ đã lưu ở bản trước
    case 'mousey':
      return MouseyAvatar(size: size);
    case 'cat':
      return _buildEmojiAvatar('🐱', const Color(0xFFFFF3E0), size);
    case 'dog':
      return _buildEmojiAvatar('🐶', const Color(0xFFEFEBE9), size);
    case 'fox':
      return _buildEmojiAvatar('🦊', const Color(0xFFFFE0B2), size);
    case 'rabbit':
      return _buildEmojiAvatar('🐰', const Color(0xFFF3E5F5), size);
    case 'panda':
      return _buildEmojiAvatar('🐼', const Color(0xFFECEFF1), size);
    case 'lion':
      return _buildEmojiAvatar('🦁', const Color(0xFFFFF8E1), size);
    case 'bear':
      return _buildEmojiAvatar('🐻', const Color(0xFFEFEBE9), size);
    default:
      return MouseyAvatar(size: size);
  }
}

/// Icon mục tiêu cũ đã bị xoá khỏi assets được đổi sang icon thay thế
const Map<String, String> _replacedGoalIcons = {
  'assets/icon/dienthoai_icon.jpg': 'assets/icon/cat_phone.png',
};

/// Đường dẫn icon mục tiêu hiện dùng được (đổi icon cũ đã xoá sang icon mới)
String normalizeGoalIcon(String? icon) {
  final safeIcon = icon ?? 'assets/icon/tietkiem_icon.jpg';
  return _replacedGoalIcons[safeIcon] ?? safeIcon;
}

Widget buildGoalIcon(String? icon, {double size = 24}) {
  final safeIcon = normalizeGoalIcon(icon);
  if (safeIcon.startsWith('assets/')) {
    return ClipOval(
      child: Image.asset(
        safeIcon,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Icon(Icons.savings_rounded, size: size, color: AppColors.tealDark),
      ),
    );
  }
  return Text(safeIcon, style: TextStyle(fontSize: size * 0.9));
}

Widget _buildEmojiAvatar(String emoji, Color bgColor, double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: bgColor,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Center(
      child: Text(
        emoji,
        style: TextStyle(fontSize: size * 0.48),
      ),
    ),
  );
}
