import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';
import '../models/transaction_model.dart';

class TransactionService extends ChangeNotifier {
  static final TransactionService instance = TransactionService._init();
  TransactionService._init();

  factory TransactionService() => instance;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<TransactionItem>> getTransactions({String? uid}) async {
    return await _dbHelper.getTransactions(uid: uid);
  }

  Future<int> addTransaction(TransactionItem item, {String? uid}) async {
    final res = await _dbHelper.insertTransaction(item, uid: uid);
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
