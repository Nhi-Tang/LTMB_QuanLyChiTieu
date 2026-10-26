import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../backend/database/db_helper.dart';
import '../../backend/models/user_model.dart';
import 'auth_screen.dart';
import '../utils/app_language.dart';

class AdminManagementScreen extends StatefulWidget {
  final UserModel currentAdmin;

  const AdminManagementScreen({super.key, required this.currentAdmin});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Map<String, int> _stats = {'total': 0, 'admins': 0, 'active': 0};

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  late UserModel _currentAdmin;

  @override
  void initState() {
    super.initState();
    _currentAdmin = widget.currentAdmin;
    _loadUsers();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final isActiveVal = data['isActive'];
        bool isActiveBool = true;
        if (isActiveVal is bool) {
          isActiveBool = isActiveVal;
        } else if (isActiveVal is int) {
          isActiveBool = isActiveVal == 1;
        }

        final user = UserModel(
          id: doc.id.hashCode,
          name: data['name'] as String? ?? 'User',
          email: data['email'] as String? ?? '',
          password: data['password'] as String? ?? '',
          role: data['role'] as String? ?? 'user',
          isActive: isActiveBool,
          createdAt: data['createdAt'] as String? ?? DateTime.now().toIso8601String(),
          uid: doc.id,
          photoUrl: data['photoUrl'] as String?,
          provider: data['provider'] as String? ?? 'password',
          plan: data['plan'] as String? ?? 'free',
          proExpiredAt: data['proExpiredAt'] as String?,
          lastLoginAt: data['lastLoginAt'] as String?,
        );
        await _dbHelper.insertOrUpdateUser(user);
      }
    } catch (e) {
      debugPrint('Error syncing users from Firestore: $e');
    }

    final users = _searchQuery.isEmpty
        ? await _dbHelper.getAllUsers()
        : await _dbHelper.searchUsers(_searchQuery);
    final stats = await _dbHelper.getUserStats();

    if (!mounted) return;

    setState(() {
      _users = users;
      _stats = stats;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = query;
      });
      _loadUsers();
    });
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
              color: isSuccess ? const Color(0xFF00BFB5) : Colors.red,
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
              backgroundColor: isSuccess ? const Color(0xFF00BFB5) : Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    if (user.id == widget.currentAdmin.id) {
      if (!mounted) return;
      _showAlertDialog(
        title: context.t('Cảnh báo'),
        message: context.t('Không thể khóa tài khoản Admin đang đăng nhập!'),
        isSuccess: false,
      );
      return;
    }

    await _dbHelper.toggleUserActiveStatus(user.id!, user.isActive);
    if (!mounted) return;
    await _loadUsers();
    if (!mounted) return;
    _showAlertDialog(
      title: context.t('Cập nhật trạng thái'),
      message: user.isActive
          ? context.t('Đã khóa tài khoản {email}', {'email': user.email})
          : context.t('Đã mở khóa tài khoản {email}', {'email': user.email}),
      isSuccess: true,
    );
  }

  Future<void> _deleteUser(UserModel user) async {
    if (user.id == widget.currentAdmin.id) {
      if (!mounted) return;
      _showAlertDialog(
        title: context.t('Cảnh báo'),
        message: context.t('Không thể xóa tài khoản Admin đang đăng nhập!'),
        isSuccess: false,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.t('Xác nhận xóa tài khoản')),
        content: Text(context.t('Bạn có chắc chắn muốn xóa tài khoản "{name}" ({email})?', {'name': user.name, 'email': user.email})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.t('Hủy'), style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.t('Xóa'), style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteUser(user.id!);
      if (!mounted) return;
      await _loadUsers();
      if (!mounted) return;
      _showAlertDialog(
        title: context.t('Xóa tài khoản thành công'),
        message: context.t('Đã xóa tài khoản {email} khỏi hệ thống!', {'email': user.email}),
        isSuccess: true,
      );
    }
  }

  void _showUserFormDialog({UserModel? userToEdit}) {
    final isEditing = userToEdit != null;
    final nameController = TextEditingController(text: userToEdit?.name ?? '');
    final emailController = TextEditingController(text: userToEdit?.email ?? '');
    final passwordController = TextEditingController(text: userToEdit?.password ?? '');
    String selectedRole = userToEdit?.role ?? 'user';
    bool isActive = userToEdit?.isActive ?? true;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              isEditing ? context.t('Chỉnh sửa tài khoản') : context.t('Thêm tài khoản mới'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    TextFormField(
                      controller: nameController,
                      keyboardType: TextInputType.text,
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.none,
                      decoration: InputDecoration(
                        labelText: context.t('Họ và tên'),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? context.t('Vui lòng nhập họ tên') : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.none,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._\-+]')),
                      ],
                      decoration: InputDecoration(
                        labelText: context.t('Email / Số điện thoại'),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? context.t('Vui lòng nhập email') : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.none,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\x20-\x7E]')),
                      ],
                      decoration: InputDecoration(
                        labelText: context.t('Mật khẩu'),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? context.t('Vui lòng nhập mật khẩu') : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: InputDecoration(
                        labelText: context.t('Quyền hạn (Role)'),
                        prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'user',
                          child: Text(context.t('Người dùng (User)')),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text(context.t('Quản trị viên (Admin)')),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedRole = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: Text(context.t('Kích hoạt tài khoản')),
                      subtitle: Text(
                        isActive ? context.t('Tài khoản đang hoạt động') : context.t('Tài khoản bị khóa'),
                      ),
                      value: isActive,
                      activeThumbColor: const Color(0xFF6FCF97),
                      onChanged: (val) {
                        setDialogState(() => isActive = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(context.t('Hủy')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6FCF97),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    try {
                      if (isEditing) {
                        final oldName = userToEdit.name;
                        final oldEmail = userToEdit.email;
                        final oldRole = userToEdit.role;
                        final newName = nameController.text.trim();
                        final newEmail = emailController.text.trim().toLowerCase();
                        final userId = userToEdit.id ?? 0;

                        if (oldName != newName) {
                          await _dbHelper.logUserChange(
                            userId: userId,
                            userEmail: userToEdit.email,
                            changedField: 'Họ và tên',
                            oldValue: oldName,
                            newValue: newName,
                          );
                        }

                        if (oldEmail != newEmail) {
                          await _dbHelper.logUserChange(
                            userId: userId,
                            userEmail: userToEdit.email,
                            changedField: 'Email / SĐT',
                            oldValue: oldEmail,
                            newValue: newEmail,
                          );
                        }

                        if (oldRole != selectedRole) {
                          await _dbHelper.logUserChange(
                            userId: userId,
                            userEmail: userToEdit.email,
                            changedField: 'Quyền hạn (Role)',
                            oldValue: oldRole,
                            newValue: selectedRole,
                          );
                        }

                        final updatedUser = userToEdit.copyWith(
                          name: newName,
                          email: newEmail,
                          password: passwordController.text,
                          role: selectedRole,
                          isActive: isActive,
                        );
                        await _dbHelper.updateUser(updatedUser);
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        if (!mounted) return;
                        _showAlertDialog(
                          title: AppLanguage.instance.t('Cập nhật thành công'),
                          message: AppLanguage.instance.t('Đã cập nhật thông tin tài khoản!'),
                          isSuccess: true,
                        );
                      } else {
                        final newUser = UserModel(
                          name: nameController.text.trim(),
                          email: emailController.text.trim().toLowerCase(),
                          password: passwordController.text,
                          role: selectedRole,
                          isActive: isActive,
                          createdAt: DateTime.now().toIso8601String(),
                        );
                        await _dbHelper.registerUser(newUser);
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        if (!mounted) return;
                        _showAlertDialog(
                          title: AppLanguage.instance.t('Tạo tài khoản thành công'),
                          message: AppLanguage.instance.t('Đã tạo tài khoản mới thành công!'),
                          isSuccess: true,
                        );
                      }
                      if (mounted) _loadUsers();
                    } catch (e) {
                      if (!mounted) return;
                      _showAlertDialog(
                        title: AppLanguage.instance.t('Lỗi'),
                        message: e.toString().replaceAll('Exception: ', ''),
                        isSuccess: false,
                      );
                    }
                  }
                },
                child: Text(isEditing ? context.t('Lưu') : context.t('Tạo tài khoản')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAdminProfileDialog() {
    final nameController = TextEditingController(text: _currentAdmin.name);
    final emailController = TextEditingController(text: _currentAdmin.email);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF00BFB5), size: 28),
            SizedBox(width: 8),
            Text(
              context.t('Thông tin cá nhân Admin'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('Xem và chỉnh sửa thông tin tài khoản Quản trị viên:'),
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  keyboardType: TextInputType.text,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.none,
                  decoration: InputDecoration(
                    labelText: context.t('Họ và tên'),
                    prefixIcon: const Icon(Icons.person, color: Color(0xFF00BFB5)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? context.t('Vui lòng nhập họ và tên') : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.none,
                  decoration: InputDecoration(
                    labelText: context.t('Email / Số điện thoại'),
                    prefixIcon: const Icon(Icons.email, color: Color(0xFF00BFB5)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? context.t('Vui lòng nhập Email / SĐT') : null,
                ),
              ],
            ),
          ),
        ),
      ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.t('Hủy'), style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFB5),
              foregroundColor: const Color(0xFF00463E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final oldName = _currentAdmin.name;
                final oldEmail = _currentAdmin.email;
                final newName = nameController.text.trim();
                final newEmail = emailController.text.trim().toLowerCase();
                final userId = _currentAdmin.id ?? 0;

                if (oldName != newName) {
                  await _dbHelper.logUserChange(
                    userId: userId,
                    userEmail: _currentAdmin.email,
                    changedField: 'Họ và tên',
                    oldValue: oldName,
                    newValue: newName,
                  );
                }

                if (oldEmail != newEmail) {
                  await _dbHelper.logUserChange(
                    userId: userId,
                    userEmail: _currentAdmin.email,
                    changedField: 'Email / SĐT',
                    oldValue: oldEmail,
                    newValue: newEmail,
                  );
                }

                final updatedAdmin = _currentAdmin.copyWith(
                  name: newName,
                  email: newEmail,
                );

                await _dbHelper.updateUser(updatedAdmin);

                if (!mounted) return;
                setState(() {
                  _currentAdmin = updatedAdmin;
                });

                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadUsers();

                _showAlertDialog(
                  title: AppLanguage.instance.t('Thành công'),
                  message: AppLanguage.instance.t('Đã cập nhật thông tin tài khoản Admin thành công!'),
                  isSuccess: true,
                );
              }
            },
            child: Text(context.t('LƯU THAY ĐỔI'), style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF00BFB5);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.admin_panel_settings, color: Colors.white),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Mousey - Admin',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: themeColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            tooltip: context.t('Thông tin cá nhân Admin'),
            onPressed: _showAdminProfileDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: context.t('Đăng xuất'),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stat Dashboard Cards Header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: themeColor.withValues(alpha: 0.08),
            child: Row(
              children: [
                _buildStatCard(
                  title: context.t('Tổng số TK'),
                  value: '${_stats['total']}',
                  icon: Icons.people_alt,
                  color: Colors.blue,
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  title: context.t('Hoạt động'),
                  value: '${_stats['active']}',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  title: 'Admin',
                  value: '${_stats['admins']}',
                  icon: Icons.security,
                  color: Colors.orange,
                ),
              ],
            ),
          ),

          // Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: context.t('Tìm kiếm tài khoản theo tên, email...'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
          ),

          // Users List Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.t('Danh sách tài khoản ({count})', {'count': _users.length}),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadUsers,
                  tooltip: context.t('Tải lại'),
                ),
              ],
            ),
          ),

          // Users ListView
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              context.t('Không tìm thấy tài khoản nào'),
                              style: TextStyle(color: Colors.grey[600], fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final isSelf = user.id == widget.currentAdmin.id;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 1.5,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  // User Avatar Icon
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: user.isAdmin
                                        ? Colors.orange[100]
                                        : themeColor.withValues(alpha: 0.15),
                                    child: Icon(
                                      user.isAdmin
                                          ? Icons.admin_panel_settings
                                          : Icons.person,
                                      color: user.isAdmin ? Colors.orange[800] : themeColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // User Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                user.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            // Role Badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: user.isAdmin
                                                    ? Colors.orange[100]
                                                    : Colors.blue[50],
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                user.role.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: user.isAdmin
                                                      ? Colors.orange[900]
                                                      : Colors.blue[800],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          user.email,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              user.isActive
                                                  ? Icons.check_circle
                                                  : Icons.lock,
                                              size: 14,
                                              color: user.isActive ? Colors.green : Colors.red,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                user.isActive ? context.t('Đang hoạt động') : context.t('Đã khóa'),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: user.isActive ? Colors.green : Colors.red,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isSelf) ...[
                                              const SizedBox(width: 6),
                                              Text(
                                                context.t('(Bạn)'),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic,
                                                  color: themeColor,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Actions Column
                                  Column(
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Edit
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 20),
                                            color: Colors.blue[700],
                                            onPressed: () => _showUserFormDialog(userToEdit: user),
                                            tooltip: context.t('Sửa'),
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(6),
                                          ),
                                          const SizedBox(width: 4),
                                          // Lock/Unlock Switch
                                          IconButton(
                                            icon: Icon(
                                              user.isActive
                                                  ? Icons.lock_open_outlined
                                                  : Icons.lock_outline,
                                              size: 20,
                                            ),
                                            color: user.isActive ? Colors.orange : Colors.green,
                                            onPressed: () => _toggleUserStatus(user),
                                            tooltip: user.isActive ? context.t('Khóa TK') : context.t('Mở khóa'),
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(6),
                                          ),
                                          const SizedBox(width: 4),
                                          // Delete
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 20),
                                            color: Colors.red[700],
                                            onPressed: () => _deleteUser(user),
                                            tooltip: context.t('Xóa'),
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(6),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        onPressed: () => _showUserFormDialog(),
        icon: const Icon(Icons.person_add),
        label: Text(context.t('Thêm tài khoản'), style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
