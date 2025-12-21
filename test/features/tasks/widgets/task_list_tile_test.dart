import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/features/tasks/widgets/task_list_tile.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('renders description and date-only start/deadline', (
    tester,
  ) async {
    final now = DateTime(2025, 12, 21, 13, 45);
    final task = Task(
      id: 't1',
      createdAt: now,
      updatedAt: now,
      name: 'Task name',
      completed: false,
      description: 'Do something important',
      startDate: DateTime(2025, 12, 21, 23, 59),
      deadlineDate: DateTime(2025, 12, 22, 1, 2),
    );

    await pumpLocalizedApp(
      tester,
      home: Scaffold(
        body: TaskListTile(
          task: task,
          onCheckboxChanged: (_, __) {},
          onTap: (_) {},
        ),
      ),
    );

    final context = tester.element(find.byType(TaskListTile));
    final localizations = MaterialLocalizations.of(context);
    final expectedStart = localizations.formatShortDate(task.startDate!);
    final expectedDeadline = localizations.formatShortDate(task.deadlineDate!);

    expect(find.text(task.name), findsOneWidget);
    expect(find.text(task.description!), findsOneWidget);

    expect(find.byIcon(Icons.play_arrow_outlined), findsOneWidget);
    expect(find.text(expectedStart), findsOneWidget);

    expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    expect(find.text(expectedDeadline), findsOneWidget);

    // Sanity check: we don't show a time-of-day.
    expect(find.textContaining(':'), findsNothing);
  });

  testWidgets('does not render subtitle when no description and no dates', (
    tester,
  ) async {
    final now = DateTime(2025, 12, 21);
    final task = Task(
      id: 't1',
      createdAt: now,
      updatedAt: now,
      name: 'Task name',
      completed: false,
    );

    await pumpLocalizedApp(
      tester,
      home: Scaffold(
        body: TaskListTile(
          task: task,
          onCheckboxChanged: (_, __) {},
          onTap: (_) {},
        ),
      ),
    );

    final listTile = tester.widget<ListTile>(find.byType(ListTile));
    expect(listTile.subtitle, isNull);

    expect(find.byIcon(Icons.play_arrow_outlined), findsNothing);
    expect(find.byIcon(Icons.flag_outlined), findsNothing);
  });
}
