import 'package:flutter/material.dart';
import '../../backend/models/transaction_model.dart';
import '../../backend/models/user_model.dart';
import '../../backend/services/auth_service.dart';
import '../../backend/services/bank_notification_listener_manager.dart';
import '../../backend/services/pro_service.dart';
import '../../backend/services/transaction_service.dart';
import '../../backend/services/totals_calculator.dart';
import '../../core/widgets/notebook_tab_bar.dart';
import '../theme/app_colors.dart';
import '../utils/app_translations.dart';
import '../widgets/app_alert_dialog.dart';
import '../widgets/notification/notification_permission_prompt.dart';
import '../widgets/transaction_sheet/new_transaction_sheet.dart';
import 'home_tab.dart';
import 'profile_tab.dart';
import 'receipt_camera_screen.dart';
import 'reports_tab.dart';
import 'savings_tab.dart';
import '../utils/app_language.dart';

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
  String _selectedAvatarKey = 'mousey';
  String get _lang => AppLanguage.instance.value;

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
    // Tài khoản PRO lần đầu vào app (hoặc vừa lên PRO): hỏi quyền thông báo
    ProService.instance.addListener(_askNotificationPermission);
    WidgetsBinding.instance.addPostFrameCallback((_) => _askNotificationPermission());
  }

  void _askNotificationPermission() {
    final uid = _currentUser.uid;
    if (!mounted || uid == null) return;
    NotificationPermissionPrompt.maybeAsk(context, uid: uid);
  }

  Future<void> _loadPreferences() async {
    await AppLanguage.instance.load(uid: _currentUser.uid);
  }

  @override
  void dispose() {
    _transactionService.removeListener(_loadTransactions);
    ProService.instance.removeListener(_askNotificationPermission);
    BankNotificationListenerManager.instance.stopListening();
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
        title: Text(context.t('Xác nhận đăng xuất')),
        content: Text(context.t('Bạn có chắc chắn muốn đăng xuất khỏi Mousey?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.t('Hủy'), style: TextStyle(color: AppColors.grey500)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBeige,
              foregroundColor: AppColors.onTeal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().signOut();
            },
            child: Text(context.t('Đăng xuất'), style: const TextStyle(color: AppColors.onTeal, fontWeight: FontWeight.bold)),
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

  Future<void> _openReceiptCamera() async {
    final saved = await ReceiptCameraScreen.open(
      context,
      onSave: (newItem) async {
        await _transactionService.addTransaction(newItem);
        _loadTransactions();
      },
    );
    if (!saved || !mounted) return;
    showAppAlertDialog(
      context: context,
      title: context.t('Thành công'),
      message: context.t('Đã lưu giao dịch mới thành công! 💸'),
      isSuccess: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = _lang;

    final navItems = [
      NotebookTabItemData(
        keyName: 'home',
        label: AppTranslations.tr(lang, 'home'),
        assetPath: 'assets/icon/tab_trang_chu.png',
      ),
      NotebookTabItemData(
        keyName: 'savings',
        label: AppTranslations.tr(lang, 'savings'),
        assetPath: 'assets/icon/tab_tiet_kiem.png',
      ),
      NotebookTabItemData(
        keyName: 'reports',
        label: AppTranslations.tr(lang, 'reports'),
        assetPath: 'assets/icon/tab_bao_cao.png',
      ),
      NotebookTabItemData(
        keyName: 'profile',
        label: AppTranslations.tr(lang, 'profile'),
        assetPath: 'assets/icon/tab_ca_nhan.png',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        // Giữ trạng thái từng tab bằng IndexedStack (4 tab)
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            HomeTab(
              currentUser: _currentUser,
              selectedAvatarKey: _selectedAvatarKey,
              selectedMonth: _selectedMonth,
              totalIncome: _totalIncome,
              totalExpense: _totalExpense,
              totalBalance: _totalBalance,
              transactions: _transactions,
              onLogout: () => _logout(context),
              onAddIncome: () => _showAddTransactionModal(defaultExpense: false),
              onAddExpense: () => _showAddTransactionModal(defaultExpense: true),
            ),
            SavingsTab(
              selectedAvatarKey: _selectedAvatarKey,
              userName: _currentUser.name,
            ),
            ReportsTab(
              transactions: _transactions,
            ),
            ProfileTab(
              currentUser: _currentUser,
              selectedAvatarKey: _selectedAvatarKey,
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
                AppLanguage.instance.change(newLanguage, uid: _currentUser.uid);
              },
              onLogout: () => _logout(context),
            ),
          ],
        ),
      ),
      // Nút (+) ghi giao dịch chỉ hiện ở Trang chủ, như cây bút kẹp vào sổ
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton(
              heroTag: 'home_add_tx_fab',
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: () => _showAddTransactionModal(defaultExpense: true),
              child: const Icon(Icons.edit_rounded, size: 24),
            )
          : null,
      bottomNavigationBar: NotebookTabBar(
        items: navItems,
        currentIndex: _currentTabIndex,
        onCenterTap: _openReceiptCamera,
        centerLabel: context.t('Quét hoá đơn'),
        onChanged: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
      ),
    );
  }
}
