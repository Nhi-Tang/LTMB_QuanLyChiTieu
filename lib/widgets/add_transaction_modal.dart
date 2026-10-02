import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction_model.dart';
import 'app_alert_dialog.dart';

class AddTransactionModal extends StatefulWidget {
  final bool defaultExpense;
  final Function(TransactionItem item) onSave;

  const AddTransactionModal({
    super.key,
    required this.defaultExpense,
    required this.onSave,
  });

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  late bool isExpense;
  late String category;
  final titleController = TextEditingController();
  final amountController = TextEditingController();

  static const Color accentGreen = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    isExpense = widget.defaultExpense;
    category = isExpense ? 'Ăn uống' : 'Lương';
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isExpense ? 'Nhập khoản chi tiêu' : 'Nhập khoản thu nhập',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Chi tiêu')),
                  selected: isExpense,
                  selectedColor: const Color(0xFFE57373),
                  labelStyle: TextStyle(
                    color: isExpense ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (val) {
                    setState(() {
                      isExpense = true;
                      category = 'Ăn uống';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Thu nhập')),
                  selected: !isExpense,
                  selectedColor: accentGreen,
                  labelStyle: TextStyle(
                    color: !isExpense ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (val) {
                    setState(() {
                      isExpense = false;
                      category = 'Lương';
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: titleController,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: isExpense ? 'Ghi chú / Tên chi tiêu' : 'Nguồn thu nhập / Ghi chú',
              hintText: isExpense ? 'VD: Ăn sáng, Mua sắm...' : 'VD: Lương tháng, Tiền thưởng...',
              prefixIcon: const Icon(Icons.edit_note, color: accentGreen),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              labelText: 'Số tiền (đ)',
              hintText: 'VD: 500000',
              prefixIcon: const Icon(Icons.attach_money, color: accentGreen),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: category,
            decoration: InputDecoration(
              labelText: 'Danh mục',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            items: (isExpense
                    ? ['Ăn uống', 'Hóa đơn', 'Di chuyển', 'Mua sắm', 'Giải trí', 'Sức khoẻ', 'Làm đẹp',
                    'Quần áo','Học tập','Thú cưng','Con cái','Hỗ trợ gia đình','Bảo hiểm','Thuế','Công việc','Nhà ở','Tiền nợ','Khác']
                    : ['Lương', 'Thưởng', 'Bán hàng', 'Đầu tư', 'Khác'])
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => category = val);
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                final title = titleController.text.trim();
                final amount = double.tryParse(amountController.text.trim());

                if (title.isEmpty || amount == null || amount <= 0) {
                  showAppAlertDialog(
                    context: context,
                    title: 'Thông báo',
                    message: 'Vui lòng nhập đầy đủ thông tin hợp lệ!',
                    isSuccess: false,
                  );
                  return;
                }

                final newItem = TransactionItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: title,
                  category: category,
                  amount: amount,
                  isExpense: isExpense,
                  date: DateTime.now(),
                );

                widget.onSave(newItem);
                Navigator.pop(context);

                showAppAlertDialog(
                  context: context,
                  title: 'Thành công',
                  message: isExpense
                      ? 'Đã ghi nhận khoản chi tiêu mới! 💸'
                      : 'Đã ghi nhận khoản thu nhập mới! 💰',
                  isSuccess: true,
                );
              },
              child: Text(
                isExpense ? 'LƯU KHOẢN CHI TIÊU' : 'LƯU KHOẢN THU NHẬP',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
