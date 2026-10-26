import 'package:flutter/material.dart';
import '../../../backend/database/db_helper.dart';
import '../../../backend/models/pending_transaction_model.dart';
import '../../../backend/services/transaction_service.dart';
import '../../../backend/services/category_repository.dart';
import '../../../backend/models/category_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_language.dart';

class PendingInboxSheet extends StatefulWidget {
  final String selectedLanguage;
  final VoidCallback? onTransactionsUpdated;

  const PendingInboxSheet({
    super.key,
    this.selectedLanguage = 'Tiếng Việt',
    this.onTransactionsUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    String selectedLanguage = 'Tiếng Việt',
    VoidCallback? onTransactionsUpdated,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PendingInboxSheet(
        selectedLanguage: selectedLanguage,
        onTransactionsUpdated: onTransactionsUpdated,
      ),
    );
  }

  @override
  State<PendingInboxSheet> createState() => _PendingInboxSheetState();
}

class _PendingInboxSheetState extends State<PendingInboxSheet> {
  List<PendingTransactionModel> _pendingItems = [];
  List<CategoryModel> _expenseCategories = [];
  List<CategoryModel> _incomeCategories = [];
  bool _isLoading = true;

  final Map<String, String> _typeOverrides = {}; // id -> 'expense' | 'income'
  final Map<String, String> _categoryOverrides = {}; // id -> category name

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final uid = DatabaseHelper.instance.currentUid;
    if (uid != null && uid.isNotEmpty) {
      try {
        await DatabaseHelper.instance.ensureDefaultCategories(uid);
      } catch (_) {}
    }
    
    final items = await DatabaseHelper.instance.getPendingTransactions(status: 'pending');
    final expCats = await CategoryRepository.instance.getCategories(type: 'expense');
    final incCats = await CategoryRepository.instance.getCategories(type: 'income');

    final finalExpCats = expCats.isNotEmpty ? expCats : DatabaseHelper.defaultExpenseCategories.map((c) => CategoryModel(
      name: c['name']!,
      iconKey: c['iconKey']!,
      type: 'expense',
      sortOrder: 0,
      isDefault: true,
      isArchived: false,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    )).toList();

    final finalIncCats = incCats.isNotEmpty ? incCats : DatabaseHelper.defaultIncomeCategories.map((c) => CategoryModel(
      name: c['name']!,
      iconKey: c['iconKey']!,
      type: 'income',
      sortOrder: 0,
      isDefault: true,
      isArchived: false,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    )).toList();

    if (mounted) {
      setState(() {
        _pendingItems = items;
        _expenseCategories = finalExpCats;
        _incomeCategories = finalIncCats;
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmItem(PendingTransactionModel item, String chosenCategory, {bool? isExpenseOverride}) async {
    final typeOverride = _typeOverrides[item.id] ?? item.type;
    await TransactionService.instance.confirmPending(
      item.id,
      categoryId: chosenCategory,
      kindOverride: typeOverride,
      isExpenseOverride: isExpenseOverride,
    );

    widget.onTransactionsUpdated?.call();
    _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t('Đã xác nhận: {description}', {'description': item.description})),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _dismissItem(PendingTransactionModel item) async {
    await DatabaseHelper.instance.updatePendingTransactionStatus(item.id, 'dismissed');
    widget.onTransactionsUpdated?.call();
    _loadData();
  }

  Future<void> _confirmAll() async {
    int count = 0;
    for (var item in List<PendingTransactionModel>.from(_pendingItems)) {
      final category = item.suggestedCategoryId ?? (item.type == 'expense' ? 'Khác' : 'Khác');
      await _confirmItem(item, category);
      count++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t('Đã xác nhận {count} giao dịch!', {'count': count})),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _showCategoryPicker(PendingTransactionModel item, bool isExpense, Function(String) onSelect) {
    // Chọn mảng danh mục dựa theo loại hiện tại (isExpense)
    final List<CategoryModel> cats = isExpense ? _expenseCategories : _incomeCategories;

    // Bổ sung tự động danh mục 'Chuyển tiền' (Không có trong Expense/Income thường)
    final transferCat = CategoryModel(
      name: 'Chuyển tiền',
      iconKey: 'swap_horiz',
      type: 'expense',
      sortOrder: 999,
      isDefault: true,
      isArchived: false,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );

    // Mở rộng mảng
    final displayCats = [...cats, transferCat];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.t('Chọn danh mục ({type})', {'type': context.t(item.type == 'expense' ? 'Chi tiêu' : 'Thu nhập')}),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.darkBeige),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: displayCats.isEmpty
                    ? Center(
                        child: Text(
                          context.t('Chưa có danh mục nào.\nVui lòng thêm ở màn hình Cài đặt.'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: displayCats.length,
                        itemBuilder: (ctx, index) {
                          final cat = displayCats[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(CategoryModel.getIconData(cat.iconKey), color: AppColors.primary, size: 22),
                            ),
                            title: Text(
                              context.tCategory(cat.name),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              onSelect(cat.name);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Container(
      height: media.size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF7EB),
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.mark_email_unread_rounded, color: AppColors.darkBeige, size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          context.t('Chờ xác nhận ({count})', {'count': _pendingItems.length}),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBeige,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_pendingItems.isNotEmpty)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _confirmAll,
                    icon: const Icon(Icons.done_all_rounded, size: 16, color: AppColors.primary),
                    label: Text(
                      context.t('Xác nhận tất cả'),
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
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
                : _pendingItems.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pendingItems.length,
                        itemBuilder: (ctx, index) {
                          final item = _pendingItems[index];
                          return _buildPendingCard(item);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/avatar/avatar.jpg',
            width: 80,
            height: 80,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.check_circle_outline_rounded,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.t('Không có giao dịch nào chờ xác nhận!'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBeige,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.t('Khi ngân hàng có thông báo mới, Mousey sẽ tự động ghi nhận bản nháp ở đây.'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard(PendingTransactionModel item) {
    final typeOverride = _typeOverrides[item.id] ?? item.type;
    final isExpense = typeOverride == 'expense';
    final isUnknown = typeOverride == 'unknown';
    final signText = isUnknown ? '' : (isExpense ? '-' : '+');
    final amountColor = isUnknown ? Colors.blue.shade700 : (isExpense ? Colors.red.shade700 : Colors.green.shade700);

    final amountText = '$signText${item.amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';
    final currentCat = _categoryOverrides[item.id] ?? item.suggestedCategoryId ?? (isExpense ? 'Khác' : 'Khác');

    Color confidenceColor;
    String confidenceLabel;
    switch (item.suggestionConfidence) {
      case 'high':
        confidenceColor = Colors.green;
        confidenceLabel = context.t('Tin cậy cao');
        break;
      case 'medium':
        confidenceColor = Colors.orange;
        confidenceLabel = context.t('Gợi ý');
        break;
      case 'none':
      default:
        confidenceColor = Colors.grey;
        confidenceLabel = context.t('Chưa phân loại');
        break;
    }

    DateTime? dt = DateTime.tryParse(item.occurredAt);
    String timeStr = dt != null
        ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} - ${dt.day}/${dt.month}/${dt.year}'
        : item.occurredAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bank Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.bankName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBeige,
                          ),
                        ),
                      ),
                      if (item.accountLast4.isNotEmpty && item.accountLast4 != 'N/A') ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isExpense ? context.t('TK trừ: ***{accountLast4}', {'accountLast4': item.accountLast4}) : context.t('TK nhận: ***{accountLast4}', {'accountLast4': item.accountLast4}),
                            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Description & Amount
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  amountText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Category selector & Confidence Badge
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (item.bankName == 'MoMo' || item.bankName == 'ZaloPay' || isUnknown)
                  InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (ctx) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.arrow_upward, color: Colors.red),
                                title: Text(context.t('Khoản Chi tiêu')),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  setState(() {
                                    _typeOverrides[item.id] = 'expense';
                                    if (_categoryOverrides[item.id] == null || _categoryOverrides[item.id] == 'Chuyển tiền') {
                                      _categoryOverrides[item.id] = 'Khác';
                                    }
                                  });
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.arrow_downward, color: Colors.green),
                                title: Text(context.t('Khoản Thu nhập')),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  setState(() {
                                    _typeOverrides[item.id] = 'income';
                                    _categoryOverrides[item.id] = 'Khác';
                                  });
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.swap_horiz, color: Colors.blue),
                                title: Text(context.t('Chuyển khoản (Không tính vào tổng)')),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  setState(() {
                                    _typeOverrides[item.id] = 'expense';
                                    _categoryOverrides[item.id] = 'Chuyển tiền';
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isUnknown ? Icons.help_outline : (isExpense ? Icons.arrow_upward : Icons.arrow_downward), size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            isUnknown ? context.t('Xác định loại') : context.t('Đổi loại'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 16, color: Colors.blue),
                        ],
                      ),
                    ),
                  ),
                InkWell(
                  onTap: () => _showCategoryPicker(item, isExpense, (newCat) {
                    setState(() {
                      _categoryOverrides[item.id] = newCat;
                    });
                  }),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accentDark.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accentDark),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.category_rounded, size: 14, color: AppColors.darkBeige),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            context.tCategory(currentCat),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkBeige,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.darkBeige),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: confidenceColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: confidenceColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    confidenceLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: confidenceColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _dismissItem(item),
                  child: Text(context.t('Bỏ qua'), style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _confirmItem(item, currentCat, isExpenseOverride: isExpense),
                  child: Text(
                    context.t('Xác nhận'),
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
