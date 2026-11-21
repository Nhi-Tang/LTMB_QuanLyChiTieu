import 'package:flutter/material.dart';
import '../../../backend/models/transaction_model.dart';
import '../../../backend/services/transaction_service.dart';
import '../../../core/utils/money_input_formatter.dart';
import '../../../core/widgets/category_icon.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_language.dart';
import 'category_grid.dart';

/// Sheet xem & sửa một giao dịch: đổi danh mục, ghi chú, số tiền hoặc xoá.
/// [onUpdated] / [onDeleted] chạy sau khi đã lưu vào sổ, để màn gọi cập nhật danh sách của nó.
Future<void> showTransactionDetailSheet(
  BuildContext context,
  TransactionItem item, {
  ValueChanged<TransactionItem>? onUpdated,
  VoidCallback? onDeleted,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TransactionDetailSheet(
      item: item,
      messengerContext: context,
      onUpdated: onUpdated,
      onDeleted: onDeleted,
    ),
  );
}

class _TransactionDetailSheet extends StatefulWidget {
  final TransactionItem item;

  /// Context của màn gọi: snackbar báo kết quả hiện ở đó sau khi sheet đóng
  final BuildContext messengerContext;
  final ValueChanged<TransactionItem>? onUpdated;
  final VoidCallback? onDeleted;

  const _TransactionDetailSheet({
    required this.item,
    required this.messengerContext,
    this.onUpdated,
    this.onDeleted,
  });

  @override
  State<_TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<_TransactionDetailSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late String _category;
  bool _isSaving = false;

  TransactionItem get _item => widget.item;

  /// Giao dịch chuyển tiền gắn với cặp giao dịch khác nên giữ nguyên danh mục
  bool get _canChangeCategory =>
      _item.transferGroupId == null && _item.kind != 'transfer_internal' && _item.kind != 'transfer_out';

  @override
  void initState() {
    super.initState();
    _category = _item.category;
    _titleController = TextEditingController(text: _item.title.isNotEmpty ? _item.title : _item.category);
    _amountController = TextEditingController(text: formatMoney(_item.amount));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$hour:$minute - $day/$month/${date.year}';
  }

  Future<void> _pickCategory() async {
    final categories = await loadActiveCategories(
      isExpense: _item.isExpense,
      ledgerId: TransactionService.instance.currentLedgerId,
    );
    if (!mounted) return;
    final picked = await showCategoryPickerSheet(context, categories: categories, selected: _category);
    if (picked == null || picked == _category || !mounted) return;
    setState(() {
      // Ghi chú đang là tên danh mục cũ (mặc định khi thêm) thì đổi theo danh mục mới
      if (_titleController.text.trim() == _category) _titleController.text = picked;
      _category = picked;
    });
  }

  Future<void> _delete() async {
    Navigator.pop(context);
    await TransactionService.instance.removeTransaction(_item.id, uid: _item.uid, date: _item.date);
    widget.onDeleted?.call();
    final ctx = widget.messengerContext;
    if (!ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(ctx.t('Đã xóa giao dịch thành công!')), backgroundColor: Colors.red),
    );
  }

  Future<void> _save() async {
    final newTitle = _titleController.text.trim();
    final newAmount = parseMoney(_amountController.text).toDouble();
    if (newAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('Vui lòng nhập số tiền hợp lệ!')), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);
    final updatedTx = _item.copyWith(
      title: newTitle.isNotEmpty ? newTitle : _category,
      category: _category,
      amount: newAmount,
    );

    await TransactionService.instance.updateTransaction(updatedTx, uid: _item.uid);
    widget.onUpdated?.call(updatedTx);

    if (!mounted) return;
    Navigator.pop(context);
    final ctx = widget.messengerContext;
    if (!ctx.mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text(ctx.t('Đã lưu thay đổi giao dịch!')), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _item.isExpense;
    final amountColor = isExpense ? AppColors.expenseStrong : AppColors.income;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Danh mục: chạm để đổi (trừ giao dịch chuyển tiền)
              InkWell(
                onTap: _canChangeCategory && !_isSaving ? _pickCategory : null,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    CategoryIcon(
                      categoryOrIconKey: _category,
                      size: 48,
                      bgColor: isExpense ? AppColors.expenseBg : AppColors.incomeBg,
                      iconColor: amountColor,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tCategory(_category),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBeige),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _canChangeCategory ? context.t('Chạm để đổi danh mục') : context.t('Danh mục cố định'),
                            style: TextStyle(fontSize: 12, color: AppColors.grey500),
                          ),
                        ],
                      ),
                    ),
                    if (_canChangeCategory) Icon(Icons.chevron_right_rounded, color: AppColors.grey500),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.rule),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.t('Ghi chú / Tên giao dịch:'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.grey500)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: context.t('Nhập tên ghi chú...'),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(context.t('Số tiền (đ):'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.grey500)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [MoneyInputFormatter()],
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: amountColor),
                      decoration: InputDecoration(
                        isDense: true,
                        prefixText: isExpense ? '- ' : '+ ',
                        prefixStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: amountColor),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.t('Thời gian:'), style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                        Text(
                          _formatDateTime(_item.date),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkBeige),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving ? null : _delete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(context.t('Xóa'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded),
                      label: Text(context.t('Lưu thay đổi'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
