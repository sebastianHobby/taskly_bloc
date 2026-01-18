@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/theme/taskly_typography.dart';

import '../../helpers/test_environment.dart';
import '../../helpers/test_imports.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('TasklyTypography', () {
    testSafe('from() builds expected token styles', () async {
      const onSurfaceVariant = Colors.purple;
      const scheme = ColorScheme.light(onSurfaceVariant: onSurfaceVariant);

      final typography = TasklyTypography.from(
        textTheme: const TextTheme(),
        colorScheme: scheme,
      );

      expect(typography.badgeTinyCaps.fontSize, 10);
      expect(typography.badgeTinyCaps.fontWeight, FontWeight.w700);
      expect(typography.badgeTinyCaps.letterSpacing, 1);
      expect(typography.badgeTinyCaps.color, onSurfaceVariant);

      expect(typography.sectionHeaderHeavy.fontWeight, FontWeight.w900);
      expect(typography.sectionHeaderHeavy.fontSize, 18);

      expect(typography.agendaSectionHeaderHeavy.fontWeight, FontWeight.w900);
      expect(typography.agendaSectionHeaderHeavy.fontSize, 24);
    });

    testSafe('copyWith() overrides only provided fields', () async {
      final base = TasklyTypography.from(
        textTheme: const TextTheme(),
        colorScheme: const ColorScheme.light(),
      );

      const overridden = TextStyle(fontSize: 99);
      final updated = base.copyWith(filterControl: overridden);

      expect(updated.filterControl.fontSize, 99);
      expect(base.filterControl.fontSize, isNot(99));
    });

    testSafe(
      'lerp() returns this when other is not TasklyTypography',
      () async {
        final base = TasklyTypography.from(
          textTheme: const TextTheme(),
          colorScheme: const ColorScheme.light(),
        );

        final result = base.lerp(null, 0.5);
        expect(identical(result, base), isTrue);
      },
    );

    testSafe('lerp() interpolates text styles when other provided', () async {
      final a = TasklyTypography.from(
        textTheme: const TextTheme(),
        colorScheme: const ColorScheme.light(),
      );
      final b = a.copyWith(
        screenTitleTight: a.screenTitleTight.copyWith(fontSize: 42),
      );

      final mid = a.lerp(b, 0.5);
      expect(mid.screenTitleTight.fontSize, isNotNull);
    });
  });
}
