import 'package:flutter/material.dart';
import '../../backend/services/auth_service.dart';
import '../widgets/app_alert_dialog.dart';
import '../utils/app_language.dart';
import '../theme/app_colors.dart';
import '../../core/widgets/asset_icon.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static Color get primaryBeige => AppColors.teal;

  bool _isLogin = true;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  // Regex dùng cho validator (kiểm tra khi bấm nút, KHÔNG chặn lúc đang gõ)
  static final RegExp _emailRegex =
  RegExp(r'^[a-zA-Z0-9._+\-]+@[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)+$');
  static final RegExp _phoneRegex = RegExp(r'^(0|\+84)\d{9}$');
  static final RegExp _asciiRegex = RegExp(r'^[\x20-\x7E]+$');

  @override
  void initState() {
    super.initState();
    // App vừa tự đăng xuất (vd. tài khoản bị khóa): báo cho người dùng biết lý do
    final notice = AuthService.pendingNotice;
    if (notice != null) {
      AuthService.pendingNotice = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showAlertDialog(title: context.t('Tài khoản bị khóa'), message: notice, isSuccess: false);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _showAlertDialog({
    required String title,
    required String message,
    bool isSuccess = true,
  }) {
    return showAppAlertDialog(
      context: context,
      title: title,
      message: message,
      isSuccess: isSuccess,
    );
  }

  /// Quên mật khẩu: Firebase gửi link đặt lại mật khẩu vào email đã đăng ký.
  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(
      text: _emailController.text.contains('@') ? _emailController.text.trim() : '',
    );
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const AssetIcon('ui_khoa', size: 32),
                const SizedBox(width: 8),
                Text(
                  context.t('Khôi phục mật khẩu'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('Nhập email đã đăng ký, Mousey sẽ gửi link đặt lại mật khẩu vào email của bạn.'),
                    style: TextStyle(fontSize: 13, color: AppColors.grey500),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: context.t('Email'),
                      prefixIcon: const Padding(padding: EdgeInsets.all(10), child: AssetIcon('ui_thu', size: 26)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? context.t('Vui lòng nhập email') : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(context.t('Hủy'), style: TextStyle(color: AppColors.grey500)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBeige,
                  foregroundColor: AppColors.onTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final email = emailController.text.trim().toLowerCase();

                        // Tài khoản đăng ký bằng SĐT dùng email nội bộ @mousey.local, không nhận được thư
                        if (!email.contains('@') || email.endsWith('@mousey.local')) {
                          showAppAlertDialog(
                            context: dialogCtx,
                            title: AppLanguage.instance.t('Chưa hỗ trợ'),
                            message: AppLanguage.instance.t('Tài khoản đăng ký bằng số điện thoại chưa thể đặt lại mật khẩu qua email. Vui lòng liên hệ hỗ trợ Mousey.'),
                            isSuccess: false,
                          );
                          return;
                        }

                        setDialogState(() => isLoading = true);
                        try {
                          await _authService.sendPasswordResetEmail(email);
                          if (!dialogCtx.mounted) return;
                          Navigator.pop(dialogCtx);
                          if (!mounted) return;
                          showAppAlertDialog(
                            context: context,
                            title: AppLanguage.instance.t('Đã gửi email'),
                            message: AppLanguage.instance.t('Nếu {email} đã đăng ký tài khoản Mousey, link đặt lại mật khẩu đã được gửi tới email này. Hãy kiểm tra cả thư mục Spam.', {'email': email}),
                            isSuccess: true,
                          );
                        } catch (e) {
                          setDialogState(() => isLoading = false);
                          if (!dialogCtx.mounted) return;
                          showAppAlertDialog(
                            context: dialogCtx,
                            title: AppLanguage.instance.t('Lỗi'),
                            message: e.toString().replaceAll('Exception: ', ''),
                            isSuccess: false,
                          );
                        }
                      },
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onTeal),
                      )
                    : Text(
                        context.t('GỬI LINK'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.onTeal),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    try {
      if (_isLogin) {
        // --- LOGIN LOGIC ---
        final user = await _authService.loginUser(email, password);

        if (!mounted) return;

        if (user == null) {
          _showAlertDialog(
            title: context.t('Đăng nhập thất bại'),
            message: context.t('Email/SĐT hoặc mật khẩu không chính xác!'),
            isSuccess: false,
          );
        } else if (!user.isActive) {
          _showAlertDialog(
            title: context.t('Tài khoản bị khóa'),
            message: context.t('Tài khoản của bạn đã bị khóa bởi Quản trị viên.'),
            isSuccess: false,
          );
        } else {
          // AuthGate will automatically handle navigation via authStateChanges()
        }
      } else {
        // --- REGISTER LOGIC ---
        final name = _nameController.text.trim();

        await _authService.registerWithEmail(name, email, password);

        if (!mounted) return;

        await _showAlertDialog(
          title: context.t('Thông báo'),
          message: context.t('Đăng ký tài khoản thành công, vui lòng đăng nhập.'),
          isSuccess: true,
        );

        if (!mounted) return;
        setState(() {
          _isLogin = true;
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        AuthService.pendingNotice = null; // đã báo ngay tại đây
        _showAlertDialog(
          title: context.t('Thông báo'),
          message: e.toString().replaceAll('Exception: ', ''),
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
      // AuthGate will automatically handle navigation via authStateChanges()
    } catch (e) {
      if (mounted) {
        AuthService.pendingNotice = null; // đã báo ngay tại đây
        _showAlertDialog(
          title: context.t('Đăng nhập Google thất bại'),
          message: e.toString().replaceAll('Exception: ', ''),
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    IconData? icon,
    String? asset,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: asset != null
          ? Padding(padding: const EdgeInsets.all(10), child: AssetIcon(asset, size: 26))
          : Icon(icon),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
    );
  }

  Widget _buildModeToggle() {
    Widget tab(String text, bool selected, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: selected ? AppColors.ink : Colors.transparent, width: 2),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? AppColors.ink : AppColors.unselectedTab,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.rule)),
      ),
      child: Row(
        children: [
          tab(context.t('Đăng nhập'), _isLogin, () => setState(() => _isLogin = true)),
          tab(context.t('Đăng ký'), !_isLogin, () => setState(() => _isLogin = false)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Branding Header
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.ink, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/avatar/avatar.jpg',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Mousey',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.t('Quản lý chi tiêu thông minh & hiệu quả'),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey500,
                  ),
                ),

                const SizedBox(height: 32),

                // Card Container for Auth Form
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.rule),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Toggle Switch between Đăng nhập & Đăng ký
                        _buildModeToggle(),
                        const SizedBox(height: 24),

                        // Họ và tên (chỉ khi đăng ký) - cần gõ tiếng Việt có dấu
                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            decoration: _inputDecoration(
                              label: context.t('Họ và tên'),
                              asset: 'tab_ca_nhan',
                            ),
                            validator: (value) {
                              if (!_isLogin && (value == null || value.trim().isEmpty)) {
                                return context.t('Vui lòng nhập họ và tên');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email / SĐT: KHÔNG dùng inputFormatters, kiểm tra bằng validator
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          enableSuggestions: false,
                          textCapitalization: TextCapitalization.none,
                          decoration: _inputDecoration(
                            label: context.t('Email hoặc Số điện thoại'),
                            asset: 'ui_thu',
                          ),
                          validator: (value) {
                            final v = value?.trim() ?? '';
                            if (v.isEmpty) {
                              return context.t('Vui lòng nhập Email hoặc Số điện thoại');
                            }
                            if (!_emailRegex.hasMatch(v) && !_phoneRegex.hasMatch(v)) {
                              return context.t('Email hoặc SĐT không hợp lệ (không dùng chữ có dấu)');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Mật khẩu: KHÔNG dùng inputFormatters, kiểm tra bằng validator
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          autocorrect: false,
                          enableSuggestions: false,
                          textCapitalization: TextCapitalization.none,
                          decoration: _inputDecoration(
                            label: context.t('Mật khẩu'),
                            asset: 'ui_khoa',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.t('Vui lòng nhập mật khẩu');
                            }
                            if (value.length < 6) {
                              return context.t('Mật khẩu phải chứa ít nhất 6 ký tự');
                            }
                            if (!_asciiRegex.hasMatch(value)) {
                              return context.t('Mật khẩu không được chứa chữ có dấu');
                            }
                            return null;
                          },
                        ),

                        if (!_isLogin) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            autocorrect: false,
                            enableSuggestions: false,
                            textCapitalization: TextCapitalization.none,
                            decoration: _inputDecoration(
                              label: context.t('Xác nhận mật khẩu'),
                              asset: 'ui_khoa',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (!_isLogin) {
                                if (value == null || value.isEmpty) {
                                  return context.t('Vui lòng xác nhận mật khẩu');
                                }
                                if (value != _passwordController.text) {
                                  return context.t('Mật khẩu xác nhận không khớp');
                                }
                              }
                              return null;
                            },
                          ),
                        ],

                        if (_isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: Text(
                                context.t('Quên mật khẩu?'),
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 12),

                        const SizedBox(height: 12),

                        // Main Action Button (Đăng nhập / Đăng ký)
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const StadiumBorder(),
                          ),
                          child: _isLoading
                              ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.onTeal,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            _isLogin ? context.t('Đăng nhập') : context.t('Đăng ký tài khoản'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onTeal,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: AppColors.rule, thickness: 1),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text(
                                context.t('Hoặc tiếp tục với'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.grey600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: AppColors.rule, thickness: 1),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Google
                        OutlinedButton(
                          onPressed: _isLoading ? null : _handleGoogleLogin,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: AppColors.ink, width: 1.2),
                            shape: const StadiumBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                child: const Text(
                                  'G',
                                  style: TextStyle(
                                    color: Color(0xFF4285F4),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isLogin ? context.t('Đăng nhập bằng Google') : context.t('Đăng ký bằng Google'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  context.t('Bằng việc tiếp tục, bạn đồng ý với Điều khoản & Chính sách của Mousey.'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
