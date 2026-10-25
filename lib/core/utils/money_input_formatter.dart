import 'package:flutter/services.dart';

class MoneyInputFormatter extends TextInputFormatter {
  static const int maxDigits = 12;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Chỉ giữ lại ký tự số
    String digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Tối đa 12 chữ số (tối đa 999.999.999.999 VND)
    if (digitsOnly.length > maxDigits) {
      digitsOnly = digitsOnly.substring(0, maxDigits);
    }

    // Bỏ số 0 thừa ở đầu, nhưng cho phép giữ "0"
    if (digitsOnly.length > 1 && digitsOnly.startsWith('0')) {
      digitsOnly = digitsOnly.replaceFirst(RegExp(r'^0+'), '');
      if (digitsOnly.isEmpty) {
        digitsOnly = '0';
      }
    }

    // Chèn dấu chấm ngăn hàng nghìn
    String formatted = formatMoneyStr(digitsOnly);

    // Giữ con trỏ ở cuối chuỗi
    int selectionIndex = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

String formatMoneyStr(String digitsOnly) {
  if (digitsOnly.isEmpty) return '';
  if (digitsOnly.length > 12) {
    digitsOnly = digitsOnly.substring(0, 12);
  }
  final buffer = StringBuffer();
  int count = 0;
  for (int i = digitsOnly.length - 1; i >= 0; i--) {
    buffer.write(digitsOnly[i]);
    count++;
    if (count == 3 && i > 0) {
      buffer.write('.');
      count = 0;
    }
  }
  return buffer.toString().split('').reversed.join('');
}

String formatMoney(num value) {
  num safeValue = value;
  if (safeValue.abs() > 999999999999) {
    safeValue = safeValue < 0 ? -999999999999 : 999999999999;
  }
  return formatMoneyStr(safeValue.toInt().abs().toString());
}

int parseMoney(String text) {
  if (text.isEmpty) return 0;
  String digitsOnly = text.replaceAll(RegExp(r'\D'), '');
  if (digitsOnly.length > 12) {
    digitsOnly = digitsOnly.substring(0, 12);
  }
  return int.tryParse(digitsOnly) ?? 0;
}
