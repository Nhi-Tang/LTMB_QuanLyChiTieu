import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../backend/models/transaction_model.dart';
import '../../backend/models/user_model.dart';
import '../../backend/services/auth_service.dart';
import '../../backend/services/bank_notification_listener_manager.dart';
import '../../backend/services/transaction_service.dart';
import '../../backend/services/totals_calculator.dart';
import '../../core/widgets/notch_tab_bar.dart';
import '../theme/app_colors.dart';
import '../utils/app_translations.dart';
import '../widgets/transaction_sheet/new_transaction_sheet.dart';
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

  // Transactions list
  final List<TransactionItem> _transactions = [];
  final TransactionService _transactionService = TransactionService();

  @override
  void initState() {
    super.initState();
    _currentUser = widget.currentUser;
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    _loadPreferences();
    _loadTransactions();
    _transactionService.addListener(_loadTransactions);
    BankNotificationListenerManager.instance.startListening(uid: _currentUser.uid);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('mousey_language_${_currentUser.uid}') ?? prefs.getString('mousey_language') ?? 'Tiếng Việt';
    if (mounted) {
      setState(() {
        _selectedLanguage = lang;
      });
    }
  }

  Future<void> _saveLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mousey_language_${_currentUser.uid}', lang);
    await prefs.setString('mousey_language', lang);
  }

  @override
  void dispose() {
    _transactionService.removeListener(_loadTransactions);
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    final txs = await _transactionService.getTransactions();
    if (!mounted) return;
    setState(() {
      _transactions.clear();
      _transactions.addAll(txs);
    });
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi Mousey?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBeige,
              foregroundColor: AppColors.darkBeige,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().signOut();
            },
            child: const Text('Đăng xuất', style: TextStyle(color: AppColors.darkBeige, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  List<TransactionItem> get _filteredTransactions {
    return _transactions.where((t) =>
      !t.isDeleted &&
      t.date.year == _selectedMonth.year &&
      t.date.month == _selectedMonth.month
    ).toList();
  }

  // Calculate totals using TotalsCalculator
  double get _totalIncome => TotalsCalculator.calculateTotalIncome(_filteredTransactions);
  double get _totalExpense => TotalsCalculator.calculateTotalExpense(_filteredTransactions);
  double get _totalBalance => TotalsCalculator.calculateBalance(_transactions);

  void _showAddTransactionModal({bool defaultExpense = true, TransactionItem? editingTransaction}) {
    NewTransactionSheet.show(
      context: context,
      defaultExpense: defaultExpense,
      editingTransaction: editingTransaction,
      onSave: (newItem) async {
        await _transactionService.addTransaction(newItem);
        _loadTransactions();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = _selectedLanguage;

    final navItems = [
      NotchTabItemData(
        keyName: 'home',
        label: AppTranslations.tr(lang, 'home'),
        assetPath: 'assets/icon/01 • Trang chủ.png',
      ),
      NotchTabItemData(
        keyName: 'savings',
        label: AppTranslations.tr(lang, 'savings'),
        assetPath: 'assets/icon/03 • Tiết kiệm.png',
      ),
      NotchTabItemData(
        keyName: 'reports',
        label: AppTranslations.tr(lang, 'reports'),
        assetPath: 'assets/icon/02 • Báo cáo.png',
      ),
      NotchTabItemData(
        keyName: 'profile',
        label: AppTranslations.tr(lang, 'profile'),
        assetPath: 'assets/icon/04 • Cá nhân.png',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Preserved tab state using IndexedStack (4 tabs)
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
                    _saveLanguage(newLanguage);
                  },
                  onLogout: () => _logout(context),
                ),
              ],
            ),

            // Separate FAB (+) for adding transaction
            Positioned(
              right: 20,
              bottom: 96,
              child: FloatingActionButton(
                heroTag: 'home_add_tx_fab',
                backgroundColor: AppColors.accentBeige,
                foregroundColor: Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                onPressed: () => _showAddTransactionModal(defaultExpense: true),
                child: const Icon(Icons.add_rounded, size: 28),
              ),
            ),

            // Sliding Curved Notched TabBar
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: NotchTabBar(
                items: navItems,
                currentIndex: _currentTabIndex,
                onChanged: (index) {
                  setState(() {
                    _currentTabIndex = index;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
