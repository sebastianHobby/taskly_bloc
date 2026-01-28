@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

import '../../helpers/test_environment.dart';
import '../../helpers/test_imports.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('TasklyTokens', () {
    testSafe('fromTheme() builds expected token values', () async {
      final tokens = TasklyTokens.fromTheme(
        ThemeData(colorScheme: const ColorScheme.light()),
      );

      expect(tokens.spaceSm, 8);
      expect(tokens.spaceLg, 16);
      expect(tokens.radiusMd, 12);
      expect(tokens.iconButtonMinSize, 44);
    });

    testSafe('copyWith() overrides only provided fields', () async {
      final base = TasklyTokens.fromTheme(ThemeData.light());

      final updated = base.copyWith(spaceSm: 99);

      expect(updated.spaceSm, 99);
      expect(base.spaceSm, isNot(99));
    });

    testSafe('lerp() returns this when other is not TasklyTokens', () async {
      final base = TasklyTokens.fromTheme(ThemeData.light());

      final result = base.lerp(null, 0.5);
      expect(identical(result, base), isTrue);
    });

    testSafe('lerp() interpolates values when other provided', () async {
      final a = TasklyTokens.fromTheme(ThemeData.light());
      final b = a.copyWith(spaceLg: a.spaceLg + 10);

      final mid = a.lerp(b, 0.5);
      expect(mid.spaceLg, closeTo(a.spaceLg + 5, 0.001));
    });
  });
}
