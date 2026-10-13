import 'package:flutter/material.dart';
import '../../backend/database/db_helper.dart';
import '../../backend/models/savings_goal_model.dart';
import '../utils/app_translations.dart';
import '../widgets/add_edit_savings_goal_dialog.dart';
import '../widgets/mousey_avatar.dart';
import 'savings_goal_detail_screen.dart';

class SavingsTab extends StatefulWidget {
  final String selectedAvatarKey;
  final String userName;
  final String selectedLanguage;

  const SavingsTab({
    super.key,
    required this.selectedAvatarKey,
    required this.userName,
    this.selectedLanguage = 'Tiếng Việt',
  });

  @override
  State<SavingsTab> createState() => _SavingsTabState();
}

class _SavingsTabState extends State<SavingsTab> {
  List<SavingsGoalModel> _goals = [];
  bool _isLoading = true;

  static const Color primaryBeigy = Color(0xFFFCF1D0);
  static const Color darkBeigy = Color(0xFF5D4222);
  static const Color accentBeigy = Color(0xFFE5D3AF);

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    final goals = await DatabaseHelper.instance.getSavingsGoals();
    if (!mounted) return;
    setState(() {
      _goals = goals;
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

  double get _totalSavedAmount {
    double sum = 0.0;
    for (var g in _goals) {
      sum += g.currentAmount;
    }
    return sum;
  }

  void _showAddGoalDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddEditSavingsGoalDialog(
        onSaved: () => _loadGoals(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.selectedLanguage;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Card Tiết Kiệm (Summary Card)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryBeigy,
                  Color(0xFFFCF1D0),
                  accentBeigy,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: darkBeigy.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppTranslations.tr(lang, 'piggy_savings_badge'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: darkBeigy,
                      ),
                    ),
                    buildUserAvatar(
                      avatarKey: widget.selectedAvatarKey,
                      userName: widget.userName,
                      size: 44,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'TỔNG TIỀN ĐÃ TIẾT KIỆM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: darkBeigy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatCurrency(_totalSavedAmount),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: darkBeigy,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          'assets/avatar/avatar.jpg',
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppTranslations.tr(lang, 'piggy_quote_home'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF222222),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Header: Danh sách Mục tiêu Tiết kiệm
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppTranslations.tr(lang, 'savings_goals'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Color(0xFF706C66),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentBeigy,
                  foregroundColor: const Color(0xFF5D4222),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _showAddGoalDialog,
                icon: ClipOval(
                  child: Image.asset(
                    'assets/icon/tietkiem.png',
                    width: 16,
                    height: 16,
                    fit: BoxFit.cover,
                  ),
                ),
                label: Text(
                  AppTranslations.tr(lang, 'create_goal'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5D4222)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // List of Goals or Empty State
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: accentBeigy))
              : _goals.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFECE7DB)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipOval(
                            child: Image.asset(
                              'assets/avatar/avatar.jpg',
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            AppTranslations.tr(lang, 'no_savings_goals'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF222222),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppTranslations.tr(lang, 'add_first_transaction'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _goals.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                      itemBuilder: (ctx, index) {
                        final goal = _goals[index];
                        final progress = goal.targetAmount > 0
                            ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
                            : 0.0;
                        final percent = (progress * 100).toStringAsFixed(0);

                        String subtitleText = '';
                        String monthlySuggestionStr = '';
                        if (goal.isCompleted) {
                          subtitleText = 'Đã hoàn thành';
                        } else if (goal.deadline != null && goal.deadline!.isNotEmpty) {
                          final deadlineDate = DateTime.tryParse(goal.deadline!);
                          if (deadlineDate != null) {
                            final daysLeft = deadlineDate.difference(DateTime.now()).inDays;
                            if (daysLeft >= 0) {
                              subtitleText = 'Còn $daysLeft ngày';
                              final monthsLeft = daysLeft > 0 ? daysLeft / 30.0 : 1.0;
                              final remainingAmt = goal.targetAmount - goal.currentAmount;
                              if (remainingAmt > 0 && monthsLeft > 0) {
                                final monthlyNeeded = remainingAmt / monthsLeft;
                                monthlySuggestionStr = 'Mỗi tháng cần để dành ${_formatCurrency(monthlyNeeded)} để kịp hạn';
                              }
                            } else {
                              subtitleText = 'Đã quá hạn';
                            }
                          }
                        } else {
                          subtitleText = 'Mục tiêu tích lũy';
                        }

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SavingsGoalDetailScreen(
                                  goal: goal,
                                  selectedLanguage: lang,
                                  onGoalUpdated: _loadGoals,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFECE7DB)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFF7EB),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: buildGoalIcon(goal.icon, size: 26),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            goal.name,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            subtitleText,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: goal.isCompleted ? accentBeigy : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '$percent%',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accentBeigy),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatCurrency(goal.currentAmount),
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
                                    ),
                                    Text(
                                      _formatCurrency(goal.targetAmount),
                                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 10,
                                    backgroundColor: const Color(0xFFF2EFE6),
                                    valueColor: const AlwaysStoppedAnimation<Color>(accentBeigy),
                                  ),
                                ),
                                if (monthlySuggestionStr.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7EB),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.lightbulb_outline_rounded, size: 14, color: accentBeigy),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            monthlySuggestionStr,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: darkBeigy),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}
