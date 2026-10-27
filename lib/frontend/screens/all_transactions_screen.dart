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
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
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
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.rule),
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

  /// Tab lọc dạng chữ gạch chân, giống tab Chi tiêu / Thu nhập ở màn Báo cáo
  Widget _filterTab(String key, String label) {
    final selected = _filterType == key;
    return InkWell(
      onTap: () => setState(() => _filterType = key),
      child: Container(
        padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
        margin: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: selected ? AppColors.ink : Colors.transparent, width: 2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? AppColors.ink : AppColors.unselectedTab,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final transactionsList = _filteredTransactions;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslations.tr(lang, 'recent_transactions')),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ô tìm kiếm kẻ một dòng + tab lọc gạch chân
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: context.t('Tìm kiếm giao dịch...'),
                prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Container(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.rule))),
              child: Row(
                children: [
                  _filterTab('all', context.t('Tất cả')),
                  _filterTab('expense', context.t('Chi tiêu')),
                  _filterTab('income', context.t('Thu nhập')),
                ],
              ),
            ),
          ),

          // Danh sách dạng dòng kẻ
          Expanded(
            child: transactionsList.isEmpty
                ? Center(
                    child: Text(
                      AppTranslations.tr(lang, 'no_transactions'),
                      style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: transactionsList.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.rule),
                    itemBuilder: (context, index) {
                      final item = transactionsList[index];
                      return InkWell(
                        onTap: () => _showTransactionDetailSheet(item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              CategoryIcon(
                                categoryOrIconKey: item.category,
                                size: 40,
                                bgColor: Colors.transparent,
                                iconColor: AppColors.ink,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title.isNotEmpty ? item.title : item.category,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${AppTranslations.trCategory(lang, item.category)} · ${_formatDateTime(item.date)}',
                                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              MoneyText(
                                amount: item.amount,
                                prefix: item.isExpense ? '−' : '+',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: item.isExpense ? AppColors.expense : AppColors.income,
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
