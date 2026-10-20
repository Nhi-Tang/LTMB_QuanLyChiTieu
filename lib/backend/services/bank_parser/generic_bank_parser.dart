import 'bank_parser.dart';
import 'package:quanlychitieu/core/utils/account_masker.dart';

class GenericBankParser extends BankParser {
  GenericBankParser(super.bankName);

  @override
  String detectType(String title, String text) {
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

  @override
  int parseAmount(String title, String text) {
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

  @override
  String parseAccountLast4(String title, String text) {
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

  @override
  String cleanDescription(String title, String text, String accountLast4) {
    String extracted = '';

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

    if (extracted.trim().isEmpty) {
      extracted = text;
    }

    extracted = extracted.replaceAll(RegExp(r'(số dư|so du|sd|ví|vi)\s*[:-]?\s*[\d.,]+\s*(vnd|đ|d)?\.?', caseSensitive: false), ' ');
    extracted = extracted.replaceAll(RegExp(r'([\d]{1,3}(?:[.,]\d{3})+|\d+)\s*(vnd|đ|d)\b', caseSensitive: false), ' ');
    extracted = extracted.replaceAll(RegExp(r'(mã gd|ma gd|magd|ref|ref no)\s*[:-]?\s*\w+', caseSensitive: false), ' ');

    extracted = maskAccountNumbers(extracted);
    extracted = extracted.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (extracted.isEmpty) {
      if (accountLast4 != 'N/A' && accountLast4.isNotEmpty) {
        extracted = '$bankName ••••$accountLast4';
      } else {
        extracted = bankName;
      }
    }

    if (extracted.length > 120) {
      extracted = extracted.substring(0, 120);
    }

    return extracted;
  }
}
