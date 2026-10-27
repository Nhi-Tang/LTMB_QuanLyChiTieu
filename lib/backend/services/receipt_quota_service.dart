import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pro_service.dart';

/// Nơi lưu bộ đếm lượt chụp trên server, để gỡ app cài lại không lấy lại được lượt.
abstract class ReceiptQuotaRemote {
  /// Số lượt đã dùng trong tháng; null nếu không đọc được (mất mạng...).
  Future<int?> fetch(String uid, String monthId);

  Future<void> increment(String uid, String monthId);
}

/// users/{uid}/receipt_quota/{yyyy_MM}: quy tắc Firestore chỉ cho tăng đúng 1 mỗi lần.
class FirestoreReceiptQuotaRemote implements ReceiptQuotaRemote {
  DocumentReference<Map<String, dynamic>> _doc(String uid, String monthId) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('receipt_quota').doc(monthId);

  @override
  Future<int?> fetch(String uid, String monthId) async {
    try {
      final snap = await _doc(uid, monthId).get().timeout(const Duration(seconds: 4));
      return (snap.data()?['count'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('Không đọc được lượt chụp trên server: $e');
      return null;
    }
  }

  @override
  Future<void> increment(String uid, String monthId) async {
    // Không chờ server xác nhận: mất mạng thì Firestore tự gửi lại khi có mạng
    unawaited(_doc(uid, monthId)
        .set({'count': FieldValue.increment(1), 'updatedAt': DateTime.now().millisecondsSinceEpoch},
            SetOptions(merge: true))
        .catchError((Object e) => debugPrint('Không ghi được lượt chụp lên server: $e')));
  }
}

/// Lượt chụp hoá đơn: tài khoản FREE được [freeMonthlyLimit] lượt mỗi tháng, PRO không giới hạn.
/// Đếm theo từng tài khoản và từng tháng (khoá có năm-tháng), sang tháng mới tự về 0.
/// Lưu cả trên máy (dùng khi mất mạng) và trên server; số đã dùng lấy bên lớn hơn.
class ReceiptQuotaService {
  static const int freeMonthlyLimit = 10;

  static final ReceiptQuotaService instance = ReceiptQuotaService(
    isPro: () => ProService.instance.isPro,
    uid: () => FirebaseAuth.instance.currentUser?.uid,
    remote: FirestoreReceiptQuotaRemote(),
  );

  final bool Function() isPro;
  final String? Function() uid;
  final ReceiptQuotaRemote? remote;
  final DateTime Function() _now;

  ReceiptQuotaService({
    required this.isPro,
    required this.uid,
    this.remote,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  bool get isUnlimited => isPro();

  String get _prefix => 'receipt_scans_${uid() ?? 'guest'}_';

  String get _monthId {
    final now = _now();
    return '${now.year}_${now.month.toString().padLeft(2, '0')}';
  }

  String get _monthKey => '$_prefix$_monthId';

  Future<int> usedThisMonth() async {
    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getInt(_monthKey) ?? 0;
    final id = uid();
    final server = (remote != null && id != null) ? await remote!.fetch(id, _monthId) : null;
    if (server != null && server > local) {
      // Máy mới / vừa cài lại: lấy số trên server
      await prefs.setInt(_monthKey, server);
      return server;
    }
    return local;
  }

  /// Số lượt còn lại trong tháng; null nghĩa là không giới hạn (PRO).
  Future<int?> remaining() async {
    if (isUnlimited) return null;
    final left = freeMonthlyLimit - await usedThisMonth();
    return left < 0 ? 0 : left;
  }

  Future<bool> canScan() async => (await remaining() ?? 1) > 0;

  /// Ghi nhận một lượt chụp đã đọc được hoá đơn (PRO không bị đếm).
  Future<void> recordScan() async {
    if (isUnlimited) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _monthKey;
    // Dọn bộ đếm của các tháng trước
    for (final old in prefs.getKeys().where((k) => k.startsWith(_prefix) && k != key).toList()) {
      await prefs.remove(old);
    }
    await prefs.setInt(key, (prefs.getInt(key) ?? 0) + 1);
    final id = uid();
    if (remote != null && id != null) await remote!.increment(id, _monthId);
  }
}
