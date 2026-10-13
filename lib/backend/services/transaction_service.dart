import '../database/db_helper.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<TransactionItem>> getTransactions() async {
    return await _dbHelper.getTransactions();
  }

  Future<int> addTransaction(TransactionItem item) async {
    return await _dbHelper.insertTransaction(item);
  }

  Future<int> removeTransaction(String id) async {
    return await _dbHelper.deleteTransaction(id);
  }

  Future<int> clear() async {
    return await _dbHelper.clearTransactions();
  }
}
