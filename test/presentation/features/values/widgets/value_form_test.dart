import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../helpers/test_imports.dart';

import 'package:taskly_bloc/presentation/features/values/widgets/value_form.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('ValueForm', () {
    testWidgetsSafe('close calls onClose when form is not dirty', (
      tester,
    ) async {
      final formKey = GlobalKey<FormBuilderState>();
      var closed = false;

      await pumpLocalizedApp(
        tester,
        home: Scaffold(
          body: ValueForm(
            formKey: formKey,
            initialData: null,
            onSubmit: () {},
            submitTooltip: 'Create value',
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
            body: ValueForm(
              formKey: formKey,
              initialData: null,
              onSubmit: () {},
              submitTooltip: 'Create value',
              onClose: () => closed = true,
            ),
          ),
        );

        await tester.pump();

        // Make the form dirty.
        await tester.enterText(find.byType(EditableText).first, 'My Value');
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
            body: ValueForm(
              formKey: formKey,
              initialData: null,
              onSubmit: () {},
              submitTooltip: 'Create value',
              onClose: () => closed = true,
            ),
          ),
        );

        await tester.pump();

        // Make the form dirty.
        await tester.enterText(find.byType(EditableText).first, 'My Value');
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
          body: ValueForm(
            formKey: formKey,
            initialData: TestData.value(id: 'v1', name: 'My Value'),
            onSubmit: () {},
            submitTooltip: 'Save value',
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
          body: ValueForm(
            formKey: formKey,
            initialData: null,
            onSubmit: () => submitted = true,
            submitTooltip: 'Create value',
          ),
        ),
      );

      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Create Value'));
      await tester.pump();

      expect(submitted, isTrue);
    });
  });
}
