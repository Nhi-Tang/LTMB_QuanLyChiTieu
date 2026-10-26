import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../models/savings_goal_model.dart';
import 'totals_calculator.dart';
import '../../core/utils/account_masker.dart';
import '../../frontend/utils/app_translations.dart';

class ExportOptions {
  final DateTime startDate;
  final DateTime endDate;
  final String ledgerId; // 'all', 'current', or specific ledgerId
  final bool exportTransactions;
  final bool exportCategorySummary;
  final bool exportMonthlySummary;
  final bool exportBudgets;
  final bool exportGoals;
  final String format; // 'xlsx' or 'csv'
  final String language;

  ExportOptions({
    required this.startDate,
    required this.endDate,
    required this.ledgerId,
    this.exportTransactions = true,
    this.exportCategorySummary = true,
    this.exportMonthlySummary = true,
    this.exportBudgets = true,
    this.exportGoals = true,
    this.format = 'xlsx',
    this.language = 'Tiếng Việt',
  });
}

class ExportService {
  static Future<void> cleanupOldTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final now = DateTime.now();
      if (await tempDir.exists()) {
        await for (var entity in tempDir.list()) {
          if (entity is File && entity.path.contains('Mousey_')) {
            final stat = await entity.stat();
            if (now.difference(stat.modified).inHours > 24) {
              await entity.delete();
            }
          }
        }
      }
    } catch (_) {}
  }

  static String _translateKind(String kind, String lang) {
    switch (kind) {
      case 'income':
        return AppTranslations.text(lang, 'Thu nhập');
      case 'received':
        return AppTranslations.text(lang, 'Tiền nhận');
      case 'expense':
        return AppTranslations.text(lang, 'Chi tiêu');
      case 'transfer_out':
        return AppTranslations.text(lang, 'Chuyển cho người khác');
      case 'transfer_internal':
        return AppTranslations.text(lang, 'Chuyển nội bộ');
      default:
        return kind;
    }
  }

  static Future<int> getEstimatedCount(ExportOptions options, String? uid) async {
    final db = await DatabaseHelper.instance.database;
    final startStr = options.startDate.toIso8601String();
    final endStr = options.endDate.toIso8601String();

    String where = 'isDeleted = 0 AND date >= ? AND date <= ?';
    List<dynamic> args = [startStr, endStr];

    if (uid != null && uid.isNotEmpty) {
      where += ' AND (uid = ? OR uid IS NULL OR uid = \'\')';
      args.add(uid);
    }

    if (options.ledgerId != 'all') {
      where += ' AND ledgerId = ?';
      args.add(options.ledgerId);
    }

    final result = await db.rawQuery('SELECT COUNT(*) as count FROM transactions WHERE $where', args);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<String?> exportData(ExportOptions options, String? uid, Function(double)? onProgress) async {
    await cleanupOldTempFiles();

    final db = await DatabaseHelper.instance.database;
    final startStr = options.startDate.toIso8601String();
    final endStr = options.endDate.toIso8601String();

    String where = 'isDeleted = 0 AND date >= ? AND date <= ?';
    List<dynamic> args = [startStr, endStr];

    if (uid != null && uid.isNotEmpty) {
      where += ' AND (uid = ? OR uid IS NULL OR uid = \'\')';
      args.add(uid);
    }

    if (options.ledgerId != 'all') {
      where += ' AND ledgerId = ?';
      args.add(options.ledgerId);
    }

    final txMaps = await db.query('transactions', where: where, whereArgs: args, orderBy: 'date DESC');
    final transactions = txMaps.map((m) => TransactionItem.fromMap(m)).toList();

    final ledgerMaps = await db.query('ledgers', where: 'isDeleted = 0');
    final Map<String, String> ledgerNames = {
      for (var l in ledgerMaps) l['id'].toString(): l['name'].toString()
    };

    List<BudgetModel> budgets = [];
    if (options.exportBudgets) {
      final bMaps = await db.query('budgets', where: 'isDeleted = 0');
      budgets = bMaps.map((m) => BudgetModel.fromMap(m)).toList();
    }

    List<SavingsGoalModel> goals = [];
    if (options.exportGoals) {
      final gMaps = await db.query('savings_goals', where: 'isDeleted = 0');
      goals = gMaps.map((m) => SavingsGoalModel.fromMap(m)).toList();
    }

    final tempDir = await getTemporaryDirectory();
    final dateTag = '${options.startDate.year}${options.startDate.month.toString().padLeft(2, '0')}_${options.endDate.year}${options.endDate.month.toString().padLeft(2, '0')}';
    
    String ledgerSlugName = 'All';
    if (options.ledgerId == 'all') {
      ledgerSlugName = 'All_Ledgers';
    } else {
      final rawName = ledgerNames[options.ledgerId] ?? options.ledgerId;
      ledgerSlugName = rawName.replaceAll(RegExp(r'[^\w]'), '_');
    }

    if (options.format == 'xlsx') {
      return await compute(_generateXlsx, {
        'transactions': transactions.map((t) => t.toMap()).toList(),
        'budgets': budgets.map((b) => b.toMap()).toList(),
        'goals': goals.map((g) => g.toMap()).toList(),
        'ledgerNames': ledgerNames,
        'options': {
          'startDate': startStr,
          'endDate': endStr,
          'ledgerId': options.ledgerId,
          'exportTransactions': options.exportTransactions,
          'exportCategorySummary': options.exportCategorySummary,
          'exportMonthlySummary': options.exportMonthlySummary,
          'exportBudgets': options.exportBudgets,
          'exportGoals': options.exportGoals,
          'language': options.language,
        },
        'tempPath': tempDir.path,
        'dateTag': dateTag,
        'slugLedger': ledgerSlugName,
      });
    } else {
      return await compute(_generateCsvZip, {
        'transactions': transactions.map((t) => t.toMap()).toList(),
        'budgets': budgets.map((b) => b.toMap()).toList(),
        'goals': goals.map((g) => g.toMap()).toList(),
        'ledgerNames': ledgerNames,
        'options': {
          'startDate': startStr,
          'endDate': endStr,
          'ledgerId': options.ledgerId,
          'exportTransactions': options.exportTransactions,
          'exportCategorySummary': options.exportCategorySummary,
          'exportMonthlySummary': options.exportMonthlySummary,
          'exportBudgets': options.exportBudgets,
          'exportGoals': options.exportGoals,
          'language': options.language,
        },
        'tempPath': tempDir.path,
        'dateTag': dateTag,
        'slugLedger': ledgerSlugName,
      });
    }
  }

  static String _generateXlsx(Map<String, dynamic> params) {
    final txMaps = params['transactions'] as List;
    final transactions = txMaps.map((m) => TransactionItem.fromMap(m)).toList();
    final ledgerNames = Map<String, String>.from(params['ledgerNames'] as Map);
    final opt = params['options'] as Map<String, dynamic>;
    final tempPath = params['tempPath'] as String;
    final dateTag = params['dateTag'] as String;
    final slugLedger = params['slugLedger'] as String;
    final lang = opt['language'] as String;

    final excel = Excel.createExcel();
    final defaultSheetName = excel.getDefaultSheet() ?? 'Sheet1';
    final txSheetName = AppTranslations.text(lang, 'Giao dịch');
    excel.rename(defaultSheetName, txSheetName);
    final sheet = excel[txSheetName];

    // Headers Giao dịch
    final headers = ['Ngày', 'Giờ', 'Loại', 'Danh mục', 'Số tiền', 'Sổ', 'Ghi chú']
        .map((h) => AppTranslations.text(lang, h))
        .toList();
    
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    for (var t in transactions) {
      final dateStr = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
      final timeStr = '${t.date.hour.toString().padLeft(2, '0')}:${t.date.minute.toString().padLeft(2, '0')}';
      final typeStr = _translateKind(t.kind, lang);
      final cleanNote = maskAccountNumbers(t.title);
      final ledgerName = AppTranslations.trLedger(lang, ledgerNames[t.ledgerId] ?? t.ledgerId ?? '');

      sheet.appendRow([
        TextCellValue(dateStr),
        TextCellValue(timeStr),
        TextCellValue(typeStr),
        TextCellValue(AppTranslations.trCategory(lang, t.category)),
        IntCellValue(t.amount.toInt()),
        TextCellValue(ledgerName),
        TextCellValue(cleanNote),
      ]);
    }

    // Sheet Tổng hợp
    if (opt['exportCategorySummary'] == true || opt['exportMonthlySummary'] == true) {
      final summarySheetName = AppTranslations.text(lang, 'Tổng hợp');
      final sumSheet = excel[summarySheetName];

      final totalInc = TotalsCalculator.calculateTotalIncome(transactions);
      final totalExp = TotalsCalculator.calculateTotalExpense(transactions);
      final balance = TotalsCalculator.calculateBalance(transactions);

      sumSheet.appendRow([TextCellValue(AppTranslations.text(lang, 'Tổng hợp tài chính'))]);
      sumSheet.appendRow([TextCellValue(AppTranslations.text(lang, 'Tổng thu nhập')), IntCellValue(totalInc.toInt())]);
      sumSheet.appendRow([TextCellValue(AppTranslations.text(lang, 'Tổng chi tiêu')), IntCellValue(totalExp.toInt())]);
      sumSheet.appendRow([TextCellValue(AppTranslations.text(lang, 'Số dư thực tế')), IntCellValue(balance.toInt())]);
      sumSheet.appendRow([]);

      if (opt['exportCategorySummary'] == true) {
        sumSheet.appendRow([TextCellValue(AppTranslations.text(lang, 'Tổng hợp theo danh mục'))]);
        sumSheet.appendRow([TextCellValue(AppTranslations.text(lang, 'Danh mục')), TextCellValue(AppTranslations.text(lang, 'Số tiền'))]);
        
        final Map<String, double> catSums = {};
        for (var t in transactions) {
          if (!t.isDeleted) {
            catSums[t.category] = (catSums[t.category] ?? 0.0) + t.amount;
          }
        }
        catSums.forEach((cat, amt) {
          sumSheet.appendRow([TextCellValue(AppTranslations.trCategory(lang, cat)), IntCellValue(amt.toInt())]);
        });
        sumSheet.appendRow([]);
      }
    }

    final fileBytes = excel.encode();
    final filePath = '$tempPath/Mousey_${slugLedger}_$dateTag.xlsx';
    final file = File(filePath);
    file.writeAsBytesSync(fileBytes!);
    return filePath;
  }

  static String _generateCsvZip(Map<String, dynamic> params) {
    final txMaps = params['transactions'] as List;
    final transactions = txMaps.map((m) => TransactionItem.fromMap(m)).toList();
    final ledgerNames = Map<String, String>.from(params['ledgerNames'] as Map);
    final opt = params['options'] as Map<String, dynamic>;
    final tempPath = params['tempPath'] as String;
    final dateTag = params['dateTag'] as String;
    final slugLedger = params['slugLedger'] as String;
    final lang = opt['language'] as String;

    List<List<dynamic>> rows = [];
    final headers = ['Ngày', 'Giờ', 'Loại', 'Danh mục', 'Số tiền', 'Sổ', 'Ghi chú']
        .map((h) => AppTranslations.text(lang, h))
        .toList();
    rows.add(headers);

    for (var t in transactions) {
      final dateStr = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
      final timeStr = '${t.date.hour.toString().padLeft(2, '0')}:${t.date.minute.toString().padLeft(2, '0')}';
      final typeStr = _translateKind(t.kind, lang);
      final cleanNote = maskAccountNumbers(t.title);
      final ledgerName = AppTranslations.trLedger(lang, ledgerNames[t.ledgerId] ?? t.ledgerId ?? '');

      rows.add([dateStr, timeStr, typeStr, AppTranslations.trCategory(lang, t.category), t.amount.toInt(), ledgerName, cleanNote]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    csvData = '\uFEFF$csvData'; // UTF-8 BOM

    final filePath = '$tempPath/Mousey_${slugLedger}_$dateTag.csv';
    final file = File(filePath);
    file.writeAsStringSync(csvData);
    return filePath;
  }

  static Future<void> shareFile(String filePath, String format) async {
    final file = XFile(filePath);
    await Share.shareXFiles(
      [file],
      text: 'Mousey Financial Report',
      subject: 'Mousey Report',
    );
  }
}
