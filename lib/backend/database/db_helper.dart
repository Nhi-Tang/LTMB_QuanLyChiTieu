import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_notification_model.dart';
import '../models/budget_model.dart';
import '../models/pending_transaction_model.dart';
import '../models/savings_goal_model.dart';
import '../models/savings_transaction_model.dart';
import '../models/transaction_model.dart';
import '../models/user_change_model.dart';
import '../models/user_model.dart';
import '../services/sync_service.dart';
import '../services/transaction_service.dart';
import '../services/in_app_notification_service.dart';
import '../../core/utils/account_masker.dart';
import '../../core/utils/money_input_formatter.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const _uuid = Uuid();

  DatabaseHelper._init();

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('piggysmart.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final db = await openDatabase(
      path,
      version: 12,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );

    await db.rawUpdate("UPDATE users SET role = 'user' WHERE email != 'admin@piggysmart.com' AND role != 'admin'");

    return db;
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'user',
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        uid TEXT,
        photoUrl TEXT,
        provider TEXT DEFAULT 'password',
        plan TEXT DEFAULT 'free',
        proExpiredAt TEXT,
        lastLoginAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_change (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        user_email TEXT NOT NULL,
        changed_field TEXT NOT NULL,
        old_value TEXT,
        new_value TEXT,
        changed_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS savings_goals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL,
        deadline TEXT,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updatedAt INTEGER NOT NULL,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        isSynced INTEGER NOT NULL DEFAULT 0,
        uid TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS savings_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_id TEXT NOT NULL,
        amount REAL NOT NULL,
        is_deposit INTEGER NOT NULL DEFAULT 1,
        note TEXT,
        date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        is_expense INTEGER NOT NULL,
        date TEXT NOT NULL,
        updatedAt INTEGER NOT NULL,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        isSynced INTEGER NOT NULL DEFAULT 0,
        uid TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT,
        name TEXT NOT NULL,
        iconKey TEXT NOT NULL,
        type TEXT NOT NULL,
        sortOrder INTEGER NOT NULL,
        isDefault INTEGER NOT NULL DEFAULT 0,
        isArchived INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ledger_categories (
        ledgerId TEXT NOT NULL,
        categoryId INTEGER NOT NULL,
        uid TEXT,
        PRIMARY KEY(ledgerId, categoryId)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS budgets (
        id TEXT PRIMARY KEY,
        uid TEXT,
        categoryId TEXT,
        amountLimit INTEGER NOT NULL,
        month TEXT,
        isRecurring INTEGER NOT NULL DEFAULT 0,
        ledgerId TEXT,
        updatedAt INTEGER NOT NULL,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS budget_alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        budgetId TEXT NOT NULL,
        month TEXT NOT NULL,
        level TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_transactions (
        id TEXT PRIMARY KEY,
        uid TEXT,
        type TEXT NOT NULL,
        amount INTEGER NOT NULL,
        bankName TEXT NOT NULL,
        accountLast4 TEXT,
        description TEXT,
        occurredAt TEXT NOT NULL,
        fingerprint TEXT NOT NULL UNIQUE,
        status TEXT NOT NULL,
        suggestedCategoryId TEXT,
        suggestionConfidence TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_notifications (
        id TEXT PRIMARY KEY,
        uid TEXT,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        payload TEXT,
        createdAt TEXT NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0,
        dedupeKey TEXT UNIQUE
      )
    ''');

    await _seedDefaultCategories(db);

    final now = DateTime.now().toIso8601String();
    await db.insert('users', {
      'name': 'Quản trị viên (Admin)',
      'email': 'admin@piggysmart.com',
      'password': 'admin123',
      'role': 'admin',
      'isActive': 1,
      'createdAt': now,
      'provider': 'password',
      'plan': 'pro',
    });

    await db.insert('users', {
      'name': 'Nguyễn Văn A',
      'email': 'user@piggysmart.com',
      'password': 'user123',
      'role': 'user',
      'isActive': 1,
      'createdAt': now,
      'provider': 'password',
      'plan': 'free',
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.rawUpdate("UPDATE users SET role = 'user' WHERE email != 'admin@piggysmart.com' AND role != 'admin'");
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_change (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          user_email TEXT NOT NULL,
          changed_field TEXT NOT NULL,
          old_value TEXT,
          new_value TEXT,
          changed_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS savings_goals (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          target_amount REAL NOT NULL,
          current_amount REAL NOT NULL,
          deadline TEXT,
          icon TEXT NOT NULL,
          color TEXT NOT NULL,
          is_completed INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updatedAt INTEGER NOT NULL,
          isDeleted INTEGER NOT NULL DEFAULT 0,
          isSynced INTEGER NOT NULL DEFAULT 0,
          uid TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS savings_transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          goal_id TEXT NOT NULL,
          amount REAL NOT NULL,
          is_deposit INTEGER NOT NULL DEFAULT 1,
          note TEXT,
          date TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      try {
        await db.execute("ALTER TABLE users ADD COLUMN uid TEXT;");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE users ADD COLUMN photoUrl TEXT;");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE users ADD COLUMN provider TEXT DEFAULT 'password';");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE users ADD COLUMN plan TEXT DEFAULT 'free';");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE users ADD COLUMN proExpiredAt TEXT;");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE users ADD COLUMN lastLoginAt TEXT;");
      } catch (_) {}
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS transactions (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          is_expense INTEGER NOT NULL,
          date TEXT NOT NULL,
          updatedAt INTEGER NOT NULL,
          isDeleted INTEGER NOT NULL DEFAULT 0,
          isSynced INTEGER NOT NULL DEFAULT 0,
          uid TEXT
        )
      ''');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uid TEXT,
          name TEXT NOT NULL,
          iconKey TEXT NOT NULL,
          type TEXT NOT NULL,
          sortOrder INTEGER NOT NULL,
          isDefault INTEGER NOT NULL DEFAULT 0,
          isArchived INTEGER NOT NULL DEFAULT 0,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ledger_categories (
          ledgerId TEXT NOT NULL,
          categoryId INTEGER NOT NULL,
          uid TEXT,
          PRIMARY KEY(ledgerId, categoryId)
        )
      ''');
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM categories')) ?? 0;
      if (count == 0) {
        await _seedDefaultCategories(db);
      }
    }
    if (oldVersion < 7) {
      try {
        await db.execute("ALTER TABLE transactions ADD COLUMN updatedAt INTEGER DEFAULT 0;");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE transactions ADD COLUMN isDeleted INTEGER DEFAULT 0;");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE transactions ADD COLUMN isSynced INTEGER DEFAULT 0;");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE transactions ADD COLUMN uid TEXT;");
      } catch (_) {}

      final nowEpoch = DateTime.now().millisecondsSinceEpoch;
      await db.rawUpdate("UPDATE transactions SET updatedAt = ? WHERE updatedAt IS NULL OR updatedAt = 0", [nowEpoch]);
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budgets (
          id TEXT PRIMARY KEY,
          uid TEXT,
          categoryId TEXT,
          amountLimit INTEGER NOT NULL,
          month TEXT,
          isRecurring INTEGER NOT NULL DEFAULT 0,
          ledgerId TEXT,
          updatedAt INTEGER NOT NULL,
          isDeleted INTEGER NOT NULL DEFAULT 0,
          isSynced INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budget_alerts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          budgetId TEXT NOT NULL,
          month TEXT NOT NULL,
          level TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 9) {
      // Migration v9: Ensure uid columns and indexes for user data isolation
      try {
        await db.execute("ALTER TABLE budget_alerts ADD COLUMN uid TEXT;");
      } catch (_) {}
      try {
        await db.execute("CREATE INDEX IF NOT EXISTS idx_tx_uid ON transactions(uid);");
        await db.execute("CREATE INDEX IF NOT EXISTS idx_goals_uid ON savings_goals(uid);");
        await db.execute("CREATE INDEX IF NOT EXISTS idx_budgets_uid ON budgets(uid);");
        await db.execute("CREATE INDEX IF NOT EXISTS idx_categories_uid ON categories(uid);");
      } catch (_) {}
    }
    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pending_transactions (
          id TEXT PRIMARY KEY,
          uid TEXT,
          type TEXT NOT NULL,
          amount INTEGER NOT NULL,
          bankName TEXT NOT NULL,
          accountLast4 TEXT,
          description TEXT,
          occurredAt TEXT NOT NULL,
          fingerprint TEXT NOT NULL,
          status TEXT NOT NULL,
          suggestedCategoryId TEXT,
          suggestionConfidence TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
      try {
        await db.execute("CREATE INDEX IF NOT EXISTS idx_pending_uid ON pending_transactions(uid);");
        await db.execute("CREATE INDEX IF NOT EXISTS idx_pending_status ON pending_transactions(status);");
        await db.execute("CREATE INDEX IF NOT EXISTS idx_pending_fp ON pending_transactions(fingerprint);");
      } catch (_) {}
    }
    if (oldVersion < 11) {
      // Migration v11: Mask account numbers in pending_transactions.description
      try {
        final pendingRows = await db.query('pending_transactions');
        for (var row in pendingRows) {
          final id = row['id'] as String;
          final rawDesc = row['description'] as String? ?? '';
          if (rawDesc.isNotEmpty) {
            final maskedDesc = maskAccountNumbers(rawDesc);
            if (maskedDesc != rawDesc) {
              await db.update('pending_transactions', {'description': maskedDesc}, where: 'id = ?', whereArgs: [id]);
            }
          }
        }
      } catch (e) {
        debugPrint('Migration v11 pending_transactions error: $e');
      }
    }
    if (oldVersion < 12) {
      // Migration v12: Tạo bảng app_notifications cho Trung tâm thông báo
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_notifications (
          id TEXT PRIMARY KEY,
          uid TEXT,
          type TEXT NOT NULL,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          payload TEXT,
          createdAt TEXT NOT NULL,
          isRead INTEGER NOT NULL DEFAULT 0,
          dedupeKey TEXT UNIQUE
        )
      ''');
      try {
        await db.execute("CREATE INDEX IF NOT EXISTS idx_notifications_uid ON app_notifications(uid);");
        await db.execute("CREATE INDEX IF NOT EXISTS idx_notifications_isRead ON app_notifications(isRead);");
      } catch (_) {}
    }
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    final expenseCats = [
      {'name': 'Ăn uống', 'iconKey': 'fastfood_rounded'},
      {'name': 'Hóa đơn', 'iconKey': 'receipt_rounded'},
      {'name': 'Di chuyển', 'iconKey': 'directions_bus_rounded'},
      {'name': 'Mua sắm', 'iconKey': 'shopping_bag_rounded'},
      {'name': 'Giải trí', 'iconKey': 'sports_esports_rounded'},
      {'name': 'Sức khoẻ', 'iconKey': 'medical_services_rounded'},
      {'name': 'Làm đẹp', 'iconKey': 'content_cut_rounded'},
      {'name': 'Quần áo', 'iconKey': 'checkroom_rounded'},
      {'name': 'Học tập', 'iconKey': 'school_rounded'},
      {'name': 'Thú cưng', 'iconKey': 'pets_rounded'},
      {'name': 'Con cái', 'iconKey': 'child_care_rounded'},
      {'name': 'Hỗ trợ gia đình', 'iconKey': 'family_restroom_rounded'},
      {'name': 'Bảo hiểm', 'iconKey': 'security_rounded'},
      {'name': 'Thuế', 'iconKey': 'account_balance_rounded'},
      {'name': 'Công việc', 'iconKey': 'work_rounded'},
      {'name': 'Nhà ở', 'iconKey': 'home_rounded'},
      {'name': 'Tiền nợ', 'iconKey': 'money_off_rounded'},
      {'name': 'Khác', 'iconKey': 'category_rounded'},
    ];

    final incomeCats = [
      {'name': 'Lương', 'iconKey': 'account_balance_wallet_rounded'},
      {'name': 'Thưởng', 'iconKey': 'card_giftcard_rounded'},
      {'name': 'Bán hàng', 'iconKey': 'storefront_rounded'},
      {'name': 'Đầu tư', 'iconKey': 'trending_up_rounded'},
      {'name': 'Khác', 'iconKey': 'category_rounded'},
    ];

    const defaultLedgerId = 'default_ledger';
    const alternativeLedgerId = 'Sổ cá nhân 1';

    int sortOrder = 0;
    for (var cat in expenseCats) {
      final categoryId = await db.insert('categories', {
        'name': cat['name'],
        'iconKey': cat['iconKey'],
        'type': 'expense',
        'sortOrder': sortOrder++,
        'isDefault': 1,
        'isArchived': 0,
        'createdAt': now,
        'updatedAt': now,
      });
      await db.insert('ledger_categories', {
        'ledgerId': defaultLedgerId,
        'categoryId': categoryId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('ledger_categories', {
        'ledgerId': alternativeLedgerId,
        'categoryId': categoryId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    sortOrder = 0;
    for (var cat in incomeCats) {
      final categoryId = await db.insert('categories', {
        'name': cat['name'],
        'iconKey': cat['iconKey'],
        'type': 'income',
        'sortOrder': sortOrder++,
        'isDefault': 1,
        'isArchived': 0,
        'createdAt': now,
        'updatedAt': now,
      });
      await db.insert('ledger_categories', {
        'ledgerId': defaultLedgerId,
        'categoryId': categoryId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('ledger_categories', {
        'ledgerId': alternativeLedgerId,
        'categoryId': categoryId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // --- TRANSACTIONS DAO METHODS (ISOLATED BY UID) ---

  Future<List<TransactionItem>> getTransactions({String? uid}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;
    debugPrint('🗄️ [DatabaseHelper] Executing getTransactions for uid: $targetUid');
    
    // Đảm bảo lọc chính xác theo uid của người dùng hiện tại
    final result = await db.query(
      'transactions',
      where: 'isDeleted = 0 AND (uid = ? OR uid IS NULL)',
      whereArgs: [targetUid],
      orderBy: 'date DESC',
    );
    return result.map((map) => TransactionItem.fromMap(map)).toList();
  }

  Future<int> insertTransaction(TransactionItem item, {String? uid}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;
    final nowEpoch = DateTime.now().millisecondsSinceEpoch;
    final itemToSave = item.copyWith(
      id: item.id.isNotEmpty ? item.id : _uuid.v4(),
      uid: targetUid,
      updatedAt: nowEpoch,
      isSynced: false,
    );
    final res = await db.insert('transactions', itemToSave.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    SyncService.instance.syncAll();
    TransactionService.instance.notifyUpdated();
    return res;
  }

  Future<int> deleteTransaction(String id, {String? uid}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;
    final nowEpoch = DateTime.now().millisecondsSinceEpoch;
    final res = await db.update(
      'transactions',
      {
        'isDeleted': 1,
        'updatedAt': nowEpoch,
        'isSynced': 0,
      },
      where: 'id = ? AND (uid = ? OR uid IS NULL)',
      whereArgs: [id, targetUid],
    );
    SyncService.instance.syncAll();
    TransactionService.instance.notifyUpdated();
    return res;
  }

  Future<int> clearTransactions({String? uid}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;
    final nowEpoch = DateTime.now().millisecondsSinceEpoch;
    final res = await db.update(
      'transactions',
      {
        'isDeleted': 1,
        'updatedAt': nowEpoch,
        'isSynced': 0,
      },
      where: 'uid = ? OR uid IS NULL',
      whereArgs: [targetUid],
    );
    SyncService.instance.syncAll();
    return res;
  }

  // --- USER AUTHENTICATION & REGISTRATION ---

  Future<int> registerUser(UserModel user) async {
    final db = await instance.database;
    try {
      final userToInsert = user.copyWith(role: user.email == 'admin@piggysmart.com' ? 'admin' : 'user');
      return await db.insert('users', userToInsert.toMap());
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        throw Exception('Email hoặc số điện thoại này đã được đăng ký!');
      }
      rethrow;
    }
  }

  Future<UserModel?> loginUser(String emailOrPhone, String password) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [emailOrPhone.trim().toLowerCase(), password],
    );

    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  Future<bool> isEmailRegistered(String email) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
    return result.isNotEmpty;
  }

  Future<int> updatePasswordByEmail(String email, String newPassword) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {'password': newPassword},
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
  }

  // --- SOCIAL LOGIN & USER DAO METHODS ---

  Future<int> insertOrUpdateUser(UserModel user) async {
    final db = await instance.database;
    return await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getCurrentUser(String uid) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [uid],
    );
    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  Future<int> clearUserSession(String uid) async {
    final db = await instance.database;
    return await db.delete('users', where: 'uid = ?', whereArgs: [uid]);
  }

  // --- ADMIN ACCOUNT MANAGEMENT CRUD ---

  Future<List<UserModel>> getAllUsers() async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      orderBy: 'id DESC',
    );
    return result.map((map) => UserModel.fromMap(map)).toList();
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'name LIKE ? OR email LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'id DESC',
    );
    return result.map((map) => UserModel.fromMap(map)).toList();
  }

  Future<int> updateUser(UserModel user) async {
    final db = await instance.database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> toggleUserActiveStatus(int id, bool currentStatus) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {'isActive': currentStatus ? 0 : 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await instance.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, int>> getUserStats() async {
    final db = await instance.database;
    final allUsers = await db.query('users');

    int total = allUsers.length;
    int admins = 0;
    int activeUsers = 0;

    for (var u in allUsers) {
      if (u['role'] == 'admin') admins++;
      if ((u['isActive'] as int? ?? 1) == 1) activeUsers++;
    }

    return {
      'total': total,
      'admins': admins,
      'active': activeUsers,
    };
  }

  // --- USER CHANGE AUDIT LOG METHODS ---

  Future<int> logUserChange({
    required int userId,
    required String userEmail,
    required String changedField,
    required String oldValue,
    required String newValue,
  }) async {
    final db = await instance.database;
    final change = UserChangeModel(
      userId: userId,
      userEmail: userEmail,
      changedField: changedField,
      oldValue: oldValue,
      newValue: newValue,
      changedAt: DateTime.now().toIso8601String(),
    );
    return await db.insert('user_change', change.toMap());
  }

  Future<List<UserChangeModel>> getUserChanges(int userId) async {
    final db = await instance.database;
    final result = await db.query(
      'user_change',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return result.map((map) => UserChangeModel.fromMap(map)).toList();
  }

  Future<List<UserChangeModel>> getAllUserChanges() async {
    final db = await instance.database;
    final result = await db.query(
      'user_change',
      orderBy: 'id DESC',
    );
    return result.map((map) => UserChangeModel.fromMap(map)).toList();
  }

  // --- SAVINGS GOALS & TRANSACTIONS CRUD (ISOLATED BY UID) ---

  Future<List<SavingsGoalModel>> getSavingsGoals({String? uid}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;
    debugPrint('🗄️ [DatabaseHelper] Executing getSavingsGoals for uid: $targetUid');
    final result = await db.query(
      'savings_goals',
      where: 'isDeleted = 0 AND (uid = ? OR uid IS NULL)',
      whereArgs: [targetUid],
      orderBy: 'updatedAt DESC',
    );
    return result.map((map) => SavingsGoalModel.fromMap(map)).toList();
  }

  Future<String> insertSavingsGoal(SavingsGoalModel goal, {String? uid}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;
    final nowEpoch = DateTime.now().millisecondsSinceEpoch;
    final goalId = goal.id != null && goal.id!.isNotEmpty ? goal.id! : _uuid.v4();
    final goalToSave = goal.copyWith(
      id: goalId,
      uid: targetUid,
      updatedAt: nowEpoch,
      isSynced: false,
    );
    await db.insert('savings_goals', goalToSave.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    SyncService.instance.syncAll();
    return goalId;
  }

  Future<int> updateSavingsGoal(SavingsGoalModel goal) async {
    final db = await instance.database;
    final nowEpoch = DateTime.now().millisecondsSinceEpoch;
    final goalToUpdate = goal.copyWith(
      updatedAt: nowEpoch,
      isSynced: false,
    );
    final res = await db.update(
      'savings_goals',
      goalToUpdate.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
    SyncService.instance.syncAll();
    return res;
  }

  Future<int> deleteSavingsGoal(String goalId) async {
    final db = await instance.database;
    final nowEpoch = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'savings_transactions',
      {},
      where: 'goal_id = ?',
      whereArgs: [goalId],
    );
    final res = await db.update(
      'savings_goals',
      {
        'isDeleted': 1,
        'updatedAt': nowEpoch,
        'isSynced': 0,
      },
      where: 'id = ?',
      whereArgs: [goalId],
    );
    SyncService.instance.syncAll();
    return res;
  }

  Future<List<SavingsTransactionModel>> getSavingsTransactions(String goalId) async {
    final db = await instance.database;
    final result = await db.query(
      'savings_transactions',
      where: 'goal_id = ?',
      whereArgs: [goalId],
      orderBy: 'id DESC',
    );
    return result.map((map) => SavingsTransactionModel.fromMap(map)).toList();
  }

  Future<int> addSavingsTransaction(SavingsTransactionModel tx) async {
    final db = await instance.database;
    final txId = await db.insert('savings_transactions', tx.toMap());

    final goalRes = await db.query('savings_goals', where: 'id = ?', whereArgs: [tx.goalId]);
    if (goalRes.isNotEmpty) {
      final goal = SavingsGoalModel.fromMap(goalRes.first);
      double newAmount = tx.isDeposit
          ? goal.currentAmount + tx.amount
          : goal.currentAmount - tx.amount;
      if (newAmount < 0) newAmount = 0;

      final nowEpoch = DateTime.now().millisecondsSinceEpoch;
      await db.update(
        'savings_goals',
        {
          'current_amount': newAmount,
          'updatedAt': nowEpoch,
          'isSynced': 0,
        },
        where: 'id = ?',
        whereArgs: [tx.goalId],
      );

      if (newAmount >= goal.targetAmount && goal.currentAmount < goal.targetAmount) {
        final formattedGoalAmount = formatMoney(newAmount);
        await InAppNotificationService.instance.add(
          type: 'savings',
          title: 'Chúc mừng! Đạt mục tiêu tiết kiệm',
          body: 'Mục tiêu "${goal.name}" đã hoàn thành 100%! Bạn đã tích lũy $formattedGoalAmount đ.',
          dedupeKey: 'notif_savings_${goal.id}',
          uid: goal.uid,
        );
      }
    }

    SyncService.instance.syncAll();
    return txId;
  }

  // --- BUDGETS & BUDGET ALERTS CRUD (ISOLATED BY UID) ---

  Future<List<BudgetModel>> getBudgets(String ledgerId, {String? month, String? uid}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;
    debugPrint('🗄️ [DatabaseHelper] Executing getBudgets for uid: $targetUid');
    String where = 'ledgerId = ? AND isDeleted = 0 AND (uid = ? OR uid IS NULL)';
    List<dynamic> args = [ledgerId, targetUid];
    if (month != null) {
      where += ' AND (month = ? OR month IS NULL OR isRecurring = 1)';
      args.add(month);
    }
    final result = await db.query(
      'budgets',
      where: where,
      whereArgs: args,
      orderBy: 'updatedAt DESC',
    );
    return result.map((map) => BudgetModel.fromMap(map)).toList();
  }

  Future<String> insertBudget(BudgetModel budget, {String? uid}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;
    final nowEpoch = DateTime.now().millisecondsSinceEpoch;
    final budgetId = budget.id != null && budget.id!.isNotEmpty ? budget.id! : _uuid.v4();
    final budgetToSave = budget.copyWith(
      id: budgetId,
      uid: targetUid,
      updatedAt: nowEpoch,
      isSynced: false,
    );
    await db.insert('budgets', budgetToSave.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    SyncService.instance.syncAll();
    return budgetId;
  }

  Future<int> updateBudget(BudgetModel budget) async {
    final db = await instance.database;
    final nowEpoch = DateTime.now().millisecondsSinceEpoch;
    final budgetToUpdate = budget.copyWith(
      updatedAt: nowEpoch,
      isSynced: false,
    );
    final res = await db.update(
      'budgets',
      budgetToUpdate.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
    SyncService.instance.syncAll();
    return res;
  }

  Future<int> deleteBudget(String budgetId) async {
    final db = await instance.database;
    final nowEpoch = DateTime.now().millisecondsSinceEpoch;
    final res = await db.update(
      'budgets',
      {
        'isDeleted': 1,
        'updatedAt': nowEpoch,
        'isSynced': 0,
      },
      where: 'id = ?',
      whereArgs: [budgetId],
    );
    SyncService.instance.syncAll();
    return res;
  }

  Future<List<Map<String, dynamic>>> getBudgetAlerts(String budgetId, String month) async {
    final db = await instance.database;
    return await db.query(
      'budget_alerts',
      where: 'budgetId = ? AND month = ?',
      whereArgs: [budgetId, month],
    );
  }

  Future<int> clearBudgetAlerts(String budgetId, String month) async {
    final db = await instance.database;
    return await db.delete(
      'budget_alerts',
      where: 'budgetId = ? AND month = ?',
      whereArgs: [budgetId, month],
    );
  }

  Future<int> insertBudgetAlert(String budgetId, String month, String level, {String? uid}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;
    return await db.insert('budget_alerts', {
      'budgetId': budgetId,
      'month': month,
      'level': level,
      'createdAt': DateTime.now().toIso8601String(),
      'uid': targetUid,
    });
  }

  // --- PENDING TRANSACTIONS CRUD (BANK NOTIFICATIONS) ---

  Future<bool> insertPendingTransaction(PendingTransactionModel pending, {String? uid}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;

    // Chống trùng lặp theo fingerprint
    final existing = await db.query(
      'pending_transactions',
      where: 'fingerprint = ? AND (uid = ? OR uid IS NULL)',
      whereArgs: [pending.fingerprint, targetUid],
    );

    if (existing.isNotEmpty) {
      return false; // Đã tồn tại giao dịch trùng lặp
    }

    final itemToSave = pending.copyWith(
      uid: targetUid,
    );

    await db.insert(
      'pending_transactions',
      itemToSave.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return true;
  }

  Future<List<PendingTransactionModel>> getPendingTransactions({String? uid, String status = 'pending'}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;
    final result = await db.query(
      'pending_transactions',
      where: 'status = ? AND (uid = ? OR uid IS NULL)',
      whereArgs: [status, targetUid],
      orderBy: 'occurredAt DESC',
    );
    return result.map((map) => PendingTransactionModel.fromMap(map)).toList();
  }

  Future<int> getPendingTransactionsCount({String? uid}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;
    final res = await db.rawQuery(
      "SELECT COUNT(*) FROM pending_transactions WHERE status = 'pending' AND (uid = ? OR uid IS NULL)",
      [targetUid],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<int> updatePendingTransactionStatus(String id, String status, {String? categoryId}) async {
    final db = await instance.database;
    final Map<String, dynamic> values = {'status': status};
    if (categoryId != null) {
      values['suggestedCategoryId'] = categoryId;
    }
    return await db.update(
      'pending_transactions',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePendingTransaction(String id) async {
    final db = await instance.database;
    return await db.delete(
      'pending_transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- IN-APP NOTIFICATIONS CRUD (ISOLATED BY UID) ---

  Future<List<AppNotificationModel>> getNotifications({String? uid}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;
    final result = await db.query(
      'app_notifications',
      where: 'uid = ? OR uid IS NULL',
      whereArgs: [targetUid],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => AppNotificationModel.fromMap(map)).toList();
  }

  Future<bool> insertAppNotification(AppNotificationModel notification, {String? uid}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;

    if (notification.dedupeKey != null && notification.dedupeKey!.isNotEmpty) {
      final existing = await db.query(
        'app_notifications',
        where: 'dedupeKey = ? AND (uid = ? OR uid IS NULL)',
        whereArgs: [notification.dedupeKey, targetUid],
      );
      if (existing.isNotEmpty) {
        return false; // Đã tồn tại thông báo trùng lặp theo dedupeKey
      }
    }

    final itemToSave = notification.copyWith(uid: targetUid);
    try {
      final res = await db.insert(
        'app_notifications',
        itemToSave.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      return res > 0;
    } catch (_) {
      return false;
    }
  }

  Future<int> markNotificationRead(String id, {String? uid}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;
    return await db.update(
      'app_notifications',
      {'isRead': 1},
      where: 'id = ? AND (uid = ? OR uid IS NULL)',
      whereArgs: [id, targetUid],
    );
  }

  Future<int> markAllNotificationsRead({String? uid}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;
    return await db.update(
      'app_notifications',
      {'isRead': 1},
      where: 'uid = ? OR uid IS NULL',
      whereArgs: [targetUid],
    );
  }

  Future<int> deleteNotification(String id, {String? uid}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;
    return await db.delete(
      'app_notifications',
      where: 'id = ? AND (uid = ? OR uid IS NULL)',
      whereArgs: [id, targetUid],
    );
  }

  Future<int> clearAllNotifications({String? uid}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;
    return await db.delete(
      'app_notifications',
      where: 'uid = ? OR uid IS NULL',
      whereArgs: [targetUid],
    );
  }

  Future<int> getUnreadNotificationCount({String? uid}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;
    final res = await db.rawQuery(
      'SELECT COUNT(*) FROM app_notifications WHERE isRead = 0 AND (uid = ? OR uid IS NULL)',
      [targetUid],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<void> autoPruneNotifications({String? uid}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;

    // 1. Xóa thông báo cũ hơn 30 ngày
    final cutoff = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    await db.delete(
      'app_notifications',
      where: 'createdAt < ? AND (uid = ? OR uid IS NULL)',
      whereArgs: [cutoff, targetUid],
    );

    // 2. Tự động giới hạn tối đa 200 thông báo gần nhất mỗi người dùng
    await db.rawDelete('''
      DELETE FROM app_notifications 
      WHERE (uid = ? OR uid IS NULL) 
        AND id NOT IN (
          SELECT id FROM app_notifications 
          WHERE (uid = ? OR uid IS NULL) 
          ORDER BY createdAt DESC 
          LIMIT 200
        )
    ''', [targetUid, targetUid]);
  }
}
