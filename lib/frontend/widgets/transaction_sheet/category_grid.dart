import 'package:flutter/material.dart';
import '../../../backend/database/db_helper.dart';
import '../../../backend/models/category_model.dart';
import '../../../backend/services/category_repository.dart';
import '../../utils/app_language.dart';
import '../../theme/app_colors.dart';

/// Danh mục đang dùng của sổ (đã liên kết, chưa lưu trữ); lỗi hoặc chưa có thì dùng danh mục mặc định
Future<List<CategoryModel>> loadActiveCategories({required bool isExpense, required String ledgerId}) async {
  final type = isExpense ? 'expense' : 'income';
  try {
    final list = await CategoryRepository.instance.getCategoriesForLedger(ledgerId, type);
    final activeLinked = list.where((c) => c.isLinked && !c.isArchived).toList();
    if (activeLinked.isNotEmpty) return activeLinked;
  } catch (e) {
    debugPrint('Error loading categories: $e');
  }
  final defaults = isExpense ? DatabaseHelper.defaultExpenseCategories : DatabaseHelper.defaultIncomeCategories;
  return defaults
      .map((c) => CategoryModel(
            name: c['name']!,
            iconKey: c['iconKey']!,
            type: type,
            sortOrder: 0,
            isDefault: true,
            isArchived: false,
            createdAt: '',
            updatedAt: '',
          ))
      .toList();
}

/// Sheet chọn trong toàn bộ danh mục; trả về tên danh mục được chọn, null nếu đóng
Future<String?> showCategoryPickerSheet(
  BuildContext context, {
  required List<CategoryModel> categories,
  required String selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      ctx.t('Chọn danh mục'),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppColors.ink),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.95,
                ),
                itemCount: categories.length,
                itemBuilder: (_, index) {
                  final cat = categories[index];
                  return _CategoryCircle(
                    label: ctx.tCategory(cat.name),
                    category: cat,
                    selected: cat.name == selected,
                    onTap: () => Navigator.pop(ctx, cat.name),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Chọn danh mục kiểu sổ: 5 danh mục đầu (luôn gồm danh mục đang chọn) dạng ô tròn,
/// ô thứ 6 là "Xem thêm" mở toàn bộ danh mục.
class CategoryGrid extends StatefulWidget {
  final bool isExpense;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final String ledgerId;

  /// Số ô danh mục hiện ra trước ô "Xem thêm" (màn quét hoá đơn chỉ hiện 1 ô đang chọn)
  final int visibleCount;

  /// Nhãn ô mở toàn bộ danh mục; mặc định "Xem thêm"
  final String? moreLabel;

  const CategoryGrid({
    super.key,
    required this.isExpense,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.ledgerId = 'default_ledger',
    this.visibleCount = 5,
    this.moreLabel,
  });

  @override
  State<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid> {
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void didUpdateWidget(covariant CategoryGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpense != widget.isExpense || oldWidget.ledgerId != widget.ledgerId) {
      _loadCategories();
    }
  }

  Future<void> _loadCategories() async {
    final list = await loadActiveCategories(isExpense: widget.isExpense, ledgerId: widget.ledgerId);
    if (mounted) {
      setState(() {
        _categories = list;
        _isLoading = false;
      });
    }
  }

  /// 5 danh mục hiện ra; nếu danh mục đang chọn nằm sau thì đưa nó vào ô cuối
  List<CategoryModel> _visibleCategories(List<CategoryModel> all) {
    final visible = all.take(widget.visibleCount).toList();
    if (visible.any((c) => c.name == widget.selectedCategory)) return visible;
    final selected = all.where((c) => c.name == widget.selectedCategory);
    if (selected.isNotEmpty && visible.isNotEmpty) visible[visible.length - 1] = selected.first;
    return visible;
  }

  Future<void> _showAllCategories(List<CategoryModel> all) async {
    final picked = await showCategoryPickerSheet(context, categories: all, selected: widget.selectedCategory);
    if (picked != null) widget.onCategorySelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 200,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
          ),
        ),
      );
    }

    final all = _categories;
    final visible = _visibleCategories(all);
    final cells = <Widget>[
      for (final cat in visible)
        _CategoryCircle(
          label: context.tCategory(cat.name),
          category: cat,
          selected: cat.name == widget.selectedCategory,
          onTap: () => widget.onCategorySelected(cat.name),
        ),
      if (all.length > visible.length)
        _CategoryCircle(
          label: widget.moreLabel ?? context.t('Xem thêm'),
          icon: Icons.more_horiz_rounded,
          selected: false,
          onTap: () => _showAllCategories(all),
        ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      childAspectRatio: 1.35,
      children: cells,
    );
  }
}

/// Một ô danh mục: vòng tròn viền mực chứa icon, tên bên dưới. Ô đang chọn có viền đậm và nền nhạt.
class _CategoryCircle extends StatelessWidget {
  final String label;
  final CategoryModel? category;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryCircle({
    required this.label,
    required this.selected,
    required this.onTap,
    this.category,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 58;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: size,
            height: size,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.tealPale : Colors.transparent,
              border: Border.all(color: AppColors.ink, width: selected ? 3 : 1.4),
            ),
            child: category != null
                ? CategoryModel.getCategoryIconWidget(
                    category!.name,
                    iconKey: category!.iconKey,
                    size: size - 14,
                    bgColor: Colors.transparent,
                    fallbackColor: AppColors.ink,
                  )
                : Icon(icon, color: AppColors.ink, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
