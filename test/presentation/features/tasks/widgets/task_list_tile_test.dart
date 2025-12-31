import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_list_tile.dart';

import '../../../../fixtures/test_data.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('renders description and date-only start/deadline', (
    tester,
  ) async {
    // Use dates far in the future (> 7 days) to ensure formatShortDate is used
    // instead of relative date formatting like "Today" or "Tomorrow"
    final now = DateTime.now();
    final farFutureStart = now.add(const Duration(days: 30));
    final farFutureDeadline = now.add(const Duration(days: 31));
    final task = TestData.task(
      id: 't1',
      createdAt: now,
      updatedAt: now,
      name: 'Task name',
      description: 'Do something important',
      startDate: farFutureStart,
      deadlineDate: farFutureDeadline,
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

    // Uses rounded icons in the new Card-based design
    expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);
    expect(find.text(expectedStart), findsOneWidget);

    expect(find.byIcon(Icons.flag_rounded), findsOneWidget);
    expect(find.text(expectedDeadline), findsOneWidget);

    // Sanity check: we don't show a time-of-day.
    expect(find.textContaining(':'), findsNothing);
  });

  testWidgets('does not render subtitle when no description and no dates', (
    tester,
  ) async {
    final now = DateTime(2025, 12, 21);
    final task = TestData.task(
      id: 't1',
      createdAt: now,
      updatedAt: now,
      name: 'Task name',
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

    // TaskListTile uses Card-based layout, not ListTile
    expect(find.byType(Card), findsOneWidget);
    expect(find.text(task.name), findsOneWidget);

    // No date icons should be shown when no dates provided
    expect(find.byIcon(Icons.calendar_today_rounded), findsNothing);
    expect(find.byIcon(Icons.flag_rounded), findsNothing);
  });
}
