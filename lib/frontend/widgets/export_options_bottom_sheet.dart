import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../backend/database/db_helper.dart';
import '../../backend/services/export_service.dart';
import '../utils/app_language.dart';

class ExportOptionsBottomSheet extends StatefulWidget {
  final String selectedLanguage;
  final String currentLedgerId;

  const ExportOptionsBottomSheet({
    super.key,
    required this.selectedLanguage,
    required this.currentLedgerId,
  });

  static Future<void> show(BuildContext context, {required String selectedLanguage, required String currentLedgerId}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExportOptionsBottomSheet(
        selectedLanguage: selectedLanguage,
        currentLedgerId: currentLedgerId,
      ),
    );
  }

  @override
  State<ExportOptionsBottomSheet> createState() => _ExportOptionsBottomSheetState();
}

class _ExportOptionsBottomSheetState extends State<ExportOptionsBottomSheet> {
  String _dateRangePreset = 'this_month'; // this_month, last_month, 3_months, 6_months, all_year, custom
  late DateTime _startDate;
  late DateTime _endDate;

  String _ledgerSelection = 'current'; // current, all, specific
  String _selectedLedgerId = '';
  List<Map<String, dynamic>> _ledgers = [];

  bool _exportTransactions = true;
  bool _exportCategorySummary = true;
  final bool _exportMonthlySummary = true;
  bool _exportBudgets = true;
  bool _exportGoals = true;

  String _format = 'xlsx'; // xlsx or csv

  int _estimatedCount = 0;
  bool _isLoadingCount = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _selectedLedgerId = widget.currentLedgerId;
    _setDateRange('this_month');
    _loadLedgers();
    _updateEstimatedCount();
  }

  void _setDateRange(String preset) {
    final now = DateTime.now();
    setState(() {
      _dateRangePreset = preset;
      if (preset == 'this_month') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      } else if (preset == 'last_month') {
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        _startDate = lastMonth;
        _endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
      } else if (preset == '3_months') {
        _startDate = DateTime(now.year, now.month - 2, 1);
        _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      } else if (preset == '6_months') {
        _startDate = DateTime(now.year, now.month - 5, 1);
        _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      } else if (preset == 'all_year') {
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31, 23, 59, 59);
      }
    });
    _updateEstimatedCount();
  }

  Future<void> _loadLedgers() async {
    final ledgers = await DatabaseHelper.instance.getLedgers();
    if (mounted) {
      setState(() {
        _ledgers = ledgers;
      });
    }
  }

  Future<void> _updateEstimatedCount() async {
    setState(() => _isLoadingCount = true);
    String? uid = DatabaseHelper.instance.currentUid;
    String targetLedger = _ledgerSelection == 'all'
        ? 'all'
        : (_ledgerSelection == 'current' ? widget.currentLedgerId : _selectedLedgerId);

    final options = ExportOptions(
      startDate: _startDate,
      endDate: _endDate,
      ledgerId: targetLedger,
    );

    final count = await ExportService.getEstimatedCount(options, uid);
    if (mounted) {
      setState(() {
        _estimatedCount = count;
        _isLoadingCount = false;
      });
    }
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null && mounted) {
      setState(() {
        _dateRangePreset = 'custom';
        _startDate = picked.start;
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
      _updateEstimatedCount();
    }
  }

  Future<void> _handleExport() async {
    if (_isExporting || _estimatedCount == 0) return;
    setState(() => _isExporting = true);

    try {
      String? uid = DatabaseHelper.instance.currentUid;
      String targetLedger = _ledgerSelection == 'all'
          ? 'all'
          : (_ledgerSelection == 'current' ? widget.currentLedgerId : _selectedLedgerId);

      final options = ExportOptions(
        startDate: _startDate,
        endDate: _endDate,
        ledgerId: targetLedger,
        exportTransactions: _exportTransactions,
        exportCategorySummary: _exportCategorySummary,
        exportMonthlySummary: _exportMonthlySummary,
        exportBudgets: _exportBudgets,
        exportGoals: _exportGoals,
        format: _format,
        language: context.lang,
      );

      final filePath = await ExportService.exportData(options, uid, (p) {});
      if (!mounted) return;
      if (filePath != null) {
        Navigator.pop(context);
        await ExportService.shareFile(filePath, _format);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('Xuất file thành công!')), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t('Lỗi xuất file: {e}', {'e': e})), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF5FDFD),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
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
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.t('Xuất dữ liệu báo cáo'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkBeige),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.t('Phạm vi thời gian'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(context.t('Tháng này')),
                        selected: _dateRangePreset == 'this_month',
                        onSelected: (_) => _setDateRange('this_month'),
                      ),
                      ChoiceChip(
                        label: Text(context.t('Tháng trước')),
                        selected: _dateRangePreset == 'last_month',
                        onSelected: (_) => _setDateRange('last_month'),
                      ),
                      ChoiceChip(
                        label: Text(context.t('3 tháng')),
                        selected: _dateRangePreset == '3_months',
                        onSelected: (_) => _setDateRange('3_months'),
                      ),
                      ChoiceChip(
                        label: Text(context.t('6 tháng')),
                        selected: _dateRangePreset == '6_months',
                        onSelected: (_) => _setDateRange('6_months'),
                      ),
                      ChoiceChip(
                        label: Text(context.t('Cả năm')),
                        selected: _dateRangePreset == 'all_year',
                        onSelected: (_) => _setDateRange('all_year'),
                      ),
                      ActionChip(
                        label: Text(_dateRangePreset == 'custom' ? context.t('Đã chọn') : context.t('Tùy chọn')),
                        onPressed: _pickCustomDateRange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(context.t('Chọn Sổ sách'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _ledgerSelection,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: [
                      DropdownMenuItem(value: 'current', child: Text(context.t('Sổ đang dùng'))),
                      DropdownMenuItem(value: 'all', child: Text(context.t('Tất cả sổ'))),
                      DropdownMenuItem(value: 'specific', child: Text(context.t('Chọn một sổ cụ thể'))),
                    ],
                    onChanged: (val) {
                      setState(() => _ledgerSelection = val ?? 'current');
                      _updateEstimatedCount();
                    },
                  ),
                  if (_ledgerSelection == 'specific') ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedLedgerId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _ledgers.map((l) => DropdownMenuItem(
                        value: l['id'].toString(),
                        child: Text(l['name'].toString()),
                      )).toList(),
                      onChanged: (val) {
                        setState(() => _selectedLedgerId = val ?? '');
                        _updateEstimatedCount();
                      },
                    ),
                  ],
                  const SizedBox(height: 16),

                  Text(context.t('Nội dung xuất'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  CheckboxListTile(
                    title: Text(context.t('Giao dịch')),
                    value: _exportTransactions,
                    onChanged: (v) => setState(() => _exportTransactions = v ?? true),
                  ),
                  CheckboxListTile(
                    title: Text(context.t('Tổng hợp theo danh mục')),
                    value: _exportCategorySummary,
                    onChanged: (v) => setState(() => _exportCategorySummary = v ?? true),
                  ),
                  CheckboxListTile(
                    title: Text(context.t('Ngân sách')),
                    value: _exportBudgets,
                    onChanged: (v) => setState(() => _exportBudgets = v ?? true),
                  ),
                  CheckboxListTile(
                    title: Text(context.t('Mục tiêu tiết kiệm')),
                    value: _exportGoals,
                    onChanged: (v) => setState(() => _exportGoals = v ?? true),
                  ),
                  const SizedBox(height: 16),

                  Text(context.t('Định dạng file'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Excel (.xlsx)'),
                          value: 'xlsx',
                          groupValue: _format,
                          onChanged: (v) => setState(() => _format = v ?? 'xlsx'),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('CSV (.csv)'),
                          value: 'csv',
                          groupValue: _format,
                          onChanged: (v) => setState(() => _format = v ?? 'csv'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _isLoadingCount
                    ? const CircularProgressIndicator()
                    : Text(
                        _estimatedCount > 0
                            ? context.t('{estimatedCount} giao dịch sẽ được xuất', {'estimatedCount': _estimatedCount})
                            : context.t('Không có dữ liệu giao dịch trong khoảng thời gian này'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _estimatedCount > 0 ? AppColors.darkBeige : Colors.red,
                        ),
                      ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: (_estimatedCount == 0 || _isExporting) ? null : _handleExport,
                    child: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(context.t('Xuất file'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
