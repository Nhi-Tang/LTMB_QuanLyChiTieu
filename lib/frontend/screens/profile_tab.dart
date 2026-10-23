import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../backend/database/db_helper.dart';
import '../../backend/models/user_model.dart';
import '../../backend/services/sync_service.dart';
import '../../backend/services/pro_service.dart';
import '../../backend/services/transaction_service.dart';
import '../../backend/services/ledger_repository.dart';
import '../../core/widgets/settings_tile.dart';
import '../utils/app_translations.dart';
import '../widgets/app_alert_dialog.dart';
import '../widgets/category_link/linked_categories_screen.dart';
import '../widgets/mousey_avatar.dart';
import '../widgets/notification/notification_settings_screen.dart';
import '../widgets/notification/pending_inbox.dart';
import '../widgets/export_options_bottom_sheet.dart';
import 'pro_upgrade_screen.dart';

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
  bool _dailyReminderEnabled = true;

  bool _isSyncing = false;
  String _syncStatus = 'Đã đồng bộ';
  String _lastSyncText = 'Chưa đồng bộ';
  int _pendingCount = 0;

  static const Color primaryBeige = Color(0xFFFCF1D0);
  static const Color darkBeige = Color(0xFF5D4222);
  static const Color accentBeige = Color(0xFFE5D3AF);

  @override
  void initState() {
    super.initState();
    _loadSyncInfo();
    _loadPendingCount();
    _loadLedgers();
  }

  List<Map<String, dynamic>> _userLedgers = [];
  String _activeLedgerId = '';
  String _activeLedgerName = 'Sổ cá nhân 1';

  Future<void> _loadLedgers() async {
    final uid = widget.currentUser.uid ?? 'default';
    await TransactionService.instance.initActiveLedger(uid);
    final ledgersList = await DatabaseHelper.instance.getLedgers(uid: uid);
    final currentId = TransactionService.instance.currentLedgerId;

    String currentName = 'Sổ cá nhân 1';
    for (var l in ledgersList) {
      if (l['id'] == currentId) {
        currentName = l['name'] as String? ?? 'Sổ cá nhân 1';
        break;
      }
    }

    if (mounted) {
      setState(() {
        _userLedgers = ledgersList;
        _activeLedgerId = currentId;
        _activeLedgerName = currentName;
      });
    }
  }

  Future<void> _loadPendingCount() async {
    final count = await DatabaseHelper.instance.getPendingTransactionsCount();
    if (mounted) {
      setState(() {
        _pendingCount = count;
      });
    }
  }

  Future<void> _loadSyncInfo() async {
    final uid = widget.currentUser.uid;
    if (uid != null) {
      final ts = await SyncService.instance.getLastSyncTimestamp(uid);
      if (ts != null && mounted) {
        final dt = DateTime.fromMillisecondsSinceEpoch(ts);
        setState(() {
          _lastSyncText = '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
        });
      }
    }
  }

  Future<void> _syncNow() async {
    if (!widget.currentUser.isAdmin && !ProService.instance.isPro) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProUpgradeScreen()),
      );
      return;
    }

    final uid = widget.currentUser.uid;
    if (uid == null) return;

    setState(() {
      _isSyncing = true;
      _syncStatus = 'Đang đồng bộ...';
    });
    try {
      await SyncService.instance.syncAll();
      final ts = await SyncService.instance.getLastSyncTimestamp(uid);
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _syncStatus = 'Đã đồng bộ';
          if (ts != null) {
            final dt = DateTime.fromMillisecondsSinceEpoch(ts);
            _lastSyncText = '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
          }
        });
        showAppAlertDialog(
          context: context,
          title: 'Đồng bộ thành công',
          message: 'Đã đồng bộ giao dịch và tiết kiệm với Cloud Firestore thành công!',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _syncStatus = 'Lỗi đồng bộ';
        });
        showAppAlertDialog(
          context: context,
          title: 'Lỗi đồng bộ',
          message: e.toString(),
          isSuccess: false,
        );
      }
    }
  }

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
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: avatars.length,
                  itemBuilder: (context, index) {
                    final item = avatars[index];
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
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSel ? primaryBeige : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSel ? darkBeige : Colors.transparent,
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
                              overflow: TextOverflow.ellipsis,
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
      if (mounted) {
        showAppAlertDialog(
          context: context,
          title: 'Lỗi chọn ảnh',
          message: 'Không thể mở thư viện ảnh: $e',
          isSuccess: false,
        );
      }
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
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              AppTranslations.tr(lang, 'personal_info'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                      decoration: InputDecoration(
                        labelText: AppTranslations.tr(lang, 'full_name'),
                        prefixIcon: const Icon(Icons.person, color: accentBeige),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ và tên' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: AppTranslations.tr(lang, 'email_or_phone'),
                        prefixIcon: const Icon(Icons.email, color: accentBeige),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập Email / SĐT' : null,
                    ),
                  ],
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

  void _showAddNewLedgerDialog() {
    final nameController = TextEditingController();
    bool isCreating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.menu_book_rounded, color: darkBeige),
                SizedBox(width: 8),
                Text('Thêm sổ sách mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nhập tên sổ sách mới để quản lý chi tiêu riêng biệt:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  enabled: !isCreating,
                  maxLength: 40,
                  decoration: InputDecoration(
                    hintText: 'VD: Sổ du lịch, Sổ kinh doanh...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isCreating ? null : () => Navigator.pop(ctx),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentBeige,
                  foregroundColor: darkBeige,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isCreating
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập tên sổ sách!'), backgroundColor: Colors.orange),
                          );
                          return;
                        }

                        setDialogState(() => isCreating = true);

                        try {
                          final uid = widget.currentUser.uid ?? 'default';
                          await LedgerRepository.instance.createLedger(name: name, uid: uid);
                          await _loadLedgers(); // Cập nhật lại UI list

                          if (!ctx.mounted) return;
                          Navigator.pop(ctx); // Đóng dialog

                          if (!mounted) return;
                          showAppAlertDialog(
                            context: context,
                            title: 'Thành công',
                            message: 'Đã tạo sổ sách "$name" thành công!',
                            isSuccess: true,
                          );
                        } catch (e) {
                          debugPrint('Error creating ledger: $e');
                          setDialogState(() => isCreating = false);
                          
                          if (e.toString().contains('Giới hạn gói Free')) {
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx); // Đóng dialog nhập tên sổ
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProUpgradeScreen()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                child: isCreating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: darkBeige))
                    : const Text('Tạo sổ mới', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLedgerPickerSheet() {
    final lang = widget.selectedLanguage;
    final uid = widget.currentUser.uid ?? 'default';

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
              child: SingleChildScrollView(
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
                    ..._userLedgers.map((lMap) {
                      final id = lMap['id'] as String;
                      final name = lMap['name'] as String;
                      final isSel = _activeLedgerId == id;

                      return ListTile(
                        leading: const Icon(Icons.menu_book_rounded, color: accentBeige),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: isSel ? Text(AppTranslations.tr(lang, 'in_use'), style: const TextStyle(color: accentBeige, fontSize: 12, fontWeight: FontWeight.bold)) : null,
                        trailing: isSel ? const Icon(Icons.check_circle, color: accentBeige) : null,
                        onTap: () async {
                          await TransactionService.instance.setCurrentLedgerId(id, uid: uid);
                          await _loadLedgers();
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          showAppAlertDialog(
                            context: context,
                            title: AppTranslations.tr(lang, 'ledger_book'),
                            message: '${AppTranslations.tr(lang, 'ledger_book')}: $name',
                            isSuccess: true,
                          );
                        },
                      );
                    }),
                    const Divider(height: 24),
                    ListenableBuilder(
                      listenable: ProService.instance,
                      builder: (context, _) {
                        final isProUser = ProService.instance.isPro || widget.currentUser.isAdmin;
                        return SizedBox(
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
                            label: Text(
                              isProUser ? 'Thêm sổ mới' : 'Thêm sổ mới (Nâng cấp PRO)',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              if (isProUser) {
                                _showAddNewLedgerDialog();
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ProUpgradeScreen()),
                                );
                              }
                            },
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
      },
    );
  }

  void _showCategoriesManagerSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LinkedCategoriesScreen(ledgerId: TransactionService.instance.currentLedgerId),
      ),
    );
  }

  void _showExportFileDialog() {
    final lang = widget.selectedLanguage;

    if (!widget.currentUser.isAdmin && !ProService.instance.isPro) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProUpgradeScreen()),
      );
      return;
    }

    ExportOptionsBottomSheet.show(
      context,
      selectedLanguage: lang,
      currentLedgerId: TransactionService.instance.currentLedgerId,
    );
  }

  void _showDeleteMyDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Cảnh báo xóa dữ liệu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa toàn bộ giao dịch, tài khoản và danh mục tùy chỉnh? Hành động này không thể hoàn tác!',
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseHelper.instance.clearTransactions();
              TransactionService.instance.notifyUpdated();
              if (!mounted) return;
              showAppAlertDialog(
                context: context,
                title: 'Đã xóa dữ liệu',
                message: 'Toàn bộ dữ liệu tài chính cá nhân đã được làm sạch thành công.',
                isSuccess: true,
              );
            },
            child: const Text('Xác nhận Xóa', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLanguagePickerSheet() {
    final lang = widget.selectedLanguage;
    final languages = ['Tiếng Việt', 'English (US)', '日本語 (Japanese)', '中文 (Chinese)', '한국어 (Korean)'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SingleChildScrollView(
          child: Container(
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
          ListenableBuilder(
            listenable: ProService.instance,
            builder: (context, _) {
              final isProUser = ProService.instance.isPro || widget.currentUser.isAdmin;
              return InkWell(
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
                                    color: isProUser ? primaryBeige : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    isProUser ? 'PRO' : 'FREE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isProUser ? darkBeige : Colors.grey[700],
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
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // PRO Upgrade Banner Card
          ListenableBuilder(
            listenable: ProService.instance,
            builder: (context, _) {
              final isPro = ProService.instance.isPro || widget.currentUser.isAdmin;
              if (isPro) {
                return Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD54F)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF57C00), size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tài khoản Mousey PRO 👑',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ProService.instance.remainingDays > 0
                                  ? 'Còn lại ${ProService.instance.remainingDays} ngày sử dụng PRO'
                                  : 'Đã mở khóa toàn bộ tính năng cao cấp',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF795548)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF3E6C4), Color(0xFFE8D5A3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: Color(0xFF5C3D1E), size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nâng cấp Mousey PRO 👑',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF3B2A17)),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Mở khóa sổ sách không giới hạn, xuất Excel & đồng bộ cloud',
                              style: TextStyle(fontSize: 11, color: Color(0xFF8A7A66)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C3D1E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProUpgradeScreen()),
                          );
                        },
                        child: const Text('Nâng cấp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 20),

          // GROUP 0: TÀI KHOẢN CÁ NHÂN
          _SectionHeaderTitle(AppTranslations.tr(lang, 'personal_account')),
          const SizedBox(height: 8),
          SettingsTileGroup(
            children: [
              SettingsTile(
                leading: const Icon(Icons.person_outline_rounded, color: accentBeige),
                title: Text(AppTranslations.tr(lang, 'personal_info'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                subtitle: Text('(${widget.currentUser.name})', style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.edit_outlined, color: accentBeige),
                onTap: _showEditProfileDialog,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // GROUP: TỰ ĐỘNG THU CHI & NGÂN HÀNG
          _SectionHeaderTitle('TỰ ĐỘNG THU CHI & NGÂN HÀNG'),
          const SizedBox(height: 8),
          SettingsTileGroup(
            children: [
              SettingsTile(
                leading: const Icon(Icons.mark_email_unread_outlined, color: accentBeige),
                title: Row(
                  children: [
                    const Expanded(
                      child: Text('Giao dịch chờ xác nhận', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                    ),
                    if (_pendingCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_pendingCount',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                subtitle: const Text('Duyệt giao dịch ngân hàng đọc tự động', style: TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  PendingInboxSheet.show(context, onTransactionsUpdated: _loadPendingCount);
                },
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFF2EFE6)),
              SettingsTile(
                leading: const Icon(Icons.notifications_active_outlined, color: accentBeige),
                title: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Cài đặt đọc thông báo ngân hàng',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
                subtitle: const Text('Vietcombank, MB, Techcombank, MoMo,...', style: TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  if (!widget.currentUser.isAdmin && !ProService.instance.isPro) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProUpgradeScreen()),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // GROUP 1: CÀI ĐẶT SỔ
          _SectionHeaderTitle(AppTranslations.tr(lang, 'ledger_settings')),
          const SizedBox(height: 8),
          SettingsTileGroup(
            children: [
              SettingsTile(
                leading: const Icon(Icons.menu_book_rounded, color: accentBeige),
                title: Text(AppTranslations.tr(lang, 'ledger_book'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                subtitle: Text(_activeLedgerName, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: _showLedgerPickerSheet,
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFF2EFE6)),
              SettingsTile(
                leading: const Icon(Icons.category_outlined, color: accentBeige),
                title: Text(AppTranslations.tr(lang, 'categories_manager'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                subtitle: Text(AppTranslations.tr(lang, 'categories_count_subtitle'), style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: _showCategoriesManagerSheet,
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFF2EFE6)),
              SettingsTile(
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
                subtitle: const Text('.csv & .xlsx', style: TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: _showExportFileDialog,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // GROUP 2: CÀI ĐẶT ỨNG DỤNG
          _SectionHeaderTitle(AppTranslations.tr(lang, 'app_settings')),
          const SizedBox(height: 8),
          SettingsTileGroup(
            children: [
              SettingsTile(
                leading: const Icon(Icons.language_rounded, color: accentBeige),
                title: Text(AppTranslations.tr(lang, 'language'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                subtitle: Text(widget.selectedLanguage, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
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

          const SizedBox(height: 24),

          // GROUP: ĐỒNG BỘ DỮ LIỆU ĐÁM MÂY (CLOUD SYNC)
          _SectionHeaderTitle('ĐỒNG BỘ DỮ LIỆU ĐÁM MÂY'),
          const SizedBox(height: 8),
          SettingsTileGroup(
            children: [
              SettingsTile(
                leading: const Icon(Icons.cloud_sync_rounded, color: accentBeige),
                title: const Text('Trạng thái đồng bộ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                subtitle: Text('Trạng thái: $_syncStatus · Lần cuối: $_lastSyncText', style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                trailing: _isSyncing
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: accentBeige))
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentBeige,
                          foregroundColor: darkBeige,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _syncNow,
                        child: const Text('Đồng bộ ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // GROUP: QUẢN LÝ TÀI KHOẢN & BẢO MẬT
          _SectionHeaderTitle('QUẢN LÝ TÀI KHOẢN & BẢO MẬT'),
          const SizedBox(height: 8),
          SettingsTileGroup(
            children: [
              SettingsTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                ),
                title: const Text('Xoá toàn bộ dữ liệu', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                subtitle: const Text('Xoá giao dịch, tài khoản & danh mục tuỳ chỉnh', style: TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: _showDeleteMyDataDialog,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // GROUP 3: GIỚI THIỆU
          _SectionHeaderTitle(AppTranslations.tr(lang, 'about')),
          const SizedBox(height: 8),
          SettingsTileGroup(
            children: [
              SettingsTile(
                leading: const Icon(Icons.star_rate_rounded, color: accentBeige),
                title: Text(AppTranslations.tr(lang, 'rate_app'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: _showRatingDialog,
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFF2EFE6)),
              SettingsTile(
                leading: const Icon(Icons.headset_mic_outlined, color: accentBeige),
                title: Text(AppTranslations.tr(lang, 'contact_support'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: _showSupportDialog,
              ),
              const Divider(height: 1, indent: 56, color: Color(0xFFF2EFE6)),
              SettingsTile(
                leading: const Icon(Icons.info_outline_rounded, color: accentBeige),
                title: Text(AppTranslations.tr(lang, 'version'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                trailing: const Text('v1.0.0 (Pro Ready)', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // GROUP: ĐĂNG XUẤT TÀI KHOẢN
          _SectionHeaderTitle(AppTranslations.tr(lang, 'logout').toUpperCase()),
          const SizedBox(height: 8),
          SettingsTileGroup(
            children: [
              SettingsTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                ),
                title: Text(
                  AppTranslations.tr(lang, 'logout'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: const Text('Đăng xuất tài khoản khỏi thiết bị này', style: TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: widget.onLogout,
              ),
            ],
          ),

          const SizedBox(height: 24),
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
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF7A6F62),
          letterSpacing: 0.5,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
