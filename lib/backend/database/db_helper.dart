import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bcrypt/bcrypt.dart';
import '../models/app_notification_model.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/pending_transaction_model.dart';
import '../models/savings_goal_model.dart';
import '../models/savings_transaction_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../services/sync_service.dart';
import '../services/transaction_service.dart';
import '../services/in_app_notification_service.dart';
import '../../core/utils/account_masker.dart';
import '../../frontend/utils/app_language.dart';
import '../../core/utils/money_input_formatter.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const _uuid = Uuid();

  DatabaseHelper._init();

  String? get _currentUid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }
  String? get currentUid => _currentUid;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mousey.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    await _migrateLegacyDbFile(dbPath, path);

    final db = await openDatabase(
      path,
      version: 23,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        debugPrint('🗄️ [DatabaseHelper] onOpen: database path=${db.path}, version=${await db.getVersion()}');
        await ensureSchema(db);
        // Sau khi đã có schema chuẩn, chèn dữ liệu ledger mặc định
        await _ensureDefaultLedgers(db);
      },
    );

    return db;
  }

  /// Bản cũ lưu dữ liệu ở piggysmart.db: đổi tên sang file mới để người dùng không mất dữ liệu
  static Future<void> _migrateLegacyDbFile(String dbPath, String newPath) async {
    if (kIsWeb) return;
    try {
      final legacyPath = join(dbPath, 'piggysmart.db');
      if (await File(newPath).exists() || !await File(legacyPath).exists()) return;
      for (final suffix in ['', '-journal', '-wal', '-shm']) {
        final f = File('$legacyPath$suffix');
        if (await f.exists()) await f.rename('$newPath$suffix');
      }
      debugPrint('🗄️ [DatabaseHelper] Migrated legacy piggysmart.db -> ${basename(newPath)}');
    } catch (e) {
      debugPrint('🗄️ [DatabaseHelper] Legacy DB migration failed: $e');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await ensureSchema(db);
  }

  Future<void> ensureSchema(Database db) async {
    debugPrint('🗄️ [DatabaseHelper] ensureSchema called');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
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
      CREATE TABLE IF NOT EXISTS ledgers (
        id TEXT PRIMARY KEY,
        uid TEXT NOT NULL,
        name TEXT NOT NULL,
        isDefault INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    try { await db.execute("CREATE INDEX IF NOT EXISTS idx_ledgers_uid ON ledgers(uid);"); } catch (_) {}

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
        uid TEXT,
        ledgerId TEXT DEFAULT 'Sổ cá nhân 1'
      )
    ''');
    try { await db.execute("CREATE INDEX IF NOT EXISTS idx_goals_uid ON savings_goals(uid);"); } catch (_) {}

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
        uid TEXT,
        ledgerId TEXT DEFAULT 'Sổ cá nhân 1',
        kind TEXT DEFAULT 'expense',
        transferGroupId TEXT
      )
    ''');
    try { await db.execute("CREATE INDEX IF NOT EXISTS idx_tx_uid ON transactions(uid);"); } catch (_) {}

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
        isDeleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
    try { await db.execute("CREATE INDEX IF NOT EXISTS idx_categories_uid ON categories(uid);"); } catch (_) {}

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ledger_categories (
        ledgerId TEXT NOT NULL,
        categoryId INTEGER NOT NULL,
        uid TEXT,
        isUnlinked INTEGER NOT NULL DEFAULT 0,
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
        ledgerId TEXT DEFAULT 'Sổ cá nhân 1',
        updatedAt INTEGER NOT NULL,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    try { await db.execute("CREATE INDEX IF NOT EXISTS idx_budgets_uid ON budgets(uid);"); } catch (_) {}

    await db.execute('''
      CREATE TABLE IF NOT EXISTS budget_alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        budgetId TEXT NOT NULL,
        month TEXT NOT NULL,
        level TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        uid TEXT
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
    try {
      await db.execute("CREATE INDEX IF NOT EXISTS idx_pending_uid ON pending_transactions(uid);");
      await db.execute("CREATE INDEX IF NOT EXISTS idx_pending_status ON pending_transactions(status);");
      await db.execute("CREATE INDEX IF NOT EXISTS idx_pending_fp ON pending_transactions(fingerprint);");
    } catch (_) {}

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

    // Bản cũ tự tạo 2 tài khoản mẫu (admin/user) chỉ có trong SQLite, giờ đăng nhập qua Firebase nên xoá đi
    await db.execute('DROP TABLE IF EXISTS user_change');
    await db.delete(
      'users',
      where: "email IN ('admin@mousey.com', 'user@mousey.com') AND (uid IS NULL OR uid = '')",
    );

    await _hashExistingPlaintextPasswords(db);
  }

  Future<void> _hashExistingPlaintextPasswords(Database db) async {
    try {
      final users = await db.query('users');
      for (var u in users) {
        final id = u['id'];
        final pass = u['password'] as String? ?? '';
        if (pass.isNotEmpty && !pass.startsWith('\$2')) {
          final hashed = BCrypt.hashpw(pass, BCrypt.gensalt());
          await db.update('users', {'password': hashed}, where: 'id = ?', whereArgs: [id]);
          debugPrint('🔐 [DatabaseHelper] Hashed legacy plaintext password for user id=$id');
        }
      }
    } catch (e) {
      debugPrint('Error hashing plaintext passwords: $e');
    }
  }

  Future<void> _ensureDefaultLedgers(Database db) async {
    final List<Map<String, dynamic>> uidsResult = await db.rawQuery('SELECT DISTINCT uid FROM users WHERE uid IS NOT NULL AND uid != \'\'');
    // Bổ sung uid = '' nếu có dữ liệu legacy
    final List<String> allUids = uidsResult.map((m) => m['uid'] as String).toList();
    if (!allUids.contains('')) allUids.add('');

    for (final uid in allUids) {
      final defaultLedgerId = 'default_$uid';
      final existing = await db.query('ledgers', where: 'id = ?', whereArgs: [defaultLedgerId]);
      if (existing.isEmpty) {
        final nowEpoch = DateTime.now().millisecondsSinceEpoch;
        await db.insert('ledgers', {
          'id': defaultLedgerId,
          'uid': uid,
          'name': 'Sổ cá nhân 1',
          'isDefault': 1,
          'createdAt': nowEpoch,
          'updatedAt': nowEpoch,
          'isDeleted': 0,
          'isSynced': 0,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        // Gán lại dữ liệu cũ bị thiếu ledgerId cho uid này
        String uidWhere = uid.isEmpty ? '(uid IS NULL OR uid = \'\')' : 'uid = ?';
        List<dynamic> args = uid.isEmpty ? [] : [uid];
        await db.rawUpdate('UPDATE transactions SET ledgerId = ? WHERE ledgerId IS NULL AND $uidWhere', [defaultLedgerId, ...args]);
        await db.rawUpdate('UPDATE budgets SET ledgerId = ? WHERE ledgerId IS NULL AND $uidWhere', [defaultLedgerId, ...args]);
        await db.rawUpdate('UPDATE savings_goals SET ledgerId = ? WHERE ledgerId IS NULL AND $uidWhere', [defaultLedgerId, ...args]);
      }
    }
  }



  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('🗄️ [DatabaseHelper] _onUpgrade from $oldVersion to $newVersion');
    await ensureSchema(db);
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
    if (oldVersion < 13) {
      // Migration v13: Thêm cột ledgerId phân lập giao dịch theo sổ sách
      try {
        await db.execute("ALTER TABLE transactions ADD COLUMN ledgerId TEXT DEFAULT 'Sổ cá nhân 1';");
      } catch (_) {}
    }
    if (oldVersion < 14) {
      // Migration v14: Tạo bảng ledgers cho quản lý đa sổ sách
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ledgers (
          id TEXT PRIMARY KEY,
          uid TEXT NOT NULL,
          name TEXT NOT NULL,
          isDefault INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          isDeleted INTEGER NOT NULL DEFAULT 0,
          isSynced INTEGER NOT NULL DEFAULT 0
        )
      ''');
      try {
        await db.execute("CREATE INDEX IF NOT EXISTS idx_ledgers_uid ON ledgers(uid);");
      } catch (_) {}
    }
    if (oldVersion < 15) {
      // Migration v15: Phục hồi và bảo đảm các danh mục mặc định cho mọi sổ
      try {
        await db.execute("ALTER TABLE categories ADD COLUMN isDeleted INTEGER DEFAULT 0;");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE ledger_categories ADD COLUMN isUnlinked INTEGER DEFAULT 0;");
      } catch (_) {}
    }
    if (oldVersion < 16) {
      // Migration v16: Thêm cột ledgerId cho budgets và savings_goals
      try {
        await db.execute("ALTER TABLE budgets ADD COLUMN ledgerId TEXT DEFAULT 'Sổ cá nhân 1';");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE savings_goals ADD COLUMN ledgerId TEXT DEFAULT 'Sổ cá nhân 1';");
      } catch (_) {}
    }
    if (oldVersion < 17) {
      // Migration v17: Chuẩn hóa bảng budgets
      try {
        await db.execute("UPDATE budgets SET isDeleted = 0 WHERE isDeleted IS NULL;");
        await db.execute("UPDATE budgets SET ledgerId = 'Sổ cá nhân 1' WHERE ledgerId IS NULL OR ledgerId = '';");
      } catch (_) {}
    }
    if (oldVersion < 19) {
      // Migration v19: Thêm cột kind và transferGroupId cho transactions
      try {
        await db.execute("ALTER TABLE transactions ADD COLUMN kind TEXT DEFAULT 'expense';");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE transactions ADD COLUMN transferGroupId TEXT;");
      } catch (_) {}
      try {
        await db.execute("UPDATE transactions SET kind = 'expense' WHERE is_expense = 1 AND (kind IS NULL OR kind = '');");
        await db.execute("UPDATE transactions SET kind = 'income' WHERE is_expense = 0 AND (kind IS NULL OR kind = '');");
      } catch (_) {}
    }
    if (oldVersion < 20) {
      // Migration v20: Mã hóa mật khẩu user bằng bcrypt nếu chưa được mã hóa
      try {
        final users = await db.query('users');
        for (var u in users) {
          final id = u['id'];
          final pass = u['password'] as String? ?? '';
          if (pass.isNotEmpty && !pass.startsWith('\$2')) {
            final hashed = BCrypt.hashpw(pass, BCrypt.gensalt());
            await db.update('users', {'password': hashed}, where: 'id = ?', whereArgs: [id]);
          }
        }
      } catch (_) {}
    }
    if (oldVersion < 22) {
      // Migration v22: bản v21 có thể đã tạo budget_alerts thiếu cột createdAt/uid
      await _ensureBudgetAlertsColumns(db);
    }
    if (oldVersion < 23) {
      // Migration v23: đổi thương hiệu PiggySmart -> Mousey cho email lưu trên máy
      try {
        await db.rawUpdate("UPDATE OR IGNORE users SET email = REPLACE(email, '@piggysmart.com', '@mousey.com') WHERE email LIKE '%@piggysmart.com'");
      } catch (_) {}
    }
  }

  static Future<void> _ensureBudgetAlertsColumns(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS budget_alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        budgetId TEXT NOT NULL,
        month TEXT NOT NULL,
        level TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        uid TEXT
      )
    ''');
    final cols = (await db.rawQuery('PRAGMA table_info(budget_alerts)')).map((c) => c['name']).toSet();
    if (!cols.contains('createdAt')) {
      await db.execute("ALTER TABLE budget_alerts ADD COLUMN createdAt TEXT NOT NULL DEFAULT ''");
    }
    if (!cols.contains('uid')) {
      await db.execute('ALTER TABLE budget_alerts ADD COLUMN uid TEXT');
    }
  }

  static const List<Map<String, String>> defaultExpenseCategories = [
    {'name': 'Ăn uống', 'iconKey': 'fastfood_rounded'},
    {'name': 'Cà phê', 'iconKey': 'local_cafe_rounded'},
    {'name': 'Trà sữa', 'iconKey': 'emoji_food_beverage_rounded'},
    {'name': 'Hóa đơn', 'iconKey': 'receipt_rounded'},
    {'name': 'Điện thoại', 'iconKey': 'smartphone_rounded'},
    {'name': 'Di chuyển', 'iconKey': 'directions_bus_rounded'},
    {'name': 'Mua sắm', 'iconKey': 'shopping_bag_rounded'},
    {'name': 'Giải trí', 'iconKey': 'sports_esports_rounded'},
    {'name': 'Netflix', 'iconKey': 'movie_rounded'},
    {'name': 'Spotify', 'iconKey': 'headphones_rounded'},
    {'name': 'YouTube', 'iconKey': 'live_tv_rounded'},
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

  static const List<Map<String, String>> defaultIncomeCategories = [
    {'name': 'Lương', 'iconKey': 'account_balance_wallet_rounded'},
    {'name': 'Thưởng', 'iconKey': 'card_giftcard_rounded'},
    {'name': 'Bán hàng', 'iconKey': 'storefront_rounded'},
    {'name': 'Đầu tư', 'iconKey': 'trending_up_rounded'},
    {'name': 'Khác', 'iconKey': 'category_rounded'},
  ];

  Future<void> ensureDefaultCategories(String uid) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();

    // 1. Đọc tất cả danh mục user đang thấy trong 1 query duy nhất. Danh mục tự tạo
    // chưa gán uid cũng phải tính, nếu không sẽ thêm trùng danh mục mặc định cùng tên.
    final existingRows = await db.query(
      'categories',
      columns: ['id', 'name', 'type', 'isDefault'],
      where: "uid = ? OR uid IS NULL OR uid = '' OR isDefault = 1",
      whereArgs: [uid],
    );
    String keyOf(Object? type, Object? name) => '$type|${CategoryModel.normalizeKey(name as String)}';

    // 2. Danh mục tự tạo trùng tên với danh mục mặc định cùng loại (vd. "Cà phê" tạo trước khi
    // thành mặc định): xoá bản tự tạo, giao dịch đã dùng tên đó chuyển sang tên danh mục mặc định
    final defaultNames = {
      for (final r in existingRows.where((r) => r['isDefault'] == 1)) keyOf(r['type'], r['name']): r['name'] as String,
    };
    final duplicates = existingRows
        .where((r) => r['isDefault'] != 1 && defaultNames.containsKey(keyOf(r['type'], r['name'])))
        .toList();
    if (duplicates.isNotEmpty) {
      await db.transaction((txn) async {
        for (final r in duplicates) {
          final name = r['name'] as String;
          final defaultName = defaultNames[keyOf(r['type'], name)]!;
          if (name != defaultName) {
            await txn.update(
              'transactions',
              {'category': defaultName},
              where: "category = ? AND (uid = ? OR uid IS NULL OR uid = '')",
              whereArgs: [name, uid],
            );
          }
          await txn.delete('ledger_categories', where: 'categoryId = ?', whereArgs: [r['id']]);
          await txn.delete('categories', where: 'id = ?', whereArgs: [r['id']]);
        }
      });
    }

    final existingKeys = existingRows.map((r) => keyOf(r['type'], r['name'])).toSet();
    final missingExpense = defaultExpenseCategories.where((c) => !existingKeys.contains(keyOf('expense', c['name']))).toList();
    final missingIncome = defaultIncomeCategories.where((c) => !existingKeys.contains(keyOf('income', c['name']))).toList();

    if (missingExpense.isEmpty && missingIncome.isEmpty) {
      return; // Đã đủ danh mục, thoát ngay tức thì trong <1ms
    }

    await db.transaction((txn) async {
      await txn.update('categories', {'uid': uid}, where: 'uid IS NULL OR uid = ""');

      int sortOrder = 0;
      for (var cat in missingExpense) {
        await txn.insert('categories', {
          'uid': uid,
          'name': cat['name'],
          'iconKey': cat['iconKey'],
          'type': 'expense',
          'sortOrder': sortOrder++,
          'isDefault': 1,
          'isArchived': 0,
          'createdAt': now,
          'updatedAt': now,
        });
      }

      sortOrder = 0;
      for (var cat in missingIncome) {
        await txn.insert('categories', {
          'uid': uid,
          'name': cat['name'],
          'iconKey': cat['iconKey'],
          'type': 'income',
          'sortOrder': sortOrder++,
          'isDefault': 1,
          'isArchived': 0,
          'createdAt': now,
          'updatedAt': now,
        });
      }
    });
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    final expenseCats = [
      {'name': 'Ăn uống', 'iconKey': 'fastfood_rounded'},
      {'name': 'Cà phê', 'iconKey': 'local_cafe_rounded'},
      {'name': 'Trà sữa', 'iconKey': 'emoji_food_beverage_rounded'},
      {'name': 'Hóa đơn', 'iconKey': 'receipt_rounded'},
      {'name': 'Điện thoại', 'iconKey': 'smartphone_rounded'},
      {'name': 'Di chuyển', 'iconKey': 'directions_bus_rounded'},
      {'name': 'Mua sắm', 'iconKey': 'shopping_bag_rounded'},
      {'name': 'Giải trí', 'iconKey': 'sports_esports_rounded'},
      {'name': 'Netflix', 'iconKey': 'movie_rounded'},
      {'name': 'Spotify', 'iconKey': 'headphones_rounded'},
      {'name': 'YouTube', 'iconKey': 'live_tv_rounded'},
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

  // --- LEDGERS DAO METHODS ---

  Future<List<Map<String, dynamic>>> getLedgers({String? uid}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;
    return await db.query(
      'ledgers',
      where: 'isDeleted = 0 AND uid = ?',
      whereArgs: [targetUid],
      orderBy: 'isDefault DESC, createdAt ASC',
    );
  }

  Future<Map<String, dynamic>?> getLedgerById(String id, {String? uid}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;
    final rows = await db.query(
      'ledgers',
      where: 'id = ? AND uid = ? AND isDeleted = 0',
      whereArgs: [id, targetUid],
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<String> insertLedger({
    required String name,
    String? id,
    String? uid,
    bool isDefault = false,
  }) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;
    final ledgerId = id ?? 'ledger_${_uuid.v4()}';
    final nowEpoch = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      'ledgers',
      {
        'id': ledgerId,
        'uid': targetUid,
        'name': name,
        'isDefault': isDefault ? 1 : 0,
        'createdAt': nowEpoch,
        'updatedAt': nowEpoch,
        'isDeleted': 0,
        'isSynced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    SyncService.instance.syncAll();
    return ledgerId;
  }

  Future<int> deleteLedger(String ledgerId, {String? uid}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;
    final nowEpoch = DateTime.now().millisecondsSinceEpoch;

    final res = await db.update(
      'ledgers',
      {
        'isDeleted': 1,
        'updatedAt': nowEpoch,
        'isSynced': 0,
      },
      where: 'id = ? AND uid = ?',
      whereArgs: [ledgerId, targetUid],
    );

    SyncService.instance.syncAll();
    return res;
  }

  // --- TRANSACTIONS DAO METHODS (ISOLATED BY UID & LEDGER) ---

  Future<List<TransactionItem>> getTransactions({String? uid, String? ledgerId}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;
    final targetLedger = ledgerId ?? TransactionService.instance.currentLedgerId;
    debugPrint('🗄️ [DatabaseHelper] Executing getTransactions for uid: $targetUid, ledgerId: $targetLedger');

    final isDefaultLedger = targetLedger.startsWith('default_') || targetLedger == 'Sổ cá nhân 1' || targetLedger == 'default_ledger';
    final List<dynamic> whereArgs = [];

    final String uidWhere;
    if (targetUid != null && targetUid.isNotEmpty) {
      uidWhere = '(uid = ? OR uid IS NULL OR uid = \'\')';
      whereArgs.add(targetUid);
    } else {
      uidWhere = '(uid IS NULL OR uid = \'\')';
    }

    final String where;
    if (isDefaultLedger) {
      where = 'isDeleted = 0 AND $uidWhere AND (ledgerId = ? OR ledgerId = \'Sổ cá nhân 1\' OR ledgerId = \'default_ledger\' OR ledgerId IS NULL OR ledgerId LIKE \'default_%\')';
      whereArgs.add(targetLedger);
    } else {
      where = 'isDeleted = 0 AND $uidWhere AND ledgerId = ?';
      whereArgs.add(targetLedger);
    }

    final result = await db.query(
      'transactions',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return result.map((map) => TransactionItem.fromMap(map)).toList();
  }

  Future<int> insertTransaction(TransactionItem item, {String? uid, String? ledgerId}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;
    final targetLedger = ledgerId ??
        ((item.ledgerId != null && item.ledgerId != 'Sổ cá nhân 1')
            ? item.ledgerId!
            : TransactionService.instance.currentLedgerId);

    final nowEpoch = DateTime.now().millisecondsSinceEpoch;
    final itemToSave = item.copyWith(
      id: item.id.isNotEmpty ? item.id : _uuid.v4(),
      uid: targetUid,
      ledgerId: targetLedger,
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

  // --- SOCIAL LOGIN & USER DAO METHODS ---

  Future<int> insertOrUpdateUser(UserModel user) async {
    final db = await instance.database;
    String passToSave = user.password;
    if (passToSave.isNotEmpty && !passToSave.startsWith('\$2')) {
      passToSave = BCrypt.hashpw(passToSave, BCrypt.gensalt());
    }
    final userToSave = user.copyWith(password: passToSave);
    return await db.insert(
      'users',
      userToSave.toMap(),
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

  // --- USER CRUD ---

  Future<List<UserModel>> getAllUsers() async {
    final db = await instance.database;
    final result = await db.query(
      'users',
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
    try {
      await db.delete(
        'savings_transactions',
        where: 'goal_id = ?',
        whereArgs: [goalId],
      );
    } catch (_) {}
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
          title: AppLanguage.instance.t('Chúc mừng! Đạt mục tiêu tiết kiệm'),
          body: AppLanguage.instance.t('Mục tiêu "{name}" đã hoàn thành 100%! Bạn đã tích lũy {amount} đ.', {'name': goal.name, 'amount': formattedGoalAmount}),
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
    final targetLedger = (ledgerId != 'default_ledger' && ledgerId.isNotEmpty) ? ledgerId : TransactionService.instance.currentLedgerId;
    debugPrint('🗄️ [DatabaseHelper] Executing getBudgets for uid: $targetUid, ledgerId: $targetLedger');

    final isDefaultLedger = targetLedger.startsWith('default_') || targetLedger == 'default_ledger' || targetLedger == 'Sổ cá nhân 1';
    final List<dynamic> args = [];

    // 1. Placeholder 1: ledgerWhere
    final String ledgerWhere;
    if (isDefaultLedger) {
      ledgerWhere = '(b.ledgerId = ? OR b.ledgerId = \'default_ledger\' OR b.ledgerId = \'Sổ cá nhân 1\' OR b.ledgerId IS NULL OR b.ledgerId LIKE \'default_%\')';
      args.add(targetLedger);
    } else {
      ledgerWhere = 'b.ledgerId = ?';
      args.add(targetLedger);
    }

    // 2. Placeholder 2: uidWhere
    final String uidWhere;
    if (targetUid != null && targetUid.isNotEmpty) {
      uidWhere = '(b.uid = ? OR b.uid IS NULL OR b.uid = \'\')';
      args.add(targetUid);
    } else {
      uidWhere = '(b.uid IS NULL OR b.uid = \'\')';
    }

    String where = '$ledgerWhere AND (b.isDeleted = 0 OR b.isDeleted IS NULL) AND $uidWhere';
    if (month != null) {
      where += ' AND (b.month = ? OR b.month IS NULL OR b.isRecurring = 1)';
      args.add(month);
    }

    final sql = '''
      SELECT b.*, c.name as categoryName, c.iconKey as categoryIcon
      FROM budgets b
      LEFT JOIN categories c ON b.categoryId = c.name AND (c.uid = b.uid OR c.uid IS NULL OR c.isDefault = 1)
      WHERE $where
      ORDER BY b.updatedAt DESC
    ''';

    final result = await db.rawQuery(sql, args);
    return result.map((map) => BudgetModel.fromMap(map)).toList();
  }

  Future<String> insertBudget(BudgetModel budget, {String? uid}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;
    final targetLedger = (budget.ledgerId != null && budget.ledgerId != 'default_ledger' && budget.ledgerId != 'Sổ cá nhân 1')
        ? budget.ledgerId
        : TransactionService.instance.currentLedgerId;

    // Check upsert
    final existing = await db.query(
      'budgets',
      where: 'ledgerId = ? AND (uid = ? OR uid IS NULL OR uid = \'\') AND (categoryId = ? OR (categoryId IS NULL AND ? IS NULL)) AND (month = ? OR month IS NULL) AND isDeleted = 0',
      whereArgs: [
        targetLedger,
        targetUid ?? '',
        budget.categoryId,
        budget.categoryId,
        budget.month
      ],
    );

    if (existing.isNotEmpty && budget.id == null) {
      final existingId = existing.first['id'] as String;
      final nowEpoch = DateTime.now().millisecondsSinceEpoch;
      final budgetToUpdate = budget.copyWith(
        id: existingId,
        uid: targetUid,
        ledgerId: targetLedger,
        updatedAt: nowEpoch,
        isSynced: false,
      );
      await db.update('budgets', budgetToUpdate.toMap(), where: 'id = ?', whereArgs: [existingId]);
      SyncService.instance.syncAll();
      return existingId;
    }

    final nowEpoch = DateTime.now().millisecondsSinceEpoch;
    final budgetId = budget.id != null && budget.id!.isNotEmpty ? budget.id! : _uuid.v4();

    final budgetToSave = budget.copyWith(
      id: budgetId,
      uid: targetUid,
      ledgerId: targetLedger,
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
    final targetLedger = (budget.ledgerId != null && budget.ledgerId != 'default_ledger' && budget.ledgerId != 'Sổ cá nhân 1')
        ? budget.ledgerId
        : TransactionService.instance.currentLedgerId;

    final budgetToUpdate = budget.copyWith(
      ledgerId: targetLedger,
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

  Future<int> clearBudgetAlertLevel(String budgetId, String month, String level) async {
    final db = await instance.database;
    return await db.delete(
      'budget_alerts',
      where: 'budgetId = ? AND month = ? AND level = ?',
      whereArgs: [budgetId, month, level],
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

    final String uidWhere;
    final List<dynamic> whereArgs = [pending.fingerprint];
    if (targetUid != null && targetUid.isNotEmpty) {
      uidWhere = '(uid = ? OR uid IS NULL OR uid = \'\')';
      whereArgs.add(targetUid);
    } else {
      uidWhere = '(uid IS NULL OR uid = \'\')';
    }

    // Chống trùng lặp theo fingerprint
    final existing = await db.query(
      'pending_transactions',
      where: 'fingerprint = ? AND $uidWhere',
      whereArgs: whereArgs,
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

    final String uidWhere;
    final List<dynamic> whereArgs = [status];
    if (targetUid != null && targetUid.isNotEmpty) {
      uidWhere = '(uid = ? OR uid IS NULL OR uid = \'\')';
      whereArgs.add(targetUid);
    } else {
      uidWhere = '(uid IS NULL OR uid = \'\')';
    }

    final result = await db.query(
      'pending_transactions',
      where: 'status = ? AND $uidWhere',
      whereArgs: whereArgs,
      orderBy: 'occurredAt DESC',
    );
    return result.map((map) => PendingTransactionModel.fromMap(map)).toList();
  }

  Future<int> getPendingTransactionsCount({String? uid}) async {
    final db = await instance.database;
    final targetUid = uid ?? _currentUid;

    final String uidWhere;
    final List<dynamic> whereArgs = [];
    if (targetUid != null && targetUid.isNotEmpty) {
      uidWhere = '(uid = ? OR uid IS NULL OR uid = \'\')';
      whereArgs.add(targetUid);
    } else {
      uidWhere = '(uid IS NULL OR uid = \'\')';
    }

    final res = await db.rawQuery(
      "SELECT COUNT(*) FROM pending_transactions WHERE status = 'pending' AND $uidWhere",
      whereArgs,
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
