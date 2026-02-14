@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';

import 'helpers/test_helpers.dart';

void main() {
  testWidgetsSafe('shows helper text when provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TasklyFormValueCard(
            title: 'Select a core value',
            helperText: 'Select a core value...',
            icon: Icons.favorite_rounded,
            iconColor: Colors.red,
            hasValue: false,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Select a core value'), findsOneWidget);
    expect(find.text('Select a core value...'), findsOneWidget);
  });

  testWidgetsSafe(
    'hides helper text when helper is null for selected value',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TasklyFormValueCard(
              title: 'Health',
              helperText: null,
              icon: Icons.favorite_rounded,
              iconColor: Colors.red,
              hasValue: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Health'), findsOneWidget);
      expect(find.text('Select a core value...'), findsNothing);
    },
  );
}
