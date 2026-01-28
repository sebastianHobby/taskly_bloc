@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';
import 'package:taskly_ui/src/sections/empty_state_widget.dart';

void main() {
  testWidgetsSafe('renders empty state with action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyStateWidget.noTasks(
            title: 'No tasks yet',
            description: 'Add your first task',
            actionLabel: 'Add task',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('No tasks yet'), findsOneWidget);
    expect(find.text('Add your first task'), findsOneWidget);
    expect(find.text('Add task'), findsOneWidget);

    await tester.tap(find.text('Add task'));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
