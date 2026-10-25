import 'package:flutter/material.dart';
import '../../../backend/models/transaction_model.dart';
import '../../../backend/services/transaction_service.dart';
import '../../screens/budgets_screen.dart';
import '../app_alert_dialog.dart';
import 'amount_card.dart';
import 'amount_expression.dart';
import 'calculator_keypad.dart';
import 'category_grid.dart';
import 'mousey_colors.dart';
import 'show_note_sheet.dart';
import 'transaction_type_switcher.dart';

class NewTransactionSheet extends StatefulWidget {
  final TransactionItem? editingTransaction;
  final bool defaultExpense;
  final Function(TransactionItem item) onSave;

  const NewTransactionSheet({
    super.key,
    this.editingTransaction,
    this.defaultExpense = true,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    bool defaultExpense = true,
    TransactionItem? editingTransaction,
    required Function(TransactionItem item) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.92,
        child: NewTransactionSheet(
          editingTransaction: editingTransaction,
          defaultExpense: defaultExpense,
          onSave: onSave,
        ),
      ),
    );
  }

  @override
  State<NewTransactionSheet> createState() => _NewTransactionSheetState();
}

class _NewTransactionSheetState extends State<NewTransactionSheet> {
  int _tabIndex = 0; // 0: Chi tiêu, 1: Thu nhập, 2: Ngân sách
  String _expression = '';
  String _selectedCategory = 'Ăn uống';
  DateTime _selectedDate = DateTime.now();
  String _note = '';

  @override
  void initState() {
    super.initState();
    if (widget.editingTransaction != null) {
      final t = widget.editingTransaction!;
      _expression = t.amount.toInt().toString();
      _selectedCategory = t.category;
      _selectedDate = t.date;
      _note = t.title;
      if (!t.isExpense) {
        _tabIndex = 1;
        _selectedCategory = t.category.isNotEmpty ? t.category : 'Lương';
      } else {
        _tabIndex = 0;
      }
    } else {
      _tabIndex = widget.defaultExpense ? 0 : 1;
      _selectedCategory = widget.defaultExpense ? 'Ăn uống' : 'Lương';
    }
  }

  void _onKeyPressed(String key) {
    setState(() {
      _expression = AmountExpression.appendInput(_expression, key);
    });
  }

  void _onDeletePressed() {
    setState(() {
      if (_expression.isNotEmpty) {
        _expression = _expression.substring(0, _expression.length - 1);
      }
    });
  }

  void _onDeleteLongPress() {
    setState(() {
      _expression = '';
    });
  }

  void _onSavePressed() {
    double amount = AmountExpression.evaluate(_expression);
    if (amount <= 0) {
      showAppAlertDialog(
        context: context,
        title: 'Thông báo',
        message: 'Vui lòng nhập số tiền hợp lệ lớn hơn 0!',
        isSuccess: false,
      );
      return;
    }

    bool isExpense = _tabIndex == 0;
    final finalTitle = _note.trim().isEmpty ? _selectedCategory : _note.trim();

    final item = TransactionItem(
      id: widget.editingTransaction?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: finalTitle,
      category: _selectedCategory,
      amount: amount,
      isExpense: isExpense,
      date: _selectedDate,
    );

    widget.onSave(item);
    Navigator.pop(context);

    showAppAlertDialog(
      context: context,
      title: 'Thành công',
      message: widget.editingTransaction != null
          ? 'Đã cập nhật giao dịch thành công!'
          : 'Đã lưu giao dịch mới thành công! 💸',
      isSuccess: true,
    );
  }

  void _showNoteDialog() async {
    final result = await showNoteSheet(
      context: context,
      currentNote: _note,
      category: _selectedCategory,
    );
    if (result != null) {
      setState(() => _note = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: MouseyColors.backgroundCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  widget.editingTransaction != null ? 'Sửa giao dịch' : 'Giao dịch mới',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MouseyColors.textMain),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // Content body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // 1. Transaction Type Switcher (Chi tiêu | Thu nhập | Ngân sách)
                  TransactionTypeSwitcher(
                    selectedIndex: _tabIndex,
                    onTabChanged: (index) {
                      if (index == 2) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BudgetsScreen(ledgerId: TransactionService.instance.currentLedgerId),
                          ),
                        );
                        return;
                      }
                      setState(() {
                        _tabIndex = index;
                        if (index == 0) {
                          _selectedCategory = 'Ăn uống';
                        } else {
                          _selectedCategory = 'Lương';
                        }
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  // 2. Category Grid
                  CategoryGrid(
                    isExpense: _tabIndex == 0,
                    selectedCategory: _selectedCategory,
                    ledgerId: TransactionService.instance.currentLedgerId,
                    onCategorySelected: (cat) {
                      setState(() => _selectedCategory = cat);
                    },
                  ),

                  const SizedBox(height: 12),

                  // 3. Amount Card
                  AmountCard(
                    expression: _expression,
                    isExpense: _tabIndex == 0,
                  ),

                  const SizedBox(height: 12),

                  // 4. Calculator Keypad
                  CalculatorKeypad(
                    onKeyPressed: _onKeyPressed,
                    onDeletePressed: _onDeletePressed,
                    onDeleteLongPress: _onDeleteLongPress,
                    onSavePressed: _onSavePressed,
                    onDatePressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    onNotePressed: _showNoteDialog,
                    selectedDate: _selectedDate,
                    hasNote: _note.isNotEmpty,
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
