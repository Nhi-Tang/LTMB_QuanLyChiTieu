import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../backend/services/pro_service.dart';
import '../../core/utils/money_input_formatter.dart';
import '../theme/app_colors.dart';
import '../widgets/app_alert_dialog.dart';

class VietQRPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const VietQRPaymentScreen({
    super.key,
    required this.orderData,
  });

  @override
  State<VietQRPaymentScreen> createState() => _VietQRPaymentScreenState();
}

class _VietQRPaymentScreenState extends State<VietQRPaymentScreen> {
  late Timer _countdownTimer;
  late Timer _pollingTimer;
  int _remainingSeconds = 15 * 60; // 15 phút đếm ngược
  bool _isChecking = false;
  bool _isPaid = false;

  @override
  void initState() {
    super.initState();
    // Thời hạn đơn do server quy định (expiresAt), mặc định 15 phút
    final expiresAt = DateTime.tryParse(widget.orderData['expiresAt'] as String? ?? '');
    if (expiresAt != null) {
      _remainingSeconds = expiresAt.difference(DateTime.now()).inSeconds.clamp(0, 24 * 3600);
    }
    _startCountdown();
    _startPolling();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _countdownTimer.cancel();
      }
    });
  }

  void _startPolling() {
    // Polling trạng thái thanh toán mỗi 5 giây
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isPaid) {
        _checkPaymentStatus(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _pollingTimer.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _checkPaymentStatus({bool silent = false}) async {
    if (_isChecking || _isPaid) return;
    if (!silent) {
      setState(() => _isChecking = true);
    }

    try {
      final orderId = widget.orderData['orderId'] as String;
      final result = await ProService.instance.checkOrderStatus(orderId);
      final status = result['status'];

      if (status == 'paid') {
        _isPaid = true;
        _countdownTimer.cancel();
        _pollingTimer.cancel();

        if (!mounted) return;
        setState(() => _isChecking = false);

        _showSuccessDialog();
      } else if (status == 'expired' || status == 'underpaid') {
        _pollingTimer.cancel();
        _countdownTimer.cancel();
        if (!mounted) return;
        setState(() {
          _isChecking = false;
          _remainingSeconds = 0;
        });
        showAppAlertDialog(
          context: context,
          title: status == 'expired' ? 'Đơn hàng đã hết hạn' : 'Chuyển khoản chưa đủ',
          message: status == 'expired'
              ? 'Đơn hàng đã quá thời gian thanh toán. Vui lòng tạo đơn mới. Nếu bạn đã chuyển tiền, gói PRO vẫn được kích hoạt khi hệ thống nhận được giao dịch.'
              : 'Số tiền nhận được thấp hơn giá gói. Vui lòng liên hệ hỗ trợ kèm mã đơn hàng.',
          isSuccess: false,
        );
      } else {
        if (!silent && mounted) {
          setState(() => _isChecking = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đơn hàng đang chờ thanh toán. Vui lòng hoàn tất chuyển khoản.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (!silent && mounted) {
        setState(() => _isChecking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kiểm tra thanh toán: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (!silent && mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  /// Chỉ dùng khi dev: backend phải bật ENABLE_MOCK_PAY
  Future<void> _mockPay() async {
    setState(() => _isChecking = true);
    try {
      await ProService.instance.mockPay(widget.orderData['orderId'] as String);
      if (mounted) setState(() => _isChecking = false);
      await _checkPaymentStatus(silent: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    }
  }

  void _showSuccessDialog() {
    showAppAlertDialog(
      context: context,
      title: 'Thanh toán thành công! 👑',
      message: 'Chúc mừng bạn đã nâng cấp thành công gói Mousey PRO. Mọi tính năng cao cấp đã được mở khóa!',
      isSuccess: true,
    );
    // Tự động quay về sau 2 giây
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label!'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.orderData['orderId'] ?? '';
    final amount = widget.orderData['amount'] ?? 0;
    final planType = widget.orderData['planType'] ?? 'monthly';
    final bank = widget.orderData['bank'] ?? '';
    final accountNo = widget.orderData['accountNo'] ?? '';
    final accountName = widget.orderData['accountName'] ?? '';
    // Nội dung chuyển khoản là mã đơn ngắn do server sinh, webhook dùng mã này để đối soát
    final content = (widget.orderData['content'] ?? orderId).toString();
    final bankId = widget.orderData['bankId'] ?? 'MB';
    final qrUrl = widget.orderData['qrUrl'] as String? ??
        'https://img.vietqr.io/image/$bankId-$accountNo-compact2.png?amount=$amount&addInfo=${Uri.encodeComponent(content)}&accountName=${Uri.encodeComponent(accountName.toString())}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Thanh toán VietQR',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 15-minute countdown timer banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.cardGradientStart.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderBeige),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Đơn hàng hết hạn sau: ',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  Text(
                    _formattedTime,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // QR Code Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Text(
                    planType == 'yearly' ? 'Gói PRO 1 Năm' : 'Gói PRO 1 Tháng',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatMoney(amount as num)}đ',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Dynamic QR image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      qrUrl,
                      height: 240,
                      width: 240,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return SizedBox(
                          height: 240,
                          width: 240,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 240,
                          width: 240,
                          color: AppColors.backgroundCream,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_2_rounded, size: 64, color: AppColors.textSecondary),
                              SizedBox(height: 8),
                              Text(
                                'Không thể tải mã QR.\nVui lòng chuyển khoản thủ công bên dưới.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sử dụng App Ngân hàng bất kỳ để quét mã QR',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bank Transfer Details & Copy Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin chuyển khoản thủ công',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Divider(height: 20),
                  _buildDetailRow('Ngân hàng', bank, copyable: false),
                  _buildDetailRow('Số tài khoản', accountNo, copyable: true, labelName: 'số tài khoản'),
                  _buildDetailRow('Chủ tài khoản', accountName, copyable: false),
                  _buildDetailRow('Số tiền', '${formatMoney(amount)}đ', copyable: true, rawText: amount.toString(), labelName: 'số tiền'),
                  _buildDetailRow('Nội dung chuyển khoản', content, copyable: true, rawText: content, labelName: 'nội dung chuyển khoản', isHighlight: true),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // "Đã chuyển khoản, kiểm tra thanh toán" Button
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
                onPressed: _isChecking ? null : () => _checkPaymentStatus(silent: false),
                child: _isChecking
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Hoàn tất chuyển khoản',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _isChecking ? null : _mockPay,
                icon: const Icon(Icons.bug_report_outlined, size: 18),
                label: const Text('Giả lập thanh toán (chỉ bản debug)'),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Hệ thống tự động kiểm tra giao dịch mỗi 5 giây.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool copyable = false, String? rawText, String? labelName, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isHighlight ? AppColors.primary : AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (copyable) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _copyToClipboard(rawText ?? value, labelName ?? label),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
