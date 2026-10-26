import 'package:flutter/material.dart';
import '../../backend/database/db_helper.dart';
import '../../backend/models/budget_model.dart';
import '../../backend/models/category_model.dart';
import '../../backend/services/category_repository.dart';
import '../../core/utils/money_input_formatter.dart';
import '../../core/widgets/category_icon.dart';
import '../utils/app_language.dart';
import '../theme/app_colors.dart';

class BudgetFormSheet extends StatefulWidget {
  final String ledgerId;
  final String currentMonth; // 'YYYY-MM'
  final BudgetModel? editingBudget;
  final List<BudgetModel> existingBudgets;
  final Function(BudgetModel) onSave;

  const BudgetFormSheet({
    super.key,
    required this.ledgerId,
    required this.currentMonth,
    this.editingBudget,
    required this.existingBudgets,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required String ledgerId,
    required String currentMonth,
    BudgetModel? editingBudget,
    required List<BudgetModel> existingBudgets,
    required Function(BudgetModel) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: BudgetFormSheet(
          ledgerId: ledgerId,
          currentMonth: currentMonth,
          editingBudget: editingBudget,
          existingBudgets: existingBudgets,
          onSave: onSave,
        ),
      ),
    );
  }

  @override
  State<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends State<BudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  String? _selectedCategory; // null = Tổng ngân sách tháng
  late bool _isRecurring;
  late String _month;
  List<CategoryModel> _availableCategories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.editingBudget != null
          ? formatMoney(widget.editingBudget!.amountLimit)
          : '',
    );
    _selectedCategory = widget.editingBudget?.categoryId;
    _isRecurring = widget.editingBudget?.isRecurring ?? false;
    _month = widget.editingBudget?.month ?? widget.currentMonth;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CategoryRepository.instance.getCategoriesForLedger(widget.ledgerId, 'expense');

      final existingCategoriesForMonth = widget.existingBudgets
          .where((b) => b.month == _month && b.id != widget.editingBudget?.id && b.categoryId != null)
          .map((b) => b.categoryId)
          .toSet();

      final filtered = categories.where((c) => !existingCategoriesForMonth.contains(c.name)).toList();

      final fallbackList = DatabaseHelper.defaultExpenseCategories
          .map((c) => CategoryModel(
                name: c['name']!,
                iconKey: c['iconKey']!,
                type: 'expense',
                sortOrder: 0,
                isDefault: true,
                isArchived: false,
                createdAt: '',
                updatedAt: '',
              ))
          .where((c) => !existingCategoriesForMonth.contains(c.name))
          .toList();

      if (mounted) {
        setState(() {
          _availableCategories = filtered.isNotEmpty ? filtered : fallbackList;

          if (widget.editingBudget?.categoryId != null) {
            final currentCatName = widget.editingBudget!.categoryId!;
            if (!_availableCategories.any((c) => c.name == currentCatName)) {
              _availableCategories.insert(
                0,
                CategoryModel(
                  name: currentCatName,
                  iconKey: 'category_rounded',
                  type: 'expense',
                  sortOrder: 0,
                  isDefault: false,
                  isArchived: false,
                  createdAt: '',
                  updatedAt: '',
                ),
              );
            }
          }
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading categories in BudgetFormSheet: $e');
      if (mounted) {
        setState(() {
          _availableCategories = DatabaseHelper.defaultExpenseCategories
              .map((c) => CategoryModel(
                    name: c['name']!,
                    iconKey: c['iconKey']!,
                    type: 'expense',
                    sortOrder: 0,
                    isDefault: true,
                    isArchived: false,
                    createdAt: '',
                    updatedAt: '',
                  ))
              .toList();
          _isLoadingCategories = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = parseMoney(_amountController.text).toDouble();
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('Vui lòng nhập hạn mức ngân sách hợp lệ (> 0)'))),
      );
      return;
    }

    final budget = BudgetModel(
      id: widget.editingBudget?.id,
      uid: widget.editingBudget?.uid,
      categoryId: _selectedCategory,
      amountLimit: amount,
      month: _isRecurring ? null : _month,
      isRecurring: _isRecurring,
      ledgerId: widget.ledgerId,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    Navigator.pop(context);
    await widget.onSave(budget);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingBudget != null;

    // Kiểm tra xem đã có "Tổng ngân sách tháng" chưa
    final hasTotalBudget = widget.existingBudgets.any(
      (b) => b.month == _month && b.id != widget.editingBudget?.id && b.categoryId == null,
    );

    return Material(
      color: AppColors.tealWhite,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.tealDark.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? context.t('Sửa Ngân Sách') : context.t('Thêm Ngân Sách Mới'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.tealDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.tealDark),
                    onPressed: () => Navigator.pop(context),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Category Selection Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.t('Chọn danh mục ngân sách'),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.tealDark),
                  ),
                  Text(
                    _selectedCategory != null ? context.tCategory(_selectedCategory!) : context.t('Tổng ngân sách'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.tealBright),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        // Card "Tổng ngân sách tháng"
                        if (!hasTotalBudget || _selectedCategory == null) ...[
                          InkWell(
                            onTap: () => setState(() => _selectedCategory = null),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedCategory == null ? AppColors.tealPale : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selectedCategory == null ? AppColors.tealBright : AppColors.tealPale,
                                  width: _selectedCategory == null ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.pie_chart_outline_rounded, color: AppColors.tealDark, size: 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      context.t('Tổng ngân sách tháng (Toàn bộ chi tiêu)'),
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.tealDark),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_selectedCategory == null)
                                    const Icon(Icons.check_circle_rounded, color: AppColors.tealDark, size: 18),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Lưới chọn danh mục bằng Card + CategoryIcon
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 2.6,
                            ),
                            itemCount: _availableCategories.length,
                            itemBuilder: (context, index) {
                              final cat = _availableCategories[index];
                              final name = cat.name;
                              final isSelected = _selectedCategory == name;

                              return InkWell(
                                onTap: () => setState(() => _selectedCategory = name),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.tealPale : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? AppColors.tealBright : AppColors.tealPale,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CategoryIcon(
                                        categoryOrIconKey: name,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          context.tCategory(name),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            color: AppColors.tealDark,
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
              const SizedBox(height: 20),

              // Amount Input
              Text(
                context.t('Hạn mức (VNĐ)'),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.tealDark),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [MoneyInputFormatter()],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  suffixText: 'đ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.t('Vui lòng nhập hạn mức ngân sách');
                  }
                  if (parseMoney(value) <= 0) {
                    return context.t('Hạn mức phải lớn hơn 0');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Recurring Switch
              SwitchListTile(
                title: Text(
                  context.t('Ngân sách định kỳ'),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.tealDark),
                ),
                subtitle: Text(
                  context.t('Áp dụng tự động cho mọi tháng'),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                value: _isRecurring,
                activeThumbColor: AppColors.tealDark,
                onChanged: (val) {
                  setState(() {
                    _isRecurring = val;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tealDark,
                    foregroundColor: AppColors.tealPale,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _submit,
                  child: Text(
                    isEditing ? context.t('Cập Nhật Ngân Sách') : context.t('Thêm Ngân Sách'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
