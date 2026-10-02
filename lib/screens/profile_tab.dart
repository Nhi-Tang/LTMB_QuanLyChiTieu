import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';
import '../widgets/app_alert_dialog.dart';
import '../widgets/piggy_avatar.dart';

class ProfileTab extends StatefulWidget {
  final UserModel currentUser;
  final String selectedAvatarKey;
  final Function(UserModel updatedUser) onUserUpdated;
  final Function(String newAvatarKey) onAvatarChanged;
  final VoidCallback onLogout;

  const ProfileTab({
    super.key,
    required this.currentUser,
    required this.selectedAvatarKey,
    required this.onUserUpdated,
    required this.onAvatarChanged,
    required this.onLogout,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // Profile Settings state
  String _selectedLedger = 'Sổ cá nhân 1';
  final List<String> _ledgers = ['Sổ cá nhân 1', 'Sổ gia đình', 'Sổ công việc'];
  String _selectedLanguage = 'Tiếng Việt';
  bool _showBalanceInTransactions = true;
  bool _dailyReminderEnabled = true;

  static const Color primaryGreen = Color(0xFFA5D6A7);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF2E7D32);

  void _showAvatarPickerSheet(StateSetter setDialogState) {
    final avatars = [
      {'key': 'piggy', 'name': 'Piggy Smart 🐷'},
      {'key': 'cat', 'name': 'Mochi Cat 🐱'},
      {'key': 'dog', 'name': 'Cún con 🐶'},
      {'key': 'fox', 'name': 'Cáo nhỏ 🦊'},
      {'key': 'rabbit', 'name': 'Thỏ con 🐰'},
      {'key': 'panda', 'name': 'Gấu trúc 🐼'},
      {'key': 'lion', 'name': 'Sư tử 🦁'},
      {'key': 'bear', 'name': 'Gấu bông 🐻'},
      {'key': 'initials', 'name': 'Chữ cái đầu 👤'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chọn Avatar đại diện',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: darkGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Tải ảnh từ máy / Thư viện', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    showAppAlertDialog(
                      context: context,
                      title: 'Đổi Avatar từ thiết bị',
                      message: 'Đã cập nhật ảnh đại diện từ thiết bị thành công!',
                      isSuccess: true,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: avatars.length,
                itemBuilder: (ctx, i) {
                  final item = avatars[i];
                  final key = item['key'] as String;
                  final isSel = widget.selectedAvatarKey == key;

                  return InkWell(
                    onTap: () {
                      widget.onAvatarChanged(key);
                      setDialogState(() {});
                      Navigator.pop(ctx);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSel ? primaryGreen.withValues(alpha: 0.3) : const Color(0xFFFAF7EE),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSel ? accentGreen : const Color(0xFFE8E2D5),
                          width: isSel ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          buildUserAvatar(
                            avatarKey: key,
                            userName: widget.currentUser.name,
                            size: 38,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['name'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              color: isSel ? darkGreen : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: widget.currentUser.name);
    final emailController = TextEditingController(text: widget.currentUser.email);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.person_outline_rounded, color: accentGreen, size: 28),
                SizedBox(width: 8),
                Text(
                  'Thông tin cá nhân',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Interactive Avatar Selection
                    GestureDetector(
                      onTap: () => _showAvatarPickerSheet(setDialogState),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          buildUserAvatar(
                            avatarKey: widget.selectedAvatarKey,
                            userName: widget.currentUser.name,
                            size: 72,
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: accentGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      keyboardType: TextInputType.text,
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.none,
                      decoration: InputDecoration(
                        labelText: 'Họ và tên',
                        prefixIcon: const Icon(Icons.person, color: accentGreen),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ và tên' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.none,
                      decoration: InputDecoration(
                        labelText: 'Email / Số điện thoại',
                        prefixIcon: const Icon(Icons.email, color: accentGreen),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Vui lòng nhập Email / SĐT' : null,
                    ),
                    if (widget.currentUser.isAdmin) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F8F4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0EBE0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Vai trò tài khoản:',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF555048)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFECB3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Quản trị viên (Admin)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE65100),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final oldName = widget.currentUser.name;
                    final oldEmail = widget.currentUser.email;
                    final newName = nameController.text.trim();
                    final newEmail = emailController.text.trim().toLowerCase();
                    final userId = widget.currentUser.id ?? 0;

                    if (oldName != newName) {
                      await DatabaseHelper.instance.logUserChange(
                        userId: userId,
                        userEmail: widget.currentUser.email,
                        changedField: 'Họ và tên',
                        oldValue: oldName,
                        newValue: newName,
                      );
                    }

                    if (oldEmail != newEmail) {
                      await DatabaseHelper.instance.logUserChange(
                        userId: userId,
                        userEmail: widget.currentUser.email,
                        changedField: 'Email / SĐT',
                        oldValue: oldEmail,
                        newValue: newEmail,
                      );
                    }

                    final updatedUser = widget.currentUser.copyWith(
                      name: newName,
                      email: newEmail,
                    );

                    await DatabaseHelper.instance.updateUser(updatedUser);
                    widget.onUserUpdated(updatedUser);

                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);

                    if (!mounted) return;
                    showAppAlertDialog(
                      context: context,
                      title: 'Thành công',
                      message: 'Đã cập nhật thông tin cá nhân thành công!',
                      isSuccess: true,
                    );
                  }
                },
                child: const Text('LƯU THAY ĐỔI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLedgerPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Cài đặt Sổ sách',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._ledgers.map((ledger) {
                    final isSel = _selectedLedger == ledger;
                    return ListTile(
                      leading: const Icon(Icons.menu_book_rounded, color: accentGreen),
                      title: Text(ledger, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: isSel ? const Text('Đang dùng', style: TextStyle(color: accentGreen, fontSize: 12, fontWeight: FontWeight.bold)) : null,
                      trailing: isSel ? const Icon(Icons.check_circle, color: accentGreen) : null,
                      onTap: () {
                        setState(() => _selectedLedger = ledger);
                        Navigator.pop(ctx);
                        showAppAlertDialog(
                          context: context,
                          title: 'Đã đổi Sổ sách',
                          message: 'Đã chuyển sang sử dụng "$ledger"!',
                          isSuccess: true,
                        );
                      },
                    );
                  }),
                  const Divider(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: darkGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Thêm sổ mới (Nâng cấp PRO)', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        showAppAlertDialog(
                          context: context,
                          title: 'Nâng cấp PiggySmart PRO',
                          message: 'Tính năng quản lý nhiều Sổ sách khả dụng trên phiên bản PiggySmart PRO!',
                          isSuccess: true,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCategoriesManagerSheet() {
    final expenseCategories = [
      'Ăn uống', 'Hóa đơn', 'Di chuyển', 'Mua sắm', 'Giải trí', 'Sức khoẻ', 'Làm đẹp',
      'Quần áo', 'Học tập', 'Thú cưng', 'Con cái', 'Hỗ trợ gia đình', 'Bảo hiểm', 'Thuế', 'Công việc', 'Nhà ở', 'Tiền nợ', 'Khác'
    ];
    final incomeCategories = ['Lương', 'Thưởng', 'Đầu tư', 'Bán hàng', 'Khác'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DefaultTabController(
          length: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Danh mục Thu & Chi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const TabBar(
                  labelColor: accentGreen,
                  indicatorColor: accentGreen,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'Chi tiêu (18)'),
                    Tab(text: 'Thu nhập (5)'),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      ListView.builder(
                        itemCount: expenseCategories.length,
                        itemBuilder: (ctx, i) {
                          final cat = expenseCategories[i];
                          return ListTile(
                            leading: Icon(_getCategoryIconData(cat), color: accentGreen),
                            title: Text(cat, style: const TextStyle(fontWeight: FontWeight.w600)),
                            trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                          );
                        },
                      ),
                      ListView.builder(
                        itemCount: incomeCategories.length,
                        itemBuilder: (ctx, i) {
                          final cat = incomeCategories[i];
                          return ListTile(
                            leading: Icon(_getCategoryIconData(cat), color: accentGreen),
                            title: Text(cat, style: const TextStyle(fontWeight: FontWeight.w600)),
                            trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getCategoryIconData(String category) {
    switch (category) {
      case 'Ăn uống':
        return Icons.fastfood_rounded;
      case 'Hóa đơn':
        return Icons.receipt_rounded;
      case 'Di chuyển':
        return Icons.directions_bus_rounded;
      case 'Mua sắm':
        return Icons.shopping_bag_rounded;
      case 'Giải trí':
        return Icons.sports_esports_rounded;
      case 'Sức khoẻ':
        return Icons.medical_services_rounded;
      case 'Làm đẹp':
        return Icons.content_cut_rounded;
      case 'Quần áo':
        return Icons.checkroom_rounded;
      case 'Học tập':
        return Icons.school_rounded;
      case 'Thú cưng':
        return Icons.pets_rounded;
      case 'Con cái':
        return Icons.child_care_rounded;
      case 'Hỗ trợ gia đình':
        return Icons.family_restroom_rounded;
      case 'Bảo hiểm':
        return Icons.security_rounded;
      case 'Thuế':
        return Icons.account_balance_rounded;
      case 'Công việc':
        return Icons.work_rounded;
      case 'Nhà ở':
        return Icons.home_rounded;
      case 'Tiền nợ':
      case 'Tiền Nợ':
        return Icons.money_off_rounded;
      case 'Lương':
        return Icons.account_balance_wallet_rounded;
      case 'Thưởng':
        return Icons.card_giftcard_rounded;
      case 'Đầu tư':
        return Icons.trending_up_rounded;
      case 'Bán hàng':
        return Icons.storefront_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  void _showExportFileDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.file_download_outlined, color: accentGreen, size: 28),
            SizedBox(width: 8),
            Text('Xuất file báo cáo (Pro)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn định dạng file xuất dữ liệu thu chi cá nhân:',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.description_outlined, color: Color(0xFF1E88E5)),
              title: const Text('Xuất file CSV (.csv)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Phù hợp cho Google Sheets & hệ thống dữ liệu'),
              onTap: () {
                Navigator.pop(ctx);
                showAppAlertDialog(
                  context: context,
                  title: 'Xuất file thành công',
                  message: 'Đã xuất file PiggySmart_Report.csv vào thư mục Tải về!',
                  isSuccess: true,
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined, color: Color(0xFF43A047)),
              title: const Text('Xuất file Excel (.xlsx)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Đầy đủ định dạng & công thức Microsoft Excel'),
              onTap: () {
                Navigator.pop(ctx);
                showAppAlertDialog(
                  context: context,
                  title: 'Xuất file thành công',
                  message: 'Đã xuất file PiggySmart_Report.xlsx vào thư mục Tải về!',
                  isSuccess: true,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePickerSheet() {
    final languages = [
      'English',
      'Tiếng Nhật (日本語)',
      'Tiếng Trung (中文)',
      'Tiếng Hàn (한국어)',
      'Tiếng Việt',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Chọn ngôn ngữ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...languages.map((lang) {
                final isSel = _selectedLanguage == lang;
                return ListTile(
                  title: Text(lang, style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSel ? const Icon(Icons.check_circle, color: accentGreen) : null,
                  onTap: () {
                    setState(() => _selectedLanguage = lang);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showRatingDialog() {
    showAppAlertDialog(
      context: context,
      title: 'Đánh giá PiggySmart',
      message: 'Cảm ơn bạn đã sử dụng PiggySmart! Hãy để lại đánh giá 5 sao trên cửa hàng ứng dụng nhé ⭐⭐⭐⭐⭐',
      isSuccess: true,
    );
  }

  void _showSupportDialog() {
    showAppAlertDialog(
      context: context,
      title: 'Liên hệ hỗ trợ',
      message: 'Hỗ trợ khách hàng PiggySmart:\n• Email: support@piggysmart.com\n• Hotline: 1900-PIGGY\n• Giờ làm việc: 8:00 - 20:00 (T2 - T7)',
      isSuccess: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Profile Header Card
          InkWell(
            onTap: _showEditProfileDialog,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFECE7DB)),
              ),
              child: Row(
                children: [
                  buildUserAvatar(
                    avatarKey: widget.selectedAvatarKey,
                    userName: widget.currentUser.name,
                    size: 72,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.currentUser.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF222222),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: primaryGreen,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'PRO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: darkGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.currentUser.email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF706C66),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // GROUP 0: TÀI KHOẢN CÁ NHÂN
          const _SectionHeaderTitle('TÀI KHOẢN CÁ NHÂN'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFECE7DB)),
            ),
            child: ListTile(
              leading: const Icon(Icons.person_outline_rounded, color: accentGreen),
              title: const Text('Thông tin cá nhân', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: Text('Xem & chỉnh sửa họ tên, email, avatar (${widget.currentUser.name})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              trailing: const Icon(Icons.edit_outlined, color: accentGreen),
              onTap: _showEditProfileDialog,
            ),
          ),

          const SizedBox(height: 24),

          // GROUP 1: CÀI ĐẶT SỔ
          const _SectionHeaderTitle('CÀI ĐẶT SỔ'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFECE7DB)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.menu_book_rounded, color: accentGreen),
                  title: const Text('Sổ sách', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text('Đang dùng: $_selectedLedger', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _showLedgerPickerSheet,
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF2EFE6)),
                ListTile(
                  leading: const Icon(Icons.category_outlined, color: accentGreen),
                  title: const Text('Danh mục chi tiêu / thu nhập', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: const Text('23 danh mục mặc định', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _showCategoriesManagerSheet,
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF2EFE6)),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined, color: accentGreen),
                  title: Row(
                    children: [
                      const Text('Xuất file CSV, XLSX ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECB3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('PRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                      ),
                    ],
                  ),
                  subtitle: const Text('Xuất báo cáo dữ liệu định dạng .csv & .xlsx', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _showExportFileDialog,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // GROUP 2: CÀI ĐẶT ỨNG DỤNG
          const _SectionHeaderTitle('CÀI ĐẶT ỨNG DỤNG'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFECE7DB)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: accentGreen),
                  title: const Text('Ngôn ngữ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text(_selectedLanguage, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _showLanguagePickerSheet,
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF2EFE6)),
                SwitchListTile(
                  secondary: const Icon(Icons.account_balance_wallet_outlined, color: accentGreen),
                  title: const Text('Số dư', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: const Text('Hiển thị số dư sau mỗi lần giao dịch', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  value: _showBalanceInTransactions,
                  activeThumbColor: accentGreen,
                  onChanged: (val) {
                    setState(() => _showBalanceInTransactions = val);
                  },
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF2EFE6)),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined, color: accentGreen),
                  title: const Text('Nhắc nhở hằng ngày', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: const Text('Lời nhắc từ Piggy khi bạn quên ghi chép', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  value: _dailyReminderEnabled,
                  activeThumbColor: accentGreen,
                  onChanged: (val) {
                    setState(() => _dailyReminderEnabled = val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // GROUP 3: GIỚI THIỆU
          const _SectionHeaderTitle('GIỚI THIỆU'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFECE7DB)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.star_rate_rounded, color: accentGreen),
                  title: const Text('Đánh giá PiggySmart', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _showRatingDialog,
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF2EFE6)),
                ListTile(
                  leading: const Icon(Icons.headset_mic_outlined, color: accentGreen),
                  title: const Text('Liên hệ hỗ trợ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _showSupportDialog,
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF2EFE6)),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: accentGreen),
                  title: const Text('Phiên bản', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  trailing: const Text('v1.0.0 (Pro Ready)', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Đăng xuất tài khoản', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
              onPressed: widget.onLogout,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeaderTitle extends StatelessWidget {
  final String title;
  const _SectionHeaderTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: Color(0xFF706C66),
        ),
      ),
    );
  }
}
