import 'dart:io';
import 'package:flutter/material.dart';

class MouseyAvatar extends StatelessWidget {
  final double size;

  const MouseyAvatar({super.key, this.size = 50});

  @override
  Widget build(BuildContext context) {
    const primaryBeige = Color(0xFFEFE8F6);
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
            child: Icon(Icons.person, size: size * 0.6, color: const Color(0xFF5D4222)),
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
  const primaryPurple = Color(0xFFEFE8F6);

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

Widget buildGoalIcon(String? icon, {double size = 24}) {
  final safeIcon = icon ?? 'assets/icon/tietkiem_icon.jpg';
  if (safeIcon.startsWith('assets/')) {
    return ClipOval(
      child: Image.asset(
        safeIcon,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => Icon(Icons.savings_rounded, size: size, color: const Color(0xFF5D4222)),
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
