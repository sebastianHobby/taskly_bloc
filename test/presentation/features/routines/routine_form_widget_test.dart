@Tags(['widget', 'routines'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/routines/widgets/routine_form.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/routines.dart';

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
  });

  setUp(setUpTestEnvironment);

  testWidgetsSafe('create form enables save when draft defaults are valid', (
    tester,
  ) async {
    final formKey = GlobalKey<FormBuilderState>();
    final now = DateTime(2025, 1, 1);
    final project = Project(
      id: 'p1',
      createdAt: now,
      updatedAt: now,
      name: 'Health',
      completed: false,
    );

    await pumpLocalizedApp(
      tester,
      home: Scaffold(
        body: RoutineForm(
          formKey: formKey,
          availableProjects: [project],
          submitTooltip: 'Save',
          initialDraft: const RoutineDraft(
            name: 'Workout',
            projectId: 'p1',
            periodType: RoutinePeriodType.week,
            scheduleMode: RoutineScheduleMode.flexible,
            targetCount: 1,
          ),
          onSubmit: () {},
        ),
      ),
    );
    await tester.pumpForStream();

    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save'),
    );
    expect(saveButton.onPressed, isNotNull);
  });

  testWidgetsSafe(
    'create form keeps save disabled when draft defaults invalid',
    (
      tester,
    ) async {
      final formKey = GlobalKey<FormBuilderState>();

      await pumpLocalizedApp(
        tester,
        home: Scaffold(
          body: RoutineForm(
            formKey: formKey,
            availableProjects: const <Project>[],
            submitTooltip: 'Save',
            initialDraft: RoutineDraft.empty(),
            onSubmit: () {},
          ),
        ),
      );
      await tester.pumpForStream();

      final saveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save'),
      );
      expect(saveButton.onPressed, isNull);
    },
  );
}
