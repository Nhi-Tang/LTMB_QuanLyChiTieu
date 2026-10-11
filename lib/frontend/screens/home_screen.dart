import 'package:flutter/material.dart';
import '../../backend/models/transaction_model.dart';
import '../../backend/models/user_model.dart';
import '../utils/app_translations.dart';
import '../widgets/add_transaction_modal.dart';
import 'auth_screen.dart';
import 'home_tab.dart';
import 'profile_tab.dart';
import 'reports_tab.dart';
import 'savings_tab.dart';

class HomeScreen extends StatefulWidget {
  final UserModel currentUser;

  const HomeScreen({super.key, required this.currentUser});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;
  late DateTime _selectedMonth;
  late UserModel _currentUser;
  String _selectedAvatarKey = 'piggy';
  String _selectedLanguage = 'Tiếng Việt';

  // Theme Colors
  static const Color primaryBeige = Color(0xFFE5D3AF);
  static const Color darkBeige = Color(0xFF5D4222);

  // Initial transactions list
  final List<TransactionItem> _transactions = [];

  @override
  void initState() {
    super.initState();
    _currentUser = widget.currentUser;
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
              backgroundColor: const Color(0xFFE5D3AF),
              foregroundColor: const Color(0xFF5D4222),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Color(0xFF5D4222), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Calculate totals
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

  void _showAddTransactionModal({bool defaultExpense = true}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return AddTransactionModal(
          defaultExpense: defaultExpense,
          selectedLanguage: _selectedLanguage,
          onSave: (newItem) {
            setState(() {
              _transactions.insert(0, newItem);
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7EB),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            IndexedStack(
              index: _currentTabIndex,
              children: [
                HomeTab(
                  currentUser: _currentUser,
                  selectedAvatarKey: _selectedAvatarKey,
                  selectedLanguage: _selectedLanguage,
                  selectedMonth: _selectedMonth,
                  totalIncome: _totalIncome,
                  totalExpense: _totalExpense,
                  totalBalance: _totalBalance,
                  transactions: _transactions,
                  onLogout: () => _logout(context),
                  onSelectMonth: () async {
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
                  onAddIncome: () => _showAddTransactionModal(defaultExpense: false),
                  onAddExpense: () => _showAddTransactionModal(defaultExpense: true),
                ),
                SavingsTab(
                  selectedAvatarKey: _selectedAvatarKey,
                  userName: _currentUser.name,
                  selectedLanguage: _selectedLanguage,
                ),
                ReportsTab(
                  transactions: _transactions,
                  selectedLanguage: _selectedLanguage,
                ),
                ProfileTab(
                  currentUser: _currentUser,
                  selectedAvatarKey: _selectedAvatarKey,
                  selectedLanguage: _selectedLanguage,
                  onUserUpdated: (updatedUser) {
                    setState(() {
                      _currentUser = updatedUser;
                    });
                  },
                  onAvatarChanged: (newAvatarKey) {
                    setState(() {
                      _selectedAvatarKey = newAvatarKey;
                    });
                  },
                  onLanguageChanged: (newLanguage) {
                    setState(() {
                      _selectedLanguage = newLanguage;
                    });
                  },
                  onLogout: () => _logout(context),
                ),
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

  Widget _buildFloatingBottomTabBar() {
    final lang = _selectedLanguage;

    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: darkBeige,
        borderRadius: BorderRadius.circular(33),
        boxShadow: [
          BoxShadow(
            color: darkBeige.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFloatingNavItem(
            index: 0,
            icon: Icons.home_rounded,
            label: AppTranslations.tr(lang, 'home'),
          ),
          _buildFloatingNavItem(
            index: 1,
            icon: Icons.savings_rounded,
            label: AppTranslations.tr(lang, 'savings'),
          ),
          GestureDetector(
            onTap: () => _showAddTransactionModal(defaultExpense: true),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: primaryBeige,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.add_rounded,
                  color: darkBeige,
                  size: 30,
                ),
              ),
            ),
          ),
          _buildFloatingNavItem(
            index: 2,
            icon: Icons.pie_chart_rounded,
            label: AppTranslations.tr(lang, 'reports'),
          ),
          _buildFloatingNavItem(
            index: 3,
            icon: Icons.person_rounded,
            label: AppTranslations.tr(lang, 'profile'),
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
              color: isSelected ? primaryBeige : Colors.white60,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryBeige : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
