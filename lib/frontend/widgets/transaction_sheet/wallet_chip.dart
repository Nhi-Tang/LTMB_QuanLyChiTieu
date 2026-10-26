import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class WalletChip extends StatelessWidget {
  final String selectedWallet;
  final VoidCallback onTap;

  const WalletChip({
    super.key,
    required this.selectedWallet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.tealWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.tealLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppColors.tealDark),
            const SizedBox(width: 6),
            Text(
              selectedWallet,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.tealDark,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.tealDark),
          ],
        ),
      ),
    );
  }
}
