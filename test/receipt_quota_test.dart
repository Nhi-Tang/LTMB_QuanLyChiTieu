import 'package:flutter_test/flutter_test.dart';
import 'package:quanlychitieu/backend/services/receipt_quota_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ReceiptQuotaService quota({bool pro = false, String uid = 'u1', required DateTime Function() now}) =>
      ReceiptQuotaService(isPro: () => pro, uid: () => uid, now: now);

  test('tài khoản FREE: 10 lượt mỗi tháng, hết lượt thì không chụp được', () async {
    final q = quota(now: () => DateTime(2026, 10, 27));
    expect(await q.remaining(), 10);
    for (var i = 0; i < 10; i++) {
      expect(await q.canScan(), isTrue);
      await q.recordScan();
    }
    expect(await q.remaining(), 0);
    expect(await q.canScan(), isFalse);
  });

  test('sang tháng mới thì reset về 10 lượt', () async {
    var now = DateTime(2026, 10, 31);
    final q = quota(now: () => now);
    for (var i = 0; i < 10; i++) {
      await q.recordScan();
    }
    expect(await q.canScan(), isFalse);

    now = DateTime(2026, 11, 1);
    expect(await q.remaining(), 10);
    await q.recordScan();
    expect(await q.remaining(), 9);
    // Bộ đếm tháng cũ đã được dọn
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().where((k) => k.startsWith('receipt_scans_u1_')), ['receipt_scans_u1_2026_11']);
  });

  test('PRO chụp không giới hạn và không bị đếm', () async {
    final q = quota(pro: true, now: () => DateTime(2026, 10, 27));
    for (var i = 0; i < 15; i++) {
      await q.recordScan();
    }
    expect(await q.remaining(), isNull);
    expect(await q.canScan(), isTrue);
    expect(await q.usedThisMonth(), 0);
  });

  test('mỗi tài khoản có bộ đếm riêng', () async {
    final now = DateTime(2026, 10, 27);
    final a = quota(uid: 'a', now: () => now);
    final b = quota(uid: 'b', now: () => now);
    for (var i = 0; i < 10; i++) {
      await a.recordScan();
    }
    expect(await a.canScan(), isFalse);
    expect(await b.remaining(), 10);
  });
}
