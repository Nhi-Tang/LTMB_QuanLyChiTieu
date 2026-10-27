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
/// Có [onCenterTap] thì chèn nút tròn nổi ở giữa (nút quét hoá đơn).
class NotebookTabBar extends StatelessWidget {
  final List<NotebookTabItemData> items;
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback? onCenterTap;
  final String? centerLabel;

  const NotebookTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onChanged,
    this.onCenterTap,
    this.centerLabel,
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (onCenterTap != null && i == items.length ~/ 2) const Expanded(child: SizedBox()),
                    Expanded(child: _buildItem(i)),
                  ],
                ],
              ),
              if (onCenterTap != null)
                Positioned(
                  top: -20,
                  left: 0,
                  right: 0,
                  child: Center(child: _buildCenterButton()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return Semantics(
      label: centerLabel,
      button: true,
      child: Material(
        color: AppColors.primary,
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: Colors.black38,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.lightImpact();
            onCenterTap!();
          },
          child: const SizedBox(
            width: 62,
            height: 62,
            child: Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CustomPaint(painter: _ScanGlyphPainter()),
              ),
            ),
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

/// Biểu tượng quét: bốn góc khung và một vạch ngang ở giữa.
class _ScanGlyphPainter extends CustomPainter {
  const _ScanGlyphPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.onTeal
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width, h = size.height, len = w * 0.3;
    final path = Path()
      ..moveTo(0, len)..lineTo(0, 0)..lineTo(len, 0)
      ..moveTo(w - len, 0)..lineTo(w, 0)..lineTo(w, len)
      ..moveTo(0, h - len)..lineTo(0, h)..lineTo(len, h)
      ..moveTo(w - len, h)..lineTo(w, h)..lineTo(w, h - len)
      ..moveTo(w * 0.22, h / 2)..lineTo(w * 0.78, h / 2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
