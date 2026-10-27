import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pro_service.dart';

/// Lượt chụp hoá đơn: tài khoản FREE được [freeMonthlyLimit] lượt mỗi tháng, PRO không giới hạn.
/// Đếm theo từng tài khoản và từng tháng (khoá có năm-tháng), sang tháng mới tự về 0.
class ReceiptQuotaService {
  static const int freeMonthlyLimit = 10;

  static final ReceiptQuotaService instance = ReceiptQuotaService(
    isPro: () => ProService.instance.isPro,
    uid: () => FirebaseAuth.instance.currentUser?.uid,
  );

  final bool Function() isPro;
  final String? Function() uid;
  final DateTime Function() _now;

  ReceiptQuotaService({
    required this.isPro,
    required this.uid,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  bool get isUnlimited => isPro();

  String get _prefix => 'receipt_scans_${uid() ?? 'guest'}_';

  String get _monthKey {
    final now = _now();
    return '$_prefix${now.year}_${now.month.toString().padLeft(2, '0')}';
  }

  Future<int> usedThisMonth() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_monthKey) ?? 0;
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
  }
}
