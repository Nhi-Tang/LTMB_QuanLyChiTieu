import 'package:flutter/material.dart';
import '../../backend/models/transaction_model.dart';
import '../../backend/services/transaction_service.dart';
import '../../core/widgets/money_text.dart';
import '../../core/widgets/category_icon.dart';
import '../utils/app_translations.dart';
import '../utils/app_language.dart';

class AllTransactionsScreen extends StatefulWidget {
  final List<TransactionItem> transactions;
  final String selectedLanguage;

  const AllTransactionsScreen({
    super.key,
    required this.transactions,
    this.selectedLanguage = 'Tiếng Việt',
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
        decoration: const BoxDecoration(
          color: Color(0xFFF5FDFD),
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
                  color: Colors.grey.shade400,
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
                  bgColor: isExpense ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                  iconColor: isExpense ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title.isNotEmpty ? item.title : item.category,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00463E)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        context.tCategory(item.category),
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCCF7F7)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.t('Số tiền:'), style: TextStyle(fontSize: 14, color: Colors.grey)),
                      MoneyText(
                        amount: item.amount,
                        prefix: isExpense ? '-' : '+',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isExpense ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.t('Ngày giờ:'), style: TextStyle(fontSize: 14, color: Colors.grey)),
                      Text(
                        formattedDateTime,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00463E)),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.t('Loại giao dịch:'), style: TextStyle(fontSize: 14, color: Colors.grey)),
                      Text(
                        isExpense ? context.t('Chi tiêu (-)') : context.t('Thu nhập (+)'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isExpense ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
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
    const accentBeige = Color(0xFFCCF7F7);
    const darkBeige = Color(0xFF00463E);
    final lang = context.lang;
    final transactionsList = _filteredTransactions;

    return Scaffold(
      backgroundColor: const Color(0xFFF5FDFD),
      appBar: AppBar(
        title: Text(
          AppTranslations.tr(lang, 'recent_transactions'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: context.t('Tìm kiếm giao dịch...'),
                    prefixIcon: const Icon(Icons.search, color: darkBeige),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF5FDFD),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFCCF7F7)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFCCF7F7)),
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
                          color: _filterType == 'all' ? darkBeige : Colors.black87,
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
                          color: _filterType == 'expense' ? Colors.white : Colors.black87,
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
                          color: _filterType == 'income' ? darkBeige : Colors.black87,
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
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          AppTranslations.tr(lang, 'no_transactions'),
                          style: TextStyle(color: Colors.grey[600], fontSize: 15),
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFCCF7F7)),
                          ),
                          child: Row(
                            children: [
                              CategoryIcon(
                                categoryOrIconKey: item.category,
                                size: 44,
                                bgColor: const Color(0xFFF5FDFD),
                                iconColor: darkBeige,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title.isNotEmpty ? item.title : item.category,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF212121),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${AppTranslations.trCategory(lang, item.category)} · ${_formatDateTime(item.date)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF9E9E9E),
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
                                  color: item.isExpense ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
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
