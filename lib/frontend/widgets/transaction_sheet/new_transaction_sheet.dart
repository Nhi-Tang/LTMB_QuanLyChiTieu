import 'package:flutter/material.dart';
import '../../../backend/models/transaction_model.dart';
import '../../../backend/services/receipt_scan_service.dart';
import '../../../backend/services/transaction_service.dart';
import '../../screens/budgets_screen.dart';
import '../app_alert_dialog.dart';
import 'amount_card.dart';
import 'amount_expression.dart';
import 'calculator_keypad.dart';
import 'category_grid.dart';
import 'receipt_review_sheet.dart';
import 'show_note_sheet.dart';
import 'transaction_type_switcher.dart';
import '../../utils/app_language.dart';
import '../../theme/app_colors.dart';

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
        title: context.t('Thông báo'),
        message: context.t('Vui lòng nhập số tiền hợp lệ lớn hơn 0!'),
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
      title: context.t('Thành công'),
      message: widget.editingTransaction != null
          ? context.t('Đã cập nhật giao dịch thành công!')
          : context.t('Đã lưu giao dịch mới thành công! 💸'),
      isSuccess: true,
    );
  }

  /// Chụp / chọn ảnh hoá đơn → đọc chữ → mở màn kiểm tra để sửa rồi lưu.
  Future<void> _scanReceipt() async {
    final fromCamera = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_camera_outlined, color: AppColors.ink),
                title: Text(ctx.t('Chụp hoá đơn'), style: TextStyle(color: AppColors.ink)),
                onTap: () => Navigator.pop(ctx, true),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: AppColors.ink),
                title: Text(ctx.t('Chọn ảnh từ thư viện'), style: TextStyle(color: AppColors.ink)),
                onTap: () => Navigator.pop(ctx, false),
              ),
            ],
          ),
        ),
      ),
    );
    if (fromCamera == null || !mounted) return;

    ReceiptScanResult? scan;
    try {
      // Chờ chọn ảnh xong mới hiện vòng tải (ML Kit đọc mất 1-2 giây)
      scan = await ReceiptScanService.instance.scan(
        fromCamera: fromCamera,
        onImagePicked: () {
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
        },
      );
    } catch (e) {
      debugPrint('Quét hoá đơn lỗi: $e');
      if (mounted) {
        Navigator.of(context).popUntil((r) => r is! DialogRoute);
        showAppAlertDialog(
          context: context,
          title: context.t('Thông báo'),
          message: context.t('Không đọc được ảnh hoá đơn. Bạn thử lại nhé.'),
          isSuccess: false,
        );
      }
      return;
    }
    if (!mounted || scan == null) return;
    Navigator.of(context).popUntil((r) => r is! DialogRoute);

    if (scan.data.rawText.trim().isEmpty) {
      showAppAlertDialog(
        context: context,
        title: context.t('Thông báo'),
        message: context.t('Không thấy chữ trên ảnh. Bạn chụp rõ hoá đơn hơn nhé.'),
        isSuccess: false,
      );
      return;
    }

    final saved = await ReceiptReviewSheet.show(context: context, scan: scan, onSave: widget.onSave);
    if (saved != true || !mounted) return;
    Navigator.pop(context);
    showAppAlertDialog(
      context: context,
      title: context.t('Thành công'),
      message: context.t('Đã lưu giao dịch mới thành công! 💸'),
      isSuccess: true,
    );
  }

  void _showNoteDialog() async {
    final result = await showNoteSheet(
      context: context,
      currentNote: _note,
      category: _selectedCategory,
    );
    if (result != null && mounted) {
      setState(() => _note = result);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.rule,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Đầu trang sổ: đóng | Ghi vào sổ | ngày
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.close_rounded, color: AppColors.ink),
                  onPressed: () => Navigator.pop(context),
                ),
                if (widget.editingTransaction == null)
                  IconButton(
                    tooltip: context.t('Quét hoá đơn'),
                    icon: Icon(Icons.document_scanner_outlined, color: AppColors.ink),
                    onPressed: _scanReceipt,
                  ),
                Expanded(
                  child: Text(
                    widget.editingTransaction != null ? context.t('Sửa giao dịch') : context.t('Ghi vào sổ'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.ink),
                  ),
                ),
                TextButton(
                  onPressed: _pickDate,
                  child: Text(dateLabel, style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chi tiêu | Thu nhập | Ngân sách
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
                  const SizedBox(height: 20),

                  AmountCard(
                    expression: _expression,
                    isExpense: _tabIndex == 0,
                  ),
                  const SizedBox(height: 16),

                  CategoryGrid(
                    isExpense: _tabIndex == 0,
                    selectedCategory: _selectedCategory,
                    ledgerId: TransactionService.instance.currentLedgerId,
                    onCategorySelected: (cat) {
                      setState(() => _selectedCategory = cat);
                    },
                  ),
                  const SizedBox(height: 8),

                  // Ghi chú: một dòng kẻ trong sổ
                  InkWell(
                    onTap: _showNoteDialog,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.rule))),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${context.t('Ghi chú')}: ',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                            TextSpan(
                              text: _note.isNotEmpty ? _note : context.t('Thêm ghi chú...'),
                              style: TextStyle(color: _note.isNotEmpty ? AppColors.ink : AppColors.unselectedTab),
                            ),
                          ],
                        ),
                        style: const TextStyle(fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + MediaQuery.of(context).padding.bottom),
            child: CalculatorKeypad(
              onKeyPressed: _onKeyPressed,
              onDeletePressed: _onDeletePressed,
              onDeleteLongPress: _onDeleteLongPress,
              onSavePressed: _onSavePressed,
              onDatePressed: _pickDate,
              onNotePressed: _showNoteDialog,
              selectedDate: _selectedDate,
              hasNote: _note.isNotEmpty,
            ),
          ),
        ],
      ),
    );
  }
}
