import 'package:flutter/material.dart';
import '../../../backend/models/category_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_language.dart';

class DeleteCategoryDialog extends StatefulWidget {
  final CategoryModel category;
  final List<CategoryModel> availableCategoriesForTransfer;
  final Function(int? transferToCategoryId, bool archiveInstead) onDeleteConfirmed;

  const DeleteCategoryDialog({
    super.key,
    required this.category,
    required this.availableCategoriesForTransfer,
    required this.onDeleteConfirmed,
  });

  @override
  State<DeleteCategoryDialog> createState() => _DeleteCategoryDialogState();
}

class _DeleteCategoryDialogState extends State<DeleteCategoryDialog> {
  bool _archiveInstead = false;
  int? _selectedTransferId;

  @override
  Widget build(BuildContext context) {
    if (widget.category.isDefault) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text(context.t('Không thể xóa'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          context.t('Danh mục "{name}" là danh mục mặc định của hệ thống và không thể xóa.', {'name': context.tCategory(widget.category.name)}),
          style: TextStyle(fontSize: 14, color: AppColors.textMain),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(context.t('Đã hiểu'), style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }

    final transferOptions = widget.availableCategoriesForTransfer
        .where((c) => c.id != widget.category.id && !c.isArchived)
        .toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.delete_outline_rounded, color: AppColors.unlinkRed, size: 28),
          const SizedBox(width: 8),
          Text(context.t('Xóa danh mục'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t('Bạn có chắc chắn muốn xóa danh mục "{name}" không?', {'name': context.tCategory(widget.category.name)}),
              style: TextStyle(fontSize: 14, color: AppColors.textMain),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: Text(context.t('Lưu trữ thay vì xóa'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: Text(context.t('Ẩn danh mục nhưng vẫn giữ nguyên dữ liệu giao dịch cũ.'), style: TextStyle(fontSize: 11, color: AppColors.textSub)),
              value: _archiveInstead,
              activeColor: AppColors.primaryGreen,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _archiveInstead = val ?? false),
            ),
            if (!_archiveInstead && transferOptions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                context.t('Chuyển các giao dịch cũ sang danh mục khác:'),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSub),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _selectedTransferId,
                decoration: InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppColors.cardCream,
                ),
                hint: Text(context.t('Chọn danh mục nhận giao dịch'), style: TextStyle(fontSize: 12)),
                items: transferOptions.map((c) {
                  return DropdownMenuItem<int>(
                    value: c.id!,
                    child: Text(context.tCategory(c.name), style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedTransferId = val),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.t('Hủy'), style: TextStyle(color: AppColors.textSub)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.unlinkRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            widget.onDeleteConfirmed(_selectedTransferId, _archiveInstead);
            Navigator.pop(context);
          },
          child: Text(context.t('Xác nhận'), style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
