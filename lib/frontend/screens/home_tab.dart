import 'package:flutter/material.dart';
import '../../backend/models/transaction_model.dart';
import '../../backend/models/user_model.dart';
import '../utils/app_translations.dart';
import '../widgets/piggy_avatar.dart';
import 'all_transactions_screen.dart';

class HomeTab extends StatelessWidget {
  final UserModel currentUser;
  final String selectedAvatarKey;
  final String selectedLanguage;
  final DateTime selectedMonth;
  final double totalIncome;
  final double totalExpense;
  final double totalBalance;
  final List<TransactionItem> transactions;
  final VoidCallback onLogout;
  final VoidCallback onSelectMonth;
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;

  static const Color primaryBeige = Color(0xFFFCF1D0);
  static const Color darkBeige = Color(0xFF5D4222);
  static const Color accentBeige = Color(0xFFE5D3AF);

  const HomeTab({
    super.key,
    required this.currentUser,
    required this.selectedAvatarKey,
    required this.selectedLanguage,
    required this.selectedMonth,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalBalance,
    required this.transactions,
    required this.onLogout,
    required this.onSelectMonth,
    required this.onAddIncome,
    required this.onAddExpense,
  });

  String _formatCurrency(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final formatted = absAmount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return '${isNegative ? '-' : ''}$formatted đ';
  }

  String _formatMonthYear(DateTime date) {
    return AppTranslations.formatMonthYear(selectedLanguage, date);
  }

  String _formatDate(DateTime date) {
    return AppTranslations.formatDate(selectedLanguage, date);
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

  @override
  Widget build(BuildContext context) {
    final lang = selectedLanguage;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 110),
      child: Column(
        children: [
          // 1. Header Gradient
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryBeige,
                  Color(0xFFFCF1D0),
                  accentBeige,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: darkBeige.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top action bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: onLogout,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: buildUserAvatar(
                          avatarKey: selectedAvatarKey,
                          userName: currentUser.name,
                          size: 40,
                        ),
                      ),
                    ),

                    // Month Picker
                    InkWell(
                      onTap: onSelectMonth,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatMonthYear(selectedMonth),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: darkBeige,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, size: 18, color: darkBeige),
                          ],
                        ),
                      ),
                    ),

                    // Bell icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none_rounded, color: darkBeige),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Total Balance
                Text(
                  AppTranslations.tr(lang, 'total_balance'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: darkBeige,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(totalBalance),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: darkBeige,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 20),

                // Income & Expense Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildHeaderSummaryCard(
                        title: AppTranslations.tr(lang, 'income'),
                        amount: '+${_formatCurrency(totalIncome)}',
                        isIncome: true,
                        onTap: onAddIncome,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildHeaderSummaryCard(
                        title: AppTranslations.tr(lang, 'expense'),
                        amount: '-${_formatCurrency(totalExpense)}',
                        isIncome: false,
                        onTap: onAddExpense,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Recent Transactions Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppTranslations.tr(lang, 'recent_transactions'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllTransactionsScreen(
                          transactions: transactions,
                          selectedLanguage: lang,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    AppTranslations.tr(lang, 'view_all'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: accentBeige,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Transaction list or empty state
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: transactions.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE8EFE8)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 48, color: primaryBeige),
                        const SizedBox(height: 12),
                        Text(
                          AppTranslations.tr(lang, 'no_transactions'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF424242),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppTranslations.tr(lang, 'add_first_transaction'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = transactions[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE8EFE8)),
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
                                    _formatDate(item.date),
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

  Widget _buildHeaderSummaryCard({
    required String title,
    required String amount,
    required bool isIncome,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: darkBeige.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: darkBeige,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: darkBeige.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 14,
                      color: darkBeige,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: darkBeige,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: totalIncome == 0 && totalExpense == 0
                      ? 0.0
                      : (isIncome ? 0.65 : 0.4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
