import 'bank_parser.dart';
import 'bank_notification_parser.dart';
import 'direction_resolver.dart';
import 'package:quanlychitieu/core/utils/account_masker.dart';

class MomoParser extends BankParser {
  MomoParser() : super('MoMo');

  @override
  ParsedBankNotification? parseNotification({
    required String title,
    required String text,
    DateTime? timestamp,
  }) {
    if (!_isRealTransaction(title, text)) {
      return null;
    }
    return super.parseNotification(title: title, text: text, timestamp: timestamp);
  }

  bool _isRealTransaction(String title, String text) {
    final combined = '${title.toLowerCase()} ${text.toLowerCase()}';
    
    // Các từ khóa quảng cáo, ưu đãi, voucher -> Bỏ qua
    final promoKeywords = [
      'khuyến mãi', 'khuyen mai', 'ưu đãi', 'uu dai', 'voucher', 'giảm giá', 
      'giam gia', 'tặng', 'tang', 'mã giảm', 'ma giam', 'điểm tích lũy', 
      'trúng thưởng', 'quà tặng', 'nhận ngay', 'nhan ngay', 'chương trình',
      'thông báo mới', 'nạp ngay', 'sưu tầm', 'sưu tam'
    ];

    for (var kw in promoKeywords) {
      if (combined.contains(kw) && !combined.contains('thành công') && !combined.contains('thanh cong')) {
        return false;
      }
    }

    // Yêu cầu bắt buộc phải có từ khóa tài chính / giao dịch
    final transactionKeywords = [
      'chuyển', 'chuyen', 'nhận', 'nhan', 'thanh toán', 'thanh toan', 
      'nạp', 'nap', 'rút', 'rut', 'giao dịch', 'giao dich', 'trừ', 'tru',
      'số dư', 'so du', 'biến động', 'ví', 'vi'
    ];

    bool hasTransactionKeyword = false;
    for (var kw in transactionKeywords) {
      if (combined.contains(kw)) {
        hasTransactionKeyword = true;
        break;
      }
    }

    return hasTransactionKeyword;
  }

  @override
  String detectType(String title, String text) {
    return DirectionResolver.resolve(title, text, defaultDirection: 'unknown');
  }

  @override
  int parseAmount(String title, String text) {
    String cleanText = text;

    cleanText = cleanText.replaceAll(RegExp(r'\b\d{1,2}:\d{2}\b'), ' ');
    cleanText = cleanText.replaceAll(RegExp(r'\b\d{1,2}h\d{0,2}\b', caseSensitive: false), ' ');
    cleanText = cleanText.replaceAll(RegExp(r'\b\d{1,2}[/-]\d{1,2}(?:[/-]\d{2,4})?\b'), ' ');

    cleanText = cleanText.replaceAll(RegExp(r'(số dư|so du|sd|ví|vi)[^.!?]*?[\d.,]+\s*(vnd|đ|d)?\.?', caseSensitive: false), ' ');
    cleanText = cleanText.replaceAll(RegExp(r'(tài khoản|tai khoan|tk|mã gd|ma gd|magd|ref|ref no)\s*[:-]?\s*\*?\w+', caseSensitive: false), ' ');

    final currencyAmountRegex = RegExp(r'([\d]{1,3}(?:[.,]\d{3})+|\d+)\s*(vnd|đ|d)\b', caseSensitive: false);
    for (var match in currencyAmountRegex.allMatches(cleanText)) {
      String rawNum = match.group(1) ?? '';
      rawNum = rawNum.replaceAll('.', '').replaceAll(',', '');
      int? val = int.tryParse(rawNum);
      if (val != null && val > 0) {
        return val;
      }
    }

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

  @override
  String parseAccountLast4(String title, String text) {
    // Thường MoMo không ghi rõ số tài khoản 4 số cuối như ngân hàng
    // Nếu có dạng ***1234 thì bắt
    final maskedRegex = RegExp(r'(\*+|x+)(\d{3,4})', caseSensitive: false);
    final maskedMatch = maskedRegex.firstMatch(text);
    if (maskedMatch != null) {
      final digits = maskedMatch.group(2) ?? '';
      return digits.padLeft(4, '0');
    }

    // Nếu có SĐT
    final sdtRegex = RegExp(r'(?:0|84)\d{9}');
    final sdtMatch = sdtRegex.firstMatch(text);
    if (sdtMatch != null) {
      final digits = sdtMatch.group(0)!;
      return digits.substring(digits.length - 4);
    }

    return 'N/A';
  }

  @override
  String cleanDescription(String title, String text, String accountLast4) {
    String extracted = text;

    extracted = extracted.replaceAll(RegExp(r'(số dư|so du|sd|ví|vi)\s*[:-]?\s*[\d.,]+\s*(vnd|đ|d)?\.?', caseSensitive: false), ' ');
    extracted = extracted.replaceAll(RegExp(r'([\d]{1,3}(?:[.,]\d{3})+|\d+)\s*(vnd|đ|d)\b', caseSensitive: false), ' ');
    extracted = extracted.replaceAll(RegExp(r'(mã gd|ma gd|magd|ref|ref no)\s*[:-]?\s*\w+', caseSensitive: false), ' ');

    extracted = maskAccountNumbers(extracted);
    extracted = extracted.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (extracted.isEmpty) {
      extracted = bankName;
    }

    if (extracted.length > 120) {
      extracted = extracted.substring(0, 120);
    }

    return extracted;
  }
}
