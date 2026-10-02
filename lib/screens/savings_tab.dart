import 'package:flutter/material.dart';
import '../widgets/app_alert_dialog.dart';
import '../widgets/piggy_avatar.dart';

class SavingsTab extends StatelessWidget {
  final String selectedAvatarKey;
  final String userName;

  static const Color primaryGreen = Color(0xFFA5D6A7);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF2E7D32);

  const SavingsTab({
    super.key,
    required this.selectedAvatarKey,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
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
                    const Text(
                      'HEO ĐẤT TIẾT KIỆM · PIGGY',
                      style: TextStyle(
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
                const Text(
                  'Quản lý Tiết kiệm',
                  style: TextStyle(
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
                  child: const Row(
                    children: [
                      Text('🐖 ', style: TextStyle(fontSize: 20)),
                      Expanded(
                        child: Text(
                          '"Tích tiểu thành đại! Hãy tạo các mục tiêu tiết kiệm để Piggy giúp bạn chạm tới ước mơ nhé!"',
                          style: TextStyle(
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
              const Text(
                'MỤC TIÊU TIẾT KIỆM',
                style: TextStyle(
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
                    title: 'Thêm mục tiêu tiết kiệm',
                    message: 'Tính năng Tạo mục tiêu tiết kiệm mới (Mua xe, Du lịch, Mua nhà,...) đang được cập nhật!',
                    isSuccess: true,
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Tạo mục tiêu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
              children: const [
                Icon(Icons.savings_outlined, size: 56, color: primaryGreen),
                SizedBox(height: 14),
                Text(
                  'Chưa có mục tiêu tiết kiệm nào',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Bấm nút (+ Tạo mục tiêu) ở trên để bắt đầu tích lũy heo đất cùng Piggy Smart ngay hôm nay!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
