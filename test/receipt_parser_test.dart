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
    expect(r.items, ['Trà Olong Sữa (M)']);
    expect(r.note, 'Trà Olong Sữa (M)');
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
    expect(r.note, 'Trà Olong Sữa (h)');
    expect(r.date, DateTime(2026, 10, 3));
  });

  // Chữ trên giaodien/mau_test_2.jpg (hoá đơn Ministop, không có hàng tiêu đề bảng món)
  test('hoá đơn mẫu 2: bỏ mã cửa hàng / Tạm tính, không lấy "sản phẩm" ở chân hoá đơn làm tiêu đề', () {
    final r = ReceiptParser.parse('''
CÔNG TY TNHH MINISTOP VIỆT NAM
96 Cao Thắng, Phường Bàn Cờ, TP.HCM
MST: 0313096162
8104 -  Dai Hoc HUTECH
15A Phan khu E1, KCN Cao, XLHN, P. Tang Nhon Phu
, TP. HCM, VN.
Hoa don Ban hang
28/10/2026  12:11:30
SCU Probi Viet quat  1  12,000  12,000
Tam tinh:  12,000
Tong cong (gom thue):  12,000
Tien mat  20,000
(Tien mat)Tien thua:  -8,000
Ma don:20261028.3.84768  Thu ngan:104559
Khong ap dung tra hang doi voi nhung san pham
tham gia chuong trinh khuyen mai, ruou, bia,
thuoc la va nhung san pham thuc an nhanh da lam
nong (tru cac san pham bi loi tu nha san xuat).
Phieu chi co hieu luc xuat HD trong ngay mua
hang. Cap nhat HDDT tai website sau 24h xuat
Thong tin hoa don do cua ban nhu sau:
Website tra cuu: https://msv-ei.fast.com.vn
Ma tra cuu: 8104328847682610
Ma CQT: M1-26-TGG5R-10437684768
Ministop xin cam on
''');
    expect(r.amount, 12000);
    expect(r.date, DateTime(2026, 10, 28));
    expect(r.items, ['SCU Probi Viet quat']);
    expect(r.note, 'SCU Probi Viet quat');
    expect(r.category, 'Mua sắm');
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

  test('khôi phục dấu tên món bị OCR đọc mất dấu, giữ kiểu viết hoa', () {
    expect(ReceiptParser.restoreMenuAccents('Tra sua tran chau'), 'Trà sữa trân châu');
    expect(ReceiptParser.restoreMenuAccents('CA PHE DEN DA'), 'CÀ PHÊ ĐEN ĐÁ');
    expect(ReceiptParser.restoreMenuAccents('Bac xiu nong'), 'Bạc xỉu nóng');
    // Từ đã có dấu hoặc không có trong từ điển thì giữ nguyên
    expect(ReceiptParser.restoreMenuAccents('Trà Olong Sữa'), 'Trà Olong Sữa');
    expect(ReceiptParser.restoreMenuAccents('Topping Pudding'), 'Topping Pudding');
    expect(ReceiptParser.restoreMenuAccents('Matcha Latte (tL)'), 'Matcha Latte (L)');
  });

  test('ưu tiên ngày trên dòng có chữ "Ngày"', () {
    final r = ReceiptParser.parse('Cửa hàng ABC\nHSD: 01/01/2027\nNgày: 15/10/2026\nTổng tiền: 50.000');
    expect(r.date, DateTime(2026, 10, 15));
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
