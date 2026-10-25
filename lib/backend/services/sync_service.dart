import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  SyncService._init();

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  bool _isSyncing = false;

  void stop() {
    _isSyncing = false;
  }

  /// Đồng bộ hai chiều (Cloud <-> SQLite) với cờ bảo vệ chống ghi đè cho tài khoản mới/phiên mới
  Future<void> syncAll() async {
    if (_isSyncing) return;
    final firestore = _firestore;
    final auth = _auth;
    if (firestore == null || auth == null) return;
    final user = auth.currentUser;
    if (user == null) return;

    _isSyncing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final isInitialSyncKey = 'is_initial_sync_done_${user.uid}';
      final isInitialSyncDone = prefs.getBool(isInitialSyncKey) ?? false;

      if (!isInitialSyncDone) {
        // LẦN ĐẦU ĐĂNG NHẬP TRÊN THIẾT BỊ: PULL TRƯỚC BẢO VỆ DỮ LIỆU ĐÁM MÂY
        debugPrint('☁️ [SyncService] Initial Sync for ${user.uid}: Pulling changes first...');
        await pullChanges(user.uid);
        await prefs.setBool(isInitialSyncKey, true);

        // Đảm bảo tạo sổ mặc định nếu cả Cloud & Local chưa có sổ nào
        final ledgers = await DatabaseHelper.instance.getLedgers(uid: user.uid);
        if (ledgers.isEmpty) {
          await DatabaseHelper.instance.insertLedger(
            id: 'default_${user.uid}',
            uid: user.uid,
            name: 'Sổ cá nhân 1',
            isDefault: true,
          );
        }
      } else {
        // CÁC LẦN ĐỒNG BỘ TIẾP THEO: PUSH TRƯỚC, PULL SAU
        await pushPending(user.uid);
        await pullChanges(user.uid);
      }
    } catch (e) {
      debugPrint('☁️ [SyncService] Sync Error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Đẩy các hàng chưa đồng bộ (isSynced = 0) ở local SQLite lên Firestore
  Future<void> pushPending(String uid) async {
    final firestore = _firestore;
    if (firestore == null) return;
    final db = await DatabaseHelper.instance.database;

    final pendingLedgerMaps = await db.query(
      'ledgers',
      where: 'uid = ? AND isSynced = 0',
      whereArgs: [uid],
    );

    final pendingTxMaps = await db.query(
      'transactions',
      where: 'uid = ? AND isSynced = 0',
      whereArgs: [uid],
    );

    final pendingGoalMaps = await db.query(
      'savings_goals',
      where: 'uid = ? AND isSynced = 0',
      whereArgs: [uid],
    );

    final pendingBudgetMaps = await db.query(
      'budgets',
      where: 'uid = ? AND isSynced = 0',
      whereArgs: [uid],
    );

    if (pendingLedgerMaps.isEmpty &&
        pendingTxMaps.isEmpty &&
        pendingGoalMaps.isEmpty &&
        pendingBudgetMaps.isEmpty) {
      return;
    }

    List<Map<String, dynamic>> allPending = [];
    for (var m in pendingLedgerMaps) {
      allPending.add({...m, '_type': 'ledger'});
    }
    for (var m in pendingTxMaps) {
      allPending.add({...m, '_type': 'transaction'});
    }
    for (var m in pendingGoalMaps) {
      allPending.add({...m, '_type': 'goal'});
    }
    for (var m in pendingBudgetMaps) {
      allPending.add({...m, '_type': 'budget'});
    }

    int batchSize = 400;
    for (int i = 0; i < allPending.length; i += batchSize) {
      final chunk = allPending.skip(i).take(batchSize);
      WriteBatch batch = firestore.batch();
      List<String> syncedLedgerIds = [];
      List<String> syncedTxIds = [];
      List<String> syncedGoalIds = [];
      List<String> syncedBudgetIds = [];

      for (var item in chunk) {
        final type = item['_type'] as String;
        final id = item['id'] as String;
        String collectionName = 'transactions';
        if (type == 'ledger') {
          collectionName = 'ledgers';
        } else if (type == 'goal') {
          collectionName = 'savings_goals';
        } else if (type == 'budget') {
          collectionName = 'budgets';
        }

        final docRef = firestore
            .collection('users')
            .doc(uid)
            .collection(collectionName)
            .doc(id);

        final firestoreData = Map<String, dynamic>.from(item)..remove('_type');
        batch.set(docRef, firestoreData, SetOptions(merge: true));

        if (type == 'ledger') {
          syncedLedgerIds.add(id);
        } else if (type == 'transaction') {
          syncedTxIds.add(id);
        } else if (type == 'goal') {
          syncedGoalIds.add(id);
        } else if (type == 'budget') {
          syncedBudgetIds.add(id);
        }
      }

      int retries = 0;
      bool success = false;
      while (retries < 3 && !success) {
        try {
          await batch.commit();
          success = true;
        } catch (e) {
          retries++;
          if (retries >= 3) rethrow;
          await Future.delayed(Duration(milliseconds: 500 * (1 << retries)));
        }
      }

      if (success) {
        if (syncedLedgerIds.isNotEmpty) {
          await db.rawUpdate(
            "UPDATE ledgers SET isSynced = 1 WHERE id IN (${List.filled(syncedLedgerIds.length, '?').join(',')})",
            syncedLedgerIds,
          );
        }
        if (syncedTxIds.isNotEmpty) {
          await db.rawUpdate(
            "UPDATE transactions SET isSynced = 1 WHERE id IN (${List.filled(syncedTxIds.length, '?').join(',')})",
            syncedTxIds,
          );
        }
        if (syncedGoalIds.isNotEmpty) {
          await db.rawUpdate(
            "UPDATE savings_goals SET isSynced = 1 WHERE id IN (${List.filled(syncedGoalIds.length, '?').join(',')})",
            syncedGoalIds,
          );
        }
        if (syncedBudgetIds.isNotEmpty) {
          await db.rawUpdate(
            "UPDATE budgets SET isSynced = 1 WHERE id IN (${List.filled(syncedBudgetIds.length, '?').join(',')})",
            syncedBudgetIds,
          );
        }
      }
    }
  }

  /// Kéo dữ liệu từ Cloud Firestore về SQLite local.
  /// THỨ TỰ THỰC HIỆN: Pull Bảng ledgers TRƯỚC, rồi mới pull transactions, budgets, goals SAU.
  Future<void> pullChanges(String uid) async {
    final firestore = _firestore;
    if (firestore == null) return;
    final prefs = await SharedPreferences.getInstance();
    final lastSyncKey = 'last_sync_$uid';
    final int lastSyncAt = prefs.getInt(lastSyncKey) ?? 0;

    final db = await DatabaseHelper.instance.database;

    // 1. PULL LEDGERS TRƯỚC
    final ledgerSnapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('ledgers')
        .where('updatedAt', isGreaterThan: lastSyncAt)
        .get();

    for (var doc in ledgerSnapshot.docs) {
      final remoteData = doc.data();
      final remoteId = doc.id;
      final remoteUpdatedAt = remoteData['updatedAt'] as int? ?? 0;

      final localRows = await db.query('ledgers', where: 'id = ?', whereArgs: [remoteId]);
      if (localRows.isEmpty) {
        await db.insert('ledgers', {
          'id': remoteId,
          'uid': uid,
          'name': remoteData['name'] ?? 'Sổ cá nhân',
          'isDefault': remoteData['isDefault'] ?? 0,
          'createdAt': remoteData['createdAt'] ?? remoteUpdatedAt,
          'updatedAt': remoteUpdatedAt,
          'isDeleted': remoteData['isDeleted'] ?? 0,
          'isSynced': 1,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
        final localRow = localRows.first;
        final localUpdatedAt = localRow['updatedAt'] as int? ?? 0;
        if (remoteUpdatedAt > localUpdatedAt) {
          await db.update(
            'ledgers',
            {
              'name': remoteData['name'],
              'isDefault': remoteData['isDefault'] ?? 0,
              'createdAt': remoteData['createdAt'] ?? remoteUpdatedAt,
              'updatedAt': remoteUpdatedAt,
              'isDeleted': remoteData['isDeleted'] ?? 0,
              'isSynced': 1,
            },
            where: 'id = ?',
            whereArgs: [remoteId],
          );
        }
      }
    }

    // PULL CATEGORIES (MERGE STRATEGY)
    try {
      final catSnapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('categories')
          .get();

      for (var doc in catSnapshot.docs) {
        final remoteData = doc.data();
        final catName = remoteData['name'] as String? ?? '';
        if (catName.isEmpty) continue;

        final localRows = await db.query(
          'categories',
          where: 'name = ? AND (uid = ? OR isDefault = 1)',
          whereArgs: [catName, uid],
        );

        if (localRows.isEmpty) {
          await db.insert('categories', {
            'uid': uid,
            'name': catName,
            'iconKey': remoteData['iconKey'] ?? 'category_rounded',
            'type': remoteData['type'] ?? 'expense',
            'sortOrder': remoteData['sortOrder'] ?? 0,
            'isDefault': remoteData['isDefault'] ?? 0,
            'isArchived': remoteData['isArchived'] ?? 0,
            'createdAt': remoteData['createdAt'] ?? DateTime.now().toIso8601String(),
            'updatedAt': remoteData['updatedAt'] ?? DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      debugPrint('Pull categories error: $e');
    }

    // 2. PULL TRANSACTIONS (Bảo lưu chính xác ledgerId gốc từ Firestore)
    final txSnapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('updatedAt', isGreaterThan: lastSyncAt)
        .get();

    for (var doc in txSnapshot.docs) {
      final remoteData = doc.data();
      final remoteId = doc.id;
      final remoteUpdatedAt = remoteData['updatedAt'] as int? ?? 0;
      final remoteLedgerId = remoteData['ledgerId'] as String? ?? 'default_$uid';

      final localRows = await db.query('transactions', where: 'id = ?', whereArgs: [remoteId]);
      if (localRows.isEmpty) {
        await db.insert('transactions', {
          'id': remoteId,
          'uid': uid,
          'title': remoteData['title'],
          'category': remoteData['category'],
          'amount': remoteData['amount'],
          'is_expense': remoteData['is_expense'],
          'date': remoteData['date'],
          'ledgerId': remoteLedgerId,
          'updatedAt': remoteUpdatedAt,
          'isDeleted': remoteData['isDeleted'] ?? 0,
          'isSynced': 1,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
        final localRow = localRows.first;
        final localUpdatedAt = localRow['updatedAt'] as int? ?? 0;
        if (remoteUpdatedAt > localUpdatedAt) {
          await db.update(
            'transactions',
            {
              'title': remoteData['title'],
              'category': remoteData['category'],
              'amount': remoteData['amount'],
              'is_expense': remoteData['is_expense'],
              'date': remoteData['date'],
              'ledgerId': remoteLedgerId,
              'updatedAt': remoteUpdatedAt,
              'isDeleted': remoteData['isDeleted'] ?? 0,
              'isSynced': 1,
            },
            where: 'id = ?',
            whereArgs: [remoteId],
          );
        }
      }
    }

    // 3. PULL SAVINGS GOALS
    final goalSnapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('savings_goals')
        .where('updatedAt', isGreaterThan: lastSyncAt)
        .get();

    for (var doc in goalSnapshot.docs) {
      final remoteData = doc.data();
      final remoteId = doc.id;
      final remoteUpdatedAt = remoteData['updatedAt'] as int? ?? 0;

      final localRows = await db.query('savings_goals', where: 'id = ?', whereArgs: [remoteId]);
      if (localRows.isEmpty) {
        await db.insert('savings_goals', {
          'id': remoteId,
          'uid': uid,
          'name': remoteData['name'],
          'target_amount': remoteData['target_amount'],
          'current_amount': remoteData['current_amount'],
          'deadline': remoteData['deadline'],
          'icon': remoteData['icon'],
          'color': remoteData['color'],
          'is_completed': remoteData['is_completed'],
          'created_at': remoteData['created_at'],
          'updatedAt': remoteUpdatedAt,
          'isDeleted': remoteData['isDeleted'] ?? 0,
          'isSynced': 1,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
        final localRow = localRows.first;
        final localUpdatedAt = localRow['updatedAt'] as int? ?? 0;
        if (remoteUpdatedAt > localUpdatedAt) {
          await db.update(
            'savings_goals',
            {
              'name': remoteData['name'],
              'target_amount': remoteData['target_amount'],
              'current_amount': remoteData['current_amount'],
              'deadline': remoteData['deadline'],
              'icon': remoteData['icon'],
              'color': remoteData['color'],
              'is_completed': remoteData['is_completed'],
              'created_at': remoteData['created_at'],
              'updatedAt': remoteUpdatedAt,
              'isDeleted': remoteData['isDeleted'] ?? 0,
              'isSynced': 1,
            },
            where: 'id = ?',
            whereArgs: [remoteId],
          );
        }
      }
    }

    // 4. PULL BUDGETS (Bảo lưu chính xác ledgerId gốc từ Firestore)
    final budgetSnapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .where('updatedAt', isGreaterThan: lastSyncAt)
        .get();

    for (var doc in budgetSnapshot.docs) {
      final remoteData = doc.data();
      final remoteId = doc.id;
      final remoteUpdatedAt = remoteData['updatedAt'] as int? ?? 0;
      final remoteLedgerId = remoteData['ledgerId'] as String? ?? 'default_$uid';

      final localRows = await db.query('budgets', where: 'id = ?', whereArgs: [remoteId]);
      if (localRows.isEmpty) {
        await db.insert('budgets', {
          'id': remoteId,
          'uid': uid,
          'categoryId': remoteData['categoryId'],
          'amountLimit': remoteData['amountLimit'],
          'month': remoteData['month'],
          'isRecurring': remoteData['isRecurring'] ?? 0,
          'ledgerId': remoteLedgerId,
          'updatedAt': remoteUpdatedAt,
          'isDeleted': remoteData['isDeleted'] ?? 0,
          'isSynced': 1,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
        final localRow = localRows.first;
        final localUpdatedAt = localRow['updatedAt'] as int? ?? 0;
        if (remoteUpdatedAt > localUpdatedAt) {
          await db.update(
            'budgets',
            {
              'categoryId': remoteData['categoryId'],
              'amountLimit': remoteData['amountLimit'],
              'month': remoteData['month'],
              'isRecurring': remoteData['isRecurring'] ?? 0,
              'ledgerId': remoteLedgerId,
              'updatedAt': remoteUpdatedAt,
              'isDeleted': remoteData['isDeleted'] ?? 0,
              'isSynced': 1,
            },
            where: 'id = ?',
            whereArgs: [remoteId],
          );
        }
      }
    }

    await prefs.setInt(lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Dọn dẹp dữ liệu local khi Đăng xuất (KHÔNG XÓA DỮ LIỆU TRÊN CLOUD FIRESTORE)
  Future<void> clearSyncData(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_sync_$uid');
    await prefs.remove('is_initial_sync_done_$uid');
    await prefs.remove('mousey_active_ledger_$uid');

    final db = await DatabaseHelper.instance.database;
    await db.delete('ledgers', where: 'uid = ?', whereArgs: [uid]);
    await db.delete('transactions', where: 'uid = ?', whereArgs: [uid]);
    await db.delete('savings_goals', where: 'uid = ?', whereArgs: [uid]);
    await db.delete('budgets', where: 'uid = ?', whereArgs: [uid]);
  }

  Future<int?> getLastSyncTimestamp(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('last_sync_$uid');
  }
}
