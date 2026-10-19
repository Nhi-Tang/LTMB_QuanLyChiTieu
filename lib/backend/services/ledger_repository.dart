import '../database/db_helper.dart';
import 'transaction_service.dart';
import 'sync_service.dart';
import 'pro_service.dart';

class LedgerRepository {
  static final LedgerRepository instance = LedgerRepository._init();
  LedgerRepository._init();

  Future<String> createLedger({required String name, required String uid}) async {
    // Kiểm tra giới hạn theo gói (Free tối đa 1, Pro không giới hạn)
    if (!ProService.instance.isPro) {
      final ledgers = await DatabaseHelper.instance.getLedgers(uid: uid);
      if (ledgers.isNotEmpty) {
        throw Exception('Giới hạn gói Free: Bạn chỉ có thể sử dụng 1 Sổ sách. Hãy nâng cấp PRO để tạo thêm!');
      }
    }

    // Kiểm tra trùng tên
    final existingLedgers = await DatabaseHelper.instance.getLedgers(uid: uid);
    if (existingLedgers.any((l) => l['name'].toString().trim().toLowerCase() == name.trim().toLowerCase())) {
      throw Exception('Tên sổ sách này đã tồn tại!');
    }

    // Insert DB
    final newId = await DatabaseHelper.instance.insertLedger(name: name, uid: uid);
    
    // Set thành activeLedgerId
    await TransactionService.instance.setCurrentLedgerId(newId, uid: uid);
    
    // Đồng bộ nếu là Pro
    if (ProService.instance.isPro) {
      SyncService.instance.syncAll();
    }
    
    return newId;
  }
}
