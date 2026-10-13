import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../database/db_helper.dart';

class ExportService {
  static Future<String> exportToCsv() async {
    final transactions = await DatabaseHelper.instance.getTransactions();
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/Mousey_Report_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);

    final buffer = StringBuffer();
    buffer.writeln('ID,Tên giao dịch,Danh mục,Số tiền,Loại,Ngày');
    for (var t in transactions) {
      final typeStr = t.isExpense ? 'Chi tiêu' : 'Thu nhập';
      buffer.writeln('${t.id},"${t.title}","${t.category}",${t.amount},$typeStr,${t.date.toIso8601String()}');
    }

    await file.writeAsString(buffer.toString());
    return file.path;
  }

  static Future<String> exportToExcel() async {
    final transactions = await DatabaseHelper.instance.getTransactions();
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/Mousey_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(path);

    final buffer = StringBuffer();
    buffer.writeln('ID\tTên giao dịch\tDanh mục\tSố tiền\tLoại\tNgày');
    for (var t in transactions) {
      final typeStr = t.isExpense ? 'Chi tiêu' : 'Thu nhập';
      buffer.writeln('${t.id}\t${t.title}\t${t.category}\t${t.amount}\t$typeStr\t${t.date.toIso8601String()}');
    }

    await file.writeAsString(buffer.toString());
    return file.path;
  }
}
