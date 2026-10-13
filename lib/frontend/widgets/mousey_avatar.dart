import 'dart:io';
import 'package:flutter/material.dart';

class MouseyAvatar extends StatelessWidget {
  final double size;

  const MouseyAvatar({super.key, this.size = 50});

  @override
  Widget build(BuildContext context) {
    const primaryBeige = Color(0xFFFCF1D0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: primaryBeige, width: 2),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/avatar/avatar.jpg',
          width: size,
          height: size,
          fit: BoxFit.cover,
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
  const primaryBeige = Color(0xFFFCF1D0);

  if (avatarKey.isNotEmpty &&
      (avatarKey.contains('/') || avatarKey.contains('\\')) &&
      File(avatarKey).existsSync()) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: primaryBeige, width: 2),
      ),
      child: ClipOval(
        child: Image.file(
          File(avatarKey),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  switch (avatarKey) {
    case 'piggy':
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

Widget buildGoalIcon(String icon, {double size = 24}) {
  if (icon.startsWith('assets/')) {
    return ClipOval(
      child: Image.asset(
        icon,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
  return Text(icon, style: TextStyle(fontSize: size * 0.9));
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
