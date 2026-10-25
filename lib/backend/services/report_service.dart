import '../models/transaction_model.dart';

class ReportService {
  double calculateTotalIncome(List<TransactionItem> transactions) {
    double total = 0;
    for (var tx in transactions) {
      if (!tx.isExpense) {
        total += tx.amount;
      }
    }
    return total;
  }

  double calculateTotalExpense(List<TransactionItem> transactions) {
    double total = 0;
    for (var tx in transactions) {
      if (tx.isExpense) {
        total += tx.amount;
      }
    }
    return total;
  }

  double calculateTotalBalance(List<TransactionItem> transactions) {
    return calculateTotalIncome(transactions) - calculateTotalExpense(transactions);
  }

  Map<String, double> getCategoryBreakdown(List<TransactionItem> transactions, {required bool isExpense}) {
    final Map<String, double> breakdown = {};
    for (var tx in transactions) {
      if (tx.isExpense == isExpense) {
        breakdown[tx.category] = (breakdown[tx.category] ?? 0.0) + tx.amount;
      }
    }
    return breakdown;
  }
}
