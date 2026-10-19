import 'package:flutter_test/flutter_test.dart';
import 'package:quanlychitieu/backend/database/db_helper.dart';
import 'package:quanlychitieu/backend/models/budget_model.dart';
import 'package:quanlychitieu/backend/services/budget_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Budget CRUD Test Suite', () {
    test('Test inserting and retrieving a budget', () async {
      await DatabaseHelper.instance.database;

      final newBudget = BudgetModel(
        categoryId: 'Ăn uống',
        amountLimit: 2000000,
        month: '2026-10',
        isRecurring: false,
        ledgerId: 'default_ledger',
      );

      final budgetId = await BudgetService.instance.insertBudget(newBudget);
      expect(budgetId, isNotEmpty);

      final budgets = await BudgetService.instance.getBudgets('default_ledger', month: '2026-10');
      expect(budgets, isNotEmpty);
      expect(budgets.any((b) => b.categoryId == 'Ăn uống'), isTrue);
      expect(budgets.firstWhere((b) => b.categoryId == 'Ăn uống').amountLimit, equals(2000000));
    });
  });
}
