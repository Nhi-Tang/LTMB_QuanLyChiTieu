import 'package:flutter/material.dart';
import '../../core/widgets/asset_icon.dart';
import '../../backend/services/pro_service.dart';
import '../../core/constants/pricing.dart';
import '../theme/app_colors.dart';
import '../utils/app_translations.dart';
import '../widgets/app_alert_dialog.dart';
import '../widgets/mousey_avatar.dart';
import '../widgets/pro/plan_card.dart';
import 'vietqr_payment_screen.dart';
import '../utils/app_language.dart';

class ProUpgradeScreen extends StatefulWidget {

  const ProUpgradeScreen({super.key});

  @override
  State<ProUpgradeScreen> createState() => _ProUpgradeScreenState();
}

class _ProUpgradeScreenState extends State<ProUpgradeScreen> {
  String _selectedPlan = 'yearly';
  bool _isLoading = false;
  String get _lang => AppLanguage.instance.value;

  Future<void> _handleStartTrial() async {
    setState(() => _isLoading = true);
    try {
      await ProService.instance.startTrial();
      if (!mounted) return;
      showAppAlertDialog(
        context: context,
        title: context.t('Kích hoạt thành công!'),
        message: context.t('Bạn đã bắt đầu 7 ngày dùng thử Mousey PRO miễn phí.'),
        isSuccess: true,
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showAppAlertDialog(
        context: context,
        title: context.t('Không thể dùng thử'),
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
        throw Exception(AppLanguage.instance.t('Không tạo được đơn hàng.'));
      }

      if (!mounted) return;
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
        title: context.t('Lỗi tạo đơn hàng'),
        message: e.toString().replaceAll('Exception: ', ''),
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = _lang;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
                  decoration: BoxDecoration(
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
                            icon: Icon(Icons.close_rounded, color: AppColors.textPrimary),
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
                      Text(
                        AppTranslations.tr(lang, 'pro_upgrade_title'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppTranslations.tr(lang, 'pro_upgrade_subtitle'),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    const SizedBox(height: 24),

                    Text(
                      AppTranslations.tr(lang, 'pro_benefits'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBenefitItem(
                      icon: 'ui_sach',
                      title: AppTranslations.tr(lang, 'benefit_1_title'),
                      subtitle: AppTranslations.tr(lang, 'benefit_1_sub'),
                    ),
                    _buildBenefitItem(
                      icon: 'ui_tai_xuong',
                      title: AppTranslations.tr(lang, 'benefit_2_title'),
                      subtitle: AppTranslations.tr(lang, 'benefit_2_sub'),
                    ),
                    _buildBenefitItem(
                      icon: 'ui_chuong_thong_bao',
                      title: AppTranslations.tr(lang, 'benefit_3_title'),
                      subtitle: AppTranslations.tr(lang, 'benefit_3_sub'),
                    ),
                    _buildBenefitItem(
                      icon: 'ui_dong_bo',
                      title: AppTranslations.tr(lang, 'benefit_4_title'),
                      subtitle: AppTranslations.tr(lang, 'benefit_4_sub'),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      AppTranslations.tr(lang, 'choose_plan'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PlanCard(
                      title: AppTranslations.tr(lang, 'yearly_plan'),
                      price: '200.000đ',
                      period: context.t('năm'),
                      savings: AppTranslations.tr(lang, 'yearly_saving'),
                      isBestValue: true,
                      bestValueLabel: AppTranslations.tr(lang, 'best_value'),
                      isSelected: _selectedPlan == 'yearly',
                      onTap: () => setState(() => _selectedPlan = 'yearly'),
                    ),
                    const SizedBox(height: 12),
                    PlanCard(
                      title: AppTranslations.tr(lang, 'monthly_plan'),
                      price: '20.000đ',
                      period: context.t('tháng'),
                      isSelected: _selectedPlan == 'monthly',
                      onTap: () => setState(() => _selectedPlan = 'monthly'),
                    ),
                    const SizedBox(height: 32),

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
                                    foregroundColor: AppColors.onTeal,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: _isLoading ? null : _handleStartTrial,
                                  child: Text(
                                    AppTranslations.tr(lang, 'start_trial_btn'),
                                    style: const TextStyle(
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
                                  side: BorderSide(color: AppColors.primary, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _isLoading ? null : _handleUpgrade,
                                child: Text(
                                  '${AppTranslations.tr(lang, 'subscribe_now')} (${_selectedPlan == 'yearly' ? '200.000đ/${context.t('năm')}' : '20.000đ/${context.t('tháng')}'})',
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({required String icon, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          AssetIcon(icon, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
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
