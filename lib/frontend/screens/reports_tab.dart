import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../backend/models/transaction_model.dart';
import '../../core/widgets/category_icon.dart';
import '../../core/widgets/money_text.dart';
import '../theme/app_colors.dart';
import '../utils/app_translations.dart';
import '../utils/report_utils.dart';
import '../utils/app_language.dart';

class ReportsTab extends StatefulWidget {
  final List<TransactionItem> transactions;

  const ReportsTab({
    super.key,
    required this.transactions,
  });

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  int _reportTypeIndex = 0; // 0: Chi tiêu, 1: Thu nhập
  String _timeRange = 'this_month';
  String _selectedCategoryFilter = 'Tất cả';
  bool _showAllCategories = false;
  int _trendMonthRange = 6; // 3t, 6t, 12t, 24t

  // Dynamic Filtering based on selected type (Chi tiêu / Thu nhập) and Category Filter
  /// Giao dịch đúng loại (chi/thu) và danh mục đang lọc, chưa lọc theo thời gian.
  List<TransactionItem> get _typeFilteredTransactions {
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

  List<TransactionItem> get _filteredTransactions {
    final now = DateTime.now();
    return _typeFilteredTransactions
        .where((t) => ReportUtils.inTimeRange(_timeRange, t.date, now))
        .toList();
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
      });
    });

    result.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    return result;
  }

  /// So với tháng trước, chỉ khi đang xem "Tháng này": null nếu không so được.
  /// [higher]: tháng này nhiều hơn tháng trước.
  ({String text, bool higher})? get _comparison {
    if (_timeRange != 'this_month') return null;
    final now = DateTime.now();
    double lastMonth = 0;
    for (final t in _typeFilteredTransactions) {
      if (ReportUtils.inTimeRange('last_month', t.date, now)) lastMonth += t.amount;
    }
    final current = _totalReportAmount;
    if (lastMonth <= 0 || current <= 0) return null;
    final pct = ((current - lastMonth) / lastMonth * 100).round();
    final prevMonth = DateTime(now.year, now.month - 1, 1).month;
    if (pct == 0) return (text: context.t('Bằng tháng {month}', {'month': prevMonth}), higher: false);
    return (
      text: context.t(
        pct > 0 ? 'Cao hơn tháng {month} khoảng {pct}%' : 'Thấp hơn tháng {month} khoảng {pct}%',
        {'month': prevMonth, 'pct': pct.abs()},
      ),
      higher: pct > 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final filtered = _selectedCategoryFilter != 'Tất cả';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Báo cáo  [Tháng này ▾] [lọc]
          Row(
            children: [
              Expanded(
                child: Text(
                  AppTranslations.tr(lang, 'reports'),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              ),
              OutlinedButton(
                onPressed: _showTimeRangePicker,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: BorderSide(color: AppColors.ink, width: 1.2),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  visualDensity: VisualDensity.compact,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppTranslations.tr(lang, _timeRange), style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 2),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  ],
                ),
              ),
              IconButton(
                tooltip: AppTranslations.tr(lang, 'filter'),
                onPressed: _showCategoryFilterPicker,
                icon: Badge(
                  isLabelVisible: filtered,
                  smallSize: 8,
                  backgroundColor: AppColors.expense,
                  child: Icon(Icons.tune_rounded, color: AppColors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Chi tiêu | Thu nhập
          Container(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.rule))),
            child: Row(
              children: [
                _buildSegmentTab(0, AppTranslations.tr(lang, 'expense')),
                _buildSegmentTab(1, AppTranslations.tr(lang, 'income')),
              ],
            ),
          ),
          if (filtered) ...[
            const SizedBox(height: 10),
            InputChip(
              label: Text(AppTranslations.trCategory(lang, _selectedCategoryFilter)),
              onDeleted: () => setState(() => _selectedCategoryFilter = 'Tất cả'),
              backgroundColor: AppColors.tealPale,
              side: BorderSide.none,
              labelStyle: TextStyle(color: AppColors.ink),
              deleteIconColor: AppColors.ink,
            ),
          ],
          const SizedBox(height: 20),

          _buildExpenseOrIncomeView(),
        ],
      ),
    );
  }

  // --- EXPENSE / INCOME TAB VIEW ---
  Widget _buildExpenseOrIncomeView() {
    final lang = context.lang;
    final categories = _dynamicCategories;
    final displayedCategories = _showAllCategories ? categories : categories.take(5).toList();
    final comparison = _comparison;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tổng chi/thu: số tô như bút dạ quang
        Text(
          '${AppTranslations.tr(lang, _reportTypeIndex == 0 ? 'total_spent' : 'total_earned')} · ${AppTranslations.tr(lang, _timeRange).toLowerCase()}',
          style: TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.highlight,
            borderRadius: BorderRadius.circular(3),
          ),
          child: MoneyText(
            amount: _totalReportAmount,
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -0.5),
          ),
        ),
        if (comparison != null) ...[
          const SizedBox(height: 6),
          // Chi tăng hoặc thu giảm là tin xấu: tô đỏ
          Text(
            comparison.text,
            style: TextStyle(
              fontSize: 14,
              color: comparison.higher == (_reportTypeIndex == 0) ? AppColors.expense : AppColors.income,
            ),
          ),
        ],
        const SizedBox(height: 28),

        // Chi / thu theo danh mục: dòng chữ + thanh mảnh một màu
        Text(
          _reportTypeIndex == 1 ? context.t('Thu theo danh mục') : context.t('Chi theo danh mục'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        if (categories.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _reportTypeIndex == 1 ? AppTranslations.tr(lang, 'no_income_data') : AppTranslations.tr(lang, 'no_report_data'),
                  style: TextStyle(fontSize: 15, color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  _reportTypeIndex == 1
                      ? AppTranslations.tr(lang, 'add_income_for_analysis')
                      : AppTranslations.tr(lang, 'add_transaction_for_analysis'),
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          )
        else ...[
          ...displayedCategories.map((cat) {
            final pct = cat['percentage'] as double;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${AppTranslations.trCategory(lang, cat['name'] as String)} · ${pct.toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 15, color: AppColors.ink),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      MoneyText(
                        amount: cat['amount'] as double,
                        suffix: '',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (pct / 100.0).clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: AppColors.tealPale,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (categories.length > 5)
            TextButton(
              onPressed: () => setState(() => _showAllCategories = !_showAllCategories),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                _showAllCategories
                    ? context.t('Thu gọn ^')
                    : context.t('Hiện tất cả ({count}) v', {'count': categories.length}),
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
        ],
        const SizedBox(height: 28),

        // N tháng gần nhất: cột nhạt, tháng hiện tại tô mực
        Builder(builder: (context) {
          final trendMonths = ReportUtils.recentMonths(_trendMonthRange, DateTime.now());
          final trendTotals = ReportUtils.monthlyTotals(_typeFilteredTransactions, trendMonths);
          final trendAverage = trendTotals.fold(0.0, (a, b) => a + b) / _trendMonthRange;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      context.t('{n} tháng gần nhất', {'n': _trendMonthRange}),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink),
                    ),
                  ),
                  for (final range in [3, 6, 12, 24])
                    GestureDetector(
                      onTap: () => setState(() => _trendMonthRange = range),
                      child: Container(
                        margin: const EdgeInsets.only(left: 10),
                        padding: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _trendMonthRange == range ? AppColors.ink : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Text(
                          context.t('{range}t', {'range': range}),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _trendMonthRange == range ? FontWeight.w600 : FontWeight.w400,
                            color: _trendMonthRange == range ? AppColors.ink : AppColors.unselectedTab,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              MoneyText(
                amount: trendAverage,
                prefix: '${AppTranslations.tr(lang, 'avg_per_month')}: ',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 150,
                width: double.infinity,
                child: CustomPaint(
                  painter: MonthlyBarChartPainter(
                    months: trendMonths.map((m) => AppTranslations.formatMonthShort(lang, m)).toList(),
                    totals: trendTotals,
                    barColor: AppColors.tealLight,
                    currentColor: AppColors.ink,
                    baseLineColor: AppColors.ink,
                    labelColor: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSegmentTab(int index, String label) {
    final isSel = _reportTypeIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _reportTypeIndex = index;
          _selectedCategoryFilter = 'Tất cả';
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 24),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isSel ? AppColors.ink : Colors.transparent, width: 2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
            color: isSel ? AppColors.ink : AppColors.unselectedTab,
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
          color: AppColors.surface,
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
                      color: AppColors.grey300,
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
                      trailing: isSel ? Icon(Icons.check_circle, color: AppColors.teal) : null,
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
      'Cà phê',
      'Trà sữa',
      'Hóa đơn',
      'Điện thoại',
      'Di chuyển',
      'Mua sắm',
      'Giải trí',
      'Netflix',
      'Spotify',
      'YouTube',
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
          color: AppColors.surface,
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
                    color: AppColors.grey300,
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
                        leading: CategoryIcon(categoryOrIconKey: cat, size: 36),
                        title: Text(
                          AppTranslations.trCategory(lang, cat),
                          style: TextStyle(
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            color: isSel ? AppColors.tealBright : AppColors.black87,
                          ),
                        ),
                        trailing: isSel ? Icon(Icons.check_circle, color: AppColors.teal) : null,
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
/// Biểu đồ cột theo tháng kiểu sổ: cột nhạt, cột cuối (tháng hiện tại) tô mực, một đường kẻ đáy
class MonthlyBarChartPainter extends CustomPainter {
  final List<String> months;
  final List<double> totals;
  final Color barColor;
  final Color currentColor;
  final Color baseLineColor;
  final Color labelColor;

  MonthlyBarChartPainter({
    required this.months,
    required this.totals,
    required this.barColor,
    required this.currentColor,
    required this.baseLineColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final count = months.length;
    if (count == 0) return;
    // Cột co lại khi nhiều tháng (12t, 24t) để vẫn vừa khung
    final double slot = size.width / count;
    final double barWidth = math.min(56.0, slot * 0.82);
    // Chỉ ghi nhãn cách quãng để chữ không chồng lên nhau
    final int labelStep = count <= 6 ? 1 : (count <= 12 ? 2 : 4);

    double maxVal = totals.fold(0.0, math.max);
    if (maxVal == 0) maxVal = 1;

    const double labelArea = 24;
    final chartHeight = size.height - labelArea;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < count; i++) {
      final x = i * slot + (slot - barWidth) / 2;
      final val = totals[i];
      if (val > 0) {
        final h = math.max(2.0, (val / maxVal) * chartHeight);
        final paint = Paint()..color = i == count - 1 ? currentColor : barColor;
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(x, chartHeight - h, barWidth, h),
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3),
          ),
          paint,
        );
      }

      // Nhãn tháng dưới cột; luôn ghi tháng hiện tại (cột cuối)
      if ((count - 1 - i) % labelStep != 0) continue;
      textPainter.text = TextSpan(text: months[i], style: TextStyle(fontSize: 12, color: labelColor));
      textPainter.layout();
      textPainter.paint(canvas, Offset(i * slot + (slot - textPainter.width) / 2, chartHeight + 8));
    }

    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(size.width, chartHeight),
      Paint()
        ..color = baseLineColor
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant MonthlyBarChartPainter oldDelegate) =>
      oldDelegate.totals != totals || oldDelegate.months != months || oldDelegate.currentColor != currentColor;
}
