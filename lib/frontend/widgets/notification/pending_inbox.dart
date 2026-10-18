import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../backend/database/db_helper.dart';
import '../../../backend/models/pending_transaction_model.dart';
import '../../../backend/models/transaction_model.dart';
import '../../../backend/services/category_repository.dart';
import '../../../backend/models/category_model.dart';
import '../../theme/app_colors.dart';

class PendingInboxSheet extends StatefulWidget {
  final VoidCallback? onTransactionsUpdated;

  const PendingInboxSheet({super.key, this.onTransactionsUpdated});

  static Future<void> show(BuildContext context, {VoidCallback? onTransactionsUpdated}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PendingInboxSheet(onTransactionsUpdated: onTransactionsUpdated),
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final items = await DatabaseHelper.instance.getPendingTransactions(status: 'pending');
    final expCats = await CategoryRepository.instance.getCategories(type: 'expense');
    final incCats = await CategoryRepository.instance.getCategories(type: 'income');

    if (mounted) {
      setState(() {
        _pendingItems = items;
        _expenseCategories = expCats;
        _incomeCategories = incCats;
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmItem(PendingTransactionModel item, String chosenCategory) async {
    final realTx = TransactionItem(
      id: const Uuid().v4(),
      title: item.description,
      category: chosenCategory,
      amount: item.amount.toDouble(),
      isExpense: item.type == 'expense',
      date: DateTime.tryParse(item.occurredAt) ?? DateTime.now(),
      uid: item.uid,
    );

    await DatabaseHelper.instance.insertTransaction(realTx, uid: item.uid);
    await DatabaseHelper.instance.updatePendingTransactionStatus(
      item.id,
      'confirmed',
      categoryId: chosenCategory,
    );

    widget.onTransactionsUpdated?.call();
    _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xác nhận: ${item.description}'),
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
          content: Text('Đã xác nhận $count giao dịch!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _showCategoryPicker(PendingTransactionModel item, Function(String) onSelect) {
    final cats = item.type == 'expense' ? _expenseCategories : _incomeCategories;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn danh mục cho giao dịch',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: cats.length,
                    itemBuilder: (ctx, index) {
                      final cat = cats[index];
                      return ListTile(
                        leading: Icon(CategoryModel.getIconData(cat.iconKey), color: AppColors.primary),
                        title: Text(cat.name),
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
                          'Chờ xác nhận (${_pendingItems.length})',
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
                    label: const Text(
                      'Xác nhận tất cả',
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
            'assets/icon/piggy.jpg',
            width: 80,
            height: 80,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.check_circle_outline_rounded,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Không có giao dịch nào chờ xác nhận!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBeige,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Khi ngân hàng có thông báo mới, Mousey sẽ tự động ghi nhận bản nháp ở đây.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard(PendingTransactionModel item) {
    final isExpense = item.type == 'expense';
    final amountText = '${isExpense ? '-' : '+'}${item.amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';
    final currentCat = item.suggestedCategoryId ?? (isExpense ? 'Khác' : 'Khác');

    Color confidenceColor;
    String confidenceLabel;
    switch (item.suggestionConfidence) {
      case 'high':
        confidenceColor = Colors.green;
        confidenceLabel = 'Tin cậy cao';
        break;
      case 'medium':
        confidenceColor = Colors.orange;
        confidenceLabel = 'Gợi ý';
        break;
      case 'none':
      default:
        confidenceColor = Colors.grey;
        confidenceLabel = 'Chưa phân loại';
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
                            isExpense ? 'TK trừ: ***${item.accountLast4}' : 'TK nhận: ***${item.accountLast4}',
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
                    color: isExpense ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Category selector & Confidence Badge
            Row(
              children: [
                InkWell(
                  onTap: () => _showCategoryPicker(item, (newCat) {
                    _confirmItem(item, newCat);
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
                        Text(
                          currentCat,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBeige,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.darkBeige),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                  child: const Text('Bỏ qua', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _confirmItem(item, currentCat),
                  child: const Text(
                    'Xác nhận',
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
