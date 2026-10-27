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

  // Chữ ML Kit đọc thật từ giaodien/mau_test.jpg (có lỗi OCR)
  const mauTest = '''
HÓA ĐƠN THANH rOÁN
So HÐ: 040529
Mã HÐ: #EBHGE  TN NGAN LH
Bàn: THỂ 14-THE
Giờ vào: : 1344  Ngay: 0310/2026
Giċ ta: i344
STT  Ten món  SLDon giá Thành tien
Trà Olong Sua (tM) 16000  60,000
Thanh tien:  60,000 d
Tông tien:  60,000 d
+Thanh toan tiên mat  60,000 d
Tien nhan  100000 d
Tien thƯa  40 000 d
Hoậc sú dụng QR ben dud
''';

  test('hoá đơn mẫu: tổng tiền, tên món làm ghi chú, ngày mất dấu /', () {
    final r = ReceiptParser.parse(mauTest);
    expect(r.amount, 60000);
    expect(r.merchant, isNull);
    expect(r.items, ['Trà Olong Sua (tM)']);
    expect(r.note, 'Trà Olong Sua (tM)');
    expect(r.date, DateTime(2026, 10, 3));
    expect(r.category, 'Trà sữa');
  });

  test('chữ ML Kit đọc từ ảnh mẫu xoay nghiêng 6°', () {
    final r = ReceiptParser.parse('''
51
HỎA ĐƠN THANH TOÁN
So HÐ: 040529
Mả HÐ: #EBHGE  TH I) NGAN LitH
Bàn: THE 14- THẾ  TRURG
Giờ vào: : 13.44  Ngay: 03'10/2026
Gič ta: 1344
STT  Ten món  SLiDor giá Thành tien
1  Trà Olong Sua (h)  1 66000  60,000
Thanh tien:  60,000 d
Tõng tien:  60,000 d
+Thanh toan tiên mat  60,000 d
Tien nhan  100000 d
TIen thưa  40 000 d
''');
    expect(r.amount, 60000);
    expect(r.merchant, isNull);
    expect(r.note, 'Trà Olong Sua (h)');
    expect(r.date, DateTime(2026, 10, 3));
  });

  test('ảnh nghiêng làm dòng ghép lệch: vẫn lấy số sau nhãn tổng, bỏ tiền mặt / tiền nhận', () {
    const text = '''
HÓA ĐƠN THANH TOÁN
STT  Tên món  SL  Đơn giá  Thành tiền
1  Trà Olong Sữa (M)  1
60,000  60,000
Tóng tiến:  +Thanh toán tiền mặt  60,000 đ
Tiền nhận  100,000 đ  60,000 đ
Tiền thừa  40,000 đ
''';
    final r = ReceiptParser.parse(text);
    expect(r.amount, 60000);
    expect(r.items, ['Trà Olong Sữa (M)']);
  });

  test('ghi chú là tên món, bỏ STT / SL / giá; không có món thì dùng tên quán', () {
    final r = ReceiptParser.parse('''
Quán cà phê Ba Miền
Ngày: 27/10/2026
1  Bạc xỉu  x2  58.000
2  Bánh mì  1  20.000
Tổng thanh toán: 78.000
''');
    expect(r.items, ['Bạc xỉu', 'Bánh mì']);
    expect(r.note, 'Bạc xỉu, Bánh mì');
    expect(ReceiptParser.parse('Quán cà phê Ba Miền\nTotal 38.000').note, 'Quán cà phê Ba Miền');
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
