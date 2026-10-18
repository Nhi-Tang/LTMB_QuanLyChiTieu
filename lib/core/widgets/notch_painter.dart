import 'package:flutter/material.dart';
import '../../frontend/theme/app_colors.dart';

/// CustomPainter vẽ hình khối thanh TabBar với rãnh lõm uốn cong mượt ở vị trí chỉ định
class NotchPainter extends CustomPainter {
  final double notchCenterX;
  final Color backgroundColor;
  final Color borderColor;

  NotchPainter({
    required this.notchCenterX,
    this.backgroundColor = Colors.white,
    this.borderColor = AppColors.borderBeige,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    final w = size.width;
    final h = size.height;
    final cornerRadius = 22.0;

    final notchWidth = 92.0;
    final halfNotch = notchWidth / 2; // 46.0
    final notchDepth = 30.0;

    // Giới hạn an toàn tuyệt đối tránh vẽ giật lùi gây tự cắt Path (Self-intersecting Path Error)
    final minCx = halfNotch + cornerRadius + 4.0; // 46 + 22 + 4 = 72.0
    final maxCx = w - halfNotch - cornerRadius - 4.0;
    final cx = notchCenterX.clamp(minCx, maxCx);

    // 1. Bắt đầu tại góc dưới bên trái
    path.moveTo(0, h);
    path.lineTo(0, cornerRadius);

    // 2. Bo góc trên bên trái
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    // 3. Tiến tới vị trí bắt đầu của rãnh (luôn luôn tịnh tiến tới)
    path.lineTo(cx - halfNotch, 0);

    // 4. Đường cong Bézier đối xứng tạo rãnh lõm mượt
    path.cubicTo(
      cx - halfNotch + 16, 0,
      cx - 22, notchDepth,
      cx, notchDepth,
    );
    path.cubicTo(
      cx + 22, notchDepth,
      cx + halfNotch - 16, 0,
      cx + halfNotch, 0,
    );

    // 5. Tiến tới góc trên bên phải
    path.lineTo(w - cornerRadius, 0);
    path.quadraticBezierTo(w, 0, w, cornerRadius);

    // 6. Cạnh bên phải và đáy khép kín Path
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    // Vẽ hình khối chính
    canvas.drawPath(path, paint);

    // Vẽ đường viền mảnh phía trên
    final topBorderPath = Path();
    topBorderPath.moveTo(0, cornerRadius);
    topBorderPath.quadraticBezierTo(0, 0, cornerRadius, 0);
    topBorderPath.lineTo(cx - halfNotch, 0);
    topBorderPath.cubicTo(
      cx - halfNotch + 16, 0,
      cx - 22, notchDepth,
      cx, notchDepth,
    );
    topBorderPath.cubicTo(
      cx + 22, notchDepth,
      cx + halfNotch - 16, 0,
      cx + halfNotch, 0,
    );
    topBorderPath.lineTo(w - cornerRadius, 0);
    topBorderPath.quadraticBezierTo(w, 0, w, cornerRadius);

    canvas.drawPath(topBorderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant NotchPainter oldDelegate) {
    return oldDelegate.notchCenterX != notchCenterX ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.borderColor != borderColor;
  }
}
