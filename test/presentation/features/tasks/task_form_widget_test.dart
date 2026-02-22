@Tags(['widget', 'tasks'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_form.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/theme/app_theme.dart';
import 'package:taskly_domain/core.dart';

class _FakeNowService implements NowService {
  _FakeNowService(this.now);

  final DateTime now;

  @override
  DateTime nowLocal() => now;

  @override
  DateTime nowUtc() => now.toUtc();
}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testWidgetsSafe(
    'prompts and removes reminder when due date is cleared for before-due reminder',
    (tester) async {
      final formKey = GlobalKey<FormBuilderState>();
      final task = Task(
        id: 'task-1',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        name: 'Task',
        completed: false,
        deadlineDate: DateTime.utc(2026, 1, 10),
        reminderKind: TaskReminderKind.beforeDue,
        reminderMinutesBeforeDue: 60,
      );

      await tester.pumpWidget(
        Provider<NowService>.value(
          value: _FakeNowService(DateTime(2026, 1, 2, 9, 0)),
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TaskForm(
                formKey: formKey,
                initialData: task,
                submitTooltip: 'save',
                onSubmit: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpForStream();

      await tester.tap(find.byIcon(Icons.flag_rounded).first);
      await tester.pumpForStream();

      await tester.tap(find.text('None').last);
      await tester.pumpForStream();

      expect(find.text('Keep this reminder?'), findsOneWidget);

      await tester.tap(find.text('Remove reminder'));
      await tester.pumpForStream();

      final reminderKind =
          formKey.currentState?.fields[TaskFieldKeys.reminderKind.id]?.value
              as TaskReminderKind?;
      final reminderAtUtc =
          formKey.currentState?.fields[TaskFieldKeys.reminderAtUtc.id]?.value
              as DateTime?;
      final reminderBeforeDue =
          formKey
                  .currentState
                  ?.fields[TaskFieldKeys.reminderMinutesBeforeDue.id]
                  ?.value
              as int?;

      expect(reminderKind, TaskReminderKind.none);
      expect(reminderAtUtc, isNull);
      expect(reminderBeforeDue, isNull);
    },
  );
}
