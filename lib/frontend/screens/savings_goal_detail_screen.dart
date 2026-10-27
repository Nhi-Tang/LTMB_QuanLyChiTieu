import 'package:flutter/material.dart';
import '../../backend/database/db_helper.dart';
import '../../backend/models/savings_goal_model.dart';
import '../../backend/models/savings_transaction_model.dart';
import '../../core/utils/money_input_formatter.dart';
import '../../core/widgets/money_text.dart';
import '../widgets/add_edit_savings_goal_dialog.dart';
import '../widgets/app_alert_dialog.dart';
import '../widgets/mousey_avatar.dart';
import '../utils/app_language.dart';
import '../theme/app_colors.dart';

class SavingsGoalDetailScreen extends StatefulWidget {
  final SavingsGoalModel goal;
  final VoidCallback onGoalUpdated;

  const SavingsGoalDetailScreen({
    super.key,
    required this.goal,
    required this.onGoalUpdated,
  });

  @override
  State<SavingsGoalDetailScreen> createState() => _SavingsGoalDetailScreenState();
}

class _SavingsGoalDetailScreenState extends State<SavingsGoalDetailScreen> {
  late SavingsGoalModel _goal;
  List<SavingsTransactionModel> _transactions = [];
  bool _isLoading = true;

  static Color get accentPurple => AppColors.tealBright;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final txs = await DatabaseHelper.instance.getSavingsTransactions(_goal.id ?? '');
    if (!mounted) return;
    setState(() {
      _transactions = txs;
      _isLoading = false;
    });
  }

  String _formatCurrency(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final formatted = absAmount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return '${isNegative ? '-' : ''}$formatted đ';
  }

  void _showDepositWithdrawModal({required bool isDeposit}) {
    if (_goal.isCompleted) return;

    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isDeposit ? context.t('Nạp thêm tiền vào mục tiêu') : context.t('Rút bớt tiền khỏi mục tiêu'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDeposit ? accentPurple : AppColors.expense,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [MoneyInputFormatter()],
                  decoration: InputDecoration(
                    labelText: context.t('Số tiền (đ)'),
                    prefixIcon: Icon(Icons.attach_money, color: isDeposit ? accentPurple : AppColors.expense),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    labelText: context.t('Ghi chú (Tùy chọn)'),
                    prefixIcon: Icon(Icons.note, color: AppColors.grey500),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDeposit ? accentPurple : AppColors.expense,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () async {
                      final amount = parseMoney(amountController.text).toDouble();
                      if (amount <= 0) {
                        showAppAlertDialog(
                          context: context,
                          title: context.t('Thông báo'),
                          message: context.t('Vui lòng nhập số tiền hợp lệ lớn hơn 0!'),
                          isSuccess: false,
                        );
                        return;
                      }

                      if (!isDeposit && amount > _goal.currentAmount) {
                        showAppAlertDialog(
                          context: context,
                          title: context.t('Không thể rút'),
                          message: context.t('Số tiền rút không được vượt quá số tiền hiện có ({value})!', {'value': _formatCurrency(_goal.currentAmount)}),
                          isSuccess: false,
                        );
                        return;
                      }

                      final tx = SavingsTransactionModel(
                        goalId: _goal.id ?? '',
                        amount: amount,
                        isDeposit: isDeposit,
                        note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : (isDeposit ? context.t('Nạp thêm') : context.t('Rút bớt')),
                        date: DateTime.now().toIso8601String(),
                      );

                      await DatabaseHelper.instance.addSavingsTransaction(tx);

                      // Refresh goal from DB
                      final goals = await DatabaseHelper.instance.getSavingsGoals();
                      final updated = goals.firstWhere((g) => g.id == _goal.id);

                      if (!mounted) return;
                      setState(() {
                        _goal = updated;
                      });
                      _loadTransactions();
                      widget.onGoalUpdated();

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);

                      if (!mounted) return;
                      showAppAlertDialog(
                        context: context,
                        title: context.t('Thành công'),
                        message: isDeposit ? context.t('Đã nạp thêm tiền thành công! 🐖') : context.t('Đã rút bớt tiền thành công!'),
                        isSuccess: true,
                      );
                    },
                    child: Text(
                      isDeposit ? context.t('XÁC NHẬN NẠP THÊM') : context.t('XÁC NHẬN RÚT BỚT'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _markAsCompleted() async {
    final updated = _goal.copyWith(isCompleted: true);
    await DatabaseHelper.instance.updateSavingsGoal(updated);
    if (!mounted) return;
    setState(() {
      _goal = updated;
    });
    widget.onGoalUpdated();
    _showCelebrationDialog();
  }

  void _showCelebrationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            Text(
              context.t('Chúc mừng bạn!'),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accentPurple),
            ),
            const SizedBox(height: 8),
            Text(
              context.t('Bạn đã hoàn thành mục tiêu "{name}" xuất sắc!', {'name': _goal.name}),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.grey500),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentPurple,
                foregroundColor: AppColors.onTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.t('TUYỆT VỜI'), style: TextStyle(color: AppColors.onTeal, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  String _getForecastText() {
    if (_goal.isCompleted) return context.t('Mục tiêu này đã hoàn thành');
    if (_transactions.isEmpty || _goal.currentAmount <= 0) return context.t('Chưa đủ dữ liệu lịch sử để dự báo.');

    final deposits = _transactions.where((t) => t.isDeposit).toList();
    if (deposits.isEmpty) return context.t('Chưa có giao dịch nạp tiền.');

    final totalDeposited = deposits.fold(0.0, (sum, t) => sum + t.amount);
    final firstTxDate = DateTime.tryParse(_transactions.last.date) ?? DateTime.now();
    final daysPassed = DateTime.now().difference(firstTxDate).inDays;
    final monthsPassed = daysPassed > 0 ? daysPassed / 30.0 : 1.0;
    final avgMonthlyDeposit = totalDeposited / monthsPassed;

    if (avgMonthlyDeposit <= 0) return context.t('Tốc độ tiết kiệm hiện tại bằng 0.');

    final remainingAmount = _goal.targetAmount - _goal.currentAmount;
    final monthsNeeded = remainingAmount / avgMonthlyDeposit;

    final targetCompletionDate = DateTime.now().add(Duration(days: (monthsNeeded * 30).toInt()));
    String deadlineStr = context.t('tháng {month}/{year}', {'month': targetCompletionDate.month, 'year': targetCompletionDate.year});

    if (_goal.deadline != null && _goal.deadline!.isNotEmpty) {
      final deadline = DateTime.tryParse(_goal.deadline!);
      if (deadline != null) {
        if (targetCompletionDate.isBefore(deadline) || targetCompletionDate.isAtSameMomentAs(deadline)) {
          return context.t('Với tốc độ hiện tại, bạn sẽ đạt mục tiêu vào {deadlineStr}, sớm hơn dự kiến!', {'deadlineStr': deadlineStr});
        } else {
          final diffMonths = (targetCompletionDate.difference(deadline).inDays / 30).ceil();
          return context.t('Với tốc độ hiện tại, bạn sẽ đạt mục tiêu vào {deadlineStr}, trễ hơn dự kiến khoảng {diffMonths} tháng.', {'deadlineStr': deadlineStr, 'diffMonths': diffMonths});
        }
      }
    }

    return context.t('Với tốc độ hiện tại, bạn sẽ hoàn thành mục tiêu vào {deadlineStr}.', {'deadlineStr': deadlineStr});
  }

  @override
  Widget build(BuildContext context) {
    final progress = _goal.targetAmount > 0 ? (_goal.currentAmount / _goal.targetAmount).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(
        title: Text(_goal.name, overflow: TextOverflow.ellipsis),
        actions: [
          // Only show edit if not completed
          if (!_goal.isCompleted)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: context.t('Sửa mục tiêu'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AddEditSavingsGoalDialog(
                    goalToEdit: _goal,
                    onSaved: () async {
                      final goals = await DatabaseHelper.instance.getSavingsGoals();
                      final updated = goals.firstWhere((g) => g.id == _goal.id);
                      if (!mounted) return;
                      setState(() => _goal = updated);
                      widget.onGoalUpdated();
                    },
                  ),
                );
              },
            ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppColors.expense),
            tooltip: context.t('Xóa mục tiêu'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Text(context.t('Xóa mục tiêu')),
                  content: Text(context.t('Bạn có chắc chắn muốn xóa mục tiêu "{name}"?', {'name': _goal.name})),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.t('Hủy'))),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        await DatabaseHelper.instance.deleteSavingsGoal(_goal.id ?? '');
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (!mounted) return;
                        Navigator.pop(context);
                        widget.onGoalUpdated();
                      },
                      child: Text(context.t('Xóa'), style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Progress Card
            Container(
              padding: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.rule)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.ink, width: 1.5),
                        ),
                        child: Center(
                          child: buildGoalIcon(_goal.icon, size: 32),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _goal.name,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _goal.isCompleted ? context.t('Đã hoàn thành 🌟') : context.t('Đang tích lũy...'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _goal.isCompleted ? accentPurple : AppColors.grey600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.highlight,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: MoneyText(
                            amount: _goal.currentAmount,
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: MoneyText(
                          amount: _goal.targetAmount,
                          alignment: Alignment.centerRight,
                          prefix: '/ ',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppColors.rule,
                      valueColor: AlwaysStoppedAnimation<Color>(accentPurple),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$percent%',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons or Completed Banner
                  if (_goal.isCompleted)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.note,
                        borderRadius: BorderRadius.circular(4),
                        border: Border(bottom: BorderSide(color: AppColors.noteBorder, width: 3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: accentPurple, size: 20),
                          SizedBox(width: 8),
                          Text(
                            context.t('Đã hoàn thành mục tiêu'),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.tealDark),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentPurple,
                              foregroundColor: AppColors.onTeal,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: const StadiumBorder(),
                            ),
                            icon: Icon(Icons.add, color: AppColors.onTeal),
                            label: Text(context.t('Nạp thêm'), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.onTeal)),
                            onPressed: () => _showDepositWithdrawModal(isDeposit: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.expense, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: const StadiumBorder(),
                            ),
                            icon: Icon(Icons.remove, color: AppColors.expense),
                            label: Text(context.t('Rút bớt'), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.expense)),
                            onPressed: () => _showDepositWithdrawModal(isDeposit: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.ink, width: 1.5),
                          shape: const StadiumBorder(),
                        ),
                        icon: Icon(Icons.check_circle_outline, color: AppColors.ink),
                        label: Text(context.t('Đánh dấu Hoàn thành'), style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.ink, fontSize: 14)),
                        onPressed: _markAsCompleted,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Forecast Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.note,
                borderRadius: BorderRadius.circular(4),
                border: Border(bottom: BorderSide(color: AppColors.noteBorder, width: 3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insights_rounded, color: accentPurple, size: 24),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      _getForecastText(),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink, height: 1.35),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // History Header
            Text(
              context.t('LỊCH SỬ NẠP / RÚT'),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textMuted),
            ),

            const SizedBox(height: 10),

            // Transactions History List
            _isLoading
                ? Center(child: CircularProgressIndicator(color: accentPurple))
                : _transactions.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          border: Border.symmetric(horizontal: BorderSide(color: AppColors.rule)),
                        ),
                        child: Center(
                          child: Text(context.t('Chưa có lịch sử giao dịch tiết kiệm nào.'), style: TextStyle(color: AppColors.grey500)),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _transactions.length,
                        separatorBuilder: (ctx, i) => Divider(height: 1, color: AppColors.rule),
                        itemBuilder: (ctx, index) {
                          final tx = _transactions[index];
                          final date = DateTime.tryParse(tx.date) ?? DateTime.now();
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: tx.isDeposit ? AppColors.income : AppColors.expense),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      tx.isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                                      color: tx.isDeposit ? AppColors.income : AppColors.expense,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.note ?? (tx.isDeposit ? context.t('Nạp thêm') : context.t('Rút bớt')),
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${date.day}/${date.month}/${date.year} · ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(fontSize: 11, color: AppColors.grey500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: MoneyText(
                                    amount: tx.amount,
                                    prefix: tx.isDeposit ? '+' : '-',
                                    alignment: Alignment.centerRight,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: tx.isDeposit ? AppColors.income : AppColors.expense,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
