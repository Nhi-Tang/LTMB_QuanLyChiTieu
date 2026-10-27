import 'package:flutter/material.dart';
import '../../frontend/theme/app_colors.dart';

/// Container nhóm các SettingsTile được bọc Material chuẩn chống assertion ListTile
class SettingsTileGroup extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;

  const SettingsTileGroup({
    super.key,
    required this.children,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Kiểu trang sổ: không khung thẻ, chỉ một đường kẻ trên và dưới nhóm
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.symmetric(horizontal: BorderSide(color: borderColor ?? AppColors.rule)),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: children,
        ),
      ),
    );
  }
}

/// Widget SettingsTile dùng chung bọc ListTile an toàn chống assertion ListTile background
class SettingsTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? contentPadding;

  const SettingsTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
      contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
