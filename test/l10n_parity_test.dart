import 'package:flutter_test/flutter_test.dart';

import 'package:cycle_care/l10n/strings.dart';

void main() {
  test('EN and SI string maps have identical key sets', () {
    final enKeys = stringsEn.keys.toSet();
    final siKeys = stringsSi.keys.toSet();

    final missingInSi = enKeys.difference(siKeys);
    final missingInEn = siKeys.difference(enKeys);

    expect(missingInSi, isEmpty,
        reason: 'Keys in EN but missing from SI: $missingInSi');
    expect(missingInEn, isEmpty,
        reason: 'Keys in SI but missing from EN: $missingInEn');
  });

  test('no SI value is empty or identical to its EN value', () {
    for (final key in stringsEn.keys) {
      final en = stringsEn[key]!;
      final si = stringsSi[key];
      expect(si, isNotNull, reason: 'SI missing key "$key"');
      expect(si, isNotEmpty, reason: 'SI value for "$key" is empty');
      // Sinhala strings should not be identical to English (they use a different
      // script), except for borrowed words or brand names.
      // We allow a few known exceptions.
      if (!const {'greeting', 'app_title'}.contains(key)) {
        expect(si, isNot(en),
            reason: 'SI value for "$key" is identical to EN: "$en"');
      }
    }
  });
}
