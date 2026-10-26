import 'package:flutter_test/flutter_test.dart';
import 'package:quanlychitieu/frontend/utils/app_language.dart';
import 'package:quanlychitieu/frontend/utils/app_translations.dart';

void main() {
  group('AppTranslations.text', () {
    test('giữ nguyên tiếng Việt khi ngôn ngữ là Tiếng Việt', () {
      expect(AppTranslations.text('Tiếng Việt', 'Hủy'), 'Hủy');
    });

    test('dịch sang các ngôn ngữ khác', () {
      expect(AppTranslations.text('English (US)', 'Hủy'), 'Cancel');
      expect(AppTranslations.text('日本語 (Japanese)', 'Hủy'), 'キャンセル');
      expect(AppTranslations.text('中文 (Chinese)', 'Hủy'), '取消');
      expect(AppTranslations.text('한국어 (Korean)', 'Hủy'), '취소');
    });

    test('thay tham số trong câu', () {
      expect(
        AppTranslations.text('English (US)', 'Còn {daysLeft} ngày', {'daysLeft': 5}),
        '5 days left',
      );
      expect(
        AppTranslations.text('Tiếng Việt', 'Còn {daysLeft} ngày', {'daysLeft': 5}),
        'Còn 5 ngày',
      );
    });

    test('gợi ý số tiền trong ô nhập', () {
      expect(AppTranslations.text('Tiếng Việt', 'VD: {amount}', {'amount': '5.000.000'}), 'VD: 5.000.000');
      expect(AppTranslations.text('English (US)', 'VD: {amount}', {'amount': '5.000.000'}), 'e.g. 5.000.000');
    });

    test('câu chưa có bản dịch thì giữ tiếng Việt', () {
      expect(AppTranslations.text('English (US)', 'Câu chưa dịch'), 'Câu chưa dịch');
    });
  });

  group('AppTranslations.tr', () {
    test('khoá thiếu ở một ngôn ngữ thì dùng tiếng Việt thay vì hiện tên khoá', () {
      expect(AppTranslations.tr('English (US)', 'welcome_back'), 'Welcome back');
      expect(AppTranslations.tr('English (US)', 'home'), 'Home');
    });
  });

  group('AppTranslations.trCategory', () {
    test('dịch danh mục mặc định cho mọi ngôn ngữ', () {
      expect(AppTranslations.trCategory('English (US)', 'Ăn uống'), 'Food & Drinks');
      expect(AppTranslations.trCategory('한국어 (Korean)', 'Lương'), '급여');
      expect(AppTranslations.trCategory('English (US)', 'Tiền Nợ'), 'Debt');
    });

    test('giữ nguyên danh mục người dùng tự tạo và tiếng Việt', () {
      expect(AppTranslations.trCategory('English (US)', 'Cà phê sáng'), 'Cà phê sáng');
      expect(AppTranslations.trCategory('Tiếng Việt', 'Ăn uống'), 'Ăn uống');
    });
  });

  test('AppLanguage.t dùng ngôn ngữ hiện tại', () {
    AppLanguage.instance.value = 'English (US)';
    expect(AppLanguage.instance.t('Đăng xuất'), 'Log out');
    AppLanguage.instance.value = 'Tiếng Việt';
    expect(AppLanguage.instance.t('Đăng xuất'), 'Đăng xuất');
  });
}
