import 'bank_parser.dart';
import 'package:quanlychitieu/core/utils/account_masker.dart';

class MBBankParser extends BankParser {
  MBBankParser() : super('MB Bank');

  @override
  String detectType(String title, String text) {
    // MB Bank luôn có định dạng: TK xxx|GD: +10,000VND hoặc GD: -5,000VND
    if (text.contains('GD: +') || text.contains('GD:  +') || text.contains('+')) {
      return 'income';
    } else if (text.contains('GD: -') || text.contains('GD:  -') || text.contains('-')) {
      return 'expense';
    }
    
    // Nếu rớt ra ngoài định dạng (hiếm) thì kiểm tra chuỗi thường
    return super.detectTypeFallback(text);
  }

  @override
  int parseAmount(String title, String text) {
    // Tách các trường bằng dấu |
    final parts = text.split('|');
    for (var part in parts) {
      final p = part.trim().toUpperCase();
      if (p.startsWith('GD:')) {
        // Lấy đoạn "GD: -5,000VND 20/10/26 15:11"
        final currencyAmountRegex = RegExp(r'([\d]{1,3}(?:[.,]\d{3})+|\d+)\s*(VND|Đ|D)?', caseSensitive: false);
        final match = currencyAmountRegex.firstMatch(p);
        if (match != null) {
          String rawNum = match.group(1) ?? '';
          rawNum = rawNum.replaceAll('.', '').replaceAll(',', '');
          return int.tryParse(rawNum) ?? 0;
        }
      }
    }
    return 0;
  }

  @override
  String parseAccountLast4(String title, String text) {
    final parts = text.split('|');
    for (var part in parts) {
      final p = part.trim().toUpperCase();
      if (p.startsWith('TK ') || p.contains('XXX') || p.contains('***')) {
        final maskedRegex = RegExp(r'(?:\*+|X+|TK\s+)(\d{3,4})', caseSensitive: false);
        final match = maskedRegex.firstMatch(p);
        if (match != null) {
          final digits = match.group(1) ?? '';
          return digits.padLeft(4, '0');
        }
      }
    }
    return 'N/A';
  }

  @override
  String cleanDescription(String title, String text, String accountLast4) {
    String denStr = '';
    String ndStr = '';

    final parts = text.split('|');
    for (var part in parts) {
      final p = part.trim();
      if (p.toUpperCase().startsWith('DEN:')) {
        denStr = p.substring(4).trim();
      } else if (p.toUpperCase().startsWith('ND:')) {
        ndStr = p.substring(3).trim();
      }
    }

    // Làm gọn tên đối tác (Ví dụ ZALOPAY - 99ZP...)
    if (denStr.isNotEmpty) {
      denStr = maskAccountNumbers(denStr);
      // Ánh xạ sang tên ví thân thiện nếu có
      if (denStr.toUpperCase().contains('ZALOPAY')) {
        denStr = 'ZaloPay';
      } else if (denStr.toUpperCase().contains('MOMO')) {
        denStr = 'MoMo';
      } else if (denStr.toUpperCase().contains('VNPAY')) {
        denStr = 'VNPAY';
      } else if (denStr.toUpperCase().contains('SHOPEEPAY')) {
        denStr = 'ShopeePay';
      }
    }

    // Che tên riêng trong Nội dung (MB Bank hay ghép <HỌ TÊN> người nhận vào giữa)
    if (ndStr.isNotEmpty) {
      // ND: MBCT NGUYEN VAN A chuyen tien... -> ND: MBCT *** chuyen tien...
      ndStr = ndStr.replaceAll(RegExp(r'\b[A-Z][A-Z\s]{2,}[A-Z]\b'), '***');
    }

    String result = '';
    if (denStr.isNotEmpty && ndStr.isNotEmpty) {
      // Thay đổi mũi tên cho sang trọng nếu là chuyển vào ví
      if (denStr == 'ZaloPay' || denStr == 'MoMo') {
         result = 'MB Bank → $denStr - $ndStr'; 
      } else {
         result = 'Đến: $denStr - $ndStr';
      }
    } else if (denStr.isNotEmpty) {
      result = 'Đến: $denStr';
    } else if (ndStr.isNotEmpty) {
      result = ndStr;
    } else {
      result = 'MB Bank ••••$accountLast4';
    }

    if (result.length > 120) {
      result = result.substring(0, 120);
    }
    return result;
  }
}
