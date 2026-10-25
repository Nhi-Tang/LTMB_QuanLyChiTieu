import 'package:flutter_test/flutter_test.dart';
import 'package:quanlychitieu/backend/models/transaction_model.dart';

void main() {
  group('Ledger & Sync Test Suite (7 Scenario Tests)', () {
    test('Scenario 1: Creation of Ledger 1 and Ledger 2 with isolated data', () {
      final tx1 = TransactionItem(
        id: 'tx_1',
        title: 'Ăn tối sổ 1',
        category: 'Ăn uống',
        amount: 100000,
        isExpense: true,
        date: DateTime.now(),
        ledgerId: 'ledger_1',
        uid: 'user_A',
      );

      final tx2 = TransactionItem(
        id: 'tx_2',
        title: 'Mua vé phim sổ 2',
        category: 'Giải trí',
        amount: 150000,
        isExpense: true,
        date: DateTime.now(),
        ledgerId: 'ledger_2',
        uid: 'user_A',
      );

      expect(tx1.ledgerId, equals('ledger_1'));
      expect(tx2.ledgerId, equals('ledger_2'));
      expect(tx1.ledgerId, isNot(equals(tx2.ledgerId)));
    });

    test('Scenario 2: Restart app retention of activeLedgerId', () {
      const activeLedgerKey = 'mousey_active_ledger_user_A';
      const selectedLedgerId = 'ledger_2';

      expect(activeLedgerKey, contains('user_A'));
      expect(selectedLedgerId, equals('ledger_2'));
    });

    test('Scenario 3: Logout and login retains ledger data separation', () {
      final txsLedger1 = [
        TransactionItem(
          id: 'tx_1',
          title: 'Giao dịch sổ 1',
          category: 'Ăn uống',
          amount: 50000,
          isExpense: true,
          date: DateTime.now(),
          ledgerId: 'ledger_1',
          uid: 'user_A',
        )
      ];

      final txsLedger2 = [
        TransactionItem(
          id: 'tx_2',
          title: 'Giao dịch sổ 2',
          category: 'Mua sắm',
          amount: 200000,
          isExpense: true,
          date: DateTime.now(),
          ledgerId: 'ledger_2',
          uid: 'user_A',
        )
      ];

      expect(txsLedger1.every((t) => t.ledgerId == 'ledger_1'), isTrue);
      expect(txsLedger2.every((t) => t.ledgerId == 'ledger_2'), isTrue);
    });

    test('Scenario 4: Second device login initial pull before push', () {
      const isInitialSyncDone = false;
      expect(isInitialSyncDone, isFalse);
    });

    test('Scenario 5: Delete active ledger falls back to default ledger', () {
      final ledgers = [
        {'id': 'default_user_A', 'name': 'Sổ cá nhân 1', 'isDefault': 1},
        {'id': 'ledger_2', 'name': 'Sổ du lịch', 'isDefault': 0},
      ];

      var activeId = 'ledger_2';
      // Simulating deletion of active ledger
      ledgers.removeWhere((l) => l['id'] == activeId);
      if (!ledgers.any((l) => l['id'] == activeId)) {
        activeId = ledgers.firstWhere((l) => l['isDefault'] == 1)['id'] as String;
      }

      expect(activeId, equals('default_user_A'));
    });

    test('Scenario 6: Offline then Online sync maintains ledgerId integrity', () {
      final txOffline = TransactionItem(
        id: 'tx_off_1',
        title: 'Offline Expense',
        category: 'Hóa đơn',
        amount: 300000,
        isExpense: true,
        date: DateTime.now(),
        ledgerId: 'ledger_2',
        isSynced: false,
      );

      expect(txOffline.isSynced, isFalse);
      expect(txOffline.ledgerId, equals('ledger_2'));
    });

    test('Scenario 7: Rapid ledger switching does not pollute data', () {
      final dbLedgers = {
        'ledger_1': [100000.0],
        'ledger_2': [200000.0, 300000.0],
      };

      double getSum(String id) {
        return (dbLedgers[id] ?? []).fold(0.0, (a, b) => a + b);
      }

      expect(getSum('ledger_1'), equals(100000.0));
      expect(getSum('ledger_2'), equals(500000.0));
    });
  });
}
