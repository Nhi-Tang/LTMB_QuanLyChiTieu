import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'auth_screen.dart';

class TransactionItem {
  final String id;
  final String title;
  final String category;
  final String wallet;
  final double amount;
  final bool isExpense;
  final DateTime date;

  TransactionItem({
    required this.id,
    required this.title,
    required this.category,
    required this.wallet,
    required this.amount,
    required this.isExpense,
    required this.date,
  });
}

class HomeScreen extends StatefulWidget {
  final UserModel currentUser;

  const HomeScreen({super.key, required this.currentUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;
  DateTime _selectedMonth = DateTime(2026, 8, 1);

  // Theme Palette (Main color: A5D6A7)
  static const Color primaryGreen = Color(0xFFA5D6A7);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF2E7D32);
  static const Color bgGreen = Color(0xFFF4F8F4);

  // Sample transactions matching Expenza design
  final List<TransactionItem> _transactions = [
    TransactionItem(
      id: '1',
      title: 'Food & Dining',
      category: 'Ăn uống',
      wallet: 'Ví Tiền Mặt',
      amount: 60.00,
      isExpense: true,
      date: DateTime(2026, 8, 14),
    ),
    TransactionItem(
      id: '2',
      title: 'Salary Deposit',
      category: 'Lương',
      wallet: 'Thẻ ATM',
      amount: 12214.00,
      isExpense: false,
      date: DateTime(2026, 8, 14),
    ),
    TransactionItem(
      id: '3',
      title: 'Utility Bill',
      category: 'Hóa đơn',
      wallet: 'Ví Điện Tử',
      amount: 98.40,
      isExpense: true,
      date: DateTime(2026, 8, 14),
    ),
    TransactionItem(
      id: '4',
      title: 'Transport',
      category: 'Di chuyển',
      wallet: 'Ví Tiền Mặt',
      amount: 80.00,
      isExpense: true,
      date: DateTime(2026, 8, 13),
    ),
  ];

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi PiggySmart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Calculate totals
  double get _totalIncome {
    double sum = 5420.00; // Base sample income matching Expenza
    for (var t in _transactions) {
      if (!t.isExpense &&
          t.date.year == _selectedMonth.year &&
          t.date.month == _selectedMonth.month) {
        sum += t.amount;
      }
    }
    return sum;
  }

  double get _totalExpense {
    double sum = 2185.40; // Base sample expense matching Expenza
    for (var t in _transactions) {
      if (t.isExpense &&
          t.date.year == _selectedMonth.year &&
          t.date.month == _selectedMonth.month) {
        sum += t.amount;
      }
    }
    return sum;
  }

  double get _totalBalance => 18450.75 + _totalIncome - _totalExpense;

  String _formatCurrency(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final formatted = absAmount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '${isNegative ? '-' : ''}\$$formatted';
  }

  String _formatMonthYear(DateTime date) {
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${monthNames[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date) {
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showAddTransactionDialog({bool defaultExpense = true}) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    bool isExpense = defaultExpense;
    String category = 'Ăn uống';
    String wallet = 'Ví Tiền Mặt';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                      const Text(
                        'Thêm giao dịch mới',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
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
                            setModalState(() {
                              isExpense = true;
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
                            setModalState(() {
                              isExpense = false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Tên giao dịch',
                      hintText: 'VD: Food & Dining, Salary...',
                      prefixIcon: const Icon(Icons.edit_note, color: accentGreen),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Số tiền (\$)',
                      hintText: 'VD: 60.00',
                      prefixIcon: const Icon(Icons.attach_money, color: accentGreen),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: category,
                          decoration: InputDecoration(
                            labelText: 'Danh mục',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          items: ['Ăn uống', 'Lương', 'Hóa đơn', 'Di chuyển', 'Mua sắm', 'Khác']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => category = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: wallet,
                          decoration: InputDecoration(
                            labelText: 'Ví',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          items: ['Ví Tiền Mặt', 'Thẻ ATM', 'Ví Điện Tử']
                              .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => wallet = val);
                          },
                        ),
                      ),
                    ],
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập thông tin hợp lệ!')),
                          );
                          return;
                        }

                        setState(() {
                          _transactions.insert(
                            0,
                            TransactionItem(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              title: title,
                              category: category,
                              wallet: wallet,
                              amount: amount,
                              isExpense: isExpense,
                              date: DateTime.now(),
                            ),
                          );
                        });

                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã thêm giao dịch thành công! 🌿')),
                        );
                      },
                      child: const Text(
                        'LƯU GIAO DỊCH',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGreen,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            IndexedStack(
              index: _currentTabIndex,
              children: [
                _buildHomeTab(),
                _buildPlaceholderTab('Giao dịch (Transaction) 📋'),
                _buildPlaceholderTab('Báo cáo (Reports) 📊'),
                _buildProfileTab(),
              ],
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: _buildFloatingBottomTabBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 110),
      child: Column(
        children: [
          // 1. Top Header Area with Primary Green Gradient (A5D6A7)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryGreen,
                  Color(0xFF81C784),
                  accentGreen,
                ],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Action Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // User Avatar
                    GestureDetector(
                      onTap: () => _logout(context),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: primaryGreen,
                          child: Text(
                            widget.currentUser.name.isNotEmpty
                                ? widget.currentUser.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Month Selector Pill
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedMonth,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedMonth = DateTime(picked.year, picked.month, 1);
                          });
                        }
                      },
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
                              _formatMonthYear(_selectedMonth),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: darkGreen,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down, size: 18, color: darkGreen),
                          ],
                        ),
                      ),
                    ),

                    // Notification Bell Button
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none_rounded, color: darkGreen),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Total Balance Label & Amount
                const Text(
                  'Total Balance',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(_totalBalance),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 20),

                // Income & Expenses Cards Side by Side
                Row(
                  children: [
                    // Income Card
                    Expanded(
                      child: _buildHeaderSummaryCard(
                        title: 'Income',
                        amount: '+${_formatCurrency(_totalIncome)}',
                        isIncome: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Expenses Card
                    Expanded(
                      child: _buildHeaderSummaryCard(
                        title: 'Expenses',
                        amount: '-${_formatCurrency(_totalExpense)}',
                        isIncome: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. Quick Action Grid Buttons (Row of 4 buttons)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickActionButton(
                  icon: Icons.credit_card_sharp,
                  label: 'Add Expense',
                  onTap: () => _showAddTransactionDialog(defaultExpense: true),
                ),
                _buildQuickActionButton(
                  icon: Icons.my_location_rounded,
                  label: 'Add Income',
                  onTap: () => _showAddTransactionDialog(defaultExpense: false),
                ),
                _buildQuickActionButton(
                  icon: Icons.sync_alt_rounded,
                  label: 'Transfer',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng Chuyển khoản (Transfer)')),
                    );
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.crop_free_rounded,
                  label: 'Scan Receipt',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng Quét hóa đơn (Scan Receipt)')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Alert / Unsorted Transactions Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8EFE8)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 20, color: accentGreen),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You have 2 unsorted transactions.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF424242),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: darkGreen,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text(
                      'Sort Now',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 4. Recent Transactions Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transaction',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'View all',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: accentGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Transaction Item List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _transactions[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE8EFE8)),
                  ),
                  child: Row(
                    children: [
                      // Category Icon Circle
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: bgGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            _getCategoryIcon(item.category),
                            color: accentGreen,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Title & Subtitle Date
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
                      // Amount
                      Text(
                        '${item.isExpense ? '-' : '+'}${_formatCurrency(item.amount)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: item.isExpense ? const Color(0xFFE57373) : accentGreen,
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
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Custom pattern indicator line
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: isIncome ? 0.65 : 0.4,
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
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8EFE8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: darkGreen, size: 26),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF424242),
          ),
        ),
      ],
    );
  }

  // --- FLOATING PILL BOTTOM TAB BAR WITH CENTER ADD BUTTON ---
  Widget _buildFloatingBottomTabBar() {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(33),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Home
          _buildFloatingNavItem(
            index: 0,
            icon: Icons.home_rounded,
            label: 'Home',
          ),
          // 2. Transaction
          _buildFloatingNavItem(
            index: 1,
            icon: Icons.receipt_long_rounded,
            label: 'Transaction',
          ),

          // 3. Center ADD Button
          GestureDetector(
            onTap: () => _showAddTransactionDialog(defaultExpense: true),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.add_rounded,
                  color: darkGreen,
                  size: 30,
                ),
              ),
            ),
          ),

          // 4. Reports
          _buildFloatingNavItem(
            index: 2,
            icon: Icons.pie_chart_rounded,
            label: 'Reports',
          ),
          // 5. Profile
          _buildFloatingNavItem(
            index: 3,
            icon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentTabIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _currentTabIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? primaryGreen : Colors.white60,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryGreen : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Ăn uống':
        return Icons.fastfood_rounded;
      case 'Lương':
        return Icons.account_balance_wallet_rounded;
      case 'Hóa đơn':
        return Icons.receipt_rounded;
      case 'Di chuyển':
        return Icons.directions_bus_rounded;
      case 'Mua sắm':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Widget _buildPlaceholderTab(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.construction_rounded, size: 60, color: accentGreen),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tính năng đang được hoàn thiện...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 45,
            backgroundColor: primaryGreen,
            child: Text(
              widget.currentUser.name.isNotEmpty ? widget.currentUser.name[0].toUpperCase() : 'U',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: darkGreen),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.currentUser.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            widget.currentUser.email,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.person_outline, color: accentGreen),
            title: const Text('Thông tin tài khoản'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.security, color: accentGreen),
            title: const Text('Bảo mật & Dữ liệu'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
