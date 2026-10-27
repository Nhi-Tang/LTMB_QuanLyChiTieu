import 'package:flutter_test/flutter_test.dart';
import 'package:quanlychitieu/core/utils/receipt_parser.dart';

void main() {
  test('hoá đơn quán cà phê: tổng thanh toán, tên quán, ngày, danh mục', () {
    const text = '''
Quán cà phê Ba Miền
ĐC: 12 Nguyễn Huệ, Q.1
ĐT: 0901234567
HOÁ ĐƠN THANH TOÁN
Ngày: 27/10/2026 08:15
Bạc xỉu        2   58.000
Bánh mì        1   20.000
Tổng tiền hàng:    78.000
Giảm giá:          40.000
Tổng thanh toán:   38.000
Tiền khách đưa:   100.000
Tiền thừa:         62.000
''';
    final r = ReceiptParser.parse(text);
    expect(r.amount, 38000);
    expect(r.merchant, 'Quán cà phê Ba Miền');
    expect(r.date, DateTime(2026, 10, 27));
    expect(r.category, 'Cà phê');
  });

  test('số tiền nằm ở dòng dưới nhãn TỔNG CỘNG, có phần lẻ ,00', () {
    const text = '''
WINMART+ 45 LE LOI
Mã HĐ: 000123456789012
Sữa tươi           32.500,00
Mì gói             12.000,00
TỔNG CỘNG
44.500,00
Tiền mặt           50.000,00
''';
    final r = ReceiptParser.parse(text);
    expect(r.amount, 44500);
    expect(r.merchant, 'WINMART+ 45 LE LOI');
    expect(r.category, 'Mua sắm');
  });

  test('không có nhãn tổng: lấy số lớn nhất, bỏ ngày và tiền khách đưa', () {
    const text = '''
Trà sữa Tocotoco
05-11-26
Trà sữa trân châu 45,000
Topping 10,000
55,000
Khách đưa 100,000
''';
    final r = ReceiptParser.parse(text);
    expect(r.amount, 55000);
    expect(r.date, DateTime(2026, 11, 5));
    expect(r.category, 'Trà sữa');
  });

  test('chữ không phải hoá đơn: các trường để trống', () {
    final r = ReceiptParser.parse('xin chao\n');
    expect(r.amount, isNull);
    expect(r.date, isNull);
    expect(r.category, isNull);
  });

  test('bỏ qua số điện thoại / mã dài và ngày không có thật', () {
    expect(ReceiptParser.moneyValues('Hotline 19001234 ma 0123456789012'), [19001234]);
    final r = ReceiptParser.parse('Cửa hàng ABC\n31/02/2026\nTotal 120.000');
    expect(r.date, isNull);
    expect(r.amount, 120000);
  });
}
