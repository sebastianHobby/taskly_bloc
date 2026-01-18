@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:taskly_ui/taskly_ui.dart';

import '../../helpers/test_imports.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testWidgetsSafe(
    'PriorityFlag renders a flag and semantics when priority set',
    (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PriorityFlag(
                priority: 2,
                semanticsLabel: 'Priority',
                semanticsValue: '2',
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.flag), findsOneWidget);
        expect(find.bySemanticsLabel('Priority'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgetsSafe('PriorityFlag renders nothing when priority is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PriorityFlag(priority: null),
        ),
      ),
    );

    expect(find.byIcon(Icons.flag), findsNothing);
  });
}
