import 'package:flutter/material.dart';
import '../../backend/services/pro_service.dart';
import '../screens/pro_upgrade_screen.dart';
import '../theme/app_colors.dart';

class ProGate extends StatelessWidget {
  final Widget child;
  final String featureTitle;
  final VoidCallback? onTapLocked;

  const ProGate({
    super.key,
    required this.child,
    required this.featureTitle,
    this.onTapLocked,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProService.instance,
      builder: (context, _) {
        final isPro = ProService.instance.isPro;

        if (isPro) {
          return child;
        }

        return InkWell(
          onTap: () {
            if (onTapLocked != null) {
              onTapLocked!();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProUpgradeScreen()),
              );
            }
          },
          child: Stack(
            children: [
              AbsorbPointer(
                child: Opacity(
                  opacity: 0.6,
                  child: child,
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accentDark.withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
