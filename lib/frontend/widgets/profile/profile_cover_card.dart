import 'package:flutter/material.dart';
import '../../../backend/models/user_model.dart';
import '../../theme/app_colors.dart';

/// Bìa sổ: tên, email
class ProfileCoverCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const ProfileCoverCard({super.key, required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cover,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Gáy sổ
              Container(width: 14, color: AppColors.coverSpine),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
