import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../backend/database/db_helper.dart';
import '../../backend/models/user_model.dart';
import '../../backend/services/export_service.dart';
import '../utils/app_translations.dart';
import '../widgets/app_alert_dialog.dart';
import '../widgets/category_link/linked_categories_screen.dart';
import '../widgets/mousey_avatar.dart';

class ProfileTab extends StatefulWidget {
  final UserModel currentUser;
  final String selectedAvatarKey;
  final String selectedLanguage;
  final Function(UserModel updatedUser) onUserUpdated;
  final Function(String newAvatarKey) onAvatarChanged;
  final Function(String newLanguage) onLanguageChanged;
  final VoidCallback onLogout;

  const ProfileTab({
    super.key,
    required this.currentUser,
    required this.selectedAvatarKey,
    required this.selectedLanguage,
    required this.onUserUpdated,
    required this.onAvatarChanged,
    required this.onLanguageChanged,
    required this.onLogout,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // Profile Settings state
  String _selectedLedger = 'Sổ cá nhân 1';
  final List<String> _ledgers = ['Sổ cá nhân 1'];
  bool _dailyReminderEnabled = true;

  static const Color primaryBeige = Color(0xFFFCF1D0);
  static const Color darkBeige = Color(0xFF5D4222);
  static const Color accentBeige = Color(0xFFE5D3AF);

  void _showAvatarPickerSheet(StateSetter setDialogState) {
    final lang = widget.selectedLanguage;
    final avatars = [
      {'key': 'cat', 'name': 'Mochi Cat'},
      {'key': 'dog', 'name': 'Cún con'},
      {'key': 'fox', 'name': 'Cáo nhỏ'},
      {'key': 'rabbit', 'name': 'Thỏ con'},
      {'key': 'panda', 'name': 'Gấu trúc'},
      {'key': 'lion', 'name': 'Sư tử'},
      {'key': 'bear', 'name': 'Gấu bông'},
      {'key': 'initials', 'name': 'Mousey'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
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
                Text(
                  AppTranslations.tr(lang, 'choose_avatar'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBeige,
                      foregroundColor: darkBeige,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      AppTranslations.tr(lang, 'upload_from_device'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showDeviceImagePicker(setDialogState);
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
                          color: isSel ? primaryBeige.withValues(alpha: 0.3) : const Color(0xFFFAF7EE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSel ? accentBeige : const Color(0xFFE8E2D5),
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
                                color: isSel ? darkBeige : Colors.black87,
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
          ),
        );
      },
    );
  }

  Future<void> _showDeviceImagePicker(StateSetter setDialogState) async {
    final lang = widget.selectedLanguage;
    Navigator.pop(context); // Close bottom sheet
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        widget.onAvatarChanged(pickedFile.path);
        setDialogState(() {});
        if (!mounted) return;
        showAppAlertDialog(
          context: context,
          title: AppTranslations.tr(lang, 'choose_avatar'),
          message: 'Đã cập nhật ảnh đại diện từ thiết bị thành công!',
          isSuccess: true,
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showEditProfileDialog() {
    final lang = widget.selectedLanguage;
    final nameController = TextEditingController(text: widget.currentUser.name);
    final emailController = TextEditingController(text: widget.currentUser.email);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.person_outline_rounded, color: accentBeige, size: 28),
                const SizedBox(width: 8),
                Text(
                  AppTranslations.tr(lang, 'personal_info'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                              color: accentBeige,
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
                        labelText: AppTranslations.tr(lang, 'full_name'),
                        prefixIcon: const Icon(Icons.person, color: accentBeige),
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
                        labelText: AppTranslations.tr(lang, 'email_or_phone'),
                        prefixIcon: const Icon(Icons.email, color: accentBeige),
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
                          color: const Color(0xFFFFF7EB),
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
          ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  AppTranslations.tr(lang, 'cancel'),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentBeige,
                  foregroundColor: darkBeige,
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
                child: Text(
                  AppTranslations.tr(lang, 'save_changes'),
                  style: const TextStyle(color: darkBeige, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showUpgradeAccountDialog() {
    showAppAlertDialog(
      context: context,
      title: 'Nâng cấp Mousey PRO 👑',
      message: 'Mở khóa tất cả tính năng cao cấp:\n• Thêm không giới hạn Sổ sách quản lý\n• Xuất báo cáo tài chính định dạng Excel (.xlsx) & CSV\n• Lời nhắc ghi chép thông minh khi có thông báo số dư ngân hàng \n• Sao lưu và đồng bộ dữ liệu an toàn',
      isSuccess: true,
    );
  }

  void _showLedgerPickerSheet() {
    final lang = widget.selectedLanguage;
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
                  Text(
                    AppTranslations.tr(lang, 'ledger_settings_title'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._ledgers.map((ledger) {
                    final isSel = _selectedLedger == ledger;
                    return ListTile(
                      leading: const Icon(Icons.menu_book_rounded, color: accentBeige),
                      title: Text(AppTranslations.trLedger(lang, ledger), style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: isSel ? Text(AppTranslations.tr(lang, 'in_use'), style: const TextStyle(color: accentBeige, fontSize: 12, fontWeight: FontWeight.bold)) : null,
                      trailing: isSel ? const Icon(Icons.check_circle, color: accentBeige) : null,
                      onTap: () {
                        setState(() => _selectedLedger = ledger);
                        Navigator.pop(ctx);
                        showAppAlertDialog(
                          context: context,
                          title: AppTranslations.tr(lang, 'ledger_book'),
                          message: '${AppTranslations.tr(lang, 'ledger_book')}: ${AppTranslations.trLedger(lang, ledger)}',
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
                        backgroundColor: primaryBeige,
                        foregroundColor: darkBeige,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(AppTranslations.tr(lang, 'add_new_ledger'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        showAppAlertDialog(
                          context: context,
                          title: 'Nâng cấp Mousey PRO',
                          message: 'Tính năng quản lý nhiều Sổ sách khả dụng trên phiên bản Mousey PRO!',
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LinkedCategoriesScreen(ledgerId: 'default_ledger'),
      ),
    );
  }

  void _showExportFileDialog() {
    final lang = widget.selectedLanguage;

    if (!widget.currentUser.isAdmin) {
      showAppAlertDialog(
        context: context,
        title: 'Nâng cấp Mousey PRO 👑',
        message: 'Tính năng Xuất file báo cáo CSV & Excel (.xlsx) khả dụng trên phiên bản Mousey PRO. Vui lòng nâng cấp tài khoản để sử dụng!',
        isSuccess: false,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.file_download_outlined, color: accentBeige, size: 28),
            const SizedBox(width: 8),
            Text(AppTranslations.tr(lang, 'export_report_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.tr(lang, 'export_report_subtitle'),
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.description_outlined, color: Color(0xFF1E88E5)),
              title: Text(AppTranslations.tr(lang, 'export_csv_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(AppTranslations.tr(lang, 'export_csv_sub')),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final filePath = await ExportService.exportToCsv();
                  if (!ctx.mounted) return;
                  showAppAlertDialog(
                    context: ctx,
                    title: 'Xuất file thành công',
                    message: 'Đã lưu file CSV tại:\n$filePath',
                    isSuccess: true,
                  );
                } catch (e) {
                  if (!ctx.mounted) return;
                  showAppAlertDialog(
                    context: ctx,
                    title: 'Lỗi xuất file',
                    message: e.toString(),
                    isSuccess: false,
                  );
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined, color: Color(0xFF43A047)),
              title: Text(AppTranslations.tr(lang, 'export_excel_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(AppTranslations.tr(lang, 'export_excel_sub')),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final filePath = await ExportService.exportToExcel();
                  if (!ctx.mounted) return;
                  showAppAlertDialog(
                    context: ctx,
                    title: 'Xuất file thành công',
                    message: 'Đã lưu file Excel tại:\n$filePath',
                    isSuccess: true,
                  );
                } catch (e) {
                  if (!ctx.mounted) return;
                  showAppAlertDialog(
                    context: ctx,
                    title: 'Lỗi xuất file',
                    message: e.toString(),
                    isSuccess: false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePickerSheet() {
    final lang = widget.selectedLanguage;
    final languages = [
      'English',
      '日本語',
      '中文',
      '한국어',
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
              Text(
                AppTranslations.tr(lang, 'language'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...languages.map((l) {
                final isSel = widget.selectedLanguage == l;
                return ListTile(
                  title: Text(l, style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSel ? const Icon(Icons.check_circle, color: accentBeige) : null,
                  onTap: () {
                    widget.onLanguageChanged(l);
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
    final lang = widget.selectedLanguage;
    showAppAlertDialog(
      context: context,
      title: AppTranslations.tr(lang, 'rate_app'),
      message: AppTranslations.tr(lang, 'rate_message'),
      isSuccess: true,
    );
  }

  void _showSupportDialog() {
    final lang = widget.selectedLanguage;
    showAppAlertDialog(
      context: context,
      title: AppTranslations.tr(lang, 'contact_support'),
      message: AppTranslations.tr(lang, 'support_message'),
      isSuccess: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.selectedLanguage;

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
                                color: widget.currentUser.isAdmin ? primaryBeige : Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                widget.currentUser.isAdmin ? 'PRO' : 'FREE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: widget.currentUser.isAdmin ? darkBeige : Colors.grey[700],
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
          _SectionHeaderTitle(AppTranslations.tr(lang, 'personal_account')),
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
                  leading: const Icon(Icons.person_outline_rounded, color: accentBeige),
                  title: Text(AppTranslations.tr(lang, 'personal_info'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text('(${widget.currentUser.name})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.edit_outlined, color: accentBeige),
                  onTap: _showEditProfileDialog,
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF2EFE6)),
                ListTile(
                  leading: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFA000)),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppTranslations.tr(lang, 'upgrade_account'),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
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
                  subtitle: Text(AppTranslations.tr(lang, 'upgrade_account_subtitle'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _showUpgradeAccountDialog,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // GROUP 1: CÀI ĐẶT SỔ
          _SectionHeaderTitle(AppTranslations.tr(lang, 'ledger_settings')),
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
                  leading: const Icon(Icons.menu_book_rounded, color: accentBeige),
                  title: Text(AppTranslations.tr(lang, 'ledger_book'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text(AppTranslations.trLedger(lang, _selectedLedger), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _showLedgerPickerSheet,
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF2EFE6)),
                ListTile(
                  leading: const Icon(Icons.category_outlined, color: accentBeige),
                  title: Text(AppTranslations.tr(lang, 'categories_manager'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text(AppTranslations.tr(lang, 'categories_count_subtitle'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _showCategoriesManagerSheet,
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF2EFE6)),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined, color: accentBeige),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppTranslations.tr(lang, 'export_files'),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
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
                  subtitle: const Text('.csv & .xlsx', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _showExportFileDialog,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // GROUP 2: CÀI ĐẶT ỨNG DỤNG
          _SectionHeaderTitle(AppTranslations.tr(lang, 'app_settings')),
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
                  leading: const Icon(Icons.language_rounded, color: accentBeige),
                  title: Text(AppTranslations.tr(lang, 'language'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text(widget.selectedLanguage, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _showLanguagePickerSheet,
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF2EFE6)),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined, color: accentBeige),
                  title: Text(AppTranslations.tr(lang, 'daily_reminder'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text(AppTranslations.tr(lang, 'reminder_subtitle'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  value: _dailyReminderEnabled,
                  activeThumbColor: accentBeige,
                  onChanged: (val) {
                    setState(() => _dailyReminderEnabled = val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // GROUP 3: GIỚI THIỆU
          _SectionHeaderTitle(AppTranslations.tr(lang, 'about')),
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
                  leading: const Icon(Icons.star_rate_rounded, color: accentBeige),
                  title: Text(AppTranslations.tr(lang, 'rate_app'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _showRatingDialog,
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF2EFE6)),
                ListTile(
                  leading: const Icon(Icons.headset_mic_outlined, color: accentBeige),
                  title: Text(AppTranslations.tr(lang, 'contact_support'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _showSupportDialog,
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF2EFE6)),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: accentBeige),
                  title: Text(AppTranslations.tr(lang, 'version'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
              label: Text(
                AppTranslations.tr(lang, 'logout'),
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
              ),
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
