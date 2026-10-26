import 'package:flutter/material.dart';

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
          color: const Color(0xFFF5FDFD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF66EBE5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 16, color: Color(0xFF00463E)),
            const SizedBox(width: 6),
            Text(
              selectedWallet,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00463E),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF00463E)),
          ],
        ),
      ),
    );
  }
}
