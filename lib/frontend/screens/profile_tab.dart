import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../backend/database/db_helper.dart';
import '../../backend/models/user_model.dart';
import '../../backend/services/sync_service.dart';
import '../../backend/services/pro_service.dart';
import '../../backend/services/transaction_service.dart';
import '../../backend/services/ledger_repository.dart';
import '../../core/widgets/asset_icon.dart';
import '../../core/widgets/settings_tile.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/app_translations.dart';
import '../widgets/app_alert_dialog.dart';
import '../widgets/category_link/linked_categories_screen.dart';
import '../widgets/mousey_avatar.dart';
import '../widgets/notification/notification_settings_screen.dart';
import '../widgets/notification/pending_inbox.dart';
import '../widgets/export_options_bottom_sheet.dart';
import 'pro_upgrade_screen.dart';
import '../utils/app_language.dart';

class ProfileTab extends StatefulWidget {
  final UserModel currentUser;
  final String selectedAvatarKey;
  final Function(UserModel updatedUser) onUserUpdated;
  final Function(String newAvatarKey) onAvatarChanged;
  final Function(String newLanguage) onLanguageChanged;
  final VoidCallback onLogout;

  const ProfileTab({
    super.key,
    required this.currentUser,
    required this.selectedAvatarKey,
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
  bool _budgetAlertsEnabled = true;

  bool _isSyncing = false;
  String _syncStateKey = 'synced'; // 'synced', 'syncing', 'error'
  String? _lastSyncTimeFormatted;
  int _pendingCount = 0;


  static Color get primaryBeige => AppColors.primaryBeige;
  static Color get darkBeige => AppColors.darkBeige;
  static Color get accentBeige => AppColors.accentBeige;

  @override
  void initState() {
    super.initState();
    _loadSyncInfo();
    _loadPendingCount();
    _loadLedgers();
    _loadBudgetAlertsSetting();
  }

  Future<void> _loadBudgetAlertsSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _budgetAlertsEnabled = prefs.getBool('budget_alerts_enabled') ?? true;
      });
    }
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
          _lastSyncTimeFormatted = '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
        });
      }
    }
  }

  Future<void> _syncNow() async {
    if (!ProService.instance.isPro) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProUpgradeScreen()),
      );
      return;
    }

    final uid = widget.currentUser.uid;
    if (uid == null) return;

    setState(() {
      _isSyncing = true;
      _syncStateKey = 'syncing';
    });
    try {
      await SyncService.instance.syncAll();
      final ts = await SyncService.instance.getLastSyncTimestamp(uid);
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _syncStateKey = 'synced';
          if (ts != null) {
            final dt = DateTime.fromMillisecondsSinceEpoch(ts);
            _lastSyncTimeFormatted = '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
          }
        });
        showAppAlertDialog(
          context: context,
          title: context.t('Đồng bộ thành công'),
          message: context.t('Đã đồng bộ giao dịch và tiết kiệm với Cloud Firestore thành công!'),
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _syncStateKey = 'error';
        });
        showAppAlertDialog(
          context: context,
          title: context.t('Lỗi đồng bộ'),
          message: e.toString(),
          isSuccess: false,
        );
      }
    }
  }

  void _showAvatarPickerSheet(StateSetter setDialogState) {
    final lang = context.lang;
    final avatars = [
      {'key': 'cat', 'name': 'Mochi Cat'},
      {'key': 'dog', 'name': context.t('Cún con')},
      {'key': 'fox', 'name': context.t('Cáo nhỏ')},
      {'key': 'rabbit', 'name': context.t('Thỏ con')},
      {'key': 'panda', 'name': context.t('Gấu trúc')},
      {'key': 'lion', 'name': context.t('Sư tử')},
      {'key': 'bear', 'name': context.t('Gấu bông')},
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
                    color: AppColors.grey300,
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
                          color: isSel ? primaryBeige : AppColors.grey100,
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
                                color: isSel ? darkBeige : AppColors.black87,
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
    final lang = context.lang;
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
          message: context.t('Đã cập nhật ảnh đại diện từ thiết bị thành công!'),
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppAlertDialog(
          context: context,
          title: context.t('Lỗi chọn ảnh'),
          message: context.t('Không thể mở thư viện ảnh: {e}', {'e': e}),
          isSuccess: false,
        );
      }
    }
  }

  void _showEditProfileDialog() {
    final lang = context.lang;
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
                            decoration: BoxDecoration(
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
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(10),
                          child: AssetIcon('tab_ca_nhan', size: 26),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? context.t('Vui lòng nhập họ và tên') : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: AppTranslations.tr(lang, 'email_or_phone'),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(10),
                          child: AssetIcon('ui_thu', size: 26),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? context.t('Vui lòng nhập Email / SĐT') : null,
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
                  style: TextStyle(color: AppColors.grey500),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentBeige,
                  foregroundColor: AppColors.onTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final newName = nameController.text.trim();
                    final newEmail = emailController.text.trim().toLowerCase();

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
                      title: context.t('Thành công'),
                      message: context.t('Đã cập nhật thông tin cá nhân thành công!'),
                      isSuccess: true,
                    );
                  }
                },
                child: Text(
                  AppTranslations.tr(lang, 'save_changes'),
                  style: const TextStyle(color: AppColors.onTeal, fontWeight: FontWeight.bold),
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
            title: Row(
              children: [
                const AssetIcon('ui_sach', size: 28),
                SizedBox(width: 8),
                Text(context.t('Thêm sổ sách mới'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.t('Nhập tên sổ sách mới để quản lý chi tiêu riêng biệt:'), style: TextStyle(fontSize: 13, color: AppColors.grey500)),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  enabled: !isCreating,
                  maxLength: 40,
                  decoration: InputDecoration(
                    hintText: context.t('VD: Sổ du lịch, Sổ kinh doanh...'),
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
                child: Text(context.t('Hủy'), style: TextStyle(color: AppColors.grey500)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentBeige,
                  foregroundColor: AppColors.onTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isCreating
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.t('Vui lòng nhập tên sổ sách!')), backgroundColor: Colors.orange),
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
                            title: context.t('Thành công'),
                            message: context.t('Đã tạo sổ sách "{name}" thành công!', {'name': name}),
                            isSuccess: true,
                          );
                        } catch (e) {
                          debugPrint('Error creating ledger: $e');
                          setDialogState(() => isCreating = false);
                          
                          if (e is FreePlanLimitException) {
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx); // Đóng dialog nhập tên sổ
                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProUpgradeScreen()),
                            );
                          } else {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                child: isCreating
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: darkBeige))
                    : Text(context.t('Tạo sổ mới'), style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLedgerPickerSheet() {
    final lang = context.lang;
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
                        color: AppColors.grey300,
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
                        leading: const AssetIcon('ui_sach'),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: isSel ? Text(AppTranslations.tr(lang, 'in_use'), style: TextStyle(color: accentBeige, fontSize: 12, fontWeight: FontWeight.bold)) : null,
                        trailing: isSel ? Icon(Icons.check_circle, color: accentBeige) : null,
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
                        final isProUser = ProService.instance.isPro;
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
                              isProUser ? AppTranslations.tr(lang, 'add_ledger_btn') : AppTranslations.tr(lang, 'add_new_ledger'),
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
    if (!ProService.instance.isPro) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProUpgradeScreen()),
      );
      return;
    }

    ExportOptionsBottomSheet.show(
      context,
      currentLedgerId: TransactionService.instance.currentLedgerId,
    );
  }

  void _showDeleteMyDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text(context.t('Cảnh báo xóa dữ liệu'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          context.t('Bạn có chắc chắn muốn xóa toàn bộ giao dịch, tài khoản và danh mục tùy chỉnh? Hành động này không thể hoàn tác!'),
          style: TextStyle(fontSize: 14, color: AppColors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.t('Hủy'), style: TextStyle(color: AppColors.grey500)),
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
                title: context.t('Đã xóa dữ liệu'),
                message: context.t('Toàn bộ dữ liệu tài chính cá nhân đã được làm sạch thành công.'),
                isSuccess: true,
              );
            },
            child: Text(context.t('Xác nhận Xóa'), style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static const Map<ThemeMode, String> _themeModeLabels = {
    ThemeMode.light: 'Sáng',
    ThemeMode.dark: 'Tối',
    ThemeMode.system: 'Theo hệ thống',
  };

  void _showThemePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.t('Giao diện'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ..._themeModeLabels.entries.map((e) {
                  final isSel = AppTheme.instance.value == e.key;
                  return ListTile(
                    title: Text(context.t(e.value), style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                    trailing: isSel ? Icon(Icons.check_circle, color: accentBeige) : null,
                    onTap: () {
                      AppTheme.instance.change(e.key);
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

  void _showLanguagePickerSheet() {
    final lang = context.lang;
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
                    color: AppColors.grey300,
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
                  final isSel = context.lang == l;
                  return ListTile(
                    title: Text(l, style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                    trailing: isSel ? Icon(Icons.check_circle, color: accentBeige) : null,
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
    final lang = context.lang;
    showAppAlertDialog(
      context: context,
      title: AppTranslations.tr(lang, 'rate_app'),
      message: AppTranslations.tr(lang, 'rate_message'),
      isSuccess: true,
    );
  }

  void _showSupportDialog() {
    final lang = context.lang;
    showAppAlertDialog(
      context: context,
      title: AppTranslations.tr(lang, 'contact_support'),
      message: AppTranslations.tr(lang, 'support_message'),
      isSuccess: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTranslations.tr(lang, 'profile'),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 16),

          // Bìa sổ: tên, email, gói FREE/PRO
          ListenableBuilder(
            listenable: ProService.instance,
            builder: (context, _) {
              final isProUser = ProService.instance.isPro;
              return Material(
                color: AppColors.cover,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _showEditProfileDialog,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Gáy sổ
                        Container(width: 14, color: AppColors.coverSpine),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.currentUser.name,
                                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.currentUser.email,
                                        style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isProUser ? AppColors.highlight : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: isProUser ? AppColors.highlight : Colors.white.withValues(alpha: 0.7)),
                                  ),
                                  child: Text(
                                    isProUser ? 'PRO' : 'FREE',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isProUser ? AppColors.ink : Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Tờ giấy nhớ: mời nâng cấp PRO, hoặc số ngày PRO còn lại
          ListenableBuilder(
            listenable: ProService.instance,
            builder: (context, _) {
              final isPro = ProService.instance.isPro;
              return Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                decoration: BoxDecoration(
                  color: AppColors.note,
                  borderRadius: BorderRadius.circular(4),
                  border: Border(bottom: BorderSide(color: AppColors.noteBorder, width: 3)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPro ? context.t('Tài khoản Mousey PRO 👑') : AppTranslations.tr(lang, 'upgrade_pro_title'),
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPro
                                ? (ProService.instance.remainingDays > 0
                                    ? context.t('Còn lại {remainingDays} ngày sử dụng PRO', {'remainingDays': ProService.instance.remainingDays})
                                    : context.t('Đã mở khóa toàn bộ tính năng cao cấp'))
                                : AppTranslations.tr(lang, 'upgrade_pro_desc'),
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    if (!isPro) ...[
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProUpgradeScreen()),
                          );
                        },
                        child: Text(AppTranslations.tr(lang, 'upgrade'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // GROUP 0: TÀI KHOẢN CÁ NHÂN
          _SectionHeaderTitle(AppTranslations.tr(lang, 'personal_account')),
          const SizedBox(height: 8),
          SettingsTileGroup(
            children: [
              SettingsTile(
                leading: const AssetIcon('tab_ca_nhan'),
                title: Text(AppTranslations.tr(lang, 'personal_info'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                subtitle: Text('(${widget.currentUser.name})', style: TextStyle(fontSize: 12, color: AppColors.grey500), overflow: TextOverflow.ellipsis),
                trailing: Icon(Icons.edit_outlined, color: accentBeige),
                onTap: _showEditProfileDialog,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // GROUP: TỰ ĐỘNG THU CHI & NGÂN HÀNG
          _SectionHeaderTitle(AppTranslations.tr(lang, 'auto_finance_banking')),
          const SizedBox(height: 8),
          SettingsTileGroup(
            children: [
              SettingsTile(
                leading: const AssetIcon('ui_thu'),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(AppTranslations.tr(lang, 'pending_confirmation'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
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
                subtitle: Text(AppTranslations.tr(lang, 'approve_bank_tx_sub'), style: TextStyle(fontSize: 12, color: AppColors.grey500), overflow: TextOverflow.ellipsis),
                trailing: Icon(Icons.chevron_right, color: AppColors.grey500),
                onTap: () {
                  PendingInboxSheet.show(
                    context,
                    onTransactionsUpdated: _loadPendingCount,
                  );
                },
              ),
              Divider(height: 1, color: AppColors.rule),
              SettingsTile(
                leading: const AssetIcon('ui_chuong_thong_bao'),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppTranslations.tr(lang, 'bank_notification_settings'),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.note,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.noteBorder),
                      ),
                      child: Text('PRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ink)),
                    ),
                  ],
                ),
                subtitle: Text('Vietcombank, MB, Techcombank, MoMo,...', style: TextStyle(fontSize: 12, color: AppColors.grey500), overflow: TextOverflow.ellipsis),
                trailing: Icon(Icons.chevron_right, color: AppColors.grey500),
                onTap: () {
                  if (!ProService.instance.isPro) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProUpgradeScreen()),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationSettingsScreen(
                      ),
                    ),
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
                leading: const AssetIcon('ui_sach'),
                title: Text(AppTranslations.tr(lang, 'ledger_book'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                subtitle: Text(_activeLedgerName, style: TextStyle(fontSize: 12, color: AppColors.grey500), overflow: TextOverflow.ellipsis),
                trailing: Icon(Icons.chevron_right, color: AppColors.grey500),
                onTap: _showLedgerPickerSheet,
              ),
              Divider(height: 1, color: AppColors.rule),
              SettingsTile(
                leading: const AssetIcon('cat_tat_ca'),
                title: Text(AppTranslations.tr(lang, 'categories_manager'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                subtitle: Text(AppTranslations.tr(lang, 'categories_count_subtitle'), style: TextStyle(fontSize: 12, color: AppColors.grey500), overflow: TextOverflow.ellipsis),
                trailing: Icon(Icons.chevron_right, color: AppColors.grey500),
                onTap: _showCategoriesManagerSheet,
              ),
              Divider(height: 1, color: AppColors.rule),
              SettingsTile(
                leading: const AssetIcon('ui_tai_xuong'),
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
                        color: AppColors.note,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.noteBorder),
                      ),
                      child: Text('PRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ink)),
                    ),
                  ],
                ),
                subtitle: Text('.csv & .xlsx', style: TextStyle(fontSize: 12, color: AppColors.grey500), overflow: TextOverflow.ellipsis),
                trailing: Icon(Icons.chevron_right, color: AppColors.grey500),
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
                leading: const AssetIcon('cat_ngon_ngu'),
                title: Text(AppTranslations.tr(lang, 'language'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                subtitle: Text(context.lang, style: TextStyle(fontSize: 12, color: AppColors.grey500), overflow: TextOverflow.ellipsis),
                trailing: Icon(Icons.chevron_right, color: AppColors.grey500),
                onTap: _showLanguagePickerSheet,
              ),
              Divider(height: 1, color: AppColors.rule),
              SettingsTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(color: Color(0xFFFFFDF8), shape: BoxShape.circle),
                  child: const Icon(Icons.dark_mode_outlined, color: Color(0xFF2E2E2E), size: 20),
                ),
                title: Text(context.t('Giao diện'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                subtitle: Text(context.t(_themeModeLabels[AppTheme.instance.value]!), style: TextStyle(fontSize: 12, color: AppColors.grey500), overflow: TextOverflow.ellipsis),
                trailing: Icon(Icons.chevron_right, color: AppColors.grey500),
                onTap: _showThemePickerSheet,
              ),
              Divider(height: 1, color: AppColors.rule),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                secondary: const AssetIcon('ui_loa'),
                title: Text(AppTranslations.tr(lang, 'daily_reminder'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Text(AppTranslations.tr(lang, 'reminder_subtitle'), style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                value: _dailyReminderEnabled,
                onChanged: (val) {
                  setState(() => _dailyReminderEnabled = val);
                },
              ),
              Divider(height: 1, color: AppColors.rule),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                secondary: const AssetIcon('tab_bao_cao'),
                title: Text(AppTranslations.tr(lang, 'budget_alerts_toggle'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Text(AppTranslations.tr(lang, 'budget_alerts_subtitle'), style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                value: _budgetAlertsEnabled,
                onChanged: (val) async {
                  setState(() => _budgetAlertsEnabled = val);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('budget_alerts_enabled', val);
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // GROUP: ĐỒNG BỘ DỮ LIỆU ĐÁM MÂY (CLOUD SYNC)
          _SectionHeaderTitle(AppTranslations.tr(lang, 'cloud_sync_section')),
          const SizedBox(height: 8),
          SettingsTileGroup(
            children: [
              SettingsTile(
                leading: const AssetIcon('ui_dong_bo'),
                title: Text(AppTranslations.tr(lang, 'sync_status_title'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                subtitle: (() {
                  final translatedStatus = AppTranslations.tr(lang, 'sync_state_$_syncStateKey');
                  final lastSyncStr = _lastSyncTimeFormatted ?? AppTranslations.tr(lang, 'never');
                  return Text('${AppTranslations.tr(lang, 'sync_status_title')}: $translatedStatus · ${AppTranslations.tr(lang, 'last_sync_label')}: $lastSyncStr', style: TextStyle(fontSize: 12, color: AppColors.grey500), overflow: TextOverflow.ellipsis);
                })(),
                trailing: _isSyncing
                    ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: accentBeige))
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentBeige,
                          foregroundColor: AppColors.onTeal,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _syncNow,
                        child: Text(AppTranslations.tr(lang, 'sync_now'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // GROUP: QUẢN LÝ TÀI KHOẢN & BẢO MẬT
          _SectionHeaderTitle(AppTranslations.tr(lang, 'account_security_section')),
          const SizedBox(height: 8),
          SettingsTileGroup(
            children: [
              SettingsTile(
                leading: const AssetIcon('ui_thung_rac'),
                title: Text(AppTranslations.tr(lang, 'delete_all_data'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                subtitle: Text(AppTranslations.tr(lang, 'delete_all_data_sub'), style: TextStyle(fontSize: 12, color: AppColors.grey500), overflow: TextOverflow.ellipsis),
                trailing: Icon(Icons.chevron_right, color: AppColors.grey500),
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
                leading: const AssetIcon('ui_ngoi_sao'),
                title: Text(AppTranslations.tr(lang, 'rate_app'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                trailing: Icon(Icons.chevron_right, color: AppColors.grey500),
                onTap: _showRatingDialog,
              ),
              Divider(height: 1, color: AppColors.rule),
              SettingsTile(
                leading: const AssetIcon('ui_micro'),
                title: Text(AppTranslations.tr(lang, 'contact_support'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                trailing: Icon(Icons.chevron_right, color: AppColors.grey500),
                onTap: _showSupportDialog,
              ),
              Divider(height: 1, color: AppColors.rule),
              SettingsTile(
                leading: const AssetIcon('ui_thong_tin'),
                title: Text(AppTranslations.tr(lang, 'version'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                trailing: Text('v1.0.0 (Pro Ready)', style: TextStyle(fontSize: 13, color: AppColors.grey500, fontWeight: FontWeight.bold)),
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                ),
                title: Text(
                  AppTranslations.tr(lang, 'logout'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(AppTranslations.tr(lang, 'logout_subtitle'), style: TextStyle(fontSize: 12, color: AppColors.grey500), overflow: TextOverflow.ellipsis),
                trailing: Icon(Icons.chevron_right, color: AppColors.grey500),
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
      padding: EdgeInsets.zero,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
