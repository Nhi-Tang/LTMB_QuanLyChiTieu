import 'package:flutter_test/flutter_test.dart';
import 'package:quanlychitieu/backend/models/transaction_model.dart';
import 'package:quanlychitieu/frontend/utils/report_utils.dart';

TransactionItem _tx(DateTime date, double amount) => TransactionItem(
      id: '$date$amount',
      title: '',
      category: 'Ăn uống',
      amount: amount,
      isExpense: true,
      date: date,
    );

void main() {
  final now = DateTime(2026, 3, 15);

  test('bộ chọn thời gian lọc đúng tháng', () {
    expect(ReportUtils.inTimeRange('this_month', DateTime(2026, 3, 1), now), isTrue);
    expect(ReportUtils.inTimeRange('this_month', DateTime(2026, 2, 28), now), isFalse);
    expect(ReportUtils.inTimeRange('last_month', DateTime(2026, 2, 10), now), isTrue);
    expect(ReportUtils.inTimeRange('last_3_months', DateTime(2026, 1, 1), now), isTrue);
    expect(ReportUtils.inTimeRange('last_3_months', DateTime(2025, 12, 31), now), isFalse);
    expect(ReportUtils.inTimeRange('this_year', DateTime(2025, 12, 31), now), isFalse);
    expect(ReportUtils.inTimeRange('all_time', DateTime(2000, 1, 1), now), isTrue);
  });

  test('tháng trước của tháng 1 là tháng 12 năm trước', () {
    expect(ReportUtils.inTimeRange('last_month', DateTime(2025, 12, 5), DateTime(2026, 1, 10)), isTrue);
  });

  test('số cột bằng số tháng đã chọn, tháng hiện tại cuối cùng', () {
    for (final n in [3, 6, 12, 24]) {
      final months = ReportUtils.recentMonths(n, now);
      expect(months.length, n);
      expect(months.last, DateTime(2026, 3, 1));
    }
    expect(ReportUtils.recentMonths(12, now).first, DateTime(2025, 4, 1));
  });

  test('cộng tiền theo từng tháng, bỏ giao dịch ngoài khoảng', () {
    final months = ReportUtils.recentMonths(3, now);
    final totals = ReportUtils.monthlyTotals([
      _tx(DateTime(2026, 3, 2), 100),
      _tx(DateTime(2026, 3, 20), 50),
      _tx(DateTime(2026, 1, 5), 30),
      _tx(DateTime(2025, 12, 5), 999),
    ], months);
    expect(totals, [30, 0, 150]);
  });
}
