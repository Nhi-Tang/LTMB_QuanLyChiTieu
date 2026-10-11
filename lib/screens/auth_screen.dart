import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';
import 'admin_management_screen.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const Color primaryBeige = Color(0xFFE5D3AF);
  static const Color accentBeige = Color(0xFFFFF7EB);
  static const Color themeColor = Color(0xFFFCF1D0);

  bool _isLogin = true;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

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
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
              color: isSuccess ? const Color(0xFFE5D3AF) : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuccess ? const Color(0xFFE5D3AF) : Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
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
        final user = await _dbHelper.loginUser(email, password);

        if (!mounted) return;

        if (user == null) {
          _showAlertDialog(
            title: 'Đăng nhập thất bại',
            message: 'Email/SĐT hoặc mật khẩu không chính xác!',
            isSuccess: false,
          );
        } else if (!user.isActive) {
          _showAlertDialog(
            title: 'Tài khoản bị khóa',
            message: 'Tài khoản của bạn đã bị khóa bởi Quản trị viên.',
            isSuccess: false,
          );
        } else {
          if (user.isAdmin) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AdminManagementScreen(currentAdmin: user),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(currentUser: user),
              ),
            );
          }
        }
      } else {
        // --- REGISTER LOGIC ---
        final name = _nameController.text.trim();

        final newUser = UserModel(
          name: name,
          email: email,
          password: password,
          role: 'user', // Default registered users are 'user'
          isActive: true,
          createdAt: DateTime.now().toIso8601String(),
        );

        await _dbHelper.registerUser(newUser);

        if (!mounted) return;

        await _showAlertDialog(
          title: 'Đăng ký thành công',
          message: 'Đăng ký tài khoản thành công! Vui lòng đăng nhập.',
          isSuccess: true,
        );

        setState(() {
          _isLogin = true;
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        _showAlertDialog(
          title: 'Thông báo',
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

  void _handleSocialLogin(String provider) {
    _showAlertDialog(
      title: 'Kết nối mạng xã hội',
      message: 'Tính năng kết nối với $provider đang được cập nhật!',
      isSuccess: true,
    );
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
          tab('Đăng nhập', _isLogin, () => setState(() => _isLogin = true)),
          tab('Đăng ký', !_isLogin, () => setState(() => _isLogin = false)),
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
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: primaryBeige.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.savings_rounded,
                    size: 64,
                    color: accentBeige,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'PiggySmart',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quản lý chi tiêu thông minh & hiệu quả',
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
                              label: 'Họ và tên',
                              icon: Icons.person_outline,
                            ),
                            validator: (value) {
                              if (!_isLogin && (value == null || value.trim().isEmpty)) {
                                return 'Vui lòng nhập họ và tên';
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
                            label: 'Email hoặc Số điện thoại',
                            icon: Icons.email_outlined,
                          ),
                          validator: (value) {
                            final v = value?.trim() ?? '';
                            if (v.isEmpty) {
                              return 'Vui lòng nhập Email hoặc Số điện thoại';
                            }
                            if (!_emailRegex.hasMatch(v) && !_phoneRegex.hasMatch(v)) {
                              return 'Email hoặc SĐT không hợp lệ (không dùng chữ có dấu)';
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
                            label: 'Mật khẩu',
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
                              return 'Vui lòng nhập mật khẩu';
                            }
                            if (value.length < 6) {
                              return 'Mật khẩu phải chứa ít nhất 6 ký tự';
                            }
                            if (!_asciiRegex.hasMatch(value)) {
                              return 'Mật khẩu không được chứa chữ có dấu';
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
                              label: 'Xác nhận mật khẩu',
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
                                  return 'Vui lòng xác nhận mật khẩu';
                                }
                                if (value != _passwordController.text) {
                                  return 'Mật khẩu xác nhận không khớp';
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
                              onPressed: () {
                                _showAlertDialog(
                                  title: 'Quên mật khẩu',
                                  message: 'Chức năng Quên mật khẩu đang được phát triển.',
                                  isSuccess: true,
                                );
                              },
                              child: const Text(
                                'Quên mật khẩu?',
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
                            foregroundColor: const Color(0xFF5D4222),
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
                              color: Color(0xFF5D4222),
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            _isLogin ? 'Đăng nhập' : 'Đăng ký tài khoản',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5D4222),
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
                                'Hoặc tiếp tục với',
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
                          onPressed: () => _handleSocialLogin('Google'),
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
                              const SizedBox(
                                width: 22,
                                height: 22,
                                child: Center(
                                  child: Text(
                                    'G',
                                    style: TextStyle(
                                      color: Color(0xFF4285F4),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isLogin ? 'Đăng nhập bằng Google' : 'Đăng ký bằng Google',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Facebook
                        ElevatedButton(
                          onPressed: () => _handleSocialLogin('Facebook'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1877F2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.facebook, size: 22),
                              const SizedBox(width: 12),
                              Text(
                                _isLogin ? 'Đăng nhập bằng Facebook' : 'Đăng ký bằng Facebook',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Apple
                        OutlinedButton(
                          onPressed: () => _handleSocialLogin('Apple'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.apple, size: 22, color: Colors.white),
                              const SizedBox(width: 12),
                              Text(
                                _isLogin ? 'Đăng nhập bằng Apple' : 'Đăng ký bằng Apple',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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
                  'Bằng việc tiếp tục, bạn đồng ý với Điều khoản & Chính sách của PiggySmart.',
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