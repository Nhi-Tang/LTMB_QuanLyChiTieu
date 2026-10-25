import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../database/db_helper.dart';
import '../models/transaction_model.dart';
import '../models/pending_transaction_model.dart';
import 'budget_alert_service.dart';

class TransactionService extends ChangeNotifier {
  static final TransactionService instance = TransactionService._init();
  TransactionService._init();

  factory TransactionService() => instance;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  String _currentLedgerId = 'default_ledger';

  String get currentLedgerId => _currentLedgerId;

  Future<void> initActiveLedger(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('mousey_active_ledger_$uid');

    if (savedId != null && savedId.isNotEmpty) {
      final exists = await _dbHelper.getLedgerById(savedId, uid: uid);
      if (exists != null) {
        _currentLedgerId = savedId;
        notifyListeners();
        return;
      }
    }

    // Fallback sang sổ mặc định
    final defaultId = 'default_$uid';
    final defaultLedger = await _dbHelper.getLedgerById(defaultId, uid: uid);
    if (defaultLedger != null) {
      _currentLedgerId = defaultId;
    } else {
      _currentLedgerId = await _dbHelper.insertLedger(
        id: defaultId,
        uid: uid,
        name: 'Sổ cá nhân 1',
        isDefault: true,
      );
    }

    await prefs.setString('mousey_active_ledger_$uid', _currentLedgerId);
    notifyListeners();
  }

  Future<void> setCurrentLedgerId(String ledgerId, {String? uid}) async {
    if (_currentLedgerId != ledgerId) {
      _currentLedgerId = ledgerId;
      if (uid != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('mousey_active_ledger_$uid', ledgerId);
      }
      notifyListeners();
    }
  }

  Future<void> confirmPending(String pendingId, {String? categoryId, String? kindOverride, bool? isExpenseOverride}) async {
    final dbHelper = DatabaseHelper.instance;
    final pendings = await dbHelper.getPendingTransactions(uid: dbHelper.currentUid);
    
    // Tìm giao dịch nháp
    PendingTransactionModel? item;
    for (var p in pendings) {
      if (p.id == pendingId) {
        item = p;
        break;
      }
    }
    if (item == null) return;

    final typeOverride = kindOverride ?? item.type;
    
    bool isExpense;
    String finalKind;

    if (typeOverride == 'expense') {
      isExpense = true;
      finalKind = 'expense';
    } else if (typeOverride == 'transfer_out') {
      isExpense = true;
      finalKind = 'transfer_out';
    } else if (typeOverride == 'transfer_internal') {
      isExpense = item.type == 'expense' || item.type == 'transfer_out';
      finalKind = 'transfer_internal';
    } else if (typeOverride == 'income') {
      isExpense = false;
      finalKind = 'income';
    } else if (typeOverride == 'received') {
      isExpense = false;
      finalKind = 'received';
    } else {
      isExpense = isExpenseOverride ?? (item.type == 'expense' || item.type == 'transfer_out');
      finalKind = isExpense ? 'expense' : 'income';
    }

    if (isExpenseOverride != null) {
      isExpense = isExpenseOverride;
      if (isExpense && finalKind != 'transfer_internal' && finalKind != 'transfer_out') {
        finalKind = 'expense';
      } else if (!isExpense && finalKind != 'income' && finalKind != 'received') {
        finalKind = 'income';
      }
    }

    final defaultCat = isExpense ? 'Khác' : 'Khác';
    final category = categoryId ?? item.suggestedCategoryId ?? defaultCat;
    if (category == 'Chuyển tiền') {
      finalKind = 'transfer_internal';
    }

    final realTx = TransactionItem(
      id: const Uuid().v4(),
      title: item.description,
      category: category,
      amount: item.amount.toDouble(),
      isExpense: isExpense,
      date: DateTime.tryParse(item.occurredAt) ?? DateTime.now(),
      uid: item.uid,
      ledgerId: _currentLedgerId, // Đảm bảo lấy ID sổ lưu bền đang active
      kind: finalKind,
    );

    // Mở đúng DB và ghi giao dịch
    await dbHelper.insertTransaction(realTx, uid: item.uid, ledgerId: _currentLedgerId);
    await BudgetAlertService.instance.checkAndAlertForDate(realTx.date, uid: item.uid);
    
    // Cập nhật trạng thái bản nháp
    await dbHelper.updatePendingTransactionStatus(
      item.id,
      'confirmed',
      categoryId: category,
    );

    notifyUpdated();
  }

  Future<List<TransactionItem>> getTransactions({String? uid, String? ledgerId}) async {
    return await _dbHelper.getTransactions(uid: uid, ledgerId: ledgerId ?? _currentLedgerId);
  }

  Future<int> addTransaction(TransactionItem item, {String? uid, String? ledgerId}) async {
    final res = await _dbHelper.insertTransaction(item, uid: uid, ledgerId: ledgerId ?? _currentLedgerId);
    await BudgetAlertService.instance.checkAndAlertForDate(item.date, uid: uid);
    notifyListeners();
    return res;
  }

  /// Cập nhật giao dịch đã có (insertTransaction ghi đè theo id) và kiểm tra lại ngân sách
  Future<int> updateTransaction(TransactionItem item, {String? uid}) async {
    final res = await _dbHelper.insertTransaction(item, uid: uid);
    await BudgetAlertService.instance.checkAndAlertForDate(item.date, uid: uid);
    notifyListeners();
    return res;
  }

  /// [date] là ngày của giao dịch bị xóa, dùng để kiểm tra lại ngân sách đúng tháng
  Future<int> removeTransaction(String id, {String? uid, DateTime? date}) async {
    final res = await _dbHelper.deleteTransaction(id, uid: uid);
    await BudgetAlertService.instance.checkAndAlertForDate(date ?? DateTime.now(), uid: uid);
    notifyListeners();
    return res;
  }

  Future<int> clear({String? uid}) async {
    final res = await _dbHelper.clearTransactions(uid: uid);
    notifyListeners();
    return res;
  }

  void notifyUpdated() {
    notifyListeners();
  }
}
