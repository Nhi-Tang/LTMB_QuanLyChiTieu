import 'dart:io';
import 'package:flutter/material.dart';

class PiggyAvatar extends StatelessWidget {
  final double size;

  const PiggyAvatar({super.key, this.size = 50});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD6D6),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFB2B2), width: size * 0.04),
            ),
          ),
          Positioned(
            top: size * 0.05,
            left: size * 0.1,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: const BoxDecoration(
                color: Color(0xFFFF8A8A),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: size * 0.05,
            right: size * 0.1,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: const BoxDecoration(
                color: Color(0xFFFF8A8A),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: size * 0.35,
            left: size * 0.28,
            child: Container(
              width: size * 0.1,
              height: size * 0.12,
              decoration: const BoxDecoration(
                color: Color(0xFF222222),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: size * 0.35,
            right: size * 0.28,
            child: Container(
              width: size * 0.1,
              height: size * 0.12,
              decoration: const BoxDecoration(
                color: Color(0xFF222222),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.22,
            child: Container(
              width: size * 0.36,
              height: size * 0.24,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6F80),
                borderRadius: BorderRadius.circular(size * 0.12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: size * 0.07,
                    height: size * 0.12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD64D5F),
                      borderRadius: BorderRadius.circular(size),
                    ),
                  ),
                  Container(
                    width: size * 0.07,
                    height: size * 0.12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD64D5F),
                      borderRadius: BorderRadius.circular(size),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
  const darkBeige = Color(0xFFC8A96B);

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
      return PiggyAvatar(size: size);
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
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: primaryBeige,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
            style: TextStyle(
              fontSize: size * 0.45,
              fontWeight: FontWeight.bold,
              color: darkBeige,
            ),
          ),
        ),
      );
  }
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
