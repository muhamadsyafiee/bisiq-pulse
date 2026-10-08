import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'messages.dart';

class AppStrings {
  const AppStrings(this.code);
  final String code;
  static const languages = {
    'ms': 'Bahasa Malaysia',
    'en': 'English',
    'id': 'Bahasa Indonesia',
    'zh': '中文',
    'ta': 'தமிழ்',
    'ar': 'العربية',
  };
  static const delegate = _StringsDelegate();
  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ??
      const AppStrings('ms');
  bool get rtl => code == 'ar';
  String text(String key, [Map<String, Object> args = const {}]) {
    final source = messages[code]![key];
    if (source == null) throw ArgumentError('Unknown translation key: $key');
    // Replace only source placeholders, never recursively interpret user text.
    return source.replaceAllMapped(
      RegExp(r'\{(\w+)\}'),
      (m) => args[m[1]]?.toString() ?? m[0]!,
    );
  }
}

class _StringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _StringsDelegate();
  @override
  bool isSupported(Locale locale) =>
      AppStrings.languages.containsKey(locale.languageCode);
  @override
  Future<AppStrings> load(Locale locale) =>
      SynchronousFuture(AppStrings(locale.languageCode));
  @override
  bool shouldReload(_StringsDelegate old) => false;
}
