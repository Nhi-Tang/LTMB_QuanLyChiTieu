import 'package:flutter/material.dart';
import 'wallet_chip.dart';
import '../../utils/app_language.dart';
import '../../theme/app_colors.dart';

class AmountDisplay extends StatelessWidget {
  final String expression;
  final bool isExpense;
  final String selectedWallet;
  final VoidCallback onWalletTap;

  const AmountDisplay({
    super.key,
    required this.expression,
    required this.isExpense,
    required this.selectedWallet,
    required this.onWalletTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.tealPale),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t('SỐ TIỀN'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                expression.isEmpty ? '0 ₫' : expression,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: isExpense ? AppColors.expense : AppColors.incomeLight,
                ),
              ),
            ],
          ),
          WalletChip(
            selectedWallet: selectedWallet,
            onTap: onWalletTap,
          ),
        ],
      ),
    );
  }
}
