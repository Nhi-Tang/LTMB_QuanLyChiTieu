import 'package:flutter/material.dart';
import '../../../backend/models/category_model.dart';
import '../../../backend/services/category_repository.dart';
import '../../theme/app_colors.dart';
import '../app_alert_dialog.dart';
import 'category_edit_sheet.dart';
import 'category_link_tile.dart';
import 'delete_category_dialog.dart';
import 'linked_categories_header.dart';
import 'type_tabs.dart';
import '../../utils/app_language.dart';

class LinkedCategoriesScreen extends StatefulWidget {
  final String ledgerId;

  const LinkedCategoriesScreen({
    super.key,
    this.ledgerId = 'default_ledger',
  });

  @override
  State<LinkedCategoriesScreen> createState() => _LinkedCategoriesScreenState();
}

class _LinkedCategoriesScreenState extends State<LinkedCategoriesScreen> {
  bool _isExpense = true;
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final type = _isExpense ? 'expense' : 'income';
      final list = await CategoryRepository.instance.getCategoriesForLedger(widget.ledgerId, type);
      if (!mounted) return;
      setState(() {
        _categories = list;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLink(CategoryModel category) async {
    try {
      if (category.id == null) return;
      if (category.isLinked) {
        await CategoryRepository.instance.unlinkCategory(widget.ledgerId, category.id!);
      } else {
        await CategoryRepository.instance.linkCategory(widget.ledgerId, category.id!);
      }
      await _loadCategories();
    } catch (e) {
      debugPrint('Error toggling link: $e');
    }
  }

  void _showAddCategorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CategoryEditSheet(
        initialType: _isExpense ? 'expense' : 'income',
        onSave: (name, iconKey, type, isLinked) async {
          final newCat = CategoryModel(
            name: name,
            iconKey: iconKey,
            type: type,
            sortOrder: _categories.length,
            isDefault: false,
            isArchived: false,
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
          );
          final categoryId = await CategoryRepository.instance.addCategory(newCat, widget.ledgerId);
          if (!isLinked) {
            await CategoryRepository.instance.unlinkCategory(widget.ledgerId, categoryId);
          }
          await _loadCategories();
          if (mounted) {
            showAppAlertDialog(
              context: context,
              title: context.t('Thành công'),
              message: context.t('Đã thêm danh mục "{name}" thành công!', {'name': name}),
              isSuccess: true,
            );
          }
        },
      ),
    );
  }

  void _showEditCategorySheet(CategoryModel category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CategoryEditSheet(
        categoryToEdit: category,
        initialType: category.type,
        onSave: (name, iconKey, type, isLinked) async {
          final updated = category.copyWith(name: name, iconKey: iconKey);
          await CategoryRepository.instance.updateCategory(updated);
          if (category.id != null) {
            if (isLinked && !category.isLinked) {
              await CategoryRepository.instance.linkCategory(widget.ledgerId, category.id!);
            } else if (!isLinked && category.isLinked) {
              await CategoryRepository.instance.unlinkCategory(widget.ledgerId, category.id!);
            }
          }
          await _loadCategories();
          if (mounted) {
            showAppAlertDialog(
              context: context,
              title: context.t('Thành công'),
              message: context.t('Đã cập nhật danh mục thành công!'),
              isSuccess: true,
            );
          }
        },
      ),
    );
  }

  void _showDeleteCategoryDialog(CategoryModel category) async {
    final allCats = await CategoryRepository.instance.getAllCategories(category.type);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => DeleteCategoryDialog(
        category: category,
        availableCategoriesForTransfer: allCats,
        onDeleteConfirmed: (transferToId, archiveInstead) async {
          try {
            if (category.id != null) {
              await CategoryRepository.instance.deleteCategory(
                category.id!,
                transferToCategoryId: transferToId,
                archiveInstead: archiveInstead,
              );
              await _loadCategories();
              if (mounted) {
                showAppAlertDialog(
                  context: context,
                  title: context.t('Thành công'),
                  message: archiveInstead ? context.t('Đã lưu trữ danh mục thành công!') : context.t('Đã xóa danh mục thành công!'),
                  isSuccess: true,
                );
              }
            }
          } catch (e) {
            if (mounted) {
              showAppAlertDialog(
                context: context,
                title: context.t('Không thể xóa'),
                message: e.toString().replaceAll('Exception: ', ''),
                isSuccess: false,
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    setState(() {
      final item = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, item);
    });

    final ids = _categories.map((c) => c.id!).toList();
    await CategoryRepository.instance.reorderCategories(ids);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: LinkedCategoriesHeader(
        title: context.t('Quản lý & Liên kết danh mục'),
        onAddPressed: _showAddCategorySheet,
      ),
      body: Column(
        children: [
          TypeTabs(
            isExpense: _isExpense,
            onTypeChanged: (isExp) {
              setState(() => _isExpense = isExp);
              _loadCategories();
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.t('Danh sách danh mục'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSub),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _showAddCategorySheet,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(context.t('Mới'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                : _categories.isEmpty
                    ? Center(
                        child: Text(
                          context.t('Chưa có danh mục nào.'),
                          style: TextStyle(color: AppColors.textSub, fontSize: 14),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primaryGreen,
                        onRefresh: _loadCategories,
                        child: ReorderableListView.builder(
                          padding: const EdgeInsets.only(bottom: 40),
                          itemCount: _categories.length,
                          onReorderItem: (oldIndex, newIndex) => _onReorder(oldIndex, newIndex),
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            return CategoryLinkTile(
                              key: ValueKey(category.id ?? index),
                              category: category,
                              index: index,
                              onToggleLink: () => _toggleLink(category),
                              onEdit: () => _showEditCategorySheet(category),
                              onDelete: () => _showDeleteCategoryDialog(category),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
