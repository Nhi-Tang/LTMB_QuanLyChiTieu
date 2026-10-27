import 'package:flutter/material.dart';
import '../../../backend/database/db_helper.dart';
import '../../../backend/models/category_model.dart';
import '../../../backend/services/category_repository.dart';
import '../../utils/app_language.dart';
import '../../theme/app_colors.dart';

/// Chọn danh mục kiểu sổ: 5 danh mục đầu (luôn gồm danh mục đang chọn) dạng ô tròn,
/// ô thứ 6 là "Xem thêm" mở toàn bộ danh mục.
class CategoryGrid extends StatefulWidget {
  final bool isExpense;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final String ledgerId;

  const CategoryGrid({
    super.key,
    required this.isExpense,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.ledgerId = 'default_ledger',
  });

  @override
  State<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid> {
  static const int _visibleCount = 5;

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
    try {
      final type = widget.isExpense ? 'expense' : 'income';
      final list = await CategoryRepository.instance.getCategoriesForLedger(widget.ledgerId, type);
      // Chỉ lấy các danh mục đã liên kết (isLinked == true) và không bị lưu trữ (isArchived == false)
      final activeLinked = list.where((c) => c.isLinked && !c.isArchived).toList();
      if (mounted) {
        setState(() {
          _categories = activeLinked;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading categories in grid: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<CategoryModel> get _allCategories {
    if (_categories.isNotEmpty) return _categories;
    final defaults = widget.isExpense ? DatabaseHelper.defaultExpenseCategories : DatabaseHelper.defaultIncomeCategories;
    return defaults
        .map((c) => CategoryModel(
              name: c['name']!,
              iconKey: c['iconKey']!,
              type: widget.isExpense ? 'expense' : 'income',
              sortOrder: 0,
              isDefault: true,
              isArchived: false,
              createdAt: '',
              updatedAt: '',
            ))
        .toList();
  }

  /// 5 danh mục hiện ra; nếu danh mục đang chọn nằm sau thì đưa nó vào ô cuối
  List<CategoryModel> _visibleCategories(List<CategoryModel> all) {
    final visible = all.take(_visibleCount).toList();
    if (visible.any((c) => c.name == widget.selectedCategory)) return visible;
    final selected = all.where((c) => c.name == widget.selectedCategory);
    if (selected.isNotEmpty && visible.isNotEmpty) visible[visible.length - 1] = selected.first;
    return visible;
  }

  void _showAllCategories(List<CategoryModel> all) {
    showModalBottomSheet(
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
                        context.t('Chọn danh mục'),
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
                  itemCount: all.length,
                  itemBuilder: (_, index) {
                    final cat = all[index];
                    return _CategoryCircle(
                      label: context.tCategory(cat.name),
                      category: cat,
                      selected: cat.name == widget.selectedCategory,
                      onTap: () {
                        Navigator.pop(ctx);
                        widget.onCategorySelected(cat.name);
                      },
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

    final all = _allCategories;
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
          label: context.t('Xem thêm'),
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
