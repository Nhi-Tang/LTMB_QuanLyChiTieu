class AmountExpression {
  static String formatMoney(num amount) {
    final val = amount.toInt();
    final str = val.abs().toString();
    final buffer = StringBuffer();
    if (val < 0) buffer.write('-');
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count == 3 && i > 0) {
        buffer.write('.');
        count = 0;
      }
    }
    final reversed = buffer.toString().split('').reversed.join('');
    return '$reversed ₫';
  }

  static double evaluate(String expression) {
    if (expression.isEmpty) return 0.0;
    try {
      String sanitized = expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('.', '');

      return _calculateBasic(sanitized);
    } catch (_) {
      return 0.0;
    }
  }

  static double _calculateBasic(String expr) {
    try {
      List<String> tokens = [];
      String currentNum = '';
      for (int i = 0; i < expr.length; i++) {
        String char = expr[i];
        if ('+-*/'.contains(char)) {
          if (currentNum.isNotEmpty) {
            tokens.add(currentNum);
            currentNum = '';
          }
          tokens.add(char);
        } else {
          currentNum += char;
        }
      }
      if (currentNum.isNotEmpty) {
        tokens.add(currentNum);
      }

      if (tokens.isEmpty) return 0.0;

      // First pass: * and /
      List<String> pass1 = [];
      for (int i = 0; i < tokens.length; i++) {
        if (tokens[i] == '*' || tokens[i] == '/') {
          if (pass1.isEmpty) return 0.0;
          double prev = double.parse(pass1.removeLast());
          double next = double.parse(tokens[++i]);
          if (tokens[i - 1] == '/') {
            if (next == 0) throw Exception('Division by zero');
            pass1.add((prev / next).toString());
          } else {
            pass1.add((prev * next).toString());
          }
        } else {
          pass1.add(tokens[i]);
        }
      }

      // Second pass: + and -
      double result = double.parse(pass1[0]);
      for (int i = 1; i < pass1.length; i += 2) {
        String op = pass1[i];
        double nextVal = double.parse(pass1[i + 1]);
        if (op == '+') {
          result += nextVal;
        } else if (op == '-') {
          result -= nextVal;
        }
      }
      return result;
    } catch (_) {
      return 0.0;
    }
  }

  static String appendInput(String currentExpr, String input) {
    if ('+-×÷'.contains(input)) {
      if (currentExpr.isEmpty) {
        if (input == '-') return '-';
        return '';
      }
      if ('+-×÷'.contains(currentExpr[currentExpr.length - 1])) {
        return currentExpr.substring(0, currentExpr.length - 1) + input;
      }
      return currentExpr + input;
    }

    if (input == '0') {
      List<String> parts = currentExpr.split(RegExp(r'[+\-×÷]'));
      if (parts.isNotEmpty && parts.last == '0') {
        return currentExpr;
      }
    }

    List<String> parts = currentExpr.split(RegExp(r'[+\-×÷]'));
    if (parts.isNotEmpty && parts.last.replaceAll('.', '').length >= 12) {
      return currentExpr;
    }

    return currentExpr + input;
  }
}
