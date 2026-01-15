import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../helpers/test_imports.dart';

import 'package:taskly_bloc/presentation/features/tasks/widgets/task_form.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('TaskForm (smoke)', () {
    testWidgetsSafe('builds for create flow', (tester) async {
      final formKey = GlobalKey<FormBuilderState>();

      await pumpLocalizedApp(
        tester,
        home: Scaffold(
          body: TaskForm(
            formKey: formKey,
            onSubmit: () {},
            submitTooltip: 'Create task',
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(TaskForm), findsOneWidget);
      expect(find.byType(FormBuilder), findsOneWidget);
      expect(find.byType(FormBuilderTextField), findsWidgets);
    });

    testWidgetsSafe('builds for edit flow with close + delete', (tester) async {
      final formKey = GlobalKey<FormBuilderState>();

      await pumpLocalizedApp(
        tester,
        home: Scaffold(
          body: TaskForm(
            formKey: formKey,
            initialData: TestData.task(id: 't1', name: 'My Task'),
            onSubmit: () {},
            submitTooltip: 'Save task',
            onDelete: () {},
            onClose: () {},
          ),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });
  });
}
