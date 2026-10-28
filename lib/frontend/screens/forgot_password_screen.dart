import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../backend/services/auth_service.dart';
import '../../core/widgets/asset_icon.dart';
import '../theme/app_colors.dart';
import '../utils/app_language.dart';
import '../widgets/app_alert_dialog.dart';

/// Quên mật khẩu: nhập email -> nhập mã 6 số gửi qua email -> đặt mật khẩu mới.
/// Đặt lại thành công thì pop về màn đăng nhập, trả về email để điền sẵn.
class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Step { email, code, password }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static final RegExp _emailRegex = RegExp(r'^[a-zA-Z0-9._+\-]+@[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)+$');
  static final RegExp _asciiRegex = RegExp(r'^[\x20-\x7E]+$');

  final AuthService _authService = AuthService();
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  late final TextEditingController _emailController = TextEditingController(text: widget.initialEmail);
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  _Step _step = _Step.email;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _email = '';
  String _resetToken = '';
  int _resendSeconds = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _startResendCountdown(int seconds) {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) timer.cancel();
    });
  }

  Future<void> _showError(Object e) {
    return showAppAlertDialog(
      context: context,
      title: context.t('Lỗi'),
      message: e.toString().replaceAll('Exception: ', ''),
      isSuccess: false,
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await action();
    } catch (e) {
      if (mounted) await _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendCode() async {
    if (_step == _Step.email && !_emailFormKey.currentState!.validate()) return;
    final email = _step == _Step.email ? _emailController.text.trim().toLowerCase() : _email;

    // Tài khoản đăng ký bằng SĐT dùng email nội bộ @mousey.local, không nhận được thư
    if (email.endsWith('@mousey.local')) {
      await _showError(context.t('Tài khoản đăng ký bằng số điện thoại chưa thể đặt lại mật khẩu qua email. Vui lòng liên hệ hỗ trợ Mousey.'));
      return;
    }

    await _run(() async {
      final wait = await _authService.requestPasswordResetCode(email);
      if (!mounted) return;
      _email = email;
      _codeController.clear();
      setState(() => _step = _Step.code);
      _startResendCountdown(wait);
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) return;
    await _run(() async {
      _resetToken = await _authService.verifyPasswordResetCode(_email, code);
      if (!mounted) return;
      setState(() => _step = _Step.password);
    });
  }

  Future<void> _resetPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;
    await _run(() async {
      await _authService.resetPassword(_email, _resetToken, _passwordController.text);
      if (!mounted) return;
      await showAppAlertDialog(
        context: context,
        title: context.t('Thành công'),
        message: context.t('Đổi mật khẩu thành công! Vui lòng đăng nhập bằng mật khẩu mới.'),
        isSuccess: true,
      );
      if (mounted) Navigator.pop(context, _email);
    });
  }

  void _back() {
    if (_step == _Step.code) {
      setState(() => _step = _Step.email);
    } else {
      // Bước mật khẩu mới: quay lại cũng phải xin mã mới, nên về hẳn màn đăng nhập
      Navigator.pop(context);
    }
  }

  InputDecoration _inputDecoration({required String label, required String asset, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Padding(padding: const EdgeInsets.all(10), child: AssetIcon(asset, size: 26)),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
    );
  }

  Widget _primaryButton(String text, VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: const StadiumBorder(),
      ),
      child: _isLoading
          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.onTeal, strokeWidth: 2))
          : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onTeal)),
    );
  }

  Widget _header(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.ink)),
        const SizedBox(height: 8),
        Text(subtitle, style: TextStyle(fontSize: 14, color: AppColors.grey500, height: 1.4)),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(
            context.t('Quên mật khẩu?'),
            context.t('Nhập email đã đăng ký, Mousey sẽ gửi mã xác nhận gồm 6 số vào email của bạn.'),
          ),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _sendCode(),
            decoration: _inputDecoration(label: context.t('Email'), asset: 'ui_thu'),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return context.t('Vui lòng nhập email');
              if (!_emailRegex.hasMatch(value)) return context.t('Email không hợp lệ.');
              return null;
            },
          ),
          const SizedBox(height: 24),
          _primaryButton(context.t('Gửi mã xác nhận'), _sendCode),
        ],
      ),
    );
  }

  Widget _buildCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(
          context.t('Nhập mã xác nhận'),
          context.t('Nếu {email} đã đăng ký tài khoản Mousey, mã gồm 6 số đã được gửi tới email này. Hãy kiểm tra cả thư mục Spam.', {'email': _email}),
        ),
        TextField(
          controller: _codeController,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofillHints: const [AutofillHints.oneTimeCode],
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 12, color: AppColors.ink),
          decoration: const InputDecoration(counterText: '', hintText: '------'),
          onChanged: (v) {
            setState(() {});
            if (v.length == 6) _verifyCode();
          },
        ),
        const SizedBox(height: 24),
        _primaryButton(context.t('Xác nhận'), _codeController.text.length == 6 ? _verifyCode : null),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _isLoading || _resendSeconds > 0 ? null : _sendCode,
          child: Text(
            _resendSeconds > 0
                ? context.t('Gửi lại mã sau {seconds}s', {'seconds': _resendSeconds})
                : context.t('Gửi lại mã'),
            style: TextStyle(fontWeight: FontWeight.w600, color: _resendSeconds > 0 ? AppColors.grey500 : AppColors.ink),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    Widget eye(bool obscure, VoidCallback onPressed) => IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: onPressed,
        );

    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(
            context.t('Đặt lại mật khẩu mới'),
            context.t('Tài khoản: {verifiedEmail}', {'verifiedEmail': _email}),
          ),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            autocorrect: false,
            enableSuggestions: false,
            decoration: _inputDecoration(
              label: context.t('Mật khẩu mới'),
              asset: 'ui_khoa',
              suffixIcon: eye(_obscurePassword, () => setState(() => _obscurePassword = !_obscurePassword)),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return context.t('Vui lòng nhập mật khẩu mới');
              if (v.length < 6) return context.t('Mật khẩu phải chứa ít nhất 6 ký tự');
              if (!_asciiRegex.hasMatch(v)) return context.t('Mật khẩu không được chứa chữ có dấu');
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            autocorrect: false,
            enableSuggestions: false,
            decoration: _inputDecoration(
              label: context.t('Xác nhận mật khẩu mới'),
              asset: 'ui_khoa',
              suffixIcon: eye(_obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return context.t('Vui lòng xác nhận mật khẩu');
              if (v != _passwordController.text) return context.t('Mật khẩu xác nhận không khớp');
              return null;
            },
          ),
          const SizedBox(height: 24),
          _primaryButton(context.t('CẬP NHẬT MẬT KHẨU'), _resetPassword),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _Step.email,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.pageBg,
        appBar: AppBar(backgroundColor: AppColors.pageBg),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: switch (_step) {
              _Step.email => _buildEmailStep(),
              _Step.code => _buildCodeStep(),
              _Step.password => _buildPasswordStep(),
            },
          ),
        ),
      ),
    );
  }
}
