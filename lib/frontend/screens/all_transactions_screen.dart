import 'package:flutter/material.dart';
import '../../backend/models/transaction_model.dart';
import '../../core/widgets/money_text.dart';
import '../../core/widgets/category_icon.dart';
import '../utils/app_translations.dart';
import '../utils/app_language.dart';
import '../theme/app_colors.dart';
import '../widgets/transaction_sheet/transaction_detail_sheet.dart';

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

  /// Bản sao danh sách để cập nhật ngay khi sửa/xoá trong màn này
  late final List<TransactionItem> _transactions = List.of(widget.transactions);

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$hour:$minute - $day/$month/$year';
  }

  List<TransactionItem> get _filteredTransactions {
    return _transactions.where((t) {
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

  void _openTransaction(TransactionItem item) {
    showTransactionDetailSheet(
      context,
      item,
      onUpdated: (updated) => setState(() {
        final i = _transactions.indexWhere((t) => t.id == updated.id);
        if (i != -1) _transactions[i] = updated;
      }),
      onDeleted: () => setState(() => _transactions.removeWhere((t) => t.id == item.id)),
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
                        onTap: () => _openTransaction(item),
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
