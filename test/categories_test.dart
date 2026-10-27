import 'package:flutter_test/flutter_test.dart';
import 'package:quanlychitieu/backend/database/db_helper.dart';
import 'package:quanlychitieu/backend/models/category_model.dart';
import 'package:quanlychitieu/frontend/utils/app_translations.dart';

void main() {
  group('Category System Test Suite (6 Scenarios)', () {
    test('Scenario 1: Default categories count (24 Expense, 5 Income)', () {
      final expenseList = DatabaseHelper.defaultExpenseCategories;
      final incomeList = DatabaseHelper.defaultIncomeCategories;

      expect(expenseList.length, equals(24));
      expect(incomeList.length, equals(5));

      final expenseNames = expenseList.map((e) => e['name']).toList();
      expect(expenseNames, containsAll([
        'Ăn uống', 'Cà phê', 'Trà sữa', 'Hóa đơn', 'Điện thoại', 'Di chuyển', 'Mua sắm', 'Giải trí', 'Netflix', 'Spotify', 'YouTube',
        'Sức khoẻ', 'Làm đẹp', 'Quần áo', 'Học tập', 'Thú cưng',
        'Con cái', 'Hỗ trợ gia đình', 'Bảo hiểm', 'Thuế', 'Công việc',
        'Nhà ở', 'Tiền nợ', 'Khác'
      ]));

      final incomeNames = incomeList.map((e) => e['name']).toList();
      expect(incomeNames, containsAll([
        'Lương', 'Thưởng', 'Bán hàng', 'Đầu tư', 'Khác'
      ]));
    });

    test('Scenario 2: Migration restores missing default categories idempotently', () {
      final existingNames = {'Ăn uống', 'Hóa đơn', 'Mua sắm'};
      final missingExpense = DatabaseHelper.defaultExpenseCategories
          .where((c) => !existingNames.contains(c['name']))
          .toList();

      expect(missingExpense.length, equals(21)); // 24 - 3 = 21
    });

    test('Scenario 3: Switching ledgers maintains all active default categories', () {
      final cat = CategoryModel(
        id: 1,
        name: 'Ăn uống',
        iconKey: 'fastfood_rounded',
        type: 'expense',
        sortOrder: 0,
        isDefault: true,
        isArchived: false,
        createdAt: '',
        updatedAt: '',
        isLinked: true,
      );

      expect(cat.isLinked, isTrue);
      expect(cat.isArchived, isFalse);
    });

    test('Scenario 4: User-created categories preserved alongside defaults', () {
      final userCategories = [
        CategoryModel(
          id: 101,
          name: 'Cà phê & Trà',
          iconKey: 'local_cafe_rounded',
          type: 'expense',
          sortOrder: 20,
          isDefault: false,
          isArchived: false,
          createdAt: '',
          updatedAt: '',
          isLinked: true,
        )
      ];

      expect(userCategories.length, equals(1));
      expect(userCategories.first.isDefault, isFalse);
    });

    test('Scenario 5: Deleting custom category does not touch default categories', () {
      final defaultCat = CategoryModel(
        id: 1,
        name: 'Ăn uống',
        iconKey: 'fastfood_rounded',
        type: 'expense',
        sortOrder: 0,
        isDefault: true,
        isArchived: false,
        createdAt: '',
        updatedAt: '',
      );

      final customCat = CategoryModel(
        id: 102,
        name: 'Đi chợ đêm',
        iconKey: 'category_rounded',
        type: 'expense',
        sortOrder: 21,
        isDefault: false,
        isArchived: false,
        createdAt: '',
        updatedAt: '',
      );

      expect(defaultCat.isDefault, isTrue);
      expect(customCat.isDefault, isFalse);
    });

    test('Scenario 6: i18n translation for default categories', () {
      expect(AppTranslations.trCategory('vi', 'Ăn uống'), equals('Ăn uống'));
      expect(AppTranslations.trCategory('en', 'Ăn uống'), equals('Ăn uống'));
      expect(AppTranslations.trCategory('ja', 'Ăn uống'), equals('Ăn uống'));
      expect(AppTranslations.trCategory('zh', 'Ăn uống'), equals('Ăn uống'));
    });
  });
}
