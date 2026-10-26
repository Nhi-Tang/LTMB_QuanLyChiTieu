import 'package:flutter/material.dart';

/// Icon ảnh trong assets/icon (ui_*, tab_*, cat_*) cắt tròn, cùng kiểu với [CategoryIcon].
class AssetIcon extends StatelessWidget {
  final String name;
  final double size;

  const AssetIcon(this.name, {super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/icon/$name.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
