import 'package:flutter_test/flutter_test.dart';
import 'package:quanlychitieu/backend/services/bank_parser/bank_notification_parser.dart';

void main() {
  test('ZaloPay exact text parse test', () {
    const text = 'Nhận 2.000đ qua chuyển khoản từ NGUYEN VAN B';
    final result = BankNotificationParser.parseNotification(
      packageName: 'vn.com.vng.zalopay',
      title: 'ZaloPay',
      text: text,
    );
    expect(result, isNotNull);
    expect(result!.bankName, 'ZaloPay');
    expect(result.type, 'income');
    expect(result.amount, 2000);
  });

  test('ZaloPay expense exact text parse test', () {
    const text = 'Bạn đã chuyển 5.000đ cho NGUYEN VAN A';
    final result = BankNotificationParser.parseNotification(
      packageName: 'vn.com.vng.zalopay',
      title: 'ZaloPay',
      text: text,
    );
    expect(result, isNotNull);
    expect(result!.bankName, 'ZaloPay');
    expect(result.type, 'expense');
    expect(result.amount, 5000);
  });

  test('ZaloPay - MB Transfer integration test', () {
    const mbExpenseText = 'TK 11xxx005|GD: -5,000VND 20/10/26 15:11 |SD: 320,696VND|DEN: ZALOPAY - 99ZP26293M••••|ND: MBCT NGUYEN VAN A chuyen tien DLLS65FN/420842';
    
    final mbResult = BankNotificationParser.parseNotification(
      packageName: 'com.mbmobile',
      title: 'MB Bank',
      text: mbExpenseText,
    );

    expect(mbResult, isNotNull);
    expect(mbResult!.bankName, 'MB Bank');
    expect(mbResult.type, 'expense');
    expect(mbResult.amount, 5000);
    expect(mbResult.description, contains('MB Bank → ZaloPay'));
    expect(mbResult.description, isNot(contains('NGUYEN VAN A')));
    expect(mbResult.description, contains('***')); // Tên bị che
  });

  test('MoMo - MB Transfer integration test', () {
    const mbExpenseText = 'TK 11xxx005|GD: -10,000VND 20/10/26 15:11 |SD: 320,696VND|DEN: MOMO - 0912345678|ND: MBCT NGUYEN VAN A chuyen tien DLLS65FN/420842';
    
    final mbResult = BankNotificationParser.parseNotification(
      packageName: 'com.mbmobile',
      title: 'MB Bank',
      text: mbExpenseText,
    );

    expect(mbResult, isNotNull);
    expect(mbResult!.bankName, 'MB Bank');
    expect(mbResult.type, 'expense');
    expect(mbResult.amount, 10000);
    expect(mbResult.description, contains('MB Bank → MoMo'));
    expect(mbResult.description, isNot(contains('NGUYEN VAN A')));
    expect(mbResult.description, contains('***')); // Tên bị che
  });
}
