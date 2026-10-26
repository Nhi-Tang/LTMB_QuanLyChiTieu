import 'package:flutter/material.dart';
import 'amount_expression.dart';
import 'mousey_colors.dart';
import '../../utils/app_language.dart';

class AmountCard extends StatelessWidget {
  final String expression;
  final bool isExpense;

  const AmountCard({
    super.key,
    required this.expression,
    required this.isExpense,
  });

  String _getFormattedAmount() {
    if (expression.isEmpty) return '0 ₫';
    double val = AmountExpression.evaluate(expression);
    if (val == 0.0 && !expression.contains('0')) return '$expression ₫';
    return AmountExpression.formatMoney(val);
  }

  @override
  Widget build(BuildContext context) {
    final amountColor = isExpense ? MouseyColors.expenseRed : MouseyColors.incomeGreen;
    final formattedText = _getFormattedAmount();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: MouseyColors.cardCream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MouseyColors.borderBeige),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('SỐ TIỀN'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: MouseyColors.textSub,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formattedText,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: amountColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
