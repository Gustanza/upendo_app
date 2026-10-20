import 'package:flutter/widgets.dart';

import 'user_preferences.dart';

/// The app's UI language. Swahili by default; the user can switch to English
/// or French from the Account screen, and the choice is persisted in
/// SharedPreferences (see UserPreferences.languageCode).
///
/// A singleton ValueNotifier rather than a provider package: main.dart calls
/// runApp() again on every auth change, so the MaterialApp listens to this
/// directly and keeps the chosen locale across those rebuilds.
class LocaleController extends ValueNotifier<Locale> {
  LocaleController._() : super(defaultLocale);

  static final LocaleController instance = LocaleController._();

  static const defaultLocale = Locale('sw');
  static const supportedLanguageCodes = ['sw', 'en', 'fr'];

  final UserPreferences _prefs = UserPreferences();

  Locale get locale => value;

  /// Normalises a stored/unknown code to one of [supportedLanguageCodes].
  static Locale resolve(String? languageCode) =>
      supportedLanguageCodes.contains(languageCode)
          ? Locale(languageCode!)
          : defaultLocale;

  Future<void> load() async {
    value = resolve(await _prefs.getLanguageCode());
  }

  Future<void> setLanguage(String languageCode) async {
    final next = resolve(languageCode);
    if (next == value) return;
    value = next;
    await _prefs.setLanguageCode(next.languageCode);
  }
}
