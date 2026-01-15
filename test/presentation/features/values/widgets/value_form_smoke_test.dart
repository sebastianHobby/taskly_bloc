import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../helpers/test_imports.dart';

import 'package:taskly_bloc/presentation/features/values/widgets/value_form.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('ValueForm (smoke)', () {
    testWidgetsSafe('builds for create flow', (tester) async {
      final formKey = GlobalKey<FormBuilderState>();

      await pumpLocalizedApp(
        tester,
        home: Scaffold(
          body: ValueForm(
            formKey: formKey,
            initialData: null,
            onSubmit: () {},
            submitTooltip: 'Create value',
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(ValueForm), findsOneWidget);
      expect(find.byType(FormBuilder), findsOneWidget);
      expect(find.byType(FormBuilderTextField), findsWidgets);
    });

    testWidgetsSafe('builds for edit flow with close + delete', (tester) async {
      final formKey = GlobalKey<FormBuilderState>();

      await pumpLocalizedApp(
        tester,
        home: Scaffold(
          body: ValueForm(
            formKey: formKey,
            initialData: TestData.value(id: 'v1', name: 'My Value'),
            onSubmit: () {},
            submitTooltip: 'Save value',
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
