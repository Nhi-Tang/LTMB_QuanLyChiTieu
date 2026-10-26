import 'package:flutter/material.dart';
import '../../../backend/models/category_model.dart';
import '../../../core/widgets/category_icon.dart';
import '../../theme/app_colors.dart';
import 'icon_picker_grid.dart';
import '../../utils/app_language.dart';

class CategoryEditSheet extends StatefulWidget {
  final CategoryModel? categoryToEdit;
  final String initialType; // 'expense' or 'income'
  final Function(String name, String iconKey, String type, bool isLinked) onSave;

  const CategoryEditSheet({
    super.key,
    this.categoryToEdit,
    required this.initialType,
    required this.onSave,
  });

  @override
  State<CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends State<CategoryEditSheet> {
  late TextEditingController _nameController;
  late String _selectedIconKey;
  late String _selectedType;
  late bool _isLinked;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.categoryToEdit?.name ?? '');
    _selectedIconKey = widget.categoryToEdit?.iconKey ?? 'category_rounded';
    _selectedType = widget.categoryToEdit?.type ?? widget.initialType;
    _isLinked = widget.categoryToEdit?.isLinked ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.categoryToEdit != null;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderBeige,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? context.t('Chỉnh sửa danh mục') : context.t('Thêm danh mục mới'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSub),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: context.t('Tên danh mục'),
                  hintText: context.t('Nhập tên danh mục...'),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: CategoryIcon(
                      categoryOrIconKey: _nameController.text.isNotEmpty ? _nameController.text : _selectedIconKey,
                      size: 28,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.cardCream,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.borderBeige),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.borderBeige),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? context.t('Vui lòng nhập tên danh mục') : null,
              ),
              const SizedBox(height: 16),
              Text(
                context.t('Chọn biểu tượng (Icon):'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              IconPickerGrid(
                selectedIconKey: _selectedIconKey,
                onIconSelected: (key) => setState(() => _selectedIconKey = key),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(
                  context.t('Tự động liên kết với sổ hiện tại'),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain),
                ),
                subtitle: Text(
                  context.t('Danh mục này sẽ xuất hiện trong sổ hiện tại.'),
                  style: TextStyle(fontSize: 12, color: AppColors.textSub),
                ),
                value: _isLinked,
                activeThumbColor: AppColors.primaryGreen,
                onChanged: (val) => setState(() => _isLinked = val),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      widget.onSave(
                        _nameController.text.trim(),
                        _selectedIconKey,
                        _selectedType,
                        _isLinked,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    isEditing ? context.t('Lưu thay đổi') : context.t('Thêm danh mục'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
