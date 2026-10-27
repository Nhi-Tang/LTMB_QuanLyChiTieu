import 'package:flutter_test/flutter_test.dart';
import 'package:quanlychitieu/core/utils/account_masker.dart';
import 'package:quanlychitieu/backend/models/pending_transaction_model.dart';
import 'package:quanlychitieu/backend/services/bank_parser/bank_notification_parser.dart';

void main() {
  group('BankNotificationParser Tests', () {
    test('Account masking helper removes 8-19 digit account numbers', () {
      expect(maskAccountNumbers('Số dư TK VCB 1039165413 lúc 17:30'), equals('Số dư TK VCB ••••5413 lúc 17:30'));
      expect(maskAccountNumbers('Chuyen tien cho TK 19031234567890 tai VCB'), equals('Chuyen tien cho TK ••••7890 tai VCB'));
      // Ensure amounts with commas or dots are NOT masked
      expect(maskAccountNumbers('So du: 1,102,600 VND'), equals('So du: 1,102,600 VND'));
      expect(maskAccountNumbers('So du: 1.102.600 đ'), equals('So du: 1.102.600 đ'));
    });

    test('VCB Real Sample Privacy Verification', () {
      const text = 'Số dư TK VCB 1039165413 -50,000VND lúc 17:30. Số dư 1,102,600VND. Ref: Mua do an tai Highlands Coffee';
      final result = BankNotificationParser.parseNotification(
        packageName: 'com.VCB',
        title: 'Vietcombank',
        text: text,
      );

      expect(result, isNotNull);
      expect(result!.accountLast4, '5413');
      expect(result.amount, 50000);
      expect(result.description, contains('Highlands Coffee'));
      expect(result.description, isNot(contains('1039165413')));
      expect(result.description, isNot(contains('1,102,600')));
      expect(RegExp(r'\d{8,}').hasMatch(result.description), isFalse);
    });

    test('MB Real Sample Privacy Verification', () {
      const text = 'xxx005|GD: -150,000VND|SD: 438,037VND|DEN: TANG NGUYEN PHUONG';
      final result = BankNotificationParser.parseNotification(
        packageName: 'com.mbmobile',
        title: 'MB Bank',
        text: text,
      );

      expect(result, isNotNull);
      expect(result!.accountLast4, '0005');
      expect(result.amount, 150000);
      expect(result.description, contains('TANG NGUYEN PHUONG'));
      expect(result.description, isNot(contains('438,037')));
      expect(RegExp(r'\d{8,}').hasMatch(result.description), isFalse);
    });

    test('Parse Techcombank expense notification', () {
      const text = 'TCB: TK 19031234567890 GD: -50,000VND. So du 1,200,000VND. Noi dung: Thanh toan tien gui xe';
      final result = BankNotificationParser.parseNotification(
        packageName: 'vn.com.techcombank.bb.app',
        title: 'Techcombank',
        text: text,
      );

      expect(result, isNotNull);
      expect(result!.bankName, 'Techcombank');
      expect(result.type, 'expense');
      expect(result.amount, 50000);
      expect(result.accountLast4, '7890');
      expect(result.description, isNot(contains('19031234567890')));
    });

    test('Parse MoMo notification', () {
      const text = 'Thanh toán thành công 85.000đ cho Circle K. Mã GD 12345678';
      final result = BankNotificationParser.parseNotification(
        packageName: 'com.mservice.momopay',
        title: 'MoMo',
        text: text,
      );

      expect(result, isNotNull);
      expect(result!.bankName, 'MoMo');
      expect(result.type, 'expense');
      expect(result.amount, 85000);
    });

    test('Parse MoMo money receive notification', () {
      const text = 'Bạn đã nhận được 2.000.000đ từ Nguyen Van A lúc 12:30. Số dư ví 5.000.000đ';
      final result = BankNotificationParser.parseNotification(
        packageName: 'com.mservice.momopay',
        title: 'MoMo',
        text: text,
      );

      expect(result, isNotNull);
      expect(result!.bankName, 'MoMo');
      expect(result.type, 'income');
      expect(result.amount, 2000000);
    });

    test('Parse MoMo receive notification variant', () {
      const text = 'Quý khách đã nhận được 500.000đ từ TRAN VAN C. Nguồn: Ví MoMo';
      final result = BankNotificationParser.parseNotification(
        packageName: 'com.mservice.momopay',
        title: 'MoMo',
        text: text,
      );

      expect(result, isNotNull);
      expect(result!.bankName, 'MoMo');
      expect(result.type, 'income');
      expect(result.amount, 500000);
    });

    test('Filter non-transactions like OTP', () {
      const text = 'Ma xac thuc OTP la 123456. Khong chia se ma nay cho bat ky ai.';
      final result = BankNotificationParser.parseNotification(
        packageName: 'com.VCB',
        title: 'Mã xác thực OTP',
        text: text,
      );

      expect(result, isNull);
    });

    test('"Cảnh báo biến động số dư" là giao dịch thật, không bị lọc', () {
      final result = BankNotificationParser.parseNotification(
        packageName: 'com.vietinbank.ipay',
        title: 'Cảnh báo biến động số dư',
        text: 'TK 1012345678 -150,000VND luc 27-10-2026 08:15. So du 2,350,000VND. ND: THANH TOAN GRAB',
      );
      expect(result, isNotNull);
      expect(result!.amount, 150000);
      expect(result.type, 'expense');
    });

    test('Cảnh báo bảo mật không có biến động số dư thì vẫn bị lọc', () {
      expect(
        BankNotificationParser.isNonTransaction(
            'Cảnh báo', 'Tài khoản của bạn vừa đăng nhập trên thiết bị mới. Nếu không phải bạn, hãy liên hệ ngân hàng.'),
        isTrue,
      );
      expect(
        BankNotificationParser.parseNotification(
          packageName: 'com.VCB',
          title: 'Canh bao lua dao',
          text: 'Khong cung cap thong tin the cho bat ky ai.',
        ),
        isNull,
      );
    });

    test('Chỉ nhận ACB khi "acb" đứng thành từ riêng', () {
      final acb = BankNotificationParser.parseNotification(
        packageName: 'mobile.acb.com.vn',
        title: 'ACB',
        text: 'ACB: TK 12345678 +2,000,000 VND luc 27/10. So du 5,000,000 VND. ND: LUONG T10',
      );
      expect(acb, isNotNull);
      expect(acb!.bankName, 'ACB');
      expect(acb.type, 'income');
      expect(acb.amount, 2000000);

      final other = BankNotificationParser.parseNotification(
        packageName: 'com.example.wallet',
        title: 'Biến động số dư',
        text: 'TK 98765432 -45,000 VND. ND: Thanh toan don ACBD9X21',
      );
      expect(other, isNotNull);
      expect(other!.bankName, isNot('ACB'));
      expect(other.amount, 45000);
    });

    test('Fingerprint generation consistency within 10-minute window', () {
      final now = DateTime(2023, 5, 12, 10, 5, 0);
      final sameWindow = DateTime(2023, 5, 12, 10, 8, 0);
      final nextWindow = DateTime(2023, 5, 12, 10, 18, 0);

      final fp1 = BankNotificationParser.generateFingerprint(
        bankName: 'Vietcombank',
        amount: 100000,
        type: 'expense',
        timestamp: now,
        accountLast4: '1234',
      );

      final fp2 = BankNotificationParser.generateFingerprint(
        bankName: 'Vietcombank',
        amount: 100000,
        type: 'expense',
        timestamp: sameWindow,
        accountLast4: '1234',
      );

      final fp3 = BankNotificationParser.generateFingerprint(
        bankName: 'Vietcombank',
        amount: 100000,
        type: 'expense',
        timestamp: nextWindow,
        accountLast4: '1234',
      );

      expect(fp1, equals(fp2));
      expect(fp1, isNot(equals(fp3)));
    });

    test('PendingTransactionModel serialization', () {
      final item = PendingTransactionModel(
        id: 'test-uuid-123',
        uid: 'user-456',
        type: 'expense',
        amount: 150000,
        bankName: 'Vietcombank',
        accountLast4: '1234',
        description: 'Thanh toan Highlands Coffee',
        occurredAt: '2023-05-12T10:00:00.000',
        fingerprint: 'fp-789',
        status: 'pending',
        suggestedCategoryId: 'Ăn uống',
        suggestionConfidence: 'high',
        createdAt: '2023-05-12T10:00:00.000',
      );

      final map = item.toMap();
      expect(map['id'], 'test-uuid-123');
      expect(map['amount'], 150000);
      expect(map['bankName'], 'Vietcombank');

      final restored = PendingTransactionModel.fromMap(map);
      expect(restored.id, item.id);
      expect(restored.amount, item.amount);
      expect(restored.bankName, item.bankName);
      expect(restored.suggestionConfidence, 'high');
    });
  });
}
