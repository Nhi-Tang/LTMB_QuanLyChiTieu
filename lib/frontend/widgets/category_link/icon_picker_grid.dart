import 'package:flutter/material.dart';
import '../../../core/widgets/category_icon.dart';
import '../../theme/app_colors.dart';

class IconPickerGrid extends StatelessWidget {
  final String selectedIconKey;
  final ValueChanged<String> onIconSelected;

  const IconPickerGrid({
    super.key,
    required this.selectedIconKey,
    required this.onIconSelected,
  });

  static const List<Map<String, String>> availableIcons = [
    {'key': 'fastfood_rounded', 'label': 'Ăn uống'},
    {'key': 'receipt_rounded', 'label': 'Hóa đơn'},
    {'key': 'directions_bus_rounded', 'label': 'Di chuyển'},
    {'key': 'shopping_bag_rounded', 'label': 'Mua sắm'},
    {'key': 'sports_esports_rounded', 'label': 'Giải trí'},
    {'key': 'medical_services_rounded', 'label': 'Sức khoẻ'},
    {'key': 'content_cut_rounded', 'label': 'Làm đẹp'},
    {'key': 'checkroom_rounded', 'label': 'Quần áo'},
    {'key': 'school_rounded', 'label': 'Học tập'},
    {'key': 'pets_rounded', 'label': 'Thú cưng'},
    {'key': 'child_care_rounded', 'label': 'Con cái'},
    {'key': 'family_restroom_rounded', 'label': 'Gia đình'},
    {'key': 'security_rounded', 'label': 'Bảo hiểm'},
    {'key': 'account_balance_rounded', 'label': 'Thuế/Ngân hàng'},
    {'key': 'work_rounded', 'label': 'Công việc'},
    {'key': 'home_rounded', 'label': 'Nhà ở'},
    {'key': 'money_off_rounded', 'label': 'Tiền nợ'},
    {'key': 'account_balance_wallet_rounded', 'label': 'Ví tiền'},
    {'key': 'card_giftcard_rounded', 'label': 'Quà tặng'},
    {'key': 'storefront_rounded', 'label': 'Bán hàng'},
    {'key': 'trending_up_rounded', 'label': 'Đầu tư'},
    {'key': 'favorite_rounded', 'label': 'Kết hôn'},
    {'key': 'category_rounded', 'label': 'Khác'},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: availableIcons.length,
      itemBuilder: (context, index) {
        final item = availableIcons[index];
        final key = item['key']!;
        final isSelected = selectedIconKey == key;

        return InkWell(
          onTap: () => onIconSelected(key),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.selectedCream : AppColors.cardCream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.selectedBorder : AppColors.borderBeige,
                width: isSelected ? 2 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: CategoryIcon(
              categoryOrIconKey: key,
              size: 32,
            ),
          ),
        );
      },
    );
  }
}
