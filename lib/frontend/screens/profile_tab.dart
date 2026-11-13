import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../backend/database/db_helper.dart';
import '../../backend/models/user_model.dart';
import '../../backend/services/transaction_service.dart';
import '../../core/widgets/asset_icon.dart';
import '../../core/widgets/settings_tile.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/app_translations.dart';
import '../widgets/app_alert_dialog.dart';
import '../widgets/category_link/linked_categories_screen.dart';
import '../widgets/notification/notification_settings_screen.dart';
import '../widgets/notification/pending_inbox.dart';
import '../widgets/export_options_bottom_sheet.dart';
import '../widgets/profile/app_settings_sheets.dart';
import '../widgets/profile/cloud_sync_tile.dart';
import '../widgets/profile/delete_data_dialog.dart';
import '../widgets/profile/edit_profile_dialog.dart';
import '../widgets/profile/ledger_sheets.dart';
import '../widgets/profile/profile_cover_card.dart';
import '../widgets/profile/profile_section_header.dart';
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

  int _pendingCount = 0;

  static Color get accentBeige => AppColors.accentBeige;

  String get _uid => widget.currentUser.uid ?? 'default';

  @override
  void initState() {
    super.initState();
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
    await TransactionService.instance.initActiveLedger(_uid);
    final ledgersList = await DatabaseHelper.instance.getLedgers(uid: _uid);
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

  void _showEditProfileDialog() {
    showEditProfileDialog(
      context,
      currentUser: widget.currentUser,
      selectedAvatarKey: widget.selectedAvatarKey,
      onUserUpdated: widget.onUserUpdated,
      onAvatarChanged: widget.onAvatarChanged,
    );
  }

  void _showLedgerPickerSheet() {
    showLedgerPickerSheet(
      context,
      uid: _uid,
      ledgers: _userLedgers,
      activeLedgerId: _activeLedgerId,
      onLedgersChanged: _loadLedgers,
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
    ExportOptionsBottomSheet.show(
      context,
      currentLedgerId: TransactionService.instance.currentLedgerId,
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

          ProfileCoverCard(user: widget.currentUser, onTap: _showEditProfileDialog),

          const SizedBox(height: 20),

          // GROUP 0: TÀI KHOẢN CÁ NHÂN
          ProfileSectionHeader(AppTranslations.tr(lang, 'personal_account')),
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
          ProfileSectionHeader(AppTranslations.tr(lang, 'auto_finance_banking')),
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
                title: Text(AppTranslations.tr(lang, 'bank_notification_settings'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                subtitle: Text('Vietcombank, MB, Techcombank, MoMo,...', style: TextStyle(fontSize: 12, color: AppColors.grey500), overflow: TextOverflow.ellipsis),
                trailing: Icon(Icons.chevron_right, color: AppColors.grey500),
                onTap: () {
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
          ProfileSectionHeader(AppTranslations.tr(lang, 'ledger_settings')),
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
                title: Text(AppTranslations.tr(lang, 'export_files'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                subtitle: Text('.csv & .xlsx', style: TextStyle(fontSize: 12, color: AppColors.grey500), overflow: TextOverflow.ellipsis),
                trailing: Icon(Icons.chevron_right, color: AppColors.grey500),
                onTap: _showExportFileDialog,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // GROUP 2: CÀI ĐẶT ỨNG DỤNG
          ProfileSectionHeader(AppTranslations.tr(lang, 'app_settings')),
          const SizedBox(height: 8),
          SettingsTileGroup(
            children: [
              SettingsTile(
                leading: const AssetIcon('cat_ngon_ngu'),
                title: Text(AppTranslations.tr(lang, 'language'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                subtitle: Text(context.lang, style: TextStyle(fontSize: 12, color: AppColors.grey500), overflow: TextOverflow.ellipsis),
                trailing: Icon(Icons.chevron_right, color: AppColors.grey500),
                onTap: () => showLanguagePickerSheet(context, onLanguageChanged: widget.onLanguageChanged),
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
                subtitle: Text(context.t(themeModeLabels[AppTheme.instance.value]!), style: TextStyle(fontSize: 12, color: AppColors.grey500), overflow: TextOverflow.ellipsis),
                trailing: Icon(Icons.chevron_right, color: AppColors.grey500),
                onTap: () => showThemePickerSheet(context),
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
          ProfileSectionHeader(AppTranslations.tr(lang, 'cloud_sync_section')),
          const SizedBox(height: 8),
          SettingsTileGroup(
            children: [
              CloudSyncTile(uid: widget.currentUser.uid),
            ],
          ),

          const SizedBox(height: 24),

          // GROUP: QUẢN LÝ TÀI KHOẢN & BẢO MẬT
          ProfileSectionHeader(AppTranslations.tr(lang, 'account_security_section')),
          const SizedBox(height: 8),
          SettingsTileGroup(
            children: [
              SettingsTile(
                leading: const AssetIcon('ui_thung_rac'),
                title: Text(AppTranslations.tr(lang, 'delete_all_data'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                subtitle: Text(AppTranslations.tr(lang, 'delete_all_data_sub'), style: TextStyle(fontSize: 12, color: AppColors.grey500), overflow: TextOverflow.ellipsis),
                trailing: Icon(Icons.chevron_right, color: AppColors.grey500),
                onTap: () => showDeleteMyDataDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // GROUP 3: GIỚI THIỆU
          ProfileSectionHeader(AppTranslations.tr(lang, 'about')),
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
                leading: const AssetIcon('cat_phone'),
                title: Text(AppTranslations.tr(lang, 'contact_support'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                trailing: Icon(Icons.chevron_right, color: AppColors.grey500),
                onTap: _showSupportDialog,
              ),
              Divider(height: 1, color: AppColors.rule),
              SettingsTile(
                leading: const AssetIcon('ui_thong_tin'),
                title: Text(AppTranslations.tr(lang, 'version'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
                trailing: Text('v1.0.0', style: TextStyle(fontSize: 13, color: AppColors.grey500, fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // GROUP: ĐĂNG XUẤT TÀI KHOẢN
          ProfileSectionHeader(AppTranslations.tr(lang, 'logout').toUpperCase()),
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
