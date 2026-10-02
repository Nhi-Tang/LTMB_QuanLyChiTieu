import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/user_change_model.dart';
import '../models/user_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('piggysmart.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Enable FFI for Windows/Linux desktop if needed
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
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
        createdAt TEXT NOT NULL
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

    // Seed default Admin account
    final now = DateTime.now().toIso8601String();
    await db.insert('users', {
      'name': 'Quản trị viên (Admin)',
      'email': 'admin@piggysmart.com',
      'password': 'admin123',
      'role': 'admin',
      'isActive': 1,
      'createdAt': now,
    });

    // Seed default Demo User account
    await db.insert('users', {
      'name': 'Nguyễn Văn A',
      'email': 'user@piggysmart.com',
      'password': 'user123',
      'role': 'user',
      'isActive': 1,
      'createdAt': now,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
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
  }

  // --- USER AUTHENTICATION & REGISTRATION ---

  Future<int> registerUser(UserModel user) async {
    final db = await instance.database;
    try {
      return await db.insert('users', user.toMap());
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
}
