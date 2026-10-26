import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_language.dart';

class InfoBanner extends StatefulWidget {
  const InfoBanner({super.key});

  @override
  State<InfoBanner> createState() => _InfoBannerState();
}

class _InfoBannerState extends State<InfoBanner> {
  bool _isVisible = true;
  static const String _prefKey = 'dismissed_category_info_banner';

  @override
  void initState() {
    super.initState();
    _checkDismissedStatus();
  }

  Future<void> _checkDismissedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool(_prefKey) ?? false;
    if (dismissed && mounted) {
      setState(() {
        _isVisible = false;
      });
    }
  }

  Future<void> _dismissBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
    if (mounted) {
      setState(() {
        _isVisible = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.selectedCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.selectedBorder, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('Quản lý & Liên kết danh mục'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.t('Bạn có thể liên kết hoặc hủy liên kết danh mục cho từng Sổ sách. Kéo thả để sắp xếp thứ tự hiển thị danh mục.'),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSub,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _dismissBanner,
            child: Padding(
              padding: EdgeInsets.all(2.0),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.textSub,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
