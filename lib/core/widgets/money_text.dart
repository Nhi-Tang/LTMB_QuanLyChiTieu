import 'package:flutter/material.dart';
import '../utils/money_input_formatter.dart';

class MoneyText extends StatelessWidget {
  final num amount;
  final TextStyle? style;
  final AlignmentGeometry alignment;
  final String prefix;
  final String suffix;
  final bool isNegative;

  const MoneyText({
    super.key,
    required this.amount,
    this.style,
    this.alignment = Alignment.centerLeft,
    this.prefix = '',
    this.suffix = ' đ',
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = formatMoney(amount.abs());
    final sign = (isNegative || amount < 0) ? '-' : '';
    final fullText = '$prefix$sign$formatted$suffix';

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(
        fullText,
        style: style,
        maxLines: 1,
      ),
    );
  }
}
