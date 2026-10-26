import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_translations.dart';

/// Ngôn ngữ hiện tại của toàn app. Mọi màn hình, dialog và service đọc từ đây
/// để khi đổi ngôn ngữ thì tất cả cùng đổi theo.
class AppLanguage extends ValueNotifier<String> {
  AppLanguage._() : super(defaultLanguage);

  static final AppLanguage instance = AppLanguage._();

  static const String defaultLanguage = 'Tiếng Việt';
  static const List<String> languages = [
    'Tiếng Việt',
    'English (US)',
    '日本語 (Japanese)',
    '中文 (Chinese)',
    '한국어 (Korean)',
  ];

  static const String _globalKey = 'mousey_language';
  static String _userKey(String uid) => 'mousey_language_$uid';

  /// Đọc ngôn ngữ đã lưu (ưu tiên theo từng user, sau đó là ngôn ngữ chung).
  Future<void> load({String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    value = (uid != null ? prefs.getString(_userKey(uid)) : null) ??
        prefs.getString(_globalKey) ??
        defaultLanguage;
  }

  Future<void> change(String lang, {String? uid}) async {
    value = lang;
    final prefs = await SharedPreferences.getInstance();
    if (uid != null) await prefs.setString(_userKey(uid), lang);
    await prefs.setString(_globalKey, lang);
  }

  /// Dịch một câu tiếng Việt sang ngôn ngữ hiện tại (dùng ở service/model).
  String t(String viText, [Map<String, Object?>? params]) =>
      AppTranslations.text(value, viText, params);
}

extension AppLanguageContext on BuildContext {
  String get lang => AppLanguage.instance.value;

  /// Dịch một câu tiếng Việt sang ngôn ngữ hiện tại.
  /// Tham số dạng `{name}` trong câu được thay bằng giá trị trong [params].
  String t(String viText, [Map<String, Object?>? params]) =>
      AppTranslations.text(AppLanguage.instance.value, viText, params);

  /// Tên danh mục (lưu bằng tiếng Việt) theo ngôn ngữ hiện tại.
  String tCategory(String category) =>
      AppTranslations.trCategory(AppLanguage.instance.value, category);
}
