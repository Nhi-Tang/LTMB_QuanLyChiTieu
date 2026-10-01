import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';
import 'auth_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
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
    setState(() {
      _searchQuery = query;
    });
    _loadUsers();
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    if (user.id == widget.currentAdmin.id) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể khóa tài khoản Admin đang đăng nhập!')),
      );
      return;
    }

    await _dbHelper.toggleUserActiveStatus(user.id!, user.isActive);
    if (!mounted) return;
    await _loadUsers();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          user.isActive
              ? 'Đã khóa tài khoản ${user.email}'
              : 'Đã mở khóa tài khoản ${user.email}',
        ),
      ),
    );
  }

  Future<void> _deleteUser(UserModel user) async {
    if (user.id == widget.currentAdmin.id) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xóa tài khoản Admin đang đăng nhập!')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa tài khoản'),
        content: Text('Bạn có chắc chắn muốn xóa tài khoản "${user.name}" (${user.email})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteUser(user.id!);
      if (!mounted) return;
      await _loadUsers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xóa tài khoản ${user.email}')),
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
              isEditing ? 'Chỉnh sửa tài khoản' : 'Thêm tài khoản mới',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email / Số điện thoại',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Vui lòng nhập email' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Quyền hạn (Role)',
                        prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'user',
                          child: Text('Người dùng (User)'),
                        ),
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text('Quản trị viên (Admin)'),
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
                      title: const Text('Kích hoạt tài khoản'),
                      subtitle: Text(
                        isActive ? 'Tài khoản đang hoạt động' : 'Tài khoản bị khóa',
                      ),
                      value: isActive,
                      activeThumbColor: const Color(0xFFFF5252),
                      onChanged: (val) {
                        setDialogState(() => isActive = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5252),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    try {
                      if (isEditing) {
                        final updatedUser = userToEdit.copyWith(
                          name: nameController.text.trim(),
                          email: emailController.text.trim().toLowerCase(),
                          password: passwordController.text,
                          role: selectedRole,
                          isActive: isActive,
                        );
                        await _dbHelper.updateUser(updatedUser);
                        if (!dialogContext.mounted) return;
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Đã cập nhật thông tin tài khoản!')),
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
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Đã tạo tài khoản mới thành công!')),
                        );
                      }
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      _loadUsers();
                    } catch (e) {
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                      );
                    }
                  }
                },
                child: Text(isEditing ? 'Lưu' : 'Tạo tài khoản'),
              ),
            ],
          );
        },
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
    const themeColor = Color(0xFFFF5252);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'PiggySmart - Admin',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: themeColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Đăng xuất',
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
                  title: 'Tổng số TK',
                  value: '${_stats['total']}',
                  icon: Icons.people_alt,
                  color: Colors.blue,
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  title: 'Hoạt động',
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
                hintText: 'Tìm kiếm tài khoản theo tên, email...',
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
                  'Danh sách tài khoản (${_users.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadUsers,
                  tooltip: 'Tải lại',
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
                              'Không tìm thấy tài khoản nào',
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
                                            Text(
                                              user.isActive ? 'Đang hoạt động' : 'Đã khóa',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: user.isActive ? Colors.green : Colors.red,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            if (isSelf) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                '(Bạn)',
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
                                            tooltip: 'Sửa',
                                          ),
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
                                            tooltip: user.isActive ? 'Khóa TK' : 'Mở khóa',
                                          ),
                                          // Delete
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 20),
                                            color: Colors.red[700],
                                            onPressed: () => _deleteUser(user),
                                            tooltip: 'Xóa',
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
        label: const Text('Thêm tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
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
