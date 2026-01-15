import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../helpers/test_imports.dart';

import 'package:taskly_bloc/presentation/features/tasks/widgets/task_form.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('TaskForm', () {
    testWidgetsSafe('close calls onClose when form is not dirty', (
      tester,
    ) async {
      final formKey = GlobalKey<FormBuilderState>();
      var closed = false;

      await pumpLocalizedApp(
        tester,
        home: Scaffold(
          body: TaskForm(
            formKey: formKey,
            onSubmit: () {},
            submitTooltip: 'Create task',
            onClose: () => closed = true,
          ),
        ),
      );

      await tester.pump();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(closed, isTrue);
      expect(find.text('Discard changes?'), findsNothing);
    });

    testWidgetsSafe(
      'close shows discard dialog when dirty (keep editing)',
      (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        var closed = false;

        await pumpLocalizedApp(
          tester,
          home: Scaffold(
            body: TaskForm(
              formKey: formKey,
              onSubmit: () {},
              submitTooltip: 'Create task',
              onClose: () => closed = true,
            ),
          ),
        );

        await tester.pump();

        // Make the form dirty.
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Discard changes?'), findsOneWidget);

        await tester.tap(find.text('Keep Editing'));
        await tester.pump();

        expect(find.byType(AlertDialog), findsNothing);
        expect(closed, isFalse);
      },
    );

    testWidgetsSafe(
      'close shows discard dialog when dirty (discard)',
      (tester) async {
        final formKey = GlobalKey<FormBuilderState>();
        var closed = false;

        await pumpLocalizedApp(
          tester,
          home: Scaffold(
            body: TaskForm(
              formKey: formKey,
              onSubmit: () {},
              submitTooltip: 'Create task',
              onClose: () => closed = true,
            ),
          ),
        );

        await tester.pump();

        // Make the form dirty.
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();

        expect(find.text('Discard changes?'), findsOneWidget);

        await tester.tap(find.text('Discard'));
        await tester.pump();

        expect(closed, isTrue);
      },
    );

    testWidgetsSafe('delete icon triggers onDelete', (tester) async {
      final formKey = GlobalKey<FormBuilderState>();
      var deleted = false;

      await pumpLocalizedApp(
        tester,
        home: Scaffold(
          body: TaskForm(
            formKey: formKey,
            initialData: TestData.task(id: 't1', name: 'My Task'),
            onSubmit: () {},
            submitTooltip: 'Save task',
            onDelete: () => deleted = true,
          ),
        ),
      );

      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pump();

      expect(deleted, isTrue);
    });

    testWidgetsSafe('submit button triggers onSubmit', (tester) async {
      final formKey = GlobalKey<FormBuilderState>();
      var submitted = false;

      await pumpLocalizedApp(
        tester,
        home: Scaffold(
          body: TaskForm(
            formKey: formKey,
            onSubmit: () => submitted = true,
            submitTooltip: 'Create task',
          ),
        ),
      );

      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Create Task'));
      await tester.pump();

      expect(submitted, isTrue);
    });
  });
}
