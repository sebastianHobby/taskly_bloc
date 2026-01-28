@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';
import 'package:taskly_ui/src/primitives/taskly_badge.dart';

void main() {
  testWidgetsSafe('renders badge label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TasklyBadge(
            label: 'Priority',
            icon: Icons.flag_rounded,
            color: Colors.red,
            style: TasklyBadgeStyle.solid,
          ),
        ),
      ),
    );

    expect(find.text('Priority'), findsOneWidget);
    expect(find.byIcon(Icons.flag_rounded), findsOneWidget);
  });
}
