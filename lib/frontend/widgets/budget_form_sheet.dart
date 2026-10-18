import 'package:flutter/material.dart';
import '../../backend/models/budget_model.dart';
import '../../backend/models/category_model.dart';
import '../../backend/services/category_repository.dart';
import '../../core/utils/money_input_formatter.dart';

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
    final categories = await CategoryRepository.instance.getCategoriesForLedger(widget.ledgerId, 'expense');
    
    // Các danh mục đã có ngân sách trong tháng này (ngoại trừ danh mục của editingBudget hiện tại)
    final existingCategoriesForMonth = widget.existingBudgets
        .where((b) => b.month == _month && b.id != widget.editingBudget?.id && b.categoryId != null)
        .map((b) => b.categoryId)
        .toSet();

    if (mounted) {
      setState(() {
        _availableCategories = categories.where((c) => !existingCategoriesForMonth.contains(c.name)).toList();
        _isLoadingCategories = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amount = parseMoney(_amountController.text).toDouble();
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập hạn mức ngân sách hợp lệ (> 0)')),
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

    widget.onSave(budget);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingBudget != null;

    // Kiểm tra xem đã có "Tổng ngân sách tháng" chưa
    final hasTotalBudget = widget.existingBudgets.any(
      (b) => b.month == _month && b.id != widget.editingBudget?.id && b.categoryId == null,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF7EB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
                    color: Colors.brown.withValues(alpha: 0.2),
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
                    isEditing ? 'Sửa Ngân Sách' : 'Thêm Ngân Sách Mới',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5D4222),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF5D4222)),
                    onPressed: () => Navigator.pop(context),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Category Selection
              const Text(
                'Danh mục ngân sách',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5D4222)),
              ),
              const SizedBox(height: 8),
              _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      hint: const Text('Chọn danh mục (hoặc Tổng ngân sách)', overflow: TextOverflow.ellipsis),
                      items: [
                        if (!hasTotalBudget || _selectedCategory == null)
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'Tổng ngân sách tháng (Toàn bộ chi tiêu)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ..._availableCategories.map((cat) => DropdownMenuItem<String?>(
                              value: cat.name,
                              child: Text(
                                cat.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val;
                        });
                      },
                    ),
              const SizedBox(height: 16),

              // Amount Input
              const Text(
                'Hạn mức (VNĐ)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5D4222)),
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
                    return 'Vui lòng nhập hạn mức ngân sách';
                  }
                  if (parseMoney(value) <= 0) {
                    return 'Hạn mức phải lớn hơn 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Recurring Switch
              SwitchListTile(
                title: const Text(
                  'Ngân sách định kỳ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5D4222)),
                ),
                subtitle: const Text(
                  'Áp dụng tự động cho mọi tháng',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                value: _isRecurring,
                activeThumbColor: const Color(0xFF5D4222),
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
                    backgroundColor: const Color(0xFF5D4222),
                    foregroundColor: const Color(0xFFFCF1D0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _submit,
                  child: Text(
                    isEditing ? 'Cập Nhật Ngân Sách' : 'Thêm Ngân Sách',
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
    );
  }
}
