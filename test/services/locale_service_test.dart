import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:localmsg/services/locale_service.dart';

void main() {
  test('resolveDefaultLocale picks the system language when supported', () {
    final result = resolveDefaultLocale(
      const Locale('fr', 'FR'),
      supportedLocales,
    );
    expect(result, const Locale('fr'));
  });

  test('resolveDefaultLocale falls back to English when unsupported', () {
    final result = resolveDefaultLocale(
      const Locale('ja', 'JP'),
      supportedLocales,
    );
    expect(result, const Locale('en'));
  });
}
