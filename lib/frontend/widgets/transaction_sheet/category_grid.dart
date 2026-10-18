import 'package:flutter/material.dart';
import '../../../backend/models/category_model.dart';
import '../../../backend/services/category_repository.dart';
import 'mousey_colors.dart';

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
    if (oldWidget.isExpense != widget.isExpense) {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Expanded(
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: MouseyColors.primaryGreen),
          ),
        ),
      );
    }

    final displayCategories = _categories.isNotEmpty
        ? _categories
        : (widget.isExpense
            ? [
                CategoryModel(name: 'Ăn uống', iconKey: 'fastfood_rounded', type: 'expense', sortOrder: 0, isDefault: true, isArchived: false, createdAt: '', updatedAt: ''),
                CategoryModel(name: 'Hóa đơn', iconKey: 'receipt_rounded', type: 'expense', sortOrder: 1, isDefault: true, isArchived: false, createdAt: '', updatedAt: ''),
                CategoryModel(name: 'Di chuyển', iconKey: 'directions_bus_rounded', type: 'expense', sortOrder: 2, isDefault: true, isArchived: false, createdAt: '', updatedAt: ''),
                CategoryModel(name: 'Mua sắm', iconKey: 'shopping_bag_rounded', type: 'expense', sortOrder: 3, isDefault: true, isArchived: false, createdAt: '', updatedAt: ''),
                CategoryModel(name: 'Khác', iconKey: 'category_rounded', type: 'expense', sortOrder: 4, isDefault: true, isArchived: false, createdAt: '', updatedAt: ''),
              ]
            : [
                CategoryModel(name: 'Lương', iconKey: 'account_balance_wallet_rounded', type: 'income', sortOrder: 0, isDefault: true, isArchived: false, createdAt: '', updatedAt: ''),
                CategoryModel(name: 'Thưởng', iconKey: 'card_giftcard_rounded', type: 'income', sortOrder: 1, isDefault: true, isArchived: false, createdAt: '', updatedAt: ''),
                CategoryModel(name: 'Khác', iconKey: 'category_rounded', type: 'income', sortOrder: 2, isDefault: true, isArchived: false, createdAt: '', updatedAt: ''),
              ]);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DANH MỤC',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: MouseyColors.textSub,
                  ),
                ),
                Text(
                  widget.selectedCategory,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: MouseyColors.selectedBorder,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.6,
              ),
              itemCount: displayCategories.length,
              itemBuilder: (context, index) {
                final cat = displayCategories[index];
                final name = cat.name;
                final isSelected = widget.selectedCategory == name;

                return InkWell(
                  onTap: () => widget.onCategorySelected(name),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? MouseyColors.selectedCream : MouseyColors.cardCream,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? MouseyColors.selectedBorder : MouseyColors.borderBeige,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        CategoryModel.getCategoryIconWidget(
                          name,
                          size: 30,
                          fallbackColor: isSelected ? MouseyColors.textMain : MouseyColors.textSub,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: MouseyColors.textMain,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
