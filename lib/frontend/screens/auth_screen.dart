import 'package:flutter/material.dart';
import '../../backend/services/auth_service.dart';
import '../widgets/app_alert_dialog.dart';
import '../utils/app_language.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const Color primaryBeige = Color(0xFF00BFB5);
  static const Color themeColor = Color(0xFFCCF7F7);

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

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    int step = 1; // 1: Enter email, 2: Enter new password
    bool isLoading = false;
    String verifiedEmail = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.lock_reset_rounded, color: primaryBeige, size: 28),
                const SizedBox(width: 8),
                Text(
                  step == 1 ? context.t('Khôi phục mật khẩu') : context.t('Đặt lại mật khẩu mới'),
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
                  if (step == 1) ...[
                    Text(
                      context.t('Nhập email hoặc số điện thoại đã đăng ký tài khoản của bạn:'),
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: context.t('Email / Số điện thoại'),
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? context.t('Vui lòng nhập Email hoặc SĐT') : null,
                    ),
                  ] else ...[
                    Text(
                      context.t('Tài khoản: {verifiedEmail}', {'verifiedEmail': verifiedEmail}),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: context.t('Mật khẩu mới'),
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return context.t('Vui lòng nhập mật khẩu mới');
                        if (v.length < 6) return context.t('Mật khẩu phải có ít nhất 6 ký tự');
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: context.t('Xác nhận mật khẩu mới'),
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return context.t('Vui lòng xác nhận mật khẩu');
                        if (v != newPasswordController.text) return context.t('Mật khẩu xác nhận không khớp');
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: Text(context.t('Hủy'), style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBeige,
                  foregroundColor: const Color(0xFF00463E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setDialogState(() => isLoading = true);
                          try {
                            if (step == 1) {
                              final email = emailController.text.trim().toLowerCase();
                              final exists = await _authService.isEmailRegistered(email);
                              if (!exists) {
                                setDialogState(() => isLoading = false);
                                if (!dialogCtx.mounted) return;
                                showAppAlertDialog(
                                  context: dialogCtx,
                                  title: AppLanguage.instance.t('Không tìm thấy'),
                                  message: AppLanguage.instance.t('Email hoặc số điện thoại này chưa được đăng ký trong hệ thống!'),
                                  isSuccess: false,
                                );
                                return;
                              }
                              verifiedEmail = email;
                              setDialogState(() {
                                step = 2;
                                isLoading = false;
                              });
                            } else {
                              final newPass = newPasswordController.text;
                              await _authService.updatePasswordByEmail(verifiedEmail, newPass);
                              setDialogState(() => isLoading = false);
                              if (!dialogCtx.mounted) return;
                              Navigator.pop(dialogCtx);
                              if (!mounted) return;
                              showAppAlertDialog(
                                context: context,
                                title: AppLanguage.instance.t('Thành công'),
                                message: AppLanguage.instance.t('Đổi mật khẩu thành công! Vui lòng đăng nhập bằng mật khẩu mới.'),
                                isSuccess: true,
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isLoading = false);
                            if (!dialogCtx.mounted) return;
                            showAppAlertDialog(
                              context: dialogCtx,
                              title: AppLanguage.instance.t('Lỗi'),
                              message: e.toString(),
                              isSuccess: false,
                            );
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00463E)),
                      )
                    : Text(
                        step == 1 ? context.t('TIẾP TỤC') : context.t('CẬP NHẬT MẬT KHẨU'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00463E)),
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
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildModeToggle() {
    Widget tab(String text, bool selected, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: selected ? themeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? Colors.grey[700] : Colors.black,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[500],
        borderRadius: BorderRadius.circular(12),
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
      backgroundColor: const Color(0xFFF8F9FA),
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
                    border: Border.all(color: primaryBeige, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.t('Quản lý chi tiêu thông minh & hiệu quả'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),

                const SizedBox(height: 32),

                // Card Container for Auth Form
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
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
                              icon: Icons.person_outline,
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
                            icon: Icons.email_outlined,
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
                            icon: Icons.lock_outline,
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
                              icon: Icons.lock_reset_outlined,
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
                                  color: primaryBeige,
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
                            backgroundColor: themeColor,
                            foregroundColor: const Color(0xFF00463E),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Color(0xFF00463E),
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            _isLogin ? context.t('Đăng nhập') : context.t('Đăng ký tài khoản'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00463E),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: Colors.grey[300], thickness: 1),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Text(
                                context.t('Hoặc tiếp tục với'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: Colors.grey[300], thickness: 1),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Google
                        OutlinedButton(
                          onPressed: _isLoading ? null : _handleGoogleLogin,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
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
                    color: Colors.grey[500],
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
