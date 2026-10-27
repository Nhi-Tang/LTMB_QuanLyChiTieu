import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../backend/models/transaction_model.dart';
import '../utils/app_translations.dart';
import 'app_alert_dialog.dart';
import '../utils/app_language.dart';
import '../theme/app_colors.dart';

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

  static Color get accentBeige => AppColors.tealLight;

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
    final lang = context.lang;

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
                color: AppColors.grey300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isExpense ? AppTranslations.tr(lang, 'add_expense') : AppTranslations.tr(lang, 'add_income'),
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
                  label: Center(child: Text(AppTranslations.tr(lang, 'expense'))),
                  selected: isExpense,
                  selectedColor: const Color(0xFFE57373),
                  labelStyle: TextStyle(
                    color: isExpense ? Colors.white : AppColors.black87,
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
                  label: Center(child: Text(AppTranslations.tr(lang, 'income'))),
                  selected: !isExpense,
                  selectedColor: accentBeige,
                  labelStyle: TextStyle(
                    color: !isExpense ? Colors.white : AppColors.black87,
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
              labelText: AppTranslations.tr(lang, 'transaction_title'),
              hintText: category,
              prefixIcon: Icon(Icons.edit_note, color: accentBeige),
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
              labelText: AppTranslations.tr(lang, 'amount'),
              hintText: 'VD: 500000',
              prefixIcon: Icon(Icons.attach_money, color: accentBeige),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: category,
            decoration: InputDecoration(
              labelText: AppTranslations.tr(lang, 'category'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            items: (isExpense
                    ? ['Ăn uống', 'Cà phê', 'Trà sữa', 'Hóa đơn', 'Điện thoại', 'Di chuyển', 'Mua sắm', 'Giải trí', 'Sức khoẻ', 'Làm đẹp',
                    'Quần áo','Học tập','Thú cưng','Con cái','Hỗ trợ gia đình','Bảo hiểm','Thuế','Công việc','Nhà ở','Tiền nợ','Khác']
                    : ['Lương', 'Thưởng', 'Bán hàng', 'Đầu tư', 'Khác'])
                .map((c) => DropdownMenuItem(value: c, child: Text(AppTranslations.trCategory(lang, c))))
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
                backgroundColor: accentBeige,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                final titleInput = titleController.text.trim();
                final finalTitle = titleInput.isEmpty ? category : titleInput;
                final amount = double.tryParse(amountController.text.trim());

                if (amount == null || amount <= 0) {
                  showAppAlertDialog(
                    context: context,
                    title: AppTranslations.tr(lang, 'language'),
                    message: context.t('Vui lòng nhập số tiền hợp lệ!'),
                    isSuccess: false,
                  );
                  return;
                }

                final newItem = TransactionItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: finalTitle,
                  category: category,
                  amount: amount,
                  isExpense: isExpense,
                  date: DateTime.now(),
                );

                widget.onSave(newItem);
                Navigator.pop(context);

                showAppAlertDialog(
                  context: context,
                  title: AppTranslations.tr(lang, 'save_transaction'),
                  message: isExpense
                      ? context.t('Đã ghi nhận khoản chi tiêu mới! 💸')
                      : context.t('Đã ghi nhận khoản thu nhập mới! 💰'),
                  isSuccess: true,
                );
              },
              child: Text(
                AppTranslations.tr(lang, 'save_transaction'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
