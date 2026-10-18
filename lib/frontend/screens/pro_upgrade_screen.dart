import 'package:flutter/material.dart';
import '../../backend/services/pro_service.dart';
import '../../core/constants/pricing.dart';
import '../theme/app_colors.dart';
import '../widgets/app_alert_dialog.dart';
import '../widgets/mousey_avatar.dart';
import '../widgets/pro/plan_card.dart';
import 'vietqr_payment_screen.dart';

class ProUpgradeScreen extends StatefulWidget {
  const ProUpgradeScreen({super.key});

  @override
  State<ProUpgradeScreen> createState() => _ProUpgradeScreenState();
}

class _ProUpgradeScreenState extends State<ProUpgradeScreen> {
  // 'monthly' or 'yearly'
  String _selectedPlan = 'yearly';
  bool _isLoading = false;

  Future<void> _handleStartTrial() async {
    setState(() => _isLoading = true);
    try {
      await ProService.instance.startTrial();
      if (!mounted) return;
      showAppAlertDialog(
        context: context,
        title: 'Kích hoạt thành công!',
        message: 'Bạn đã bắt đầu 7 ngày dùng thử Mousey PRO miễn phí.',
        isSuccess: true,
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showAppAlertDialog(
        context: context,
        title: 'Không thể dùng thử',
        message: e.toString().replaceAll('Exception: ', ''),
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUpgrade() async {
    setState(() => _isLoading = true);
    try {
      final amount = _selectedPlan == 'yearly' ? PricingConstants.yearlyPrice : PricingConstants.monthlyPrice;
      final order = await ProService.instance.createOrder(_selectedPlan, amount);
      if (order == null || !order.containsKey('orderId')) {
        throw Exception('Không tạo được đơn hàng.');
      }

      if (!mounted) return;
      // Navigate to VietQR Payment Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VietQRPaymentScreen(orderData: order),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showAppAlertDialog(
        context: context,
        title: 'Lỗi tạo đơn hàng',
        message: e.toString().replaceAll('Exception: ', ''),
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient Header with Close Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.cardGradientStart, AppColors.cardGradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      buildUserAvatar(
                        avatarKey: 'mousey',
                        userName: 'Mousey PRO',
                        size: 52,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nâng Cấp Mousey PRO',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Trải nghiệm trọn vẹn sức mạnh quản lý tài chính thông minh',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 4 Benefit Points
                const Text(
                  'Quyền lợi độc quyền PRO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildBenefitItem(
                  icon: Icons.menu_book_rounded,
                  title: 'Thêm không giới hạn Sổ sách quản lý',
                  subtitle: 'Quản lý riêng biệt quỹ cá nhân, gia đình, công việc',
                ),
                _buildBenefitItem(
                  icon: Icons.table_chart_rounded,
                  title: 'Xuất báo cáo Excel (.xlsx) & CSV',
                  subtitle: 'Dễ dàng lưu trữ và phân tích dữ liệu chuyên sâu',
                ),
                _buildBenefitItem(
                  icon: Icons.notifications_active_rounded,
                  title: 'Lời nhắc ghi chép thông minh',
                  subtitle: 'Tự động nhắc khi có thông báo số dư ngân hàng',
                ),
                _buildBenefitItem(
                  icon: Icons.cloud_sync_rounded,
                  title: 'Sao lưu và đồng bộ Cloud an toàn',
                  subtitle: 'Đồng bộ dữ liệu thời gian thực giữa các thiết bị',
                ),
                const SizedBox(height: 24),

                // Plan Selection Cards
                const Text(
                  'Chọn gói đăng ký phù hợp',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                PlanCard(
                  title: 'Gói Năm (Khuyên dùng)',
                  price: '200.000đ',
                  period: 'năm',
                  savings: 'Tiết kiệm ${PricingConstants.yearlyDiscountPercentage}% (~16.600đ/tháng)',
                  isBestValue: true,
                  isSelected: _selectedPlan == 'yearly',
                  onTap: () => setState(() => _selectedPlan = 'yearly'),
                ),
                const SizedBox(height: 12),
                PlanCard(
                  title: 'Gói Tháng',
                  price: '20.000đ',
                  period: 'tháng',
                  isSelected: _selectedPlan == 'monthly',
                  onTap: () => setState(() => _selectedPlan = 'monthly'),
                ),
                const SizedBox(height: 32),

                // Action Buttons
                ListenableBuilder(
                  listenable: ProService.instance,
                  builder: (context, _) {
                    final trialUsed = ProService.instance.trialUsed;
                    return Column(
                      children: [
                        if (!trialUsed) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _isLoading ? null : _handleStartTrial,
                              child: const Text(
                                'Dùng thử miễn phí 7 ngày',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _isLoading ? null : _handleUpgrade,
                            child: Text(
                              trialUsed ? 'Nâng cấp ngay (${_selectedPlan == 'yearly' ? '200.000đ/năm' : '20.000đ/tháng'})' : 'Đăng ký ngay (${_selectedPlan == 'yearly' ? '200.000đ/năm' : '20.000đ/tháng'})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Footer Links
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        showAppAlertDialog(
                          context: context,
                          title: 'Khôi phục giao dịch',
                          message: 'Đã kiểm tra tài khoản. Không tìm thấy gói cước cần khôi phục.',
                          isSuccess: true,
                        );
                      },
                      child: const Text(
                        'Khôi phục giao dịch',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                    const Text('•', style: TextStyle(color: AppColors.textSecondary)),
                    TextButton(
                      onPressed: () {
                        showAppAlertDialog(
                          context: context,
                          title: 'Điều khoản dịch vụ',
                          message: 'Bằng việc đăng ký, bạn đồng ý với Điều khoản sử dụng và Chính sách bảo mật của Mousey.',
                          isSuccess: true,
                        );
                      },
                      child: const Text(
                        'Điều khoản dịch vụ',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({required IconData icon, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cardGradientStart,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
