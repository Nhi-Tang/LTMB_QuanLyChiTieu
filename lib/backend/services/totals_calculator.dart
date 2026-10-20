import '../models/transaction_model.dart';

class TotalsCalculator {
  static double calculateTotalIncome(List<TransactionItem> transactions) {
    double sum = 0.0;
    for (var t in transactions) {
      if (!t.isDeleted && t.kind == 'income') {
        sum += t.amount;
      }
    }
    return sum;
  }

  static double calculateTotalExpense(List<TransactionItem> transactions) {
    double sum = 0.0;
    for (var t in transactions) {
      if (!t.isDeleted && (t.kind == 'expense' || t.kind == 'transfer_out')) {
        sum += t.amount;
      }
    }
    return sum;
  }

  static double calculateBalance(List<TransactionItem> transactions) {
    double sum = 0.0;
    for (var t in transactions) {
      if (t.isDeleted) continue;
      if (t.kind == 'income' || t.kind == 'received') {
        sum += t.amount;
      } else if (t.kind == 'expense' || t.kind == 'transfer_out') {
        sum -= t.amount;
      } else if (t.kind == 'transfer_internal') {
        // Chuyển khoản nội bộ đơn lẻ vẫn làm thay đổi số dư thực tế của tài khoản (trừ đi nếu tiền ra, cộng vào nếu tiền vào)
        // nhưng KHÔNG tính vào tổng Thu nhập hay Chi tiêu tháng.
        if (t.isExpense) {
          sum -= t.amount;
        } else {
          sum += t.amount;
        }
      }
    }
    return sum;
  }
}
