import '../database/db_helper.dart';
import 'transaction_service.dart';
import 'sync_service.dart';
import '../../frontend/utils/app_language.dart';

class LedgerRepository {
  static final LedgerRepository instance = LedgerRepository._init();
  LedgerRepository._init();

  Future<String> createLedger({required String name, required String uid}) async {
    // Kiểm tra trùng tên
    final existingLedgers = await DatabaseHelper.instance.getLedgers(uid: uid);
    if (existingLedgers.any((l) => l['name'].toString().trim().toLowerCase() == name.trim().toLowerCase())) {
      throw Exception(AppLanguage.instance.t('Tên sổ sách này đã tồn tại!'));
    }

    // Insert DB
    final newId = await DatabaseHelper.instance.insertLedger(name: name, uid: uid);
    
    // Set thành activeLedgerId
    await TransactionService.instance.setCurrentLedgerId(newId, uid: uid);
    
    SyncService.instance.syncAll();
    
    return newId;
  }
}
