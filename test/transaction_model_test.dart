import 'package:flutter_test/flutter_test.dart';
import 'package:quanlychitieu/backend/models/transaction_model.dart';

Map<String, dynamic> _row({required int isExpense, String? kind, String category = 'Lương'}) => {
      'id': '1',
      'title': category,
      'category': category,
      'amount': 1000,
      'is_expense': isExpense,
      'date': '2026-10-01T00:00:00.000',
      'kind': kind,
    };

void main() {
  test('kind ngược với is_expense thì suy lại từ is_expense', () {
    // Giao dịch đã đổi sang thu nhập ở máy khác nhưng kind cũ vẫn là expense
    expect(TransactionItem.fromMap(_row(isExpense: 0, kind: 'expense')).kind, 'income');
    expect(TransactionItem.fromMap(_row(isExpense: 1, kind: 'income', category: 'Ăn uống')).kind, 'expense');
  });

  test('giữ nguyên kind hợp lệ, kể cả chuyển tiền', () {
    expect(TransactionItem.fromMap(_row(isExpense: 0, kind: 'received')).kind, 'received');
    expect(TransactionItem.fromMap(_row(isExpense: 1, kind: 'transfer_internal', category: 'Chuyển tiền')).kind,
        'transfer_internal');
    expect(TransactionItem.fromMap(_row(isExpense: 1, kind: 'transfer_out', category: 'Chuyển tiền')).kind,
        'transfer_out');
  });

  test('thiếu kind thì suy từ is_expense', () {
    expect(TransactionItem.fromMap(_row(isExpense: 0)).kind, 'income');
    expect(TransactionItem.fromMap(_row(isExpense: 1, category: 'Ăn uống')).kind, 'expense');
  });
}
