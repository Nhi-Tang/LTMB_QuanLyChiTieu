import 'bank_parser.dart';
import 'package:quanlychitieu/core/utils/account_masker.dart';

class MBBankParser extends BankParser {
  MBBankParser() : super('MB Bank');

  @override
  String detectType(String title, String text) {
    final upper = text.toUpperCase();
    if (upper.contains('GD: +') || upper.contains('GD:  +') || upper.contains('GD:+') || upper.contains('TU:') || upper.contains('TỪ:')) {
      return 'income';
    } else if (upper.contains('GD: -') || upper.contains('GD:  -') || upper.contains('GD:-') || upper.contains('DEN:') || upper.contains('ĐẾN:')) {
      return 'expense';
    }
    
    return super.detectTypeFallback(text);
  }

  @override
  int parseAmount(String title, String text) {
    final parts = text.split('|');
    for (var part in parts) {
      final p = part.trim().toUpperCase();
      if (p.startsWith('GD:')) {
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
    String tuStr = '';
    String ndStr = '';

    final parts = text.split('|');
    for (var part in parts) {
      final p = part.trim();
      final pUp = p.toUpperCase();
      if (pUp.startsWith('DEN:')) {
        denStr = p.substring(4).trim();
      } else if (pUp.startsWith('TU:') || pUp.startsWith('TỪ:')) {
        tuStr = p.substring(p.indexOf(':') + 1).trim();
      } else if (pUp.startsWith('ND:')) {
        ndStr = p.substring(3).trim();
      }
    }

    if (tuStr.isNotEmpty) {
      tuStr = maskAccountNumbers(tuStr);
      if (tuStr.toUpperCase().contains('ZALOPAY')) {
        tuStr = 'ZaloPay';
      } else if (tuStr.toUpperCase().contains('MOMO')) {
        tuStr = 'MoMo';
      } else if (tuStr.toUpperCase().contains('VNPAY')) {
        tuStr = 'VNPAY';
      } else if (tuStr.toUpperCase().contains('SHOPEEPAY')) {
        tuStr = 'ShopeePay';
      }

      if (tuStr == 'ZaloPay' || tuStr == 'MoMo') {
        return '$tuStr → MB Bank';
      }
      return 'Từ: $tuStr';
    }

    if (denStr.isNotEmpty) {
      denStr = maskAccountNumbers(denStr);
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

    if (ndStr.isNotEmpty) {
      ndStr = ndStr.replaceAll(RegExp(r'\b[A-Z][A-Z\s]{2,}[A-Z]\b'), '***');
    }

    String result = '';
    if (denStr.isNotEmpty && ndStr.isNotEmpty) {
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
