import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../database/db_helper.dart';
import '../models/pending_transaction_model.dart';
import '../models/transaction_model.dart';
import 'bank_parser/bank_notification_parser.dart';
import 'budget_alert_service.dart';
import 'in_app_notification_service.dart';
import 'daily_reminder_service.dart';
import '../../core/utils/money_input_formatter.dart';
import '../../frontend/utils/app_language.dart';

class CategorySuggestionResult {
  final String? suggestedCategoryId; // Tên/ID danh mục gợi ý
  final String confidence; // 'none' | 'medium' | 'high'
  final int matchCount; // Số giao dịch khớp lịch sử

  CategorySuggestionResult({
    this.suggestedCategoryId,
    required this.confidence,
    this.matchCount = 0,
  });
}

class CategorySuggestionService {
  static final CategorySuggestionService instance = CategorySuggestionService._();
  CategorySuggestionService._();

  static const List<String> _stopWords = [
    'chuyen', 'tien', 'nhan', 'cho', 'tu', 'luc', 'qua', 'tai', 'khoan',
    'chuyển', 'tiền', 'nhận', 'cho', 'từ', 'lúc', 'qua', 'tại', 'khoản',
    'thanh', 'toan', 'thanh toán', 'mua', 'ban', 'bán', 'ngan', 'hang', 'ngân', 'hàng'
  ];

  /// Phân tích lịch sử giao dịch để gợi ý danh mục
  Future<CategorySuggestionResult> suggestCategory({
    required String description,
    required String type,
    String? uid,
  }) async {
    final history = await DatabaseHelper.instance.getTransactions(uid: uid);
    final isExpense = (type == 'expense');

    // Lọc các giao dịch cùng loại (chi tiêu hoặc thu nhập)
    final filteredHistory = history.where((t) => t.isExpense == isExpense).toList();

    if (filteredHistory.isEmpty || description.trim().isEmpty) {
      return CategorySuggestionResult(confidence: 'none', matchCount: 0);
    }

    // Tách từ khóa trong mô tả
    final words = description
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\sđàáảãạăắằẳẵặâấầẩẫậèéẻẽẹêếềểễệìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !_stopWords.contains(w))
        .toList();

    if (words.isEmpty) {
      return CategorySuggestionResult(confidence: 'none', matchCount: 0);
    }

    final Map<String, int> categoryScores = {};

    for (var tx in filteredHistory) {
      final txTitle = tx.title.toLowerCase();
      int score = 0;
      for (var word in words) {
        if (txTitle.contains(word)) {
          score++;
        }
      }
      if (score > 0) {
        categoryScores[tx.category] = (categoryScores[tx.category] ?? 0) + score;
      }
    }

    if (categoryScores.isEmpty) {
      return CategorySuggestionResult(confidence: 'none', matchCount: 0);
    }

    // Tìm danh mục có điểm cao nhất
    String topCategory = categoryScores.keys.first;
    int maxMatches = categoryScores.values.first;

    categoryScores.forEach((cat, matches) {
      if (matches > maxMatches) {
        maxMatches = matches;
        topCategory = cat;
      }
    });

    String confidence = 'none';
    if (maxMatches >= 3) {
      confidence = 'high';
    } else if (maxMatches >= 1) {
      confidence = 'medium';
    }

    return CategorySuggestionResult(
      suggestedCategoryId: topCategory,
      confidence: confidence,
      matchCount: maxMatches,
    );
  }

  /// Xử lý thông báo ngân hàng đầu vào, tự động phân loại và lưu bản nháp
  Future<PendingTransactionModel?> processIncomingNotification(
    ParsedBankNotification parsed, {
    String? uid,
    bool isTestMode = false,
  }) async {
    final suggestion = await suggestCategory(
      description: parsed.description,
      type: parsed.type,
      uid: uid,
    );

    final prefs = await SharedPreferences.getInstance();
    final autoConfirm = prefs.getBool('auto_confirm_high_confidence') ?? false;

    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String();

    bool isHighConfidenceAutoConfirm = autoConfirm && suggestion.confidence == 'high';
    String status = isHighConfidenceAutoConfirm ? 'confirmed' : 'pending';

    final effectiveFingerprint = isTestMode
        ? 'test_${DateTime.now().microsecondsSinceEpoch}_${parsed.fingerprint}'
        : parsed.fingerprint;

    final pendingItem = PendingTransactionModel(
      id: id,
      uid: uid,
      type: parsed.type,
      amount: parsed.amount,
      bankName: parsed.bankName,
      accountLast4: parsed.accountLast4,
      description: parsed.description,
      occurredAt: parsed.occurredAt.toIso8601String(),
      fingerprint: effectiveFingerprint,
      status: status,
      suggestedCategoryId: suggestion.suggestedCategoryId,
      suggestionConfidence: suggestion.confidence,
      createdAt: now,
    );

    final saved = await DatabaseHelper.instance.insertPendingTransaction(pendingItem, uid: uid);
    if (!saved) {
      debugPrint('🚫 [Parser] REASON: DUPLICATE_FINGERPRINT | fp=${pendingItem.fingerprint}');
      // Bị trùng lặp fingerprint
      return null;
    }

    // Logic ghép giao dịch chuyển khoản nội bộ (Ví dụ MB -> ZaloPay)
    // Nếu vừa có khoản chi và khoản thu cùng số tiền trong vòng 5 phút, gộp lại thành 1 khoản Chuyển Tiền
    if (!isTestMode) {
      final recentPendings = await DatabaseHelper.instance.getPendingTransactions(uid: uid);
      final cutoff = DateTime.now().subtract(const Duration(minutes: 5));

      final matchedList = recentPendings.where((p) {
        if (p.id == pendingItem.id) return false;
        if (p.amount != pendingItem.amount) return false;
        if (p.type == pendingItem.type) return false; // Cần 1 thu 1 chi
        if (p.bankName == pendingItem.bankName) return false; // Không ghép 2 giao dịch cùng một ngân hàng/nguồn
        
        final pTime = DateTime.tryParse(p.occurredAt);
        if (pTime == null) return false;
        if (pTime.isBefore(cutoff)) return false;
        
        return true;
      }).toList();

      if (matchedList.isNotEmpty) {
        final pair = matchedList.first;

        // Đánh dấu 2 bản nháp gốc là 'merged' và ẩn đi
        await DatabaseHelper.instance.updatePendingTransactionStatus(pendingItem.id, 'merged');
        await DatabaseHelper.instance.updatePendingTransactionStatus(pair.id, 'merged');

        // Xác định chiều từ đâu sang đâu
        final sourceBank = pendingItem.type == 'expense' ? pendingItem.bankName : pair.bankName;
        final targetBank = pendingItem.type == 'income' ? pendingItem.bankName : pair.bankName;

        final transferItem = PendingTransactionModel(
          id: const Uuid().v4(),
          uid: uid,
          type: 'unknown',
          amount: pendingItem.amount,
          bankName: sourceBank,
          accountLast4: '',
          description: '$sourceBank → $targetBank',
          occurredAt: now,
          fingerprint: 'transfer_${pendingItem.id}_${pair.id}',
          status: 'pending',
          suggestedCategoryId: 'Chuyển tiền',
          suggestionConfidence: 'high',
          createdAt: now,
        );

        await DatabaseHelper.instance.insertPendingTransaction(transferItem, uid: uid);

        final formattedAmount = formatMoney(transferItem.amount);
        final transferTitle = AppLanguage.instance.t('Chuyển khoản nội bộ tự động');
        final transferBody = AppLanguage.instance.t('Đã chuyển {amount} đ từ {sourceBank} sang {targetBank}', {'amount': formattedAmount, 'sourceBank': sourceBank, 'targetBank': targetBank});

        await InAppNotificationService.instance.add(
          type: 'pending_tx',
          title: transferTitle,
          body: transferBody,
          dedupeKey: 'notif_pending_${transferItem.id}',
          uid: uid,
        );

        await DailyReminderService.instance.showInstantNotification(
          title: transferTitle,
          body: transferBody,
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        );
        
        return transferItem;
      }
    }

    // Thêm thông báo nội bộ vào Trung tâm thông báo
    final formattedAmount = formatMoney(parsed.amount);
    final isInc = parsed.type == 'income';
    final notifTitle = AppLanguage.instance.t(isInc ? 'Tài khoản vừa tăng' : 'Tài khoản vừa giảm');
    final signText = isInc ? '+' : '-';
    final notifBody = '$signText$formattedAmount đ · ${parsed.description}';

    await InAppNotificationService.instance.add(
      type: 'pending_tx',
      title: notifTitle,
      body: notifBody,
      dedupeKey: 'notif_pending_${pendingItem.id}',
      uid: uid,
    );

    // Hiển thị thông báo đẩy (system push notification) ra thanh trạng thái điện thoại thực
    await DailyReminderService.instance.showInstantNotification(
      title: notifTitle,
      body: notifBody,
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    if (isHighConfidenceAutoConfirm) {
      // Tự động tạo giao dịch chính thức khi khớp độ tin cậy cao
      final realTx = TransactionItem(
        id: const Uuid().v4(),
        title: parsed.description,
        category: suggestion.suggestedCategoryId ?? (parsed.type == 'expense' ? 'Khác' : 'Khác'),
        amount: parsed.amount.toDouble(),
        isExpense: parsed.type == 'expense',
        date: parsed.occurredAt,
        uid: uid,
      );
      await DatabaseHelper.instance.insertTransaction(realTx, uid: uid);
      await BudgetAlertService.instance.checkAndAlertForDate(realTx.date, uid: uid);
    }

    return pendingItem;
  }
}
