import 'package:flutter/material.dart';
import '../../backend/models/transaction_model.dart';
import '../../backend/services/transaction_service.dart';
import '../../core/widgets/money_text.dart';
import '../../core/widgets/category_icon.dart';
import '../utils/app_translations.dart';
import '../utils/app_language.dart';
import '../theme/app_colors.dart';

class AllTransactionsScreen extends StatefulWidget {
  final List<TransactionItem> transactions;

  const AllTransactionsScreen({
    super.key,
    required this.transactions,
  });

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'expense', 'income'

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$hour:$minute - $day/$month/$year';
  }

  List<TransactionItem> get _filteredTransactions {
    return widget.transactions.where((t) {
      if (_filterType == 'expense' && !t.isExpense) return false;
      if (_filterType == 'income' && t.isExpense) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = t.title.toLowerCase().contains(q);
        final matchCategory = t.category.toLowerCase().contains(q);
        if (!matchTitle && !matchCategory) return false;
      }
      return true;
    }).toList();
  }

  void _showTransactionDetailSheet(TransactionItem item) {
    final isExpense = item.isExpense;
    final formattedDateTime = _formatDateTime(item.date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.tealWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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

            // Header Icon & Title
            Row(
              children: [
                CategoryIcon(
                  categoryOrIconKey: item.category,
                  size: 48,
                  bgColor: isExpense ? AppColors.expenseBg : AppColors.incomeBg,
                  iconColor: isExpense ? AppColors.expenseStrong : AppColors.income,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title.isNotEmpty ? item.title : item.category,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.tealDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        context.tCategory(item.category),
                        style: TextStyle(fontSize: 13, color: AppColors.grey500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Details Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.tealPale),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.t('Số tiền:'), style: TextStyle(fontSize: 14, color: AppColors.grey500)),
                      MoneyText(
                        amount: item.amount,
                        prefix: isExpense ? '-' : '+',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isExpense ? AppColors.expenseStrong : AppColors.income,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.t('Ngày giờ:'), style: TextStyle(fontSize: 14, color: AppColors.grey500)),
                      Text(
                        formattedDateTime,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.tealDark),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.t('Loại giao dịch:'), style: TextStyle(fontSize: 14, color: AppColors.grey500)),
                      Text(
                        isExpense ? context.t('Chi tiêu (-)') : context.t('Thu nhập (+)'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isExpense ? AppColors.expenseStrong : AppColors.income,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Button (Xóa giao dịch)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await TransactionService.instance.removeTransaction(item.id, uid: item.uid, date: item.date);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.t('Đã xóa giao dịch thành công!')), backgroundColor: Colors.red),
                  );
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(context.t('Xóa giao dịch'), style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accentBeige = AppColors.tealPale;
    final darkBeige = AppColors.tealDark;
    final lang = context.lang;
    final transactionsList = _filteredTransactions;

    return Scaffold(
      backgroundColor: AppColors.tealWhite,
      appBar: AppBar(
        title: Text(
          AppTranslations.tr(lang, 'recent_transactions'),
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.black87),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.black87),
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: context.t('Tìm kiếm giao dịch...'),
                    prefixIcon: Icon(Icons.search, color: darkBeige),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.tealWhite,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.tealPale),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.tealPale),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Center(child: Text(context.t('Tất cả'))),
                        selected: _filterType == 'all',
                        selectedColor: accentBeige,
                        labelStyle: TextStyle(
                          color: _filterType == 'all' ? darkBeige : AppColors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) => setState(() => _filterType = 'all'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: Center(child: Text(context.t('Chi tiêu'))),
                        selected: _filterType == 'expense',
                        selectedColor: const Color(0xFFE57373),
                        labelStyle: TextStyle(
                          color: _filterType == 'expense' ? Colors.white : AppColors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) => setState(() => _filterType = 'expense'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: Center(child: Text(context.t('Thu nhập'))),
                        selected: _filterType == 'income',
                        selectedColor: accentBeige,
                        labelStyle: TextStyle(
                          color: _filterType == 'income' ? darkBeige : AppColors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) => setState(() => _filterType = 'income'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Transactions List
          Expanded(
            child: transactionsList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.grey400),
                        const SizedBox(height: 12),
                        Text(
                          AppTranslations.tr(lang, 'no_transactions'),
                          style: TextStyle(color: AppColors.grey600, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: transactionsList.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = transactionsList[index];
                      return InkWell(
                        onTap: () => _showTransactionDetailSheet(item),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.tealPale),
                          ),
                          child: Row(
                            children: [
                              CategoryIcon(
                                categoryOrIconKey: item.category,
                                size: 44,
                                bgColor: AppColors.tealWhite,
                                iconColor: darkBeige,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title.isNotEmpty ? item.title : item.category,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.pick(const Color(0xFF212121), const Color(0xFFEDEDED)),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${AppTranslations.trCategory(lang, item.category)} · ${_formatDateTime(item.date)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.unselectedTab,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              MoneyText(
                                amount: item.amount,
                                prefix: item.isExpense ? '-' : '+',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: item.isExpense ? AppColors.expenseStrong : AppColors.income,
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
