import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';

class SyncService {
  static final SyncService instance = SyncService._init();
  SyncService._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isSyncing = false;

  void stop() {
    _isSyncing = false;
  }

  /// Runs push then pull with mutex flag.
  Future<void> syncAll() async {
    if (_isSyncing) return;
    final user = _auth.currentUser;
    if (user == null) return;

    _isSyncing = true;
    try {
      await pushPending(user.uid);
      await pullChanges(user.uid);
    } catch (e) {
      // Error handling with backoff/retry is handled within operations
    } finally {
      _isSyncing = false;
    }
  }

  /// Pushes local rows where isSynced = 0 to Firestore in batches (max 400).
  Future<void> pushPending(String uid) async {
    final db = await DatabaseHelper.instance.database;

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

    if (pendingTxMaps.isEmpty && pendingGoalMaps.isEmpty && pendingBudgetMaps.isEmpty) return;

    List<Map<String, dynamic>> allPending = [];
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
      WriteBatch batch = _firestore.batch();
      List<String> syncedTxIds = [];
      List<String> syncedGoalIds = [];
      List<String> syncedBudgetIds = [];

      for (var item in chunk) {
        final type = item['_type'] as String;
        final id = item['id'] as String;
        String collectionName = 'transactions';
        if (type == 'goal') {
          collectionName = 'savings_goals';
        } else if (type == 'budget') {
          collectionName = 'budgets';
        }

        final docRef = _firestore
            .collection('users')
            .doc(uid)
            .collection(collectionName)
            .doc(id);

        final firestoreData = Map<String, dynamic>.from(item)..remove('_type');
        batch.set(docRef, firestoreData, SetOptions(merge: true));

        if (type == 'transaction') {
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

  /// Pulls changes from Firestore where updatedAt > lastSyncAt and upserts into SQLite.
  Future<void> pullChanges(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncKey = 'last_sync_$uid';
    final int lastSyncAt = prefs.getInt(lastSyncKey) ?? 0;

    final db = await DatabaseHelper.instance.database;

    // Pull transactions
    final txSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('updatedAt', isGreaterThan: lastSyncAt)
        .get();

    for (var doc in txSnapshot.docs) {
      final remoteData = doc.data();
      final remoteId = doc.id;
      final remoteUpdatedAt = remoteData['updatedAt'] as int? ?? 0;

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

    // Pull savings goals
    final goalSnapshot = await _firestore
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

    // Pull budgets
    final budgetSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('budgets')
        .where('updatedAt', isGreaterThan: lastSyncAt)
        .get();

    for (var doc in budgetSnapshot.docs) {
      final remoteData = doc.data();
      final remoteId = doc.id;
      final remoteUpdatedAt = remoteData['updatedAt'] as int? ?? 0;

      final localRows = await db.query('budgets', where: 'id = ?', whereArgs: [remoteId]);
      if (localRows.isEmpty) {
        await db.insert('budgets', {
          'id': remoteId,
          'uid': uid,
          'categoryId': remoteData['categoryId'],
          'amountLimit': remoteData['amountLimit'],
          'month': remoteData['month'],
          'isRecurring': remoteData['isRecurring'] ?? 0,
          'ledgerId': remoteData['ledgerId'],
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
              'ledgerId': remoteData['ledgerId'],
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

  /// Clears last sync timestamp and local data on logout for the account.
  Future<void> clearSyncData(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_sync_$uid');

    final db = await DatabaseHelper.instance.database;
    await db.delete('transactions', where: 'uid = ?', whereArgs: [uid]);
    await db.delete('savings_goals', where: 'uid = ?', whereArgs: [uid]);
    await db.delete('budgets', where: 'uid = ?', whereArgs: [uid]);
  }

  Future<int?> getLastSyncTimestamp(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('last_sync_$uid');
  }
}
