import '../../backend/models/category_model.dart';

/// Thông tin đọc được từ ảnh hoá đơn. Mọi trường đều có thể thiếu,
/// người dùng sẽ kiểm tra và sửa lại trước khi lưu.
class ReceiptData {
  final double? amount;
  final String? merchant;
  final DateTime? date;
  final String? category;
  final List<String> items;
  final String rawText;

  const ReceiptData({
    this.amount,
    this.merchant,
    this.date,
    this.category,
    this.items = const [],
    this.rawText = '',
  });

  /// Ghi chú gợi ý: tên món / sản phẩm, không có thì dùng tên cửa hàng.
  String? get note {
    if (items.isEmpty) return merchant;
    final shown = items.take(3).join(', ');
    return items.length > 3 ? '$shown…' : shown;
  }
}

/// Tách số tiền tổng, tên cửa hàng, ngày, tên món và đoán danh mục từ chữ OCR của hoá đơn.
/// Chữ OCR hay sai dấu / sai một ký tự nên so khớp từ khoá theo kiểu gần đúng.
class ReceiptParser {
  ReceiptParser._();

  /// Từ khoá dòng tổng tiền, xếp theo độ ưu tiên (đã bỏ dấu, chữ thường).
  /// "Tổng thanh toán" là số sau giảm giá nên đứng trước "Tổng tiền hàng".
  static const List<List<String>> _totalKeywords = [
    ['tong thanh toan', 'can thanh toan', 'khach can tra', 'khach phai tra', 'phai thanh toan', 'grand total'],
    ['tong cong', 'tong tien', 'thanh tien', 'total', 'amount due'],
    ['thanh toan', 'tong'],
  ];

  /// Tiền khách đưa / tiền thừa / giảm giá: số đứng sau các nhãn này không phải số cần ghi.
  static const List<String> _ignoreKeywords = [
    'tien mat', 'tien khach', 'khach dua', 'tien nhan', 'tra lai', 'tien thua', 'tien thoi',
    'cash', 'change', 'giam gia', 'chiet khau', 'discount', 'tien thue', 'thue gtgt',
  ];

  /// Dòng thông tin hoá đơn (mã, bàn, thu ngân, liên hệ...): không phải tên quán / tên món.
  static const List<String> _metaKeywords = [
    'hoa don', 'phieu', 'bien lai', 'dia chi', 'dc', 'dt', 'sdt', 'tel', 'hotline',
    'mst', 'ma so thue', 'www', 'http', 'receipt', 'invoice', 'ngay', 'gio vao', 'gio ra',
    'thoi gian', 'so hd', 'ma hd', 'ban', 'tn', 'thu ngan', 'nhan vien', 'wifi', 'pass', 'stt',
  ];

  /// Tiêu đề hoá đơn ("HOÁ ĐƠN THANH TOÁN") không phải dòng tổng tiền.
  static const List<String> _titleKeywords = ['hoa don', 'phieu', 'bien lai'];

  /// Hàng tiêu đề bảng món.
  static const List<String> _itemHeaderKeywords = [
    'ten mon', 'ten hang', 'san pham', 'mat hang', 'dien giai', 'ten sp', 'don gia',
  ];

  /// Đoán danh mục theo từ khoá; xét tên cửa hàng, rồi tên món, rồi toàn bộ hoá đơn.
  static const List<MapEntry<String, List<String>>> _categoryKeywords = [
    MapEntry('Trà sữa', ['tra sua', 'milk tea', 'tocotoco', 'gong cha', 'koi the', 'phuc long', 'tran chau', 'boba', 'olong', 'oolong', 'matcha', 'tra dao', 'tra vai', 'hong tra', 'luc tra']),
    MapEntry('Cà phê', ['ca phe', 'cafe', 'coffee', 'highlands', 'starbucks', 'trung nguyen', 'cong caphe', 'katinat', 'bac xiu', 'espresso', 'latte']),
    MapEntry('Di chuyển', ['grab', 'xanh sm', 'taxi', 'xang', 'petrolimex', 'gui xe', 've xe', 'parking']),
    MapEntry('Hóa đơn', ['dien luc', 'evn', 'tien dien', 'tien nuoc', 'cap nuoc', 'internet', 'vnpt', 'cuoc', 'truyen hinh']),
    MapEntry('Sức khoẻ', ['nha thuoc', 'pharmacy', 'long chau', 'pharmacity', 'benh vien', 'phong kham', 'thuoc']),
    MapEntry('Mua sắm', ['sieu thi', 'winmart', 'coopmart', 'co.op', 'bach hoa xanh', 'lotte mart', 'aeon', 'circle k', 'gs25', '7-eleven', 'familymart', 'ministop', 'shopee', 'lazada']),
    MapEntry('Ăn uống', ['nha hang', 'quan an', 'restaurant', 'com ', 'pho', 'bun', 'banh mi', 'lau', 'nuong', 'kfc', 'lotteria', 'jollibee', 'pizza', 'mcdonald']),
  ];

  static final RegExp _moneyPattern = RegExp(r'\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?|\d{4,}');
  // OCR hay làm mất dấu "/" giữa ngày và tháng (03/10/2026 → 0310/2026)
  static final RegExp _datePattern =
      RegExp(r"(?<!\d)(?:(\d{1,2})\s*[/\-.']\s*(\d{1,2})|(\d{2})(\d{2}))\s*[/\-.']\s*(\d{4}|\d{2})(?!\d)");
  static final RegExp _word = RegExp(r'[a-z0-9]+');
  static final RegExp _letter = RegExp(r'\p{L}', unicode: true);

  static ReceiptData parse(String text) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final keys = lines.map(CategoryModel.normalizeKey).toList();
    final header = _itemHeaderIndex(keys);
    final merchant = _findMerchant(lines, keys, header);
    final items = _findItems(lines, keys, header);
    return ReceiptData(
      amount: _findAmount(keys),
      merchant: merchant,
      date: _findDate(lines),
      category: guessCategory(text, merchant: merchant, items: items),
      items: items,
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

  /// Khoảng cách sửa chữ (Levenshtein) giữa hai từ ngắn.
  static int _editDistance(String a, String b) {
    var prev = List<int>.generate(b.length + 1, (j) => j);
    for (var i = 1; i <= a.length; i++) {
      final cur = [i, ...List.filled(b.length, 0)];
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        cur[j] = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost].reduce((x, y) => x < y ? x : y);
      }
      prev = cur;
    }
    return prev[b.length];
  }

  /// Tìm cụm từ khoá trong dòng đã bỏ dấu, chịu sai 1 ký tự mỗi từ (từ ≥ 4 chữ, cụm ≥ 2 từ).
  /// Trả về (vị trí bắt đầu, vị trí kết thúc) của lần khớp đầu tiên, null nếu không có.
  static (int, int)? _match(String key, String phrase) {
    final words = _word.allMatches(key).toList();
    final target = phrase.split(' ');
    for (var i = 0; i + target.length <= words.length; i++) {
      var ok = true;
      for (var j = 0; j < target.length && ok; j++) {
        final w = words[i + j].group(0)!;
        final t = target[j];
        ok = w == t || (target.length > 1 && t.length >= 4 && _editDistance(w, t) <= 1);
      }
      if (ok) return (words[i].start, words[i + target.length - 1].end);
    }
    return null;
  }

  static bool _hasAny(String key, List<String> phrases) => phrases.any((p) => _match(key, p) != null);

  /// Vị trí sớm nhất của một nhãn tiền khách đưa / tiền thừa... trong đoạn, -1 nếu không có.
  static int _firstIgnore(String segment) {
    var first = -1;
    for (final p in _ignoreKeywords) {
      final m = _match(segment, p);
      if (m != null && (first < 0 || m.$1 < first)) first = m.$1;
    }
    return first;
  }

  static double? _findAmount(List<String> keys) {
    for (final level in _totalKeywords) {
      double? found;
      for (var i = 0; i < keys.length; i++) {
        if (_hasAny(keys[i], _titleKeywords)) continue;
        for (final phrase in level) {
          final m = _match(keys[i], phrase);
          if (m == null) continue;
          // Chỉ lấy số đứng sau nhãn, dừng ở nhãn "tiền mặt / tiền nhận..." nếu dòng bị ghép chung
          var segment = keys[i].substring(m.$2);
          final cut = _firstIgnore(segment);
          if (cut >= 0) segment = segment.substring(0, cut);
          var values = moneyValues(segment);
          // Số tiền hay nằm ở dòng ngay dưới nhãn "Tổng cộng"
          if (values.isEmpty && cut < 0 && i + 1 < keys.length && _firstIgnore(keys[i + 1]) < 0) {
            values = moneyValues(keys[i + 1].replaceAll(_datePattern, ' '));
          }
          // Lấy dòng cuối cùng khớp: tổng cuối hoá đơn
          if (values.isNotEmpty) found = values.last;
          break;
        }
      }
      if (found != null) return found;
    }

    // Không có nhãn tổng: lấy số lớn nhất, bỏ dòng tiền khách đưa / mã hoá đơn / ngày
    double? best;
    for (final key in keys) {
      if (_firstIgnore(key) >= 0 || _hasAny(key, _metaKeywords.where((k) => k != 'ngay').toList())) continue;
      for (final v in moneyValues(key.replaceAll(_datePattern, ' '))) {
        if (best == null || v > best) best = v;
      }
    }
    return best;
  }

  static int _itemHeaderIndex(List<String> keys) {
    for (var i = 0; i < keys.length; i++) {
      if (_hasAny(keys[i], _itemHeaderKeywords)) return i;
    }
    return -1;
  }

  static String? _findMerchant(List<String> lines, List<String> keys, int header) {
    final limit = header >= 0 ? header : lines.length;
    for (var i = 0; i < limit && i < 6; i++) {
      final line = lines[i];
      // Tên quán gần như không có ":" hay "#" (khác với "Mã HĐ: #...", "Bàn: 14")
      if (line.contains(':') || line.contains('#')) continue;
      if (_hasAny(keys[i], _metaKeywords)) continue;
      final letters = _letter.allMatches(line).length;
      if (letters < 3 || letters < line.replaceAll(' ', '').length / 2) continue;
      return line;
    }
    return null;
  }

  /// Tên món: phần chữ của dòng hàng, bỏ STT ở đầu và SL / đơn giá / thành tiền phía sau.
  static String? _itemName(String line) {
    final tokens = line.split(RegExp(r'\s+|\|')).where((t) => t.isNotEmpty).toList();
    while (tokens.isNotEmpty && RegExp(r'^[\d.,:)\-]+$').hasMatch(tokens.first)) {
      tokens.removeAt(0);
    }
    final name = <String>[];
    for (final t in tokens) {
      if (RegExp(r'^[x×*]?\d[\d.,]*[dđ]?$', caseSensitive: false).hasMatch(t)) break;
      name.add(t);
    }
    final text = name.join(' ').trim();
    return _letter.allMatches(text).length >= 2 ? text : null;
  }

  static List<String> _findItems(List<String> lines, List<String> keys, int header) {
    bool isTotal(String key) => _totalKeywords.any((level) => _hasAny(key, level));
    final items = <String>[];
    for (var i = header + 1; i < lines.length; i++) {
      final key = keys[i];
      if (_hasAny(key, _metaKeywords)) continue;
      // Hết bảng món khi gặp dòng tổng / tiền khách đưa
      if (isTotal(key) || _firstIgnore(key) >= 0) break;
      // Không có tiêu đề bảng: chỉ nhận dòng có giá tiền
      if (header < 0 && moneyValues(key.replaceAll(_datePattern, ' ')).isEmpty) continue;
      final name = _itemName(lines[i]);
      if (name != null) items.add(name);
    }
    return items;
  }

  static DateTime? _findDate(List<String> lines) {
    for (final line in lines) {
      for (final m in _datePattern.allMatches(line)) {
        final day = int.parse(m.group(1) ?? m.group(3)!);
        final month = int.parse(m.group(2) ?? m.group(4)!);
        var year = int.parse(m.group(5)!);
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

  static String? guessCategory(String text, {String? merchant, List<String> items = const []}) {
    final sources = [
      if (merchant != null) CategoryModel.normalizeKey(merchant),
      if (items.isNotEmpty) CategoryModel.normalizeKey(items.join(' ')),
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
