import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../models/budget_model.dart';
import 'in_app_notification_service.dart';
import 'transaction_service.dart';
import 'daily_reminder_service.dart';
import '../../frontend/utils/app_translations.dart';

class BudgetStatus {
  final BudgetModel budget;
  final double spent;
  final double limit;
  final double remaining;
  final double percent;
  final String level; // 'ok' (<80%), 'warning' (80-99%), 'reached' (100-119%), 'exceeded' (>=120%)
  final double dailyRemaining;
  final double forecast;

  BudgetStatus({
    required this.budget,
    required this.spent,
    required this.limit,
    required this.remaining,
    required this.percent,
    required this.level,
    required this.dailyRemaining,
    required this.forecast,
  });
}

class BudgetService extends ChangeNotifier {
  static final BudgetService instance = BudgetService._init();
  BudgetService._init();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TransactionService _transactionService = TransactionService();

  List<BudgetStatus> _currentBudgets = [];
  bool _isLoading = false;

  List<BudgetStatus> get currentBudgets => _currentBudgets;
  bool get isLoading => _isLoading;

  /// Nạp lại dữ liệu ngân sách theo tháng và ledgerId (lấy từ TransactionService)
  Future<void> loadBudgets(String monthStr) async {
    _isLoading = true;
    notifyListeners();

    try {
      final ledgerId = _transactionService.currentLedgerId;
      _currentBudgets = await getBudgetStatuses(ledgerId, monthStr);
      await checkAndTriggerAlerts(ledgerId, monthStr);
    } catch (e) {
      debugPrint('Error loading budgets in BudgetService: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tính tổng số tiền đã chi tiêu cho một danh mục trong tháng (hoặc tổng tất cả nếu categoryId == null).
  /// Loại trừ các giao dịch đã xóa, không phải chi phí (thu nhập), hoặc giao dịch chuyển khoản/tiết kiệm.
  Future<double> spent(String? categoryId, String month, String ledgerId) async {
    final transactions = await _transactionService.getTransactions(ledgerId: ledgerId);
    final parts = month.split('-');
    if (parts.length != 2) return 0.0;
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final m = int.tryParse(parts[1]) ?? DateTime.now().month;

    double totalSpent = 0.0;
    for (var t in transactions) {
      if (t.isDeleted || (t.kind != 'expense' && t.kind != 'transfer_out')) continue;
      if (t.date.year != year || t.date.month != m) continue;

      // Tiền chuyển sang quỹ tiết kiệm không phải chi tiêu, không tính vào ngân sách
      if (t.category.toLowerCase().contains('tiết kiệm')) continue;

      if (categoryId == null || categoryId.isEmpty) {
        totalSpent += t.amount;
      } else {
        if (t.category.trim().toLowerCase() == categoryId.trim().toLowerCase()) {
          totalSpent += t.amount;
        }
      }
    }
    return totalSpent;
  }

  /// Lấy danh sách các trạng thái ngân sách cho sổ và tháng chỉ định.
  Future<List<BudgetStatus>> getBudgetStatuses(String ledgerId, String month) async {
    final budgets = await _dbHelper.getBudgets(ledgerId, month: month);
    final List<BudgetStatus> statuses = [];

    final parts = month.split('-');
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final m = int.tryParse(parts[1]) ?? DateTime.now().month;
    final totalDays = DateTime(year, m + 1, 0).day;

    final now = DateTime.now();
    int currentDay;
    if (now.year == year && now.month == m) {
      currentDay = now.day;
    } else if (DateTime(year, m).isAfter(now)) {
      currentDay = 1;
    } else {
      currentDay = totalDays;
    }
    final daysLeft = (totalDays - currentDay + 1).clamp(1, totalDays);

    for (var budget in budgets) {
      final spentAmount = await spent(budget.categoryId, month, ledgerId);
      final limit = budget.amountLimit.toDouble();
      final remaining = limit - spentAmount;
      final percent = limit > 0 ? (spentAmount / limit) * 100.0 : (spentAmount > 0 ? 100.0 : 0.0);

      String level = 'ok';
      if (percent >= 120.0) {
        level = 'exceeded';
      } else if (percent >= 100.0) {
        level = 'reached';
      } else if (percent >= 80.0) {
        level = 'warning';
      }

      final dailyRemaining = remaining > 0 ? remaining / daysLeft : 0.0;
      final forecast = currentDay > 0 ? (spentAmount / currentDay) * totalDays : spentAmount;

      statuses.add(BudgetStatus(
        budget: budget,
        spent: spentAmount,
        limit: limit,
        remaining: remaining,
        percent: percent,
        level: level,
        dailyRemaining: dailyRemaining,
        forecast: forecast,
      ));
    }

    return statuses;
  }

  static const List<String> _alertLevels = ['warning', 'reached', 'exceeded'];

  /// Kiểm tra các ngưỡng ngân sách (80% warning, 100% reached, 120% exceeded) và kích hoạt cảnh báo.
  /// Mỗi ngưỡng chỉ báo tối đa 1 lần/tháng/ngân sách; nhảy thẳng lên ngưỡng cao thì các ngưỡng thấp hơn
  /// được đánh dấu đã báo để không phát cảnh báo "lùi" khi chi tiêu giảm nhẹ.
  Future<List<String>> checkAndTriggerAlerts(String ledgerId, String month, {String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('budget_alerts_enabled') ?? true;
    if (!enabled) return [];

    final lang = (uid != null ? prefs.getString('mousey_language_$uid') : null) ??
        prefs.getString('mousey_language') ??
        'Tiếng Việt';

    final statuses = await getBudgetStatuses(ledgerId, month);
    final List<String> newAlertMessages = [];

    final parts = month.split('-');
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final m = int.tryParse(parts[1]) ?? DateTime.now().month;
    final totalDays = DateTime(year, m + 1, 0).day;
    final now = DateTime.now();
    int currentDay = (now.year == year && now.month == m) ? now.day : (DateTime(year, m).isAfter(now) ? 1 : totalDays);
    final daysLeft = (totalDays - currentDay + 1).clamp(1, totalDays);

    for (var status in statuses) {
      final budgetId = status.budget.id;
      if (budgetId == null) continue;

      final existingAlerts = await _dbHelper.getBudgetAlerts(budgetId, month);
      final hasWarning = existingAlerts.any((a) => a['level'] == 'warning');
      final hasReached = existingAlerts.any((a) => a['level'] == 'reached');
      final hasExceeded = existingAlerts.any((a) => a['level'] == 'exceeded');

      final categoryName = status.budget.categoryId ?? 'Tổng';
      final isTotal = status.budget.categoryId == null || status.budget.categoryId!.isEmpty;
      final ratio = status.limit > 0 ? (status.spent / status.limit) : 0.0;

      // Clean up higher level alerts if spent dropped below threshold
      if (ratio < 1.2 && hasExceeded) {
        await _dbHelper.clearBudgetAlertLevel(budgetId, month, 'exceeded');
      }
      if (ratio < 1.0 && hasReached) {
        await _dbHelper.clearBudgetAlertLevel(budgetId, month, 'reached');
      }
      if (ratio < 0.8 && hasWarning) {
        await _dbHelper.clearBudgetAlertLevel(budgetId, month, 'warning');
      }

      String? level;
      if (ratio >= 1.2) {
        level = 'exceeded';
      } else if (ratio >= 1.0) {
        level = 'reached';
      } else if (ratio >= 0.8) {
        level = 'warning';
      }

      if (level == null) continue;

      final refreshedAlerts = await _dbHelper.getBudgetAlerts(budgetId, month);
      final alreadyAlerted = refreshedAlerts.any((a) => a['level'] == level);

      if (!alreadyAlerted) {
        for (final l in _alertLevels.sublist(0, _alertLevels.indexOf(level) + 1)) {
          if (!refreshedAlerts.any((a) => a['level'] == l)) {
            await _dbHelper.insertBudgetAlert(budgetId, month, l);
          }
        }

        final remaining = status.remaining.clamp(0.0, double.infinity);
        final over = (status.spent - status.limit).clamp(0.0, double.infinity);
        final perDay = daysLeft > 0 ? remaining / daysLeft : 0.0;
        final percent = (ratio * 100).toInt();

        final params = {
          'categoryKey': isTotal ? 'total' : categoryName,
          'percent': percent,
          'spent': status.spent,
          'limit': status.limit,
          'over': over,
          'remaining': remaining,
          'daysLeft': daysLeft,
          'perDay': perDay,
        };

        final dedupeKey = 'budget:$budgetId:$month:$level';
        final notifType = 'budget_$level';
        final title = AppTranslations.formatBudgetAlertTitle(lang, notifType, params);

        final inserted = await InAppNotificationService.instance.add(
          type: notifType,
          title: title,
          body: jsonEncode(params),
          dedupeKey: dedupeKey,
          uid: uid,
        );
        // Đã có thông báo trùng (cùng ngân sách/tháng/mức) thì không đẩy push lần nữa
        if (inserted == null) continue;

        await DailyReminderService.instance.showInstantNotification(
          title: title,
          body: AppTranslations.formatBudgetAlertMessage(lang, notifType, params, dedupeKey),
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        );

        newAlertMessages.add(dedupeKey);
      }
    }

    return newAlertMessages;
  }

  Future<List<BudgetModel>> getBudgets(String ledgerId, {String? month}) async {
    return await _dbHelper.getBudgets(ledgerId, month: month);
  }

  Future<String> insertBudget(BudgetModel budget) async {
    final id = await _dbHelper.insertBudget(budget);
    _transactionService.notifyUpdated();
    notifyListeners();
    return id;
  }

  Future<int> updateBudget(BudgetModel budget) async {
    final res = await _dbHelper.updateBudget(budget);
    _transactionService.notifyUpdated();
    notifyListeners();
    return res;
  }

  Future<int> deleteBudget(String budgetId) async {
    final res = await _dbHelper.deleteBudget(budgetId);
    _transactionService.notifyUpdated();
    notifyListeners();
    return res;
  }
}
