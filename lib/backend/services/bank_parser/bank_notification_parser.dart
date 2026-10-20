import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../../../core/utils/account_masker.dart';
import 'bank_parser.dart';
import 'generic_bank_parser.dart';
import 'momo_parser.dart';
import 'zalopay_parser.dart';
import 'mb_bank_parser.dart';

class ParsedBankNotification {
  final String bankName;
  final String type; // 'expense' hoặc 'income'
  final int amount; // VND
  final String accountLast4;
  final String description; // Tối đa 120 ký tự
  final DateTime occurredAt;
  final String fingerprint;

  ParsedBankNotification({
    required this.bankName,
    required this.type,
    required this.amount,
    required this.accountLast4,
    required this.description,
    required this.occurredAt,
    required this.fingerprint,
  });
}

class BankNotificationParser {
  static const List<String> _nonTransactionKeywords = [
    'otp',
    'ma xac thuc',
    'mã xác thực',
    'khuyen mai',
    'khuyến mãi',
    'nhac no',
    'nhắc nợ',
    'mat khau',
    'mật khẩu',
    'canh bao',
    'cảnh báo',
    'dieu khoan',
    'điều khoản',
    'quang cao',
    'quảng cáo',
    'qc:',
    'ad:',
  ];

  static bool isNonTransaction(String title, String text) {
    final combined = '${title.toLowerCase()} ${text.toLowerCase()}';
    for (var keyword in _nonTransactionKeywords) {
      if (combined.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  static BankParser _getParser(String packageName, String title, String text) {
    final pkg = packageName.toLowerCase();
    final txt = text.toLowerCase();
    
    if (pkg == 'com.mservice.momopay' || pkg == 'com.mservice.momotransfer') {
      return MomoParser();
    } else if (pkg == 'vn.com.vng.zalopay' || pkg == 'vn.zalopay.pay') {
      return ZaloPayParser();
    } else if (pkg.contains('mbmobile') || pkg.contains('mbbank') || txt.contains('mb bank') || txt.contains('mb:')) {
      return MBBankParser();
    } else if (pkg.contains('techcombank') || pkg.contains('tcb') || txt.contains('techcombank')) {
      return GenericBankParser('Techcombank');
    } else if (pkg.contains('vcb') || pkg.contains('vietcombank') || txt.contains('vietcombank')) {
      return GenericBankParser('Vietcombank');
    } else if (pkg.contains('bidv') || txt.contains('bidv')) {
      return GenericBankParser('BIDV');
    } else if (pkg.contains('vietinbank') || txt.contains('vietinbank')) {
      return GenericBankParser('VietinBank');
    } else if (pkg.contains('tpb') || pkg.contains('tpbank') || txt.contains('tpbank')) {
      return GenericBankParser('TPBank');
    } else if (pkg.contains('acb') || txt.contains('acb')) {
      return GenericBankParser('ACB');
    } else if (pkg.contains('vpbank') || txt.contains('vpbank')) {
      return GenericBankParser('VPBank');
    }

    return GenericBankParser('Ngân hàng');
  }

  static String detectType(String text) {
    final txt = text.toLowerCase();

    if (txt.contains('nhận') ||
        txt.contains('nhan') ||
        txt.contains('cộng') ||
        txt.contains('cong') ||
        txt.contains('hoàn tiền') ||
        txt.contains('hoan tien') ||
        txt.contains('tiền vào') ||
        txt.contains('tien vao') ||
        txt.contains('co:') ||
        txt.contains('có:')) {
      if (!txt.contains('trừ') && !txt.contains('tru') && !txt.contains('thanh toán') && !txt.contains('thanh toan') && !txt.contains('chuyển đi') && !txt.contains('chuyen di')) {
        return 'income';
      }
    }

    if (txt.contains('+')) {
      return 'income';
    }

    return 'expense';
  }

  static int parseAmount(String text) {
    String cleanText = text;

    // 0. Loại bỏ hoàn toàn các cụm từ chứa số dư / ví / tài khoản / mã giao dịch kèm số tiền
    cleanText = cleanText.replaceAll(RegExp(r'(số dư|so du|sd|ví|vi)[^.!?]*?[\d.,]+\s*(vnd|đ|d)?\.?', caseSensitive: false), ' ');
    cleanText = cleanText.replaceAll(RegExp(r'(tài khoản|tai khoan|tk|mã gd|ma gd|magd|ref|ref no)\s*[:-]?\s*\*?\w+', caseSensitive: false), ' ');

    // 0.1. Loại bỏ thời gian (VD: 12:30 hoặc 12h30)
    cleanText = cleanText.replaceAll(RegExp(r'\b\d{1,2}:\d{2}\b'), ' ');
    cleanText = cleanText.replaceAll(RegExp(r'\b\d{1,2}h\d{0,2}\b', caseSensitive: false), ' ');

    // 0.2. Loại bỏ ngày tháng (VD: 19/10/2026 hoặc 19-10)
    cleanText = cleanText.replaceAll(RegExp(r'\b\d{1,2}[/-]\d{1,2}(?:[/-]\d{2,4})?\b'), ' ');

    // 1. Ưu tiên số tiền đi kèm đơn vị tiền tệ rõ ràng (vnd, đ, d)
    final currencyAmountRegex = RegExp(r'([\d]{1,3}(?:[.,]\d{3})+|\d+)\s*(vnd|đ|d)\b', caseSensitive: false);
    for (var match in currencyAmountRegex.allMatches(cleanText)) {
      String rawNum = match.group(1) ?? '';
      rawNum = rawNum.replaceAll('.', '').replaceAll(',', '');
      int? val = int.tryParse(rawNum);
      if (val != null && val > 0) {
        return val;
      }
    }

    // 2. Tìm số tiền đi kèm ký hiệu +, -
    final explicitAmountRegex = RegExp(r'([+-])\s*([\d]{1,3}(?:[.,]\d{3})+|\d+)', caseSensitive: false);
    final explicitMatch = explicitAmountRegex.firstMatch(cleanText);
    if (explicitMatch != null) {
      String rawNum = explicitMatch.group(2) ?? '';
      rawNum = rawNum.replaceAll('.', '').replaceAll(',', '');
      int? val = int.tryParse(rawNum);
      if (val != null && val > 0) {
        return val;
      }
    }

    // 3. Fallback: số có định dạng phân cách hàng nghìn (VD: 50.000 hoặc 1.000.000)
    final formattedAmountRegex = RegExp(r'\b([\d]{1,3}(?:[.,]\d{3})+)\b');
    for (var match in formattedAmountRegex.allMatches(cleanText)) {
      String rawNum = match.group(1) ?? '';
      rawNum = rawNum.replaceAll('.', '').replaceAll(',', '');
      int? val = int.tryParse(rawNum);
      if (val != null && val > 0) {
        return val;
      }
    }

    return 0;
  }

  static String parseAccountLast4(String text) {
    // 1. Bắt TK / Tài khoản / account kèm tên bank tùy chọn (VD: TK VCB 1039165413)
    final tkRegex = RegExp(r'(tk|tài khoản|tai khoan|acc|account)\s*(?:vcb|mb|tcb|bidv|tpb|acb|vpbank)?\s*[:-]?\s*\*?(\d{4,19}|\w*\d{4})', caseSensitive: false);
    final match = tkRegex.firstMatch(text);
    if (match != null) {
      String fullAcc = match.group(2) ?? '';
      final digits = fullAcc.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 4) {
        return digits.substring(digits.length - 4);
      }
    }

    // 2. Bắt dãy số liên tiếp 8-19 chữ số làm số tài khoản nếu có
    final digitsRegex = RegExp(r'(?<![\d.,])\d{8,19}(?![\d.,])');
    final digitsMatch = digitsRegex.firstMatch(text);
    if (digitsMatch != null) {
      final digits = digitsMatch.group(0)!;
      return digits.substring(digits.length - 4);
    }

    // 3. Bắt chuỗi số dạng xxx005 hoặc ***1234
    final maskedRegex = RegExp(r'(\*+|x+)(\d{3,4})', caseSensitive: false);
    final maskedMatch = maskedRegex.firstMatch(text);
    if (maskedMatch != null) {
      final digits = maskedMatch.group(2) ?? '';
      return digits.padLeft(4, '0');
    }

    return 'N/A';
  }

  /// Tách duy nhất phần nội dung chuyển khoản, che số tài khoản, không gán nguyên văn thông báo
  static String cleanDescription(String title, String text, String bankName, String accountLast4) {
    String extracted = '';

    // Lọc bỏ phần "lời nhắn:" hay "nội dung:" do người dùng tự nhập để tránh bị nhiễu
    String cleanCoreText = text;
    final userMessageMarkers = [
      'kèm lời nhắn:', 'kem loi nhan:',
      'nội dung:', 'noi dung:', 'nd:', 'ref:',
      'tin nhắn:', 'tin nhan:',
      'với nội dung', 'voi noi dung'
    ];
    for (var marker in userMessageMarkers) {
      final idx = cleanCoreText.toLowerCase().indexOf(marker);
      if (idx != -1) {
        cleanCoreText = cleanCoreText.substring(0, idx);
        break;
      }
    }

    // Tìm từ khóa chỉ phần nội dung chuyển khoản
    final keywords = [
      RegExp(r'(?:ref|nd|noi dung|nội dung|den|đến|mô tả|mo ta|cho|từ|tu)\s*[:-]\s*(.*)', caseSensitive: false),
      RegExp(r'thanh toán\s+(.*)', caseSensitive: false),
      RegExp(r'thanh toan\s+(.*)', caseSensitive: false),
      RegExp(r'chuyển tiền\s+(.*)', caseSensitive: false),
      RegExp(r'chuyen tien\s+(.*)', caseSensitive: false),
      RegExp(r'nhận được\s+(.*)', caseSensitive: false),
      RegExp(r'nhan duoc\s+(.*)', caseSensitive: false),
    ];

    for (var kw in keywords) {
      final match = kw.firstMatch(text);
      if (match != null && match.group(1) != null) {
        extracted = match.group(1)!.trim();
        break;
      }
    }

    // Nếu không tìm thấy từ khóa nội dung, sử dụng tên ngân hàng + 4 số cuối tài khoản
    if (extracted.trim().isEmpty) {
      if (accountLast4 != 'N/A' && accountLast4.isNotEmpty) {
        extracted = '$bankName ••••$accountLast4';
      } else {
        extracted = bankName;
      }
    }

    // 1. Loại bỏ thông tin số dư khỏi trích xuất
    extracted = extracted.replaceAll(RegExp(r'(số dư|so du|sd)\s*[:-]?\s*[\d.,]+\s*(vnd|đ|d)?\.?', caseSensitive: false), ' ');

    // 2. Loại bỏ mã GD thừa ở cuối
    extracted = extracted.replaceAll(RegExp(r'(mã gd|ma gd|magd)\s*[:-]?\s*\w+', caseSensitive: false), ' ');

    // 3. Che số tài khoản từ 8-19 chữ số bằng maskAccountNumbers
    extracted = maskAccountNumbers(extracted);

    // 4. Dọn dẹp khoảng trắng
    extracted = extracted.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (extracted.isEmpty) {
      extracted = '$bankName ••••$accountLast4';
    }

    // Cắt tối đa 120 ký tự
    if (extracted.length > 120) {
      extracted = extracted.substring(0, 120);
    }

    return extracted;
  }

  static String generateFingerprint({
    required String bankName,
    required int amount,
    required String type,
    required DateTime timestamp,
    required String accountLast4,
  }) {
    final roundedMinute = timestamp.millisecondsSinceEpoch ~/ (10 * 60 * 1000);
    final rawKey = '${bankName.toLowerCase()}_${amount}_${type.toLowerCase()}_${roundedMinute}_$accountLast4';
    return sha256.convert(utf8.encode(rawKey)).toString();
  }

  static ParsedBankNotification? parseNotification({
    required String packageName,
    required String title,
    required String text,
    DateTime? timestamp,
  }) {
    if (isNonTransaction(title, text)) {
      return null;
    }

    final parser = _getParser(packageName, title, text);
    return parser.parseNotification(title: title, text: text, timestamp: timestamp);
  }
}
