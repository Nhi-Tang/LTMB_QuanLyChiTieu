/// Thay thế mọi dãy 8-19 chữ số liền (không chứa dấu , hoặc .) bằng "••••" + 4 số cuối
String maskAccountNumbers(String text) {
  if (text.isEmpty) return text;

  // Regex tìm dãy 8-19 chữ số liền nhau (đảm bảo không bị phân tách bởi dấu chấm, phẩy)
  final regExp = RegExp(r'(?<![\d.,])\d{8,19}(?![\d.,])');

  return text.replaceAllMapped(regExp, (match) {
    final digits = match.group(0)!;
    final last4 = digits.substring(digits.length - 4);
    return '••••$last4';
  });
}
