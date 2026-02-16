@Tags(['widget', 'values'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/values/widgets/value_form.dart';
import 'package:taskly_domain/core.dart';

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
  });

  setUp(setUpTestEnvironment);

  testWidgetsSafe('create form enables save when draft defaults are valid', (
    tester,
  ) async {
    final formKey = GlobalKey<FormBuilderState>();

    await pumpLocalizedApp(
      tester,
      home: Scaffold(
        body: ValueForm(
          formKey: formKey,
          initialData: null,
          initialDraft: const ValueDraft(
            name: 'Health',
            color: '#33AA77',
            priority: ValuePriority.medium,
          ),
          submitTooltip: 'Save',
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
          body: ValueForm(
            formKey: formKey,
            initialData: null,
            initialDraft: ValueDraft.empty(),
            submitTooltip: 'Save',
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
