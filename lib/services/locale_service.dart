import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const supportedLocales = [
  Locale('en'),
  Locale('fr'),
  Locale('es'),
  Locale('de'),
  Locale('it'),
  Locale('pt'),
];

const _fallbackLocale = Locale('en');

/// Picks [systemLocale]'s language if it's one of [supported], otherwise
/// falls back to English. Pure function so this can be unit tested without
/// mocking `dart:ui`/shared_preferences.
Locale resolveDefaultLocale(Locale systemLocale, List<Locale> supported) {
  for (final locale in supported) {
    if (locale.languageCode == systemLocale.languageCode) return locale;
  }
  return _fallbackLocale;
}

/// Current app language, persisted across restarts.
class LocaleService extends ChangeNotifier {
  static const _prefKey = 'locale_code';

  Locale _locale = _fallbackLocale;
  Locale get locale => _locale;

  Future<void> load() async {
    final saved = await SharedPreferencesAsync().getString(_prefKey);
    _locale = saved != null
        ? Locale(saved)
        : resolveDefaultLocale(
            PlatformDispatcher.instance.locale,
            supportedLocales,
          );
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await SharedPreferencesAsync().setString(_prefKey, locale.languageCode);
    notifyListeners();
  }
}
