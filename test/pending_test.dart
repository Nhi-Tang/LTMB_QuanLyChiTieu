import 'package:flutter_test/flutter_test.dart';
import 'package:quanlychitieu/backend/database/db_helper.dart';
import 'package:quanlychitieu/backend/models/pending_transaction_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('Pending tx insert test', () async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('pending_transactions');

    final pendingItem = PendingTransactionModel(
      id: 'pending_1',
      type: 'expense',
      amount: 100000,
      bankName: 'VCB',
      description: 'Test bank',
      occurredAt: DateTime.now().toIso8601String(),
      fingerprint: 'fp_123',
      createdAt: DateTime.now().toIso8601String(),
    );

    try {
      final success = await DatabaseHelper.instance.insertPendingTransaction(pendingItem, uid: 'test_uid_123');
      print('Insert pending success: $success');
    } catch(e) {
      print('Insert error: $e');
    }

    try {
      final count = await DatabaseHelper.instance.getPendingTransactionsCount(uid: 'test_uid_123');
      print('Pending count: $count');
    } catch(e) {
      print('Count error: $e');
    }
  });
}
