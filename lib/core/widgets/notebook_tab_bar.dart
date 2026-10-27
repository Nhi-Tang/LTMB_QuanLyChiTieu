import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../frontend/theme/app_colors.dart';

class NotebookTabItemData {
  final String keyName;
  final String label;
  final String assetPath;

  const NotebookTabItemData({
    required this.keyName,
    required this.label,
    required this.assetPath,
  });
}

/// Thanh tab dưới kiểu "cuốn sổ": nền giấy, một đường kẻ phía trên,
/// tab đang chọn có vạch mực ngắn phía trên icon.
class NotebookTabBar extends StatelessWidget {
  final List<NotebookTabItemData> items;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const NotebookTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Nền gần trắng trùng nền sẵn có của ảnh icon, để không lộ khung vuông quanh icon
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.rule)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(child: _buildItem(i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int index) {
    final item = items[index];
    final selected = index == currentIndex;
    return Semantics(
      label: item.label,
      selected: selected,
      button: true,
      child: InkWell(
        onTap: () {
          if (selected) return;
          HapticFeedback.selectionClick();
          onChanged(index);
        },
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 28 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.tealDark,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
              ),
            ),
            const Spacer(),
            // Ảnh icon có sẵn nền trắng: ở nền tối làm mờ sẽ thành ô xám,
            // nên chế độ tối giữ icon rõ, bo góc như ô icon ở màn Cá nhân
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: selected || AppColors.isDark ? 1 : 0.6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(item.assetPath, width: 46, height: 46),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
