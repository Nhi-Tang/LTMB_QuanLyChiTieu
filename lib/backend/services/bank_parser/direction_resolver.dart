class DirectionResolver {
  static String resolve(String title, String text, {String defaultDirection = 'expense'}) {
    // 1. Tách riêng phần lời nhắn/nội dung do người dùng tự nhập để không bị nhiễu
    String coreText = text.toLowerCase();
    final messageMarkers = [
      'kèm lời nhắn:', 'kem loi nhan:',
      'nội dung:', 'noi dung:', 'nd:', 'ref:',
      'tin nhắn:', 'tin nhan:',
      'với nội dung', 'voi noi dung'
    ];

    for (var marker in messageMarkers) {
      final idx = coreText.indexOf(marker);
      if (idx != -1) {
        coreText = coreText.substring(0, idx); // Chỉ lấy phần trước lời nhắn
        break;
      }
    }

    final combined = '${title.toLowerCase()} $coreText';

    final incomeMatch = RegExp(r'\b(nhận|nhan|nhận được|nhan duoc|vừa nhận|vua nhan|tiền về|tien ve|hoàn tiền|hoan tien|chuyển tiền cho bạn|chuyen tien cho ban|được cộng|duoc cong|cộng|cong)\b').firstMatch(combined);
    final expenseMatch = RegExp(r'\b(đã chuyển|da chuyen|chuyển tiền đến|chuyen tien den|chuyển khoản đến|chuyen khoan den|thanh toán|thanh toan|đã trả|da tra|chuyển đi|chuyen di|trừ|tru)\b').firstMatch(combined);

    if (incomeMatch != null && expenseMatch != null) {
      if (incomeMatch.start < expenseMatch.start) return 'income';
      return 'expense';
    } else if (incomeMatch != null) {
      return 'income';
    } else if (expenseMatch != null) {
      return 'expense';
    }

    if (combined.contains('+')) return 'income';
    if (combined.contains('-')) return 'expense';

    return defaultDirection;
  }
}
