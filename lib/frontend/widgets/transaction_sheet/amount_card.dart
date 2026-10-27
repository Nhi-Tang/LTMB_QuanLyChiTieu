import 'package:flutter/material.dart';
import 'amount_expression.dart';
import 'mousey_colors.dart';
import '../../utils/app_language.dart';
import '../../theme/app_colors.dart';

/// Ô "Số tiền" kiểu sổ: nhãn nhỏ, số tiền lớn, một đường kẻ mực phía dưới
class AmountCard extends StatelessWidget {
  final String expression;
  final bool isExpense;

  const AmountCard({
    super.key,
    required this.expression,
    required this.isExpense,
  });

  String _getFormattedAmount() {
    if (expression.isEmpty) return '0 đ';
    double val = AmountExpression.evaluate(expression);
    if (val == 0.0 && !expression.contains('0')) return '$expression đ';
    return AmountExpression.formatMoney(val);
  }

  @override
  Widget build(BuildContext context) {
    final amountColor = isExpense ? MouseyColors.expenseRed : MouseyColors.incomeGreen;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.ink, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('Số tiền'),
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _getFormattedAmount(),
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: amountColor,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
