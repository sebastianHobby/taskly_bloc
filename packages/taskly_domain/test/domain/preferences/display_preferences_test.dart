@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/preferences.dart';

void main() {
  testSafe('DisplayPreferences.fromJson falls back to standard', () async {
    final prefs = DisplayPreferences.fromJson(const <String, dynamic>{});
    expect(prefs.density, DisplayDensity.standard);
  });

  testSafe('DisplayPreferences serializes and restores density', () async {
    const prefs = DisplayPreferences(density: DisplayDensity.compact);
    final restored = DisplayPreferences.fromJson(prefs.toJson());
    expect(restored, equals(prefs));
  });
}
