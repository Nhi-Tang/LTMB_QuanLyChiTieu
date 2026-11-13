import 'package:flutter/material.dart';
import '../../../backend/services/sync_service.dart';
import '../../../core/widgets/asset_icon.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_language.dart';
import '../../utils/app_translations.dart';
import '../app_alert_dialog.dart';

/// Ô trạng thái đồng bộ Cloud Firestore + nút "Đồng bộ ngay".
class CloudSyncTile extends StatefulWidget {
  final String? uid;

  const CloudSyncTile({super.key, required this.uid});

  @override
  State<CloudSyncTile> createState() => _CloudSyncTileState();
}

class _CloudSyncTileState extends State<CloudSyncTile> {
  bool _isSyncing = false;
  String _syncStateKey = 'synced'; // 'synced', 'syncing', 'error'
  String? _lastSyncTimeFormatted;

  @override
  void initState() {
    super.initState();
    _loadSyncInfo();
  }

  static String _formatTimestamp(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadSyncInfo() async {
    final uid = widget.uid;
    if (uid != null) {
      final ts = await SyncService.instance.getLastSyncTimestamp(uid);
      if (ts != null && mounted) {
        setState(() {
          _lastSyncTimeFormatted = _formatTimestamp(ts);
        });
      }
    }
  }

  Future<void> _syncNow() async {
    final uid = widget.uid;
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
            _lastSyncTimeFormatted = _formatTimestamp(ts);
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

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final translatedStatus = AppTranslations.tr(lang, 'sync_state_$_syncStateKey');
    final lastSyncStr = _lastSyncTimeFormatted ?? AppTranslations.tr(lang, 'never');

    return SettingsTile(
      leading: const AssetIcon('ui_dong_bo'),
      title: Text(AppTranslations.tr(lang, 'sync_status_title'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
      subtitle: Text('${AppTranslations.tr(lang, 'sync_status_title')}: $translatedStatus · ${AppTranslations.tr(lang, 'last_sync_label')}: $lastSyncStr', style: TextStyle(fontSize: 12, color: AppColors.grey500), overflow: TextOverflow.ellipsis),
      trailing: _isSyncing
          ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentBeige))
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBeige,
                foregroundColor: AppColors.onTeal,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _syncNow,
              child: Text(AppTranslations.tr(lang, 'sync_now'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
    );
  }
}
