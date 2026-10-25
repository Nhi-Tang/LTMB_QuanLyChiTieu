import 'package:flutter/foundation.dart';
import 'budget_service.dart';
import 'transaction_service.dart';

/// Điểm vào duy nhất để kiểm tra cảnh báo ngân sách sau khi giao dịch thay đổi.
/// Toàn bộ logic ngưỡng (80% / 100% / 120%) nằm ở [BudgetService.checkAndTriggerAlerts].
class BudgetAlertService {
  static final BudgetAlertService instance = BudgetAlertService._init();
  BudgetAlertService._init();

  Future<void> checkAndAlertForDate(DateTime date, {String? uid, String? ledgerId}) async {
    try {
      final monthStr = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final targetLedger = (ledgerId != null && ledgerId.isNotEmpty)
          ? ledgerId
          : TransactionService.instance.currentLedgerId;
      await BudgetService.instance.checkAndTriggerAlerts(targetLedger, monthStr, uid: uid);
    } catch (e) {
      debugPrint('Error in checkAndAlertForDate: $e');
    }
  }
}
