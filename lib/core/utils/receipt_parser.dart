import '../../backend/models/category_model.dart';

/// Thông tin đọc được từ ảnh hoá đơn. Mọi trường đều có thể thiếu,
/// người dùng sẽ kiểm tra và sửa lại trước khi lưu.
class ReceiptData {
  final double? amount;
  final String? merchant;
  final DateTime? date;
  final String? category;
  final String rawText;

  const ReceiptData({
    this.amount,
    this.merchant,
    this.date,
    this.category,
    this.rawText = '',
  });
}

/// Tách số tiền tổng, tên cửa hàng, ngày và đoán danh mục từ chữ OCR của hoá đơn.
class ReceiptParser {
  ReceiptParser._();

  /// Từ khoá dòng tổng tiền, xếp theo độ ưu tiên (đã bỏ dấu, chữ thường).
  /// "Tổng thanh toán" là số sau giảm giá nên đứng trước "Tổng tiền hàng".
  static const List<List<String>> _totalKeywords = [
    ['tong thanh toan', 'can thanh toan', 'khach can tra', 'khach phai tra', 'phai thanh toan', 'grand total'],
    ['tong cong', 'tong tien', 'thanh tien', 'total', 'amount due'],
    ['thanh toan', 'tong'],
  ];

  /// Dòng tiền khách đưa / tiền thừa / giảm giá: không phải số cần ghi.
  static const List<String> _ignoreKeywords = [
    'tien mat', 'tien khach', 'khach dua', 'tra lai', 'tien thua', 'tien thoi',
    'cash', 'change', 'giam gia', 'chiet khau', 'discount', 'tien thue', 'thue gtgt',
  ];

  /// Dòng đầu hoá đơn không phải tên cửa hàng.
  static const List<String> _notMerchantKeywords = [
    'hoa don', 'phieu', 'bien lai', 'dia chi', 'dc:', 'd/c', 'dt:', 'sdt', 'tel', 'hotline',
    'mst', 'ma so thue', 'www', 'http', '.com', '.vn', 'receipt', 'invoice', 'ngay', 'gio',
    'so:', 'ban:', 'thu ngan', 'nhan vien', 'wifi', 'pass',
  ];

  /// Đoán danh mục theo từ khoá; xét tên cửa hàng trước rồi đến toàn bộ hoá đơn.
  static const List<MapEntry<String, List<String>>> _categoryKeywords = [
    MapEntry('Trà sữa', ['tra sua', 'milk tea', 'tocotoco', 'gong cha', 'koi the', 'phuc long', 'tran chau', 'boba']),
    MapEntry('Cà phê', ['ca phe', 'cafe', 'coffee', 'highlands', 'starbucks', 'trung nguyen', 'cong caphe', 'katinat', 'bac xiu', 'espresso', 'latte']),
    MapEntry('Di chuyển', ['grab', 'xanh sm', 'taxi', 'xang', 'petrolimex', 'gui xe', 've xe', 'parking']),
    MapEntry('Hóa đơn', ['dien luc', 'evn', 'tien dien', 'tien nuoc', 'cap nuoc', 'internet', 'vnpt', 'cuoc', 'truyen hinh']),
    MapEntry('Sức khoẻ', ['nha thuoc', 'pharmacy', 'long chau', 'pharmacity', 'benh vien', 'phong kham', 'thuoc']),
    MapEntry('Mua sắm', ['sieu thi', 'winmart', 'coopmart', 'co.op', 'bach hoa xanh', 'lotte mart', 'aeon', 'circle k', 'gs25', '7-eleven', 'familymart', 'ministop', 'shopee', 'lazada']),
    MapEntry('Ăn uống', ['nha hang', 'quan an', 'restaurant', 'com ', 'pho', 'bun', 'banh mi', 'lau', 'nuong', 'kfc', 'lotteria', 'jollibee', 'pizza', 'mcdonald']),
  ];

  static final RegExp _moneyPattern = RegExp(r'\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?|\d{4,}');
  static final RegExp _datePattern = RegExp(r'(\d{1,2})\s*[/\-.]\s*(\d{1,2})\s*[/\-.]\s*(\d{4}|\d{2})');

  static ReceiptData parse(String text) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final merchant = _findMerchant(lines);
    return ReceiptData(
      amount: _findAmount(lines),
      merchant: merchant,
      date: _findDate(lines),
      category: guessCategory(text, merchant: merchant),
      rawText: text,
    );
  }

  /// Số tiền trong một chuỗi; bỏ phần lẻ ",00" / ".00" và các số quá lớn (mã số, số điện thoại).
  static List<double> moneyValues(String line) {
    final values = <double>[];
    for (final m in _moneyPattern.allMatches(line)) {
      var raw = m.group(0)!;
      // Phần thập phân 1-2 chữ số ở cuối (vd 38.000,00) không tính vào số đồng
      raw = raw.replaceFirst(RegExp(r'[.,]\d{1,2}$'), '');
      final digits = raw.replaceAll(RegExp(r'[.,]'), '');
      // Số liền không phân cách dài > 9 chữ số thường là mã đơn / số điện thoại
      if (!m.group(0)!.contains(RegExp(r'[.,]')) && digits.length > 9) continue;
      final value = double.tryParse(digits);
      if (value != null && value > 0 && value < 1e10) values.add(value);
    }
    return values;
  }

  static double? _findAmount(List<String> lines) {
    final keys = lines.map(CategoryModel.normalizeKey).toList();
    bool ignored(int i) => _ignoreKeywords.any(keys[i].contains);

    for (final level in _totalKeywords) {
      double? found;
      for (var i = 0; i < lines.length; i++) {
        if (ignored(i) || !level.any(keys[i].contains)) continue;
        var values = moneyValues(lines[i]);
        // Số tiền hay nằm ở dòng ngay dưới nhãn "Tổng cộng"
        if (values.isEmpty && i + 1 < lines.length && !ignored(i + 1)) {
          values = moneyValues(lines[i + 1]);
        }
        // Lấy dòng cuối cùng khớp: tổng cuối hoá đơn
        if (values.isNotEmpty) found = values.last;
      }
      if (found != null) return found;
    }

    // Không có nhãn tổng: lấy số lớn nhất không thuộc dòng tiền khách đưa / ngày
    double? best;
    for (var i = 0; i < lines.length; i++) {
      if (ignored(i)) continue;
      final withoutDates = lines[i].replaceAll(_datePattern, ' ');
      for (final v in moneyValues(withoutDates)) {
        if (best == null || v > best) best = v;
      }
    }
    return best;
  }

  static String? _findMerchant(List<String> lines) {
    for (final line in lines.take(6)) {
      final key = CategoryModel.normalizeKey(line);
      if (_notMerchantKeywords.any(key.contains)) continue;
      final letters = RegExp(r'\p{L}', unicode: true).allMatches(line).length;
      if (letters < 3 || letters < line.replaceAll(' ', '').length / 2) continue;
      return line;
    }
    return null;
  }

  static DateTime? _findDate(List<String> lines) {
    for (final line in lines) {
      for (final m in _datePattern.allMatches(line)) {
        final day = int.parse(m.group(1)!);
        final month = int.parse(m.group(2)!);
        var year = int.parse(m.group(3)!);
        if (year < 100) year += 2000;
        if (day < 1 || day > 31 || month < 1 || month > 12 || year < 2000 || year > 2100) continue;
        final date = DateTime(year, month, day);
        // Loại ngày không có thật (vd 31/02)
        if (date.month != month) continue;
        return date;
      }
    }
    return null;
  }

  static String? guessCategory(String text, {String? merchant}) {
    final sources = [
      if (merchant != null) CategoryModel.normalizeKey(merchant),
      CategoryModel.normalizeKey(text.replaceAll(RegExp(r'[\r\n]+'), ' ')),
    ];
    for (final source in sources) {
      for (final entry in _categoryKeywords) {
        if (entry.value.any(source.contains)) return entry.key;
      }
    }
    return null;
  }
}
