import '../../backend/models/transaction_model.dart';

/// Các phép tính dùng chung cho tab Báo cáo.
class ReportUtils {
  /// Ngày [date] có nằm trong khoảng thời gian [range] (khoá của bộ chọn thời gian) tính từ [now] không.
  static bool inTimeRange(String range, DateTime date, DateTime now) {
    switch (range) {
      case 'this_month':
        return date.year == now.year && date.month == now.month;
      case 'last_month':
        final last = DateTime(now.year, now.month - 1, 1);
        return date.year == last.year && date.month == last.month;
      case 'last_3_months':
        // Tháng này và 2 tháng trước
        return !date.isBefore(DateTime(now.year, now.month - 2, 1)) &&
            date.isBefore(DateTime(now.year, now.month + 1, 1));
      case 'this_year':
        return date.year == now.year;
      case 'all_time':
      default:
        return true;
    }
  }

  /// Ngày đầu của [count] tháng gần nhất, cũ nhất trước, tháng hiện tại cuối cùng.
  static List<DateTime> recentMonths(int count, DateTime now) {
    return [
      for (int i = count - 1; i >= 0; i--) DateTime(now.year, now.month - i, 1),
    ];
  }

  /// Tổng tiền từng tháng trong [months].
  static List<double> monthlyTotals(List<TransactionItem> transactions, List<DateTime> months) {
    final totals = List<double>.filled(months.length, 0.0);
    for (final t in transactions) {
      for (int i = 0; i < months.length; i++) {
        if (t.date.year == months[i].year && t.date.month == months[i].month) {
          totals[i] += t.amount;
          break;
        }
      }
    }
    return totals;
  }
}
