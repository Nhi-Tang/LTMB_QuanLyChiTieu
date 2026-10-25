import 'package:flutter_test/flutter_test.dart';
import 'package:quanlychitieu/frontend/utils/app_translations.dart';

void main() {
  group('Budget alert messages', () {
    final params = {
      'categoryKey': 'Ăn uống',
      'percent': 85,
      'spent': 850000.0,
      'limit': 1000000.0,
      'over': 0.0,
      'remaining': 150000.0,
      'daysLeft': 5,
      'perDay': 30000.0,
    };

    test('Title differs per level', () {
      final w = AppTranslations.formatBudgetAlertTitle('Tiếng Việt', 'budget_warning', params);
      final r = AppTranslations.formatBudgetAlertTitle('Tiếng Việt', 'budget_reached', params);
      final e = AppTranslations.formatBudgetAlertTitle('Tiếng Việt', 'budget_exceeded', params);
      expect({w, r, e}.length, 3);
      expect(w, contains('85%'));
    });

    test('Total budget uses localized name', () {
      final total = {...params, 'categoryKey': 'total'};
      expect(AppTranslations.formatBudgetAlertTitle('English', 'budget_warning', total), startsWith('Total budget'));
      expect(AppTranslations.formatBudgetAlertMessage('Tiếng Việt', 'budget_reached', total, 'k'), contains('Tổng chi tháng này'));
    });

    test('Message is never raw JSON for known levels', () {
      for (final type in ['budget_warning', 'budget_reached', 'budget_exceeded']) {
        for (final lang in ['Tiếng Việt', 'English', '日本語', '中文', '한국어']) {
          final msg = AppTranslations.formatBudgetAlertMessage(lang, type, params, 'budget:b1:2026-10:$type');
          expect(msg.startsWith('{'), isFalse, reason: '$lang/$type');
        }
      }
    });
  });
}
