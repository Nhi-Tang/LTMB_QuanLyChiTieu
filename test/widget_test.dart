// This is a basic Flutter widget test for PiggySmart.

import 'package:flutter_test/flutter_test.dart';
import 'package:quanlychitieu/main.dart';

void main() {
  testWidgets('PiggySmart app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PiggySmartApp());

    // Verify that PiggySmart title and login option are displayed.
    expect(find.text('PiggySmart'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsWidgets);
  });
}
