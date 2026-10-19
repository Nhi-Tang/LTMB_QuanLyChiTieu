import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../models/transaction_model.dart';

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

  Future<List<TransactionItem>> getTransactions({String? uid, String? ledgerId}) async {
    return await _dbHelper.getTransactions(uid: uid, ledgerId: ledgerId ?? _currentLedgerId);
  }

  Future<int> addTransaction(TransactionItem item, {String? uid, String? ledgerId}) async {
    final res = await _dbHelper.insertTransaction(item, uid: uid, ledgerId: ledgerId ?? _currentLedgerId);
    notifyListeners();
    return res;
  }

  Future<int> removeTransaction(String id, {String? uid}) async {
    final res = await _dbHelper.deleteTransaction(id, uid: uid);
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
