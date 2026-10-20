import 'package:quanlychitieu/backend/services/bank_parser/bank_notification_parser.dart';

abstract class BankParser {
  final String bankName;

  BankParser(this.bankName);

  String detectType(String title, String text);
  
  // Method cho các parser dùng chung
  String detectTypeFallback(String text) {
    final txt = text.toLowerCase();
    if (txt.contains('nhận') || txt.contains('cộng') || txt.contains('hoàn tiền') || txt.contains('+')) {
      if (!txt.contains('trừ') && !txt.contains('thanh toán')) return 'income';
    }
    return 'expense';
  }

  int parseAmount(String title, String text);
  String parseAccountLast4(String title, String text);
  String cleanDescription(String title, String text, String accountLast4);

  ParsedBankNotification? parseNotification({
    required String title,
    required String text,
    DateTime? timestamp,
  }) {
    if (BankNotificationParser.isNonTransaction(title, text)) {
      return null;
    }

    final amount = parseAmount(title, text);
    if (amount <= 0) {
      return null;
    }

    final type = detectType(title, text);
    final accountLast4 = parseAccountLast4(title, text);
    final description = cleanDescription(title, text, accountLast4);
    final occurredAt = timestamp ?? DateTime.now();

    final fingerprint = BankNotificationParser.generateFingerprint(
      bankName: bankName,
      amount: amount,
      type: type,
      timestamp: occurredAt,
      accountLast4: accountLast4,
    );

    return ParsedBankNotification(
      bankName: bankName,
      type: type,
      amount: amount,
      accountLast4: accountLast4,
      description: description,
      occurredAt: occurredAt,
      fingerprint: fingerprint,
    );
  }
}
