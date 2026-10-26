import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../backend/database/db_helper.dart';
import '../../../backend/models/app_notification_model.dart';
import '../../../backend/services/in_app_notification_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_translations.dart';
import '../../screens/budgets_screen.dart';
import '../../screens/pro_upgrade_screen.dart';
import 'pending_inbox.dart';
import '../../utils/app_language.dart';

class NotificationCenterSheet extends StatefulWidget {
  final String selectedLanguage;
  final String ledgerId;
  final VoidCallback? onTransactionsUpdated;

  const NotificationCenterSheet({
    super.key,
    required this.selectedLanguage,
    required this.ledgerId,
    this.onTransactionsUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required String selectedLanguage,
    required String ledgerId,
    VoidCallback? onTransactionsUpdated,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NotificationCenterSheet(
        selectedLanguage: selectedLanguage,
        ledgerId: ledgerId,
        onTransactionsUpdated: onTransactionsUpdated,
      ),
    );
  }

  @override
  State<NotificationCenterSheet> createState() => _NotificationCenterSheetState();
}

class _NotificationCenterSheetState extends State<NotificationCenterSheet> {
  List<AppNotificationModel> _notifications = [];
  int _pendingDraftCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    InAppNotificationService.instance.addListener(_loadData);
    _loadData();
  }

  @override
  void dispose() {
    InAppNotificationService.instance.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final notifs = await InAppNotificationService.instance.getNotifications();
    final count = await DatabaseHelper.instance.getPendingTransactionsCount();
    if (mounted) {
      setState(() {
        _notifications = notifs;
        _pendingDraftCount = count;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    await InAppNotificationService.instance.markAllRead();
    _loadData();
  }

  Future<void> _deleteNotification(String id) async {
    await InAppNotificationService.instance.delete(id);
    _loadData();
  }

  void _handleItemTap(AppNotificationModel notif) async {
    await InAppNotificationService.instance.markRead(notif.id);

    if (!mounted) return;
    Navigator.pop(context);

    // Điều hướng dựa theo type và payload
    switch (notif.type) {
      case 'pending_tx':
        PendingInboxSheet.show(
          context,
          selectedLanguage: context.lang,
          onTransactionsUpdated: widget.onTransactionsUpdated,
        );
        break;
      case 'budget':
      case 'budget_warning':
      case 'budget_reached':
      case 'budget_exceeded':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BudgetsScreen(
              ledgerId: widget.ledgerId,
              selectedLanguage: context.lang,
            ),
          ),
        );
        break;
      case 'pro':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProUpgradeScreen(),
          ),
        );
        break;
      case 'savings':
      case 'sync':
      default:
        break;
    }
  }

  String _formatRelativeTime(String createdAtIso) {
    final dt = DateTime.tryParse(createdAtIso) ?? DateTime.now();
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) {
      return context.t('Vừa xong');
    } else if (diff.inMinutes < 60) {
      return context.t('{inMinutes} phút trước', {'inMinutes': diff.inMinutes});
    } else if (diff.inHours < 24) {
      return context.t('{inHours} giờ trước', {'inHours': diff.inHours});
    } else if (diff.inDays < 7) {
      return context.t('{inDays} ngày trước', {'inDays': diff.inDays});
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  bool _isToday(String createdAtIso) {
    final dt = DateTime.tryParse(createdAtIso) ?? DateTime.now();
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'pending_tx':
        return Icons.mark_email_unread_rounded;
      case 'budget':
      case 'budget_warning':
        return Icons.pie_chart_rounded;
      case 'budget_reached':
        return Icons.error_outline_rounded;
      case 'budget_exceeded':
        return Icons.warning_amber_rounded;
      case 'pro':
        return Icons.workspace_premium_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'sync':
        return Icons.cloud_sync_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'pending_tx':
        return Colors.blue.shade700;
      case 'budget':
      case 'budget_warning':
        return Colors.orange.shade800;
      case 'budget_reached':
        return Colors.deepOrange.shade700;
      case 'budget_exceeded':
        return Colors.red.shade700;
      case 'pro':
        return Colors.amber.shade900;
      case 'savings':
        return Colors.green.shade700;
      case 'sync':
        return Colors.purple.shade700;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final lang = context.lang;

    final todayNotifs = _notifications.where((n) => _isToday(n.createdAt)).toList();
    final earlierNotifs = _notifications.where((n) => !_isToday(n.createdAt)).toList();

    return Container(
      height: media.size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF5FDFD),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle & Header
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: AppColors.darkBeige, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      AppTranslations.tr(lang, context.t('Thông báo')),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBeige,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _markAllRead,
                  icon: const Icon(Icons.done_all_rounded, size: 16, color: AppColors.primary),
                  label: Text(
                    AppTranslations.tr(lang, 'mark_all_read'),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Pending Drafts Card
                      if (_pendingDraftCount > 0) ...[
                        Card(
                          color: const Color(0xFFFFF3E0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.orange.shade300),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange.shade100,
                              child: Icon(Icons.mark_email_unread_rounded, color: Colors.orange.shade900),
                            ),
                            title: Text(
                              context.t('Giao dịch chờ xác nhận ({pendingDraftCount})', {'pendingDraftCount': _pendingDraftCount}),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange.shade900),
                            ),
                            subtitle: Text(
                              context.t('Nhấn để xem và xác nhận các khoản nháp từ thông báo ngân hàng'),
                              style: TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.orange),
                            onTap: () {
                              Navigator.pop(context);
                              PendingInboxSheet.show(
                                context,
                                onTransactionsUpdated: widget.onTransactionsUpdated,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (_notifications.isEmpty && _pendingDraftCount == 0)
                        _buildEmptyState(lang)
                      else ...[
                        if (todayNotifs.isNotEmpty) ...[
                          Text(
                            AppTranslations.tr(lang, 'today_section'),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          ...todayNotifs.map((n) => _buildNotificationTile(n)),
                          const SizedBox(height: 16),
                        ],
                        if (earlierNotifs.isNotEmpty) ...[
                          Text(
                            AppTranslations.tr(lang, 'earlier_section'),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          ...earlierNotifs.map((n) => _buildNotificationTile(n)),
                        ],
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/avatar/avatar.jpg',
            width: 80,
            height: 80,
            errorBuilder: (ctx, err, stack) => const Icon(
              Icons.notifications_none_rounded,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppTranslations.tr(lang, 'no_notifications'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkBeige),
          ),
          const SizedBox(height: 6),
          Text(
            AppTranslations.tr(lang, 'no_notifications_subtitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(AppNotificationModel notif) {
    final typeColor = _getTypeColor(notif.type);
    final typeIcon = _getTypeIcon(notif.type);

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _deleteNotification(notif.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        color: notif.isRead ? Colors.white : const Color(0xFFF5FDFD),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: notif.isRead ? const Color(0xFFCCF7F7) : AppColors.primary.withValues(alpha: 0.4),
            width: notif.isRead ? 1 : 1.5,
          ),
        ),
        elevation: notif.isRead ? 0 : 2,
        child: InkWell(
          onTap: () => _handleItemTap(notif),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: typeColor.withValues(alpha: 0.15),
                  child: Icon(typeIcon, size: 20, color: typeColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              () {
                                if (notif.type.startsWith('budget_')) {
                                  try {
                                    final params = jsonDecode(notif.body) as Map<String, dynamic>;
                                    return AppTranslations.formatBudgetAlertTitle(context.lang, notif.type, params);
                                  } catch (_) {}
                                }
                                return notif.title;
                              }(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notif.isRead) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        () {
                          if (notif.type.startsWith('budget_')) {
                            try {
                              final params = jsonDecode(notif.body) as Map<String, dynamic>;
                              return AppTranslations.formatBudgetAlertMessage(context.lang, notif.type, params, notif.dedupeKey ?? '');
                            } catch (_) {}
                          }
                          return notif.body;
                        }(),
                        style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.35),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatRelativeTime(notif.createdAt),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
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
