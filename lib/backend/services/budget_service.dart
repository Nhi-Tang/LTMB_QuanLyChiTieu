import '../database/db_helper.dart';
import '../models/budget_model.dart';
import 'in_app_notification_service.dart';
import 'transaction_service.dart';

class BudgetStatus {
  final BudgetModel budget;
  final double spent;
  final double limit;
  final double remaining;
  final double percent;
  final String level; // 'ok' (<80%), 'warning' (80-99%), 'exceeded' (>=100%)
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

class BudgetService {
  static final BudgetService instance = BudgetService._init();
  BudgetService._init();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TransactionService _transactionService = TransactionService();

  /// Tính tổng số tiền đã chi tiêu cho một danh mục trong tháng (hoặc tổng tất cả nếu categoryId == null).
  /// Loại trừ các giao dịch đã xóa, không phải chi phí (thu nhập), hoặc giao dịch chuyển khoản/tiết kiệm.
  Future<double> spent(String? categoryId, String month, String ledgerId) async {
    final transactions = await _transactionService.getTransactions();
    final parts = month.split('-');
    if (parts.length != 2) return 0.0;
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final m = int.tryParse(parts[1]) ?? DateTime.now().month;

    double totalSpent = 0.0;
    for (var t in transactions) {
      if (!t.isExpense || t.isDeleted) continue;
      if (t.date.year != year || t.date.month != m) continue;

      // Bỏ qua chuyển khoản hoặc đóng góp tiết kiệm nếu có phân loại riêng
      if (t.category.toLowerCase().contains('chuyển tiền') ||
          t.category.toLowerCase().contains('tiết kiệm')) {
        continue;
      }

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
      if (percent >= 100.0) {
        level = 'exceeded';
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

  /// Kiểm tra các ngưỡng ngân sách (80% cảnh báo, 100% vượt quá) và kích hoạt cảnh báo,
  /// đảm bảo mỗi ngưỡng chỉ kích hoạt 1 lần trừ khi chi tiêu giảm xuống rồi vượt lại.
  /// Trả về danh sách thông báo cảnh báo mới cho chuông thông báo.
  Future<List<String>> checkAndTriggerAlerts(String ledgerId, String month) async {
    final statuses = await getBudgetStatuses(ledgerId, month);
    final List<String> newAlertMessages = [];

    for (var status in statuses) {
      final budgetId = status.budget.id;
      if (budgetId == null) continue;

      final existingAlerts = await _dbHelper.getBudgetAlerts(budgetId, month);
      final hasWarning = existingAlerts.any((a) => a['level'] == 'warning');
      final hasExceeded = existingAlerts.any((a) => a['level'] == 'exceeded');

      final categoryName = status.budget.categoryId ?? 'Tổng ngân sách tháng';

      if (status.percent < 80.0) {
        // Chi tiêu giảm xuống dưới 80%, xóa trạng thái cảnh báo để có thể kích hoạt lại sau
        if (existingAlerts.isNotEmpty) {
          await _dbHelper.clearBudgetAlerts(budgetId, month);
        }
      } else if (status.percent >= 100.0) {
        if (!hasExceeded) {
          await _dbHelper.insertBudgetAlert(budgetId, month, 'exceeded');
          final msg = '⚠️ Ngân sách "$categoryName" đã vượt quá hạn mức (${status.percent.toStringAsFixed(1)}%)!';
          newAlertMessages.add(msg);
          await InAppNotificationService.instance.add(
            type: 'budget',
            title: 'Cảnh báo vượt ngân sách',
            body: msg,
            dedupeKey: 'notif_budget_exceeded_${budgetId}_$month',
          );
        }
      } else if (status.percent >= 80.0) {
        if (!hasWarning && !hasExceeded) {
          await _dbHelper.insertBudgetAlert(budgetId, month, 'warning');
          final msg = '⚡ Ngân sách "$categoryName" đã đạt 80% hạn mức (${status.percent.toStringAsFixed(1)}%)!';
          newAlertMessages.add(msg);
          await InAppNotificationService.instance.add(
            type: 'budget',
            title: 'Cảnh báo hạn mức ngân sách',
            body: msg,
            dedupeKey: 'notif_budget_warning_${budgetId}_$month',
          );
        }
      }
    }

    return newAlertMessages;
  }

  Future<List<BudgetModel>> getBudgets(String ledgerId, {String? month}) async {
    return await _dbHelper.getBudgets(ledgerId, month: month);
  }

  Future<String> insertBudget(BudgetModel budget) async {
    return await _dbHelper.insertBudget(budget);
  }

  Future<int> updateBudget(BudgetModel budget) async {
    return await _dbHelper.updateBudget(budget);
  }

  Future<int> deleteBudget(String budgetId) async {
    return await _dbHelper.deleteBudget(budgetId);
  }
}
