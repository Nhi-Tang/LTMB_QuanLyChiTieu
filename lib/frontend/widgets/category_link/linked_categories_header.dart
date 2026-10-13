import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class LinkedCategoriesHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onAddPressed;

  const LinkedCategoriesHeader({
    super.key,
    required this.title,
    required this.onAddPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.cardCream,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textMain),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_rounded, color: AppColors.primaryGreen, size: 28),
          onPressed: onAddPressed,
          tooltip: 'Thêm danh mục mới',
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: AppColors.borderBeige,
          height: 1,
        ),
      ),
    );
  }
}
