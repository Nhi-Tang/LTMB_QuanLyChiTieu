import 'package:flutter/material.dart';
import '../../backend/models/category_model.dart';
import '../../frontend/theme/app_colors.dart';

/// Widget dùng chung hiển thị icon danh mục trong vòng tròn nền chuẩn AppColors
class CategoryIcon extends StatelessWidget {
  final String categoryOrIconKey;
  /// iconKey của danh mục, dùng khi tên là danh mục tự tạo không có icon riêng
  final String? iconKey;
  final Color? bgColor;
  final double size;
  final Color? iconColor;

  const CategoryIcon({
    super.key,
    required this.categoryOrIconKey,
    this.iconKey,
    this.bgColor,
    this.size = 44,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = CategoryModel.getCategoryAssetPath(categoryOrIconKey, iconKey: iconKey);
    final fallbackIcon = CategoryModel.getIconData(iconKey ?? categoryOrIconKey);

    // Lấy tối đa 98% - 100% đường kính để hình ảnh lấp đầy hoàn toàn ô tròn
    final imageSize = size * 0.98;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor ?? AppColors.accentBeige.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: ClipOval(
          child: Image.asset(
            assetPath,
            width: imageSize,
            height: imageSize,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) {
              return Image.asset(
                'assets/icon/cat_khac.png',
                width: imageSize,
                height: imageSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  fallbackIcon,
                  size: size * 0.6,
                  color: iconColor ?? AppColors.darkBeige,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
