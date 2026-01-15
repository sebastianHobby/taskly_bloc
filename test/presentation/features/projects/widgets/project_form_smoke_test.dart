import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../helpers/test_imports.dart';

import 'package:taskly_bloc/presentation/features/projects/widgets/project_form.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('ProjectForm (smoke)', () {
    testWidgetsSafe('builds for create flow', (tester) async {
      final formKey = GlobalKey<FormBuilderState>();

      await pumpLocalizedApp(
        tester,
        home: Scaffold(
          body: ProjectForm(
            formKey: formKey,
            initialData: null,
            onSubmit: () {},
            submitTooltip: 'Create project',
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(ProjectForm), findsOneWidget);
      expect(find.byType(FormBuilder), findsOneWidget);
      expect(find.byType(FormBuilderTextField), findsWidgets);
    });

    testWidgetsSafe('builds for edit flow with close + delete', (tester) async {
      final formKey = GlobalKey<FormBuilderState>();

      await pumpLocalizedApp(
        tester,
        home: Scaffold(
          body: ProjectForm(
            formKey: formKey,
            initialData: TestData.project(id: 'p1', name: 'My Project'),
            onSubmit: () {},
            submitTooltip: 'Save project',
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
