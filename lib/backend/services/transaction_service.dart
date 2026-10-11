import '../models/transaction_model.dart';

class TransactionService {
  final List<TransactionItem> _transactions = [];

  List<TransactionItem> getTransactions() {
    return List.unmodifiable(_transactions);
  }

  void addTransaction(TransactionItem item) {
    _transactions.insert(0, item);
  }

  void removeTransaction(String id) {
    _transactions.removeWhere((tx) => tx.id == id);
  }

  void clear() {
    _transactions.clear();
  }
}
