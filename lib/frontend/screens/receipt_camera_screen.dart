import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../backend/models/transaction_model.dart';
import '../../backend/services/receipt_scan_service.dart';
import '../utils/app_language.dart';
import '../widgets/app_alert_dialog.dart';
import '../widgets/transaction_sheet/receipt_review_sheet.dart';

/// Màn chụp hoá đơn: camera mở sẵn, khung ngắm, nút chụp và "Chọn ảnh".
/// Đọc xong mở màn kiểm tra; lưu xong thì đóng và trả về true.
class ReceiptCameraScreen extends StatefulWidget {
  final Function(TransactionItem item) onSave;

  const ReceiptCameraScreen({super.key, required this.onSave});

  static Future<bool> open(BuildContext context, {required Function(TransactionItem item) onSave}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ReceiptCameraScreen(onSave: onSave)),
    );
    return saved == true;
  }

  @override
  State<ReceiptCameraScreen> createState() => _ReceiptCameraScreenState();
}

class _ReceiptCameraScreenState extends State<ReceiptCameraScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  // Màn chụp luôn tối như kính ngắm, không theo theme sáng/tối của app
  static const Color _bg = Color(0xFF1E2230);
  static const Color _scanLine = Color(0xFFF2C94C);

  CameraController? _controller;
  bool _cameraFailed = false;
  bool _flashOn = false;
  bool _busy = false;
  late final AnimationController _lineAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lineAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lineAnim.dispose();
    _controller?.dispose();
    super.dispose();
  }

  // Nhả camera khi app ẩn, mở lại khi quay về
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (state == AppLifecycleState.inactive) {
      if (controller == null || !controller.value.isInitialized) return;
      _controller = null;
      controller.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && _controller == null && !_busy) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(back, ResolutionPreset.high, enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _cameraFailed = false;
        _flashOn = false;
      });
    } catch (e) {
      debugPrint('Không mở được camera: $e');
      if (mounted) setState(() => _cameraFailed = true);
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      await controller.setFlashMode(_flashOn ? FlashMode.off : FlashMode.torch);
      if (mounted) setState(() => _flashOn = !_flashOn);
    } catch (e) {
      debugPrint('Không bật được đèn: $e');
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (_busy || controller == null || !controller.value.isInitialized) return;
    try {
      final photo = await controller.takePicture();
      if (_flashOn) {
        await controller.setFlashMode(FlashMode.off);
        if (mounted) setState(() => _flashOn = false);
      }
      await _readAndReview(photo.path);
    } catch (e) {
      debugPrint('Chụp lỗi: $e');
      _showError('Không đọc được ảnh hoá đơn. Bạn thử lại nhé.');
    }
  }

  Future<void> _pickFromGallery() async {
    if (_busy) return;
    final path = await ReceiptScanService.instance.pickFromGallery();
    if (path != null) await _readAndReview(path);
  }

  Future<void> _readAndReview(String path) async {
    setState(() => _busy = true);
    ReceiptScanResult scan;
    try {
      scan = await ReceiptScanService.instance.recognize(path);
    } catch (e) {
      debugPrint('Quét hoá đơn lỗi: $e');
      if (mounted) setState(() => _busy = false);
      _showError('Không đọc được ảnh hoá đơn. Bạn thử lại nhé.');
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);

    if (scan.data.rawText.trim().isEmpty) {
      _showError('Không thấy chữ trên ảnh. Bạn chụp rõ hoá đơn hơn nhé.');
      return;
    }
    final saved = await ReceiptReviewSheet.show(context: context, scan: scan, onSave: widget.onSave);
    // Huỷ ở màn kiểm tra thì ở lại để chụp lại
    if (saved == true && mounted) Navigator.pop(context, true);
  }

  void _showError(String message) {
    if (!mounted) return;
    showAppAlertDialog(
      context: context,
      title: context.t('Thông báo'),
      message: context.t(message),
      isSuccess: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (ready)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.previewSize?.height ?? 1,
                height: controller.value.previewSize?.width ?? 1,
                child: CameraPreview(controller),
              ),
            ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final frameW = constraints.maxWidth * 0.72;
                final frameH = (frameW * 1.3).clamp(0.0, constraints.maxHeight * 0.55);
                return Column(
                  children: [
                    // Đầu màn: đóng | Chụp ảnh | đèn
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                          Expanded(
                            child: Text(
                              context.t('Chụp ảnh'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            tooltip: context.t('Đèn flash'),
                            icon: Icon(
                              _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                              color: _flashOn ? _scanLine : Colors.white,
                              size: 26,
                            ),
                            onPressed: ready ? _toggleFlash : null,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: frameW,
                      height: frameH,
                      child: Stack(
                        children: [
                          Positioned.fill(child: CustomPaint(painter: _FrameCornersPainter())),
                          // Vạch quét vàng chạy lên xuống trong khung
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _lineAnim,
                              builder: (context, child) => Align(
                                alignment: Alignment(0, -0.76 + 1.52 * _lineAnim.value),
                                child: child,
                              ),
                              child: Container(width: frameW * 0.84, height: 2, color: _scanLine),
                            ),
                          ),
                          if (_cameraFailed)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  context.t('Không mở được camera. Bạn có thể chọn ảnh có sẵn.'),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.t('Đưa hoá đơn vào khung để ghi nhanh'),
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    // Nút chụp
                    GestureDetector(
                      onTap: ready ? _capture : null,
                      child: Container(
                        width: 72,
                        height: 72,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ready ? Colors.white : Colors.white24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.image_outlined, size: 18, color: Colors.white),
                      label: Text(context.t('Chọn ảnh'), style: const TextStyle(color: Colors.white, fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 1.2),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
          if (_busy)
            Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 14),
                  Text(context.t('Đang đọc hoá đơn...'), style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Bốn góc bo của khung ngắm.
class _FrameCornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 30.0, r = 10.0;
    final w = size.width, h = size.height;

    Path corner(Offset a, Offset c, Offset b) => Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(c.dx + (a.dx - c.dx).sign * r, c.dy + (a.dy - c.dy).sign * r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + (b.dx - c.dx).sign * r, c.dy + (b.dy - c.dy).sign * r)
      ..lineTo(b.dx, b.dy);

    canvas.drawPath(corner(const Offset(0, len), Offset.zero, const Offset(len, 0)), paint);
    canvas.drawPath(corner(Offset(w - len, 0), Offset(w, 0), Offset(w, len)), paint);
    canvas.drawPath(corner(Offset(0, h - len), Offset(0, h), Offset(len, h)), paint);
    canvas.drawPath(corner(Offset(w - len, h), Offset(w, h), Offset(w, h - len)), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
