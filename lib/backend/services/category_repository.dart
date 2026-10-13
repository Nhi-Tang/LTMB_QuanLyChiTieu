import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';
import '../models/category_model.dart';

class CategoryRepository {
  static final CategoryRepository instance = CategoryRepository._init();

  CategoryRepository._init();

  /// Lấy danh sách danh mục cho một sổ (ledger) và loại (expense/income), kèm trạng thái liên kết (isLinked)
  Future<List<CategoryModel>> getCategoriesForLedger(String ledgerId, String type) async {
    final db = await DatabaseHelper.instance.database;

    // Lấy tất cả danh mục chưa lưu trữ thuộc loại type
    final categoriesResult = await db.query(
      'categories',
      where: 'type = ? AND isArchived = 0',
      whereArgs: [type],
      orderBy: 'sortOrder ASC, id ASC',
    );

    // Lấy danh sách categoryId đã liên kết với ledgerId này
    final linkedResult = await db.query(
      'ledger_categories',
      where: 'ledgerId = ?',
      whereArgs: [ledgerId],
    );
    final linkedIds = linkedResult.map((row) => row['categoryId'] as int).toSet();

    return categoriesResult.map((map) {
      final id = map['id'] as int;
      final isLinked = linkedIds.contains(id);
      return CategoryModel.fromMap(map, isLinked: isLinked);
    }).toList();
  }

  /// Lấy tất cả danh mục theo loại (bao gồm cả đã lưu trữ hoặc chưa liên kết)
  Future<List<CategoryModel>> getAllCategories(String type) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'sortOrder ASC, id ASC',
    );
    return result.map((map) => CategoryModel.fromMap(map, isLinked: true)).toList();
  }

  /// Thêm danh mục mới và tự động liên kết với ledgerId hiện tại
  Future<int> addCategory(CategoryModel category, String ledgerId) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();

    // Lấy max sortOrder hiện tại
    final maxOrderResult = await db.rawQuery(
      'SELECT MAX(sortOrder) as maxOrder FROM categories WHERE type = ?',
      [category.type],
    );
    int nextOrder = 0;
    if (maxOrderResult.isNotEmpty && maxOrderResult.first['maxOrder'] != null) {
      nextOrder = (maxOrderResult.first['maxOrder'] as int) + 1;
    }

    final categoryId = await db.insert('categories', {
      'name': category.name,
      'iconKey': category.iconKey,
      'type': category.type,
      'sortOrder': nextOrder,
      'isDefault': category.isDefault ? 1 : 0,
      'isArchived': category.isArchived ? 1 : 0,
      'createdAt': now,
      'updatedAt': now,
    });

    // Liên kết với sổ hiện tại
    await db.insert('ledger_categories', {
      'ledgerId': ledgerId,
      'categoryId': categoryId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    return categoryId;
  }

  /// Cập nhật thông tin danh mục
  Future<int> updateCategory(CategoryModel category) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();
    return await db.update(
      'categories',
      {
        'name': category.name,
        'iconKey': category.iconKey,
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Xóa hoặc lưu trữ danh mục. Hỗ trợ chuyển đổi giao dịch sang danh mục khác nếu đang được sử dụng.
  Future<bool> deleteCategory(int categoryId, {int? transferToCategoryId, bool archiveInstead = false}) async {
    final db = await DatabaseHelper.instance.database;

    // Kiểm tra xem có phải danh mục mặc định không
    final catResult = await db.query('categories', where: 'id = ?', whereArgs: [categoryId]);
    if (catResult.isEmpty) return false;
    final category = CategoryModel.fromMap(catResult.first);

    if (category.isDefault) {
      throw Exception('Không thể xóa danh mục mặc định của hệ thống!');
    }

    if (archiveInstead) {
      await db.update('categories', {'isArchived': 1, 'updatedAt': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [categoryId]);
      return true;
    }

    // Kiểm tra xem có giao dịch nào đang dùng danh mục này không (theo tên danh mục trong bảng transactions)
    final txCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM transactions WHERE category = ?',
      [category.name],
    )) ?? 0;

    await db.transaction((txn) async {
      if (txCount > 0 && transferToCategoryId != null) {
        // Lấy tên danh mục đích để chuyển giao dịch sang
        final targetRes = await txn.query('categories', where: 'id = ?', whereArgs: [transferToCategoryId]);
        if (targetRes.isNotEmpty) {
          final targetName = targetRes.first['name'] as String;
          await txn.update(
            'transactions',
            {'category': targetName},
            where: 'category = ?',
            whereArgs: [category.name],
          );
        }
      }

      // Xóa liên kết trong ledger_categories
      await txn.delete('ledger_categories', where: 'categoryId = ?', whereArgs: [categoryId]);

      // Xóa danh mục
      await txn.delete('categories', where: 'id = ?', whereArgs: [categoryId]);
    });

    return true;
  }

  /// Lưu trữ hoặc bỏ lưu trữ danh mục
  Future<int> archiveCategory(int categoryId, bool isArchived) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'categories',
      {'isArchived': isArchived ? 1 : 0, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }

  /// Liên kết danh mục với sổ
  Future<void> linkCategory(String ledgerId, int categoryId) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'ledger_categories',
      {'ledgerId': ledgerId, 'categoryId': categoryId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Hủy liên kết danh mục với sổ
  Future<void> unlinkCategory(String ledgerId, int categoryId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'ledger_categories',
      where: 'ledgerId = ? AND categoryId = ?',
      whereArgs: [ledgerId, categoryId],
    );
  }

  /// Sắp xếp lại thứ tự danh mục
  Future<void> reorderCategories(List<int> categoryIds) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      for (int i = 0; i < categoryIds.length; i++) {
        await txn.update(
          'categories',
          {'sortOrder': i},
          where: 'id = ?',
          whereArgs: [categoryIds[i]],
        );
      }
    });
  }
}
