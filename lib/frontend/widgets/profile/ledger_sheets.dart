import 'package:flutter/material.dart';
import '../../../backend/services/ledger_repository.dart';
import '../../../backend/services/transaction_service.dart';
import '../../../core/widgets/asset_icon.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_language.dart';
import '../../utils/app_translations.dart';
import '../app_alert_dialog.dart';

void showLedgerPickerSheet(
  BuildContext context, {
  required String uid,
  required List<Map<String, dynamic>> ledgers,
  required String activeLedgerId,
  required Future<void> Function() onLedgersChanged,
}) {
  final lang = context.lang;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
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
              ...ledgers.map((lMap) {
                final id = lMap['id'] as String;
                final name = lMap['name'] as String;
                final isSel = activeLedgerId == id;

                return ListTile(
                  leading: const AssetIcon('ui_sach'),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: isSel ? Text(AppTranslations.tr(lang, 'in_use'), style: TextStyle(color: AppColors.accentBeige, fontSize: 12, fontWeight: FontWeight.bold)) : null,
                  trailing: isSel ? Icon(Icons.check_circle, color: AppColors.accentBeige) : null,
                  onTap: () async {
                    await TransactionService.instance.setCurrentLedgerId(id, uid: uid);
                    await onLedgersChanged();
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (!context.mounted) return;
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
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBeige,
                    foregroundColor: AppColors.darkBeige,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    AppTranslations.tr(lang, 'add_ledger_btn'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    showAddNewLedgerDialog(context, uid: uid, onLedgersChanged: onLedgersChanged);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void showAddNewLedgerDialog(
  BuildContext context, {
  required String uid,
  required Future<void> Function() onLedgersChanged,
}) {
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
              const SizedBox(width: 8),
              Text(context.t('Thêm sổ sách mới'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                backgroundColor: AppColors.accentBeige,
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
                        await LedgerRepository.instance.createLedger(name: name, uid: uid);
                        await onLedgersChanged(); // Cập nhật lại UI list

                        if (!ctx.mounted) return;
                        Navigator.pop(ctx); // Đóng dialog

                        if (!context.mounted) return;
                        showAppAlertDialog(
                          context: context,
                          title: context.t('Thành công'),
                          message: context.t('Đã tạo sổ sách "{name}" thành công!', {'name': name}),
                          isSuccess: true,
                        );
                      } catch (e) {
                        debugPrint('Error creating ledger: $e');
                        setDialogState(() => isCreating = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                        );
                      }
                    },
              child: isCreating
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkBeige))
                  : Text(context.t('Tạo sổ mới'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ),
  );
}
