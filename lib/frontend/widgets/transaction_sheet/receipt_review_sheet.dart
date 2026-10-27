import 'dart:io';
import 'package:flutter/material.dart';
import '../../../backend/models/transaction_model.dart';
import '../../../backend/services/receipt_scan_service.dart';
import '../../../backend/services/transaction_service.dart';
import '../../../core/utils/money_input_formatter.dart';
import '../app_alert_dialog.dart';
import 'category_grid.dart';
import '../../utils/app_language.dart';
import '../../theme/app_colors.dart';

/// Màn kiểm tra hoá đơn vừa quét: số tiền, danh mục, ghi chú, ngày đều sửa được trước khi lưu.
class ReceiptReviewSheet extends StatefulWidget {
  final ReceiptScanResult scan;
  final Function(TransactionItem item) onSave;

  const ReceiptReviewSheet({super.key, required this.scan, required this.onSave});

  /// Trả về true khi người dùng đã lưu giao dịch.
  static Future<bool?> show({
    required BuildContext context,
    required ReceiptScanResult scan,
    required Function(TransactionItem item) onSave,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.92,
        child: ReceiptReviewSheet(scan: scan, onSave: onSave),
      ),
    );
  }

  @override
  State<ReceiptReviewSheet> createState() => _ReceiptReviewSheetState();
}

class _ReceiptReviewSheetState extends State<ReceiptReviewSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late String _category;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final data = widget.scan.data;
    final amount = data.amount?.round() ?? 0;
    _amountController = TextEditingController(text: amount > 0 ? formatMoneyStr(amount.toString()) : '');
    _noteController = TextEditingController(text: data.note ?? '');
    _category = data.category ?? 'Ăn uống';
    _date = data.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String get _bannerText {
    final data = widget.scan.data;
    if (data.amount == null) {
      return context.t('Chưa đọc được số tiền trên hoá đơn. Bạn nhập giúp rồi lưu nhé.');
    }
    if (data.merchant != null) {
      return context.t('Quét từ hoá đơn của {merchant}. Bạn kiểm tra lại rồi lưu nhé.', {'merchant': data.merchant});
    }
    return context.t('Đã đọc hoá đơn. Bạn kiểm tra lại rồi lưu nhé.');
  }

  String get _dateLabel {
    final now = DateTime.now();
    if (_date.year == now.year && _date.month == now.month && _date.day == now.day) {
      return context.t('Hôm nay');
    }
    return '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  void _showPhoto() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        child: InteractiveViewer(
          maxScale: 5,
          child: Image.file(File(widget.scan.imagePath), fit: BoxFit.contain),
        ),
      ),
    );
  }

  void _onSave() {
    final amount = parseMoney(_amountController.text).toDouble();
    if (amount <= 0) {
      showAppAlertDialog(
        context: context,
        title: context.t('Thông báo'),
        message: context.t('Vui lòng nhập số tiền hợp lệ lớn hơn 0!'),
        isSuccess: false,
      );
      return;
    }
    final note = _noteController.text.trim();
    widget.onSave(TransactionItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: note.isEmpty ? _category : note,
      category: _category,
      amount: amount,
      isExpense: true,
      date: _date,
    ));
    Navigator.pop(context, true);
  }

  /// Một dòng kẻ trong sổ: nhãn mờ + nội dung
  Widget _ruledLine({required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.rule))),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
          Expanded(child: child),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              decoration: BoxDecoration(color: AppColors.rule, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.close_rounded, color: AppColors.ink),
                  onPressed: () => Navigator.pop(context, false),
                ),
                Expanded(
                  child: Text(
                    context.t('Ghi vào sổ'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.ink),
                  ),
                ),
                IconButton(
                  tooltip: context.t('Xem ảnh hoá đơn'),
                  icon: Icon(Icons.image_outlined, color: AppColors.ink),
                  onPressed: _showPhoto,
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
                  // Giấy nhớ vàng: nguồn quét + nhắc kiểm tra lại
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: AppColors.note,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(Icons.document_scanner_outlined, size: 18, color: AppColors.ink),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _bannerText,
                            style: TextStyle(fontSize: 14, color: AppColors.ink, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(context.t('Số tiền'), style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
                  // Số tiền sửa được, chữ "đ" đi sát ngay sau số; gạch mực kéo hết dòng
                  Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.ink, width: 1.5)),
                    ),
                    child: Row(
                      children: [
                        IntrinsicWidth(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [MoneyInputFormatter()],
                            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.expense),
                            decoration: const InputDecoration(
                              hintText: '0',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),
                        Text(
                          ' đ',
                          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.expense),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Danh mục đoán được + "Đổi" mở toàn bộ danh mục
                  CategoryGrid(
                    isExpense: true,
                    selectedCategory: _category,
                    ledgerId: TransactionService.instance.currentLedgerId,
                    visibleCount: 1,
                    moreLabel: context.t('Đổi'),
                    onCategorySelected: (cat) => setState(() => _category = cat),
                  ),

                  _ruledLine(
                    label: context.t('Ghi chú'),
                    child: TextField(
                      controller: _noteController,
                      style: TextStyle(fontSize: 15, color: AppColors.ink),
                      decoration: InputDecoration(
                        hintText: context.t('Thêm ghi chú...'),
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _pickDate,
                    child: _ruledLine(
                      label: context.t('Ngày'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(_dateLabel, style: TextStyle(fontSize: 15, color: AppColors.ink)),
                            ),
                            Icon(Icons.edit_calendar_outlined, size: 18, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 16 + MediaQuery.of(context).padding.bottom),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
                onPressed: _onSave,
                child: Text(
                  context.t('Lưu'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.onTeal),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
