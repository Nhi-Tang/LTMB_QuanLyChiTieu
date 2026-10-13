import 'package:flutter/material.dart';
import '../../backend/database/db_helper.dart';
import '../../backend/models/savings_goal_model.dart';
import '../../backend/models/savings_transaction_model.dart';
import '../../core/utils/money_input_formatter.dart';
import '../widgets/add_edit_savings_goal_dialog.dart';
import '../widgets/app_alert_dialog.dart';
import '../widgets/mousey_avatar.dart';

class SavingsGoalDetailScreen extends StatefulWidget {
  final SavingsGoalModel goal;
  final String selectedLanguage;
  final VoidCallback onGoalUpdated;

  const SavingsGoalDetailScreen({
    super.key,
    required this.goal,
    this.selectedLanguage = 'Tiếng Việt',
    required this.onGoalUpdated,
  });

  @override
  State<SavingsGoalDetailScreen> createState() => _SavingsGoalDetailScreenState();
}

class _SavingsGoalDetailScreenState extends State<SavingsGoalDetailScreen> {
  late SavingsGoalModel _goal;
  List<SavingsTransactionModel> _transactions = [];
  bool _isLoading = true;

  static const Color accentBeige = Color(0xFFE5D3AF);

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final txs = await DatabaseHelper.instance.getSavingsTransactions(_goal.id ?? 0);
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isDeposit ? 'Nạp thêm tiền vào mục tiêu' : 'Rút bớt tiền khỏi mục tiêu',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDeposit ? accentBeige : Colors.red[700],
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
                  labelText: 'Số tiền (đ)',
                  prefixIcon: Icon(Icons.attach_money, color: isDeposit ? accentBeige : Colors.red),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Ghi chú (Tùy chọn)',
                  prefixIcon: const Icon(Icons.note, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDeposit ? accentBeige : Colors.red[700],
                    foregroundColor: isDeposit ? const Color(0xFF5D4222) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final amount = parseMoney(amountController.text).toDouble();
                    if (amount <= 0) {
                      showAppAlertDialog(
                        context: context,
                        title: 'Thông báo',
                        message: 'Vui lòng nhập số tiền hợp lệ lớn hơn 0!',
                        isSuccess: false,
                      );
                      return;
                    }

                    if (!isDeposit && amount > _goal.currentAmount) {
                      showAppAlertDialog(
                        context: context,
                        title: 'Không thể rút',
                        message: 'Số tiền rút không được vượt quá số tiền hiện có (${_formatCurrency(_goal.currentAmount)})!',
                        isSuccess: false,
                      );
                      return;
                    }

                    final tx = SavingsTransactionModel(
                      goalId: _goal.id ?? 0,
                      amount: amount,
                      isDeposit: isDeposit,
                      note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : (isDeposit ? 'Nạp thêm' : 'Rút bớt'),
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
                      title: 'Thành công',
                      message: isDeposit ? 'Đã nạp thêm tiền thành công! 🐖' : 'Đã rút bớt tiền thành công!',
                      isSuccess: true,
                    );
                  },
                  child: Text(
                    isDeposit ? 'XÁC NHẬN NẠP THÊM' : 'XÁC NHẬN RÚT BỚT',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _markAsCompleted() async {
    final updated = _goal.copyWith(isCompleted: true);
    await DatabaseHelper.instance.updateSavingsGoal(updated);
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
            const Text(
              'Chúc mừng bạn!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accentBeige),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn đã hoàn thành mục tiêu "${_goal.name}" xuất sắc!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentBeige,
                foregroundColor: const Color(0xFF5D4222),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('TUYỆT VỜI', style: TextStyle(color: Color(0xFF5D4222), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  String _getForecastText() {
    if (_goal.isCompleted) return 'Mục tiêu này đã hoàn thành';
    if (_transactions.isEmpty || _goal.currentAmount <= 0) return 'Chưa đủ dữ liệu lịch sử để dự báo.';

    final deposits = _transactions.where((t) => t.isDeposit).toList();
    if (deposits.isEmpty) return 'Chưa có giao dịch nạp tiền.';

    final totalDeposited = deposits.fold(0.0, (sum, t) => sum + t.amount);
    final firstTxDate = DateTime.tryParse(_transactions.last.date) ?? DateTime.now();
    final daysPassed = DateTime.now().difference(firstTxDate).inDays;
    final monthsPassed = daysPassed > 0 ? daysPassed / 30.0 : 1.0;
    final avgMonthlyDeposit = totalDeposited / monthsPassed;

    if (avgMonthlyDeposit <= 0) return 'Tốc độ tiết kiệm hiện tại bằng 0.';

    final remainingAmount = _goal.targetAmount - _goal.currentAmount;
    final monthsNeeded = remainingAmount / avgMonthlyDeposit;

    final targetCompletionDate = DateTime.now().add(Duration(days: (monthsNeeded * 30).toInt()));
    String deadlineStr = 'tháng ${targetCompletionDate.month}/${targetCompletionDate.year}';

    if (_goal.deadline != null && _goal.deadline!.isNotEmpty) {
      final deadline = DateTime.tryParse(_goal.deadline!);
      if (deadline != null) {
        if (targetCompletionDate.isBefore(deadline) || targetCompletionDate.isAtSameMomentAs(deadline)) {
          return 'Với tốc độ hiện tại, bạn sẽ đạt mục tiêu vào $deadlineStr, sớm hơn dự kiến!';
        } else {
          final diffMonths = (targetCompletionDate.difference(deadline).inDays / 30).ceil();
          return 'Với tốc độ hiện tại, bạn sẽ đạt mục tiêu vào $deadlineStr, trễ hơn dự kiến khoảng $diffMonths tháng.';
        }
      }
    }

    return 'Với tốc độ hiện tại, bạn sẽ hoàn thành mục tiêu vào $deadlineStr.';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _goal.targetAmount > 0 ? (_goal.currentAmount / _goal.targetAmount).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).toStringAsFixed(0);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7EB),
      appBar: AppBar(
        title: Text(_goal.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          // Only show edit if not completed
          if (!_goal.isCompleted)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Sửa mục tiêu',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AddEditSavingsGoalDialog(
                    goalToEdit: _goal,
                    onSaved: () async {
                      final goals = await DatabaseHelper.instance.getSavingsGoals();
                      final updated = goals.firstWhere((g) => g.id == _goal.id);
                      setState(() => _goal = updated);
                      widget.onGoalUpdated();
                    },
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Xóa mục tiêu',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Xóa mục tiêu'),
                  content: Text('Bạn có chắc chắn muốn xóa mục tiêu "${_goal.name}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        await DatabaseHelper.instance.deleteSavingsGoal(_goal.id ?? 0);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                        widget.onGoalUpdated();
                      },
                      child: const Text('Xóa', style: TextStyle(color: Colors.white)),
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFECE7DB)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF7EB),
                          shape: BoxShape.circle,
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
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _goal.isCompleted ? 'Đã hoàn thành 🌟' : 'Đang tích lũy...',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _goal.isCompleted ? accentBeige : Colors.grey[600],
                              ),
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
                      Text(
                        _formatCurrency(_goal.currentAmount),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: accentBeige),
                      ),
                      Text(
                        _formatCurrency(_goal.targetAmount),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 14,
                      backgroundColor: const Color(0xFFF2EFE6),
                      valueColor: const AlwaysStoppedAnimation<Color>(accentBeige),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$percent%',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF706C66)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons or Completed Banner
                  if (_goal.isCompleted)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7EB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5D3AF)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: accentBeige, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Đã hoàn thành mục tiêu',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5D4222)),
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
                              backgroundColor: accentBeige,
                              foregroundColor: const Color(0xFF5D4222),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.add, color: Color(0xFF5D4222)),
                            label: const Text('Nạp thêm', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D4222))),
                            onPressed: () => _showDepositWithdrawModal(isDeposit: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red[700]!),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: Icon(Icons.remove, color: Colors.red[700]),
                            label: Text('Rút bớt', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700])),
                            onPressed: () => _showDepositWithdrawModal(isDeposit: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                        label: const Text('Đánh dấu Hoàn thành', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
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
                color: const Color(0xFFFFF7EB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5D3AF)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.insights_rounded, color: accentBeige, size: 24),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      _getForecastText(),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF5D4222), height: 1.35),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // History Header
            const Text(
              'LỊCH SỬ NẠP / RÚT',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Color(0xFF706C66)),
            ),

            const SizedBox(height: 10),

            // Transactions History List
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: accentBeige))
                : _transactions.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFECE7DB)),
                        ),
                        child: const Center(
                          child: Text('Chưa có lịch sử giao dịch tiết kiệm nào.', style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _transactions.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                        itemBuilder: (ctx, index) {
                          final tx = _transactions[index];
                          final date = DateTime.tryParse(tx.date) ?? DateTime.now();
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFECE7DB)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: tx.isDeposit ? const Color(0xFFFFF7EB) : const Color(0xFFFFEBEE),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      tx.isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                                      color: tx.isDeposit ? accentBeige : Colors.red,
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
                                        tx.note ?? (tx.isDeposit ? 'Nạp thêm' : 'Rút bớt'),
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${date.day}/${date.month}/${date.year} · ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${tx.isDeposit ? '+' : '-'}${_formatCurrency(tx.amount)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: tx.isDeposit ? accentBeige : Colors.red,
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
