@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

import 'helpers/test_helpers.dart';

void main() {
  testSafe('TasklyTokens.fromTheme provides stable defaults', () async {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    );

    final tokens = TasklyTokens.fromTheme(theme);

    expect(tokens.spaceMd, 12);
    expect(tokens.radiusPill, 999);
    expect(tokens.minTapTargetSize, 40);
    expect(tokens.iconButtonMinSize, 44);
  });

  testSafe('TasklyTokens.copyWith updates selected values', () async {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    );
    final tokens = TasklyTokens.fromTheme(theme);

    final updated = tokens.copyWith(
      spaceMd: 99,
      minTapTargetSize: 48,
      neonAccent: Colors.red,
    );

    expect(updated.spaceMd, 99);
    expect(updated.minTapTargetSize, 48);
    expect(updated.neonAccent, Colors.red);
    expect(updated.spaceLg, tokens.spaceLg);
  });

  testSafe('TasklyTokens.lerp interpolates token values', () async {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    );
    final a = TasklyTokens.fromTheme(theme);
    final b = a.copyWith(spaceMd: a.spaceMd + 10, radiusMd: a.radiusMd + 4);

    final mid = a.lerp(b, 0.5);

    expect(mid.spaceMd, closeTo(a.spaceMd + 5, 0.001));
    expect(mid.radiusMd, closeTo(a.radiusMd + 2, 0.001));
  });

  testWidgetsSafe('TasklyTokens.of reads extension when present', (
    tester,
  ) async {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    );
    final ext = TasklyTokens.fromTheme(theme).copyWith(spaceMd: 77);

    late TasklyTokens fromExtension;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme.copyWith(extensions: <ThemeExtension<dynamic>>[ext]),
        home: Builder(
          builder: (context) {
            fromExtension = TasklyTokens.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(fromExtension.spaceMd, 77);
  });

  testWidgetsSafe('TasklyTokens.of falls back to fromTheme', (tester) async {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    );
    late TasklyTokens fromFallback;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) {
            fromFallback = TasklyTokens.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(fromFallback.spaceMd, 12);
  });
}
