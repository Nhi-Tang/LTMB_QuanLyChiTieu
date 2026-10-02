import 'package:flutter/material.dart';
import '../utils/app_translations.dart';
import '../widgets/app_alert_dialog.dart';
import '../widgets/piggy_avatar.dart';

class SavingsTab extends StatelessWidget {
  final String selectedAvatarKey;
  final String userName;
  final String selectedLanguage;

  static const Color primaryGreen = Color(0xFFA5D6A7);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF2E7D32);

  const SavingsTab({
    super.key,
    required this.selectedAvatarKey,
    required this.userName,
    this.selectedLanguage = 'Tiếng Việt',
  });

  @override
  Widget build(BuildContext context) {
    final lang = selectedLanguage;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Card Tiết Kiệm
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryGreen,
                  Color(0xFF81C784),
                  accentGreen,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: darkGreen.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppTranslations.tr(lang, 'piggy_savings_badge'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: darkGreen,
                      ),
                    ),
                    buildUserAvatar(
                      avatarKey: selectedAvatarKey,
                      userName: userName,
                      size: 44,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  AppTranslations.tr(lang, 'savings_management'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Text('🐖 ', style: TextStyle(fontSize: 20)),
                      Expanded(
                        child: Text(
                          AppTranslations.tr(lang, 'piggy_quote_home'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF222222),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Header: Danh sách Mục tiêu Tiết kiệm
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTranslations.tr(lang, 'savings_goals'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Color(0xFF706C66),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  showAppAlertDialog(
                    context: context,
                    title: AppTranslations.tr(lang, 'create_goal'),
                    message: 'Tính năng Tạo mục tiêu tiết kiệm mới đang được cập nhật!',
                    isSuccess: true,
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  AppTranslations.tr(lang, 'create_goal'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Empty State
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFECE7DB)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.savings_outlined, size: 56, color: primaryGreen),
                const SizedBox(height: 14),
                Text(
                  AppTranslations.tr(lang, 'no_savings_goals'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppTranslations.tr(lang, 'add_first_transaction'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
