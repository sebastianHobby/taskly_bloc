@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_ui/taskly_ui_primitives.dart';
import 'package:taskly_ui/taskly_ui_theme.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

import 'helpers/test_helpers.dart';

void main() {
  testWidgetsSafe('TasklyChip resolves semantic colors from theme', (
    tester,
  ) async {
    final theme = ThemeData.light().copyWith(
      extensions: <ThemeExtension<dynamic>>[
        TasklyTokens.fromTheme(ThemeData.light()),
        TasklyChipTheme.fromTheme(ThemeData.light()),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: TasklyChip(
            label: 'Status',
            variant: TasklyChipVariant.status,
          ),
        ),
      ),
    );

    expect(find.text('Status'), findsOneWidget);
  });

  testWidgetsSafe('TasklyCardSurface and TasklySheetChrome render child', (
    tester,
  ) async {
    final baseTheme = ThemeData.light();
    final theme = baseTheme.copyWith(
      extensions: <ThemeExtension<dynamic>>[
        TasklyTokens.fromTheme(baseTheme),
        TasklyCardTheme.fromTheme(baseTheme),
        TasklySheetTheme.fromTheme(baseTheme),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Column(
            children: const [
              TasklyCardSurface(
                child: Text('Card content'),
              ),
              TasklySheetChrome(
                child: Text('Sheet content'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Card content'), findsOneWidget);
    expect(find.text('Sheet content'), findsOneWidget);
  });
}
