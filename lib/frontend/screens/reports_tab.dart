import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../backend/models/transaction_model.dart';
import '../../core/widgets/money_text.dart';
import '../theme/app_colors.dart';
import '../utils/app_translations.dart';
import '../widgets/mousey_avatar.dart';
import '../utils/app_language.dart';

class ReportsTab extends StatefulWidget {
  final List<TransactionItem> transactions;
  final String selectedLanguage;

  const ReportsTab({
    super.key,
    required this.transactions,
    this.selectedLanguage = 'Tiếng Việt',
  });

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  int _reportTypeIndex = 0; // 0: Chi tiêu, 1: Thu nhập
  String _timeRange = 'all_time';
  String _selectedCategoryFilter = 'Tất cả';
  bool _showAllCategories = false;
  int _trendMonthRange = 6; // 3t, 6t, 12t, 24t

  @override
  void didUpdateWidget(covariant ReportsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLanguage != widget.selectedLanguage) {
      setState(() {});
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Ăn uống':
        return const Color(0xFFE53935);
      case 'Hóa đơn':
        return const Color(0xFF78909C);
      case 'Di chuyển':
        return const Color(0xFFFB8C00);
      case 'Mua sắm':
        return const Color(0xFF8E24AA);
      case 'Giải trí':
        return const Color(0xFFD81B60);
      case 'Sức khoẻ':
        return const Color(0xFF00ACC1);
      case 'Làm đẹp':
        return const Color(0xFFEC407A);
      case 'Quần áo':
        return const Color(0xFF5C6BC0);
      case 'Học tập':
        return const Color(0xFF1E88E5);
      case 'Thú cưng':
        return const Color(0xFFFF7043);
      case 'Con cái':
        return const Color(0xFFAB47BC);
      case 'Hỗ trợ gia đình':
        return const Color(0xFF26A69A);
      case 'Bảo hiểm':
        return const Color(0xFF3949AB);
      case 'Thuế':
        return const Color(0xFF5D4037);
      case 'Công việc':
        return const Color(0xFF455A64);
      case 'Nhà ở':
        return const Color(0xFF8D6E63);
      case 'Tiền nợ':
      case 'Tiền Nợ':
        return const Color(0xFFD32F2F);
      case 'Lương':
        return const Color(0xFF43A047);
      case 'Thưởng':
        return const Color(0xFF00ACC1);
      case 'Đầu tư':
        return const Color(0xFF3949AB);
      case 'Bán hàng':
        return const Color(0xFF7CB342);
      default:
        return const Color(0xFF009688);
    }
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case 'Ăn uống':
        return '🍜';
      case 'Hóa đơn':
        return '🧾';
      case 'Di chuyển':
        return '🚌';
      case 'Mua sắm':
        return '🛍️';
      case 'Giải trí':
        return '🎮';
      case 'Sức khoẻ':
        return '🏥';
      case 'Làm đẹp':
        return '💅';
      case 'Quần áo':
        return '👕';
      case 'Học tập':
        return '🎓';
      case 'Thú cưng':
        return '🐾';
      case 'Con cái':
        return '👶';
      case 'Hỗ trợ gia đình':
        return '👨‍👩‍👧';
      case 'Bảo hiểm':
        return '🛡️';
      case 'Thuế':
        return '🏛️';
      case 'Công việc':
        return '💼';
      case 'Nhà ở':
        return '🏠';
      case 'Tiền nợ':
      case 'Tiền Nợ':
        return '💸';
      case 'Lương':
        return '💰';
      case 'Thưởng':
        return '🎁';
      case 'Đầu tư':
        return '📈';
      case 'Bán hàng':
        return '🏪';
      default:
        return '📦';
    }
  }

  // Dynamic Filtering based on selected type (Chi tiêu / Thu nhập) and Category Filter
  List<TransactionItem> get _filteredTransactions {
    return widget.transactions.where((t) {
      if (t.isDeleted) return false;
      if (_reportTypeIndex == 0) {
        if (t.kind != 'expense' && t.kind != 'transfer_out') return false;
      } else {
        if (t.kind != 'income' && t.kind != 'received') return false;
      }
      if (_selectedCategoryFilter != 'Tất cả' && t.category != _selectedCategoryFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  double get _totalReportAmount {
    double sum = 0.0;
    for (var t in _filteredTransactions) {
      sum += t.amount;
    }
    return sum;
  }

  // Group transactions by category dynamically
  List<Map<String, dynamic>> get _dynamicCategories {
    final Map<String, double> categorySums = {};

    for (var t in _filteredTransactions) {
      categorySums[t.category] = (categorySums[t.category] ?? 0.0) + t.amount;
    }

    final total = _totalReportAmount;
    final List<Map<String, dynamic>> result = [];

    categorySums.forEach((catName, sumAmount) {
      final pct = total > 0 ? (sumAmount / total) * 100.0 : 0.0;
      result.add({
        'name': catName,
        'amount': sumAmount,
        'percentage': pct,
        'color': _getCategoryColor(catName),
        'icon': _getCategoryIcon(catName),
      });
    });

    result.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    return result;
  }

  String get _aiInsightQuote {
    final lang = context.lang;
    final categories = _dynamicCategories;
    if (categories.isEmpty || _totalReportAmount == 0) {
      if (_reportTypeIndex == 1) {
        return AppTranslations.tr(lang, 'mousey_quote_no_income');
      }
      return AppTranslations.tr(lang, 'mousey_quote_no_expense');
    }
    final top = categories.first;
    final translatedCategory = AppTranslations.trCategory(lang, top['name'] as String);
    return '"$translatedCategory ${(top['percentage'] as double).toStringAsFixed(0)}%."';
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented Selector Tabs (Chi tiêu | Thu nhập)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF66EBE5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _buildSegmentTab(0, AppTranslations.tr(lang, 'expense')),
                _buildSegmentTab(1, AppTranslations.tr(lang, 'income')),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Filter Bar
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _showTimeRangePicker,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF66EBE5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF4A463D)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            AppTranslations.tr(lang, _timeRange),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF222222),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF4A463D)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: _showCategoryFilterPicker,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedCategoryFilter != 'Tất cả' ? const Color(0xFFCCF7F7) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedCategoryFilter != 'Tất cả' ? const Color(0xFFCCF7F7) : const Color(0xFFF2F2F2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF4A463D)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _selectedCategoryFilter != 'Tất cả'
                                ? AppTranslations.trCategory(lang, _selectedCategoryFilter)
                                : AppTranslations.tr(lang, 'filter'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF222222),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Main View (Chi tiêu / Thu nhập)
          _buildExpenseOrIncomeView(),
        ],
      ),
    );
  }

  // --- EXPENSE / INCOME TAB VIEW ---
  Widget _buildExpenseOrIncomeView() {
    final lang = context.lang;
    final categories = _dynamicCategories;
    final displayedCategories = _showAllCategories
        ? categories
        : categories.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Card (Chi tiêu / Thu nhập)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF00D1CC), Color(0xFF33DEBF)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
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
                  Expanded(
                    child: Text(
                      _reportTypeIndex == 0
                          ? '${AppTranslations.tr(lang, 'total_spent')} · ${AppTranslations.tr(lang, _timeRange).toUpperCase()}'
                          : '${AppTranslations.tr(lang, 'total_earned')} · ${AppTranslations.tr(lang, _timeRange).toUpperCase()}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const MouseyAvatar(size: 48),
                ],
              ),
              const SizedBox(height: 4),
              MoneyText(
                amount: _totalReportAmount,
                prefix: 'đ',
                suffix: '',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _aiInsightQuote,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '— ${AppTranslations.tr(lang, 'mousey_friend')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Section: CHI TIẾT / NGUỒN THU
        Text(
          _reportTypeIndex == 1 ? AppTranslations.tr(lang, 'income_sources') : AppTranslations.tr(lang, 'details'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: Color(0xFF706C66),
          ),
        ),

        const SizedBox(height: 10),

        // Detail Card Container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF66EBE5)),
          ),
          child: categories.isEmpty
              ? SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Icon(
                        _reportTypeIndex == 1
                            ? Icons.account_balance_wallet_outlined
                            : Icons.pie_chart_outline_rounded,
                        size: 52,
                        color: const Color(0xFF66EBE5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _reportTypeIndex == 1 ? AppTranslations.tr(lang, 'no_income_data') : AppTranslations.tr(lang, 'no_report_data'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF222222),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _reportTypeIndex == 1
                            ? AppTranslations.tr(lang, 'add_income_for_analysis')
                            : AppTranslations.tr(lang, 'add_transaction_for_analysis'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Donut Chart + Legend Row
                    Row(
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CustomPaint(
                            painter: DonutChartPainter(
                              percentages: categories
                                  .map((c) => (c['percentage'] as double))
                                  .toList(),
                              colors: categories
                                  .map((c) => (c['color'] as Color))
                                  .toList(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: categories.take(5).map((cat) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: cat['color'] as Color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              AppTranslations.trCategory(lang, cat['name'] as String),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF222222),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        '${(cat['percentage'] as double).toStringAsFixed(1)}%',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF222222),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFF66EBE5), height: 1),
                    const SizedBox(height: 12),

                    // Category List with Progress Bars
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayedCategories.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 14),
                      itemBuilder: (ctx, index) {
                        final cat = displayedCategories[index];
                        final double pct = cat['percentage'] as double;
                        final Color catColor = cat['color'] as Color;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF66EBE5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            cat['icon'] as String,
                                            style: const TextStyle(fontSize: 18),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          AppTranslations.trCategory(lang, cat['name'] as String),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF222222),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: MoneyText(
                                    amount: cat['amount'] as double,
                                    prefix: 'đ',
                                    suffix: '',
                                    alignment: Alignment.centerRight,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF222222),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: (pct / 100.0).clamp(0.0, 1.0),
                                      minHeight: 10,
                                      backgroundColor: const Color(0xFFCCF7F7),
                                      valueColor: AlwaysStoppedAnimation<Color>(catColor),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 52,
                                  child: Text(
                                    '${pct.toStringAsFixed(1)}%',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF706C66),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),

                    if (categories.length > 5) ...[
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _showAllCategories = !_showAllCategories;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          child: Text(
                            _showAllCategories
                                ? context.t('Thu gọn ^')
                                : context.t('Hiện tất cả ({count}) v', {'count': categories.length}),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF555048),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),

        const SizedBox(height: 24),

        // Section: XU HƯỚNG
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                AppTranslations.tr(lang, 'trend'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Color(0xFF706C66),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF66EBE5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  _SmallPillText('N'),
                  SizedBox(width: 8),
                  _SmallPillText('T'),
                  SizedBox(width: 8),
                  _SmallPillText('T', isActive: true),
                  SizedBox(width: 8),
                  _SmallPillText('N'),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Trend Chart Container
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF66EBE5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MoneyText(
                          amount: _totalReportAmount > 0 ? _totalReportAmount / _trendMonthRange : 0,
                          prefix: 'đ',
                          suffix: '',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF222222),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${AppTranslations.tr(lang, 'avg_per_month')} · $_trendMonthRange ${AppTranslations.tr(lang, 'recent_months')}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF888480),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [3, 6, 12, 24].map((range) {
                      final isSel = _trendMonthRange == range;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _trendMonthRange = range);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(left: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF222222) : const Color(0xFF66EBE5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            context.t('{range}t', {'range': range}),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSel ? Colors.white : const Color(0xFF666666),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 180,
                width: double.infinity,
                child: CustomPaint(
                  painter: StackedBarChartPainter(
                    months: _getRecent6MonthsLabels(),
                    transactions: _filteredTransactions,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _getRecent6MonthsLabels() {
    final lang = context.lang;
    final now = DateTime.now();
    final List<String> labels = [];
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      labels.add(AppTranslations.formatMonthYear(lang, m).split(' ')[0]);
    }
    return labels;
  }

  Widget _buildSegmentTab(int index, String label) {
    final isSel = _reportTypeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _reportTypeIndex = index;
            _selectedCategoryFilter = 'Tất cả';
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSel
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
              color: isSel ? const Color(0xFF222222) : const Color(0xFF706C66),
            ),
          ),
        ),
      ),
    );
  }

  void _showTimeRangePicker() {
    final lang = context.lang;
    final options = [
      'all_time',
      'this_month',
      'last_month',
      'last_3_months',
      'this_year',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppTranslations.tr(lang, 'filter'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...options.map((key) {
                    final isSel = _timeRange == key;
                    return ListTile(
                      title: Text(
                        AppTranslations.tr(lang, key),
                        style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal),
                      ),
                      trailing: isSel ? const Icon(Icons.check_circle, color: Color(0xFF00BFB5)) : null,
                      onTap: () {
                        setState(() => _timeRange = key);
                        Navigator.pop(ctx);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCategoryFilterPicker() {
    final lang = context.lang;
    final expenseCategories = [
      'Tất cả',
      'Ăn uống',
      'Hóa đơn',
      'Di chuyển',
      'Mua sắm',
      'Giải trí',
      'Sức khoẻ',
      'Làm đẹp',
      'Quần áo',
      'Học tập',
      'Thú cưng',
      'Con cái',
      'Hỗ trợ gia đình',
      'Bảo hiểm',
      'Thuế',
      'Công việc',
      'Nhà ở',
      'Tiền nợ',
      'Khác'
    ];

    final incomeCategories = [
      'Tất cả',
      'Lương',
      'Thưởng',
      'Đầu tư',
      'Bán hàng',
      'Khác'
    ];

    final categories = _reportTypeIndex == 1 ? incomeCategories : expenseCategories;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.65,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppTranslations.tr(lang, 'filter_categories'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSel = _selectedCategoryFilter == cat;
                      return ListTile(
                        leading: Text(
                          cat == 'Tất cả' ? '📌' : _getCategoryIcon(cat),
                          style: const TextStyle(fontSize: 20),
                        ),
                        title: Text(
                          AppTranslations.trCategory(lang, cat),
                          style: TextStyle(
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel ? const Color(0xFF00D1CC) : Colors.black87,
                          ),
                        ),
                        trailing: isSel ? const Icon(Icons.check_circle, color: Color(0xFF00BFB5)) : null,
                        onTap: () {
                          setState(() {
                            _selectedCategoryFilter = cat;
                          });
                          Navigator.pop(ctx);
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
}

// --- DONUT CHART PAINTER ---
class DonutChartPainter extends CustomPainter {
  final List<double> percentages;
  final List<Color> colors;

  DonutChartPainter({required this.percentages, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22.0
      ..strokeCap = StrokeCap.butt;

    if (percentages.isEmpty || percentages.fold(0.0, (a, b) => a + b) == 0) {
      paint.color = const Color(0xFFE8E5D8);
      canvas.drawCircle(center, radius, paint);
      return;
    }

    double startAngle = -math.pi / 2;

    for (int i = 0; i < percentages.length; i++) {
      final sweepAngle = (percentages[i] / 100.0) * 2 * math.pi;
      if (sweepAngle <= 0) continue;
      paint.color = colors[i % colors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.05,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- STACKED BAR CHART PAINTER ---
class StackedBarChartPainter extends CustomPainter {
  final List<String> months;
  final List<TransactionItem> transactions;

  StackedBarChartPainter({required this.months, required this.transactions});

  @override
  void paint(Canvas canvas, Size size) {
    final double barWidth = 26.0;
    final double spacing = (size.width - (months.length * barWidth)) / (months.length + 1);

    final now = DateTime.now();
    final List<double> monthlyTotals = List.filled(months.length, 0.0);

    for (var t in transactions) {
      for (int i = 0; i < months.length; i++) {
        final targetMonth = DateTime(now.year, now.month - (5 - i), 1);
        if (t.date.year == targetMonth.year && t.date.month == targetMonth.month) {
          monthlyTotals[i] += t.amount;
        }
      }
    }

    double maxVal = monthlyTotals.fold(0.0, math.max);
    if (maxVal == 0) maxVal = 100000.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < months.length; i++) {
      final x = spacing + i * (barWidth + spacing);
      final chartHeight = size.height - 28;

      // Draw light background column
      final bgPaint = Paint()..color = const Color(0xFFF5F3EC);
      final RRect bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, barWidth, chartHeight),
        const Radius.circular(6),
      );
      canvas.drawRRect(bgRect, bgPaint);

      // Draw filled bar
      final val = monthlyTotals[i];
      if (val > 0) {
        final segH = (val / maxVal) * chartHeight;
        final segPaint = Paint()..color = const Color(0xFF66EBE5);

        final segRect = Rect.fromLTWH(x, chartHeight - segH, barWidth, segH);
        canvas.drawRect(segRect, segPaint);
      }

      // Draw Month Label below bar
      textPainter.text = TextSpan(
        text: months[i],
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF706C66),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + (barWidth - textPainter.width) / 2, size.height - 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SmallPillText extends StatelessWidget {
  final String text;
  final bool isActive;

  const _SmallPillText(this.text, {this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: isActive
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          color: isActive ? const Color(0xFF222222) : const Color(0xFF888480),
        ),
      ),
    );
  }
}
