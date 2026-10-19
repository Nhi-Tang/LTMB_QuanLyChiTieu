import 'package:flutter_test/flutter_test.dart';
import 'package:quanlychitieu/backend/services/bank_notification_listener_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Listener Manager', () {
    BankNotificationListenerManager.instance.startListening(uid: 'user1');
    BankNotificationListenerManager.instance.stopListening();
  });
}
