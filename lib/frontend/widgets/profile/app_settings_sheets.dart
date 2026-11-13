import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_language.dart';
import '../../utils/app_translations.dart';

const Map<ThemeMode, String> themeModeLabels = {
  ThemeMode.light: 'Sáng',
  ThemeMode.dark: 'Tối',
  ThemeMode.system: 'Theo hệ thống',
};

void showThemePickerSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.t('Giao diện'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...themeModeLabels.entries.map((e) {
                final isSel = AppTheme.instance.value == e.key;
                return ListTile(
                  title: Text(context.t(e.value), style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSel ? Icon(Icons.check_circle, color: AppColors.accentBeige) : null,
                  onTap: () {
                    AppTheme.instance.change(e.key);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}

void showLanguagePickerSheet(
  BuildContext context, {
  required void Function(String newLanguage) onLanguageChanged,
}) {
  final lang = context.lang;
  final languages = ['Tiếng Việt', 'English (US)', '日本語 (Japanese)', '中文 (Chinese)', '한국어 (Korean)'];

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppTranslations.tr(lang, 'language'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...languages.map((l) {
                final isSel = lang == l;
                return ListTile(
                  title: Text(l, style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSel ? Icon(Icons.check_circle, color: AppColors.accentBeige) : null,
                  onTap: () {
                    onLanguageChanged(l);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}
