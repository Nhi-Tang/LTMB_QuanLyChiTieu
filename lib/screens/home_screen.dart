import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import 'auth_screen.dart';
import 'reports_tab.dart';

class TransactionItem {
  final String id;
  final String title;
  final String category;
  final double amount;
  final bool isExpense;
  final DateTime date;

  TransactionItem({
    required this.id,
    required this.title,
    required this.category,
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
  late DateTime _selectedMonth;

  // Palette màu chủ đạo: Green A5D6A7
  static const Color primaryGreen = Color(0xFFA5D6A7);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF2E7D32);
  static const Color bgGreen = Color(0xFFF4F8F4);

  // Mặc định như vừa mới tải app về: Danh sách giao dịch trống
  final List<TransactionItem> _transactions = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
  }

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

  Future<void> _showAlertDialog({
    required String title,
    required String message,
    bool isSuccess = true,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
              color: isSuccess ? const Color(0xFF2E7D32) : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuccess ? const Color(0xFF2E7D32) : Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Tính toán số dư, thu nhập, chi tiêu thực tế từ danh sách giao dịch
  double get _totalIncome {
    double sum = 0.0;
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
    double sum = 0.0;
    for (var t in _transactions) {
      if (t.isExpense &&
          t.date.year == _selectedMonth.year &&
          t.date.month == _selectedMonth.month) {
        sum += t.amount;
      }
    }
    return sum;
  }

  double get _totalBalance => _totalIncome - _totalExpense;

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
    return 'Tháng ${date.month}, ${date.year}';
  }

  String _formatDate(DateTime date) {
    return '${date.day} Tháng ${date.month}, ${date.year}';
  }

  void _showAddTransactionDialog({bool defaultExpense = true}) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    bool isExpense = defaultExpense;
    String category = isExpense ? 'Ăn uống' : 'Lương';

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
                      Text(
                        isExpense ? 'Nhập khoản chi tiêu' : 'Nhập khoản thu nhập',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            setModalState(() {
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
                    textCapitalization: TextCapitalization.sentences, // tự viết hoa đầu câu, tiện hơn
                    decoration: InputDecoration(
                      labelText: isExpense ? 'Ghi chú / Tên chi tiêu' : 'Nguồn thu nhập / Ghi chú',
                      hintText: isExpense ? 'VD: Ăn sáng, Mua sắm...' : 'VD: Lương tháng, Tiền thưởng...',
                      prefixIcon: const Icon(Icons.edit_note, color: accentGreen),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    // Không có inputFormatters
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
                      if (val != null) setModalState(() => category = val);
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
                          _showAlertDialog(
                            title: 'Thông báo',
                            message: 'Vui lòng nhập đầy đủ thông tin hợp lệ!',
                            isSuccess: false,
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
                              amount: amount,
                              isExpense: isExpense,
                              date: DateTime.now(),
                            ),
                          );
                        });

                        Navigator.pop(ctx);
                        _showAlertDialog(
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            IndexedStack(
              index: _currentTabIndex,
              children: [
                _buildHomeTab(),
                _buildPlaceholderTab('Giao dịch 📋'),
                ReportsTab(transactions: _transactions),
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
          // 1. Header Gradient xanh lá (A5D6A7)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryGreen,
                  Color(0xFF81C784),
                  accentGreen,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: darkGreen.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thanh tác vụ trên cùng
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Avatar người dùng
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

                    // Bộ chọn tháng
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

                    // Nút Chuông thông báo
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

                // Tổng số dư
                const Text(
                  'Tổng số dư',
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
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 20),

                // Thẻ Thu nhập & Chi tiêu song song (Dạng button bấm vào để nhập)
                Row(
                  children: [
                    // Thẻ Thu nhập (Button bấm vào để nhập Thu nhập)
                    Expanded(
                      child: _buildHeaderSummaryCard(
                        title: 'Thu nhập',
                        amount: '+${_formatCurrency(_totalIncome)}',
                        isIncome: true,
                        onTap: () => _showAddTransactionDialog(defaultExpense: false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Thẻ Chi tiêu (Button bấm vào để nhập Chi tiêu)
                    Expanded(
                      child: _buildHeaderSummaryCard(
                        title: 'Chi tiêu',
                        amount: '-${_formatCurrency(_totalExpense)}',
                        isIncome: false,
                        onTap: () => _showAddTransactionDialog(defaultExpense: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Danh sách Giao dịch gần đây
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Giao dịch gần đây',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Xem tất cả',
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

          // Danh sách các dòng giao dịch hoặc Trạng thái trống mặc định
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _transactions.isEmpty
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
                      children: const [
                        Icon(Icons.receipt_long_outlined, size: 48, color: primaryGreen),
                        SizedBox(height: 12),
                        Text(
                          'Chưa có giao dịch nào trong tháng này',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF424242),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Nhấn vào nút Thu nhập/Chi tiêu ở trên hoặc nút (+) bên dưới để thêm giao dịch đầu tiên nhé!',
                          style: TextStyle(
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
                            // Icon danh mục
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
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
                            // Tên & Ngày giao dịch
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
                            // Số tiền
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
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
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 14,
                      color: Colors.white,
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
                  color: Colors.white,
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
                  widthFactor: _totalIncome == 0 && _totalExpense == 0
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

  // --- FLOATING PILL BOTTOM TAB BAR ---
  Widget _buildFloatingBottomTabBar() {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Color(0xFFE8F5E9),
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
          // 1. Trang chủ
          _buildFloatingNavItem(
            index: 0,
            icon: Icons.home_rounded,
            label: 'Trang chủ',
          ),
          // 4. Báo cáo
          _buildFloatingNavItem(
            index: 2,
            icon: Icons.pie_chart_rounded,
            label: 'Báo cáo',
          ),

          // 3. Nút THÊM ở giữa
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
                  color: Color(0xFF618764),
                  size: 30,
                ),
              ),
            ),
          ),

          // 2. Thông báo
          _buildFloatingNavItem(
            index: 1,
            icon: Icons.notifications,
            label: 'Thông báo',
          ),
          // 5. Cá nhân
          _buildFloatingNavItem(
            index: 3,
            icon: Icons.person_rounded,
            label: 'Cá nhân',
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
              color: isSelected ? Color(0xFF273338) : Color(0xFF6FCF97),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.bold,
                color: isSelected ? Color(0xFF273338) : Color(0xFF6FCF97),
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
