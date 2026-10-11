import 'package:flutter/material.dart';
import '../../backend/models/transaction_model.dart';
import '../utils/app_translations.dart';

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

  String _formatCurrency(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final formatted = absAmount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return '${isNegative ? '-' : ''}$formatted đ';
  }

  String _formatDate(DateTime date) {
    return AppTranslations.formatDate(widget.selectedLanguage, date);
  }

  IconData _getCategoryIconData(String category) {
    switch (category) {
      case 'Ăn uống':
        return Icons.fastfood_rounded;
      case 'Hóa đơn':
        return Icons.receipt_rounded;
      case 'Di chuyển':
        return Icons.directions_bus_rounded;
      case 'Mua sắm':
        return Icons.shopping_bag_rounded;
      case 'Giải trí':
        return Icons.sports_esports_rounded;
      case 'Sức khoẻ':
        return Icons.medical_services_rounded;
      case 'Làm đẹp':
        return Icons.content_cut_rounded;
      case 'Quần áo':
        return Icons.checkroom_rounded;
      case 'Học tập':
        return Icons.school_rounded;
      case 'Thú cưng':
        return Icons.pets_rounded;
      case 'Con cái':
        return Icons.child_care_rounded;
      case 'Hỗ trợ gia đình':
        return Icons.family_restroom_rounded;
      case 'Bảo hiểm':
        return Icons.security_rounded;
      case 'Thuế':
        return Icons.account_balance_rounded;
      case 'Công việc':
        return Icons.work_rounded;
      case 'Nhà ở':
        return Icons.home_rounded;
      case 'Tiền nợ':
      case 'Tiền Nợ':
        return Icons.money_off_rounded;
      case 'Lương':
        return Icons.account_balance_wallet_rounded;
      case 'Thưởng':
        return Icons.card_giftcard_rounded;
      case 'Đầu tư':
        return Icons.trending_up_rounded;
      case 'Bán hàng':
        return Icons.storefront_rounded;
      default:
        return Icons.category_rounded;
    }
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

  @override
  Widget build(BuildContext context) {
    const accentBeige = Color(0xFFE5D3AF);
    const darkBeige = Color(0xFF5D4222);
    final lang = widget.selectedLanguage;
    final transactionsList = _filteredTransactions;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7EB),
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
                    hintText: 'Tìm kiếm giao dịch...',
                    prefixIcon: const Icon(Icons.search, color: darkBeige),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFFFF7EB),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFECE7DB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFECE7DB)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Tất cả')),
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
                        label: const Center(child: Text('Chi tiêu')),
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
                        label: const Center(child: Text('Thu nhập')),
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
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFECE7DB)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF7EB),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  _getCategoryIconData(item.category),
                                  color: accentBeige,
                                  size: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF212121),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${AppTranslations.trCategory(lang, item.category)} · ${_formatDate(item.date)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9E9E9E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${item.isExpense ? '-' : '+'}${_formatCurrency(item.amount)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: item.isExpense ? const Color(0xFFE57373) : accentBeige,
                              ),
                            ),
                          ],
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
