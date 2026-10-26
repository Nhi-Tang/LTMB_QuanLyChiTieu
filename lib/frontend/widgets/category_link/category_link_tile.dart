import 'package:flutter/material.dart';
import '../../../backend/models/category_model.dart';
import '../../../core/widgets/category_icon.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_language.dart';

class CategoryLinkTile extends StatelessWidget {
  final CategoryModel category;
  final int index;
  final VoidCallback onToggleLink;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoryLinkTile({
    super.key,
    required this.category,
    required this.index,
    required this.onToggleLink,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(category.id),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: category.isLinked ? AppColors.selectedBorder.withValues(alpha: 0.6) : AppColors.borderBeige,
          width: category.isLinked ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onEdit,
          onLongPress: onDelete,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(Icons.drag_indicator_rounded, color: AppColors.unselectedTab, size: 20),
                ),
              ),
              CategoryIcon(
                categoryOrIconKey: category.name.isNotEmpty ? category.name : category.iconKey,
                size: 38,
                bgColor: category.isLinked ? AppColors.selectedCream : AppColors.backgroundCream,
              ),
            ],
          ),
          title: Text(
            context.tCategory(category.name),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: category.isArchived ? AppColors.textSub : AppColors.textMain,
              decoration: category.isArchived ? TextDecoration.lineThrough : null,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (category.isLinked) ...[
                InkWell(
                  onTap: onToggleLink,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppColors.unlinkRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.remove, size: 14, color: Colors.white),
                  ),
                ),
              ] else ...[
                InkWell(
                  onTap: onToggleLink,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
