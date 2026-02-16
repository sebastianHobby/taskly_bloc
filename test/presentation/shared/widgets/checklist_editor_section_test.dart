@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/shared/widgets/checklist_editor_section.dart';

import '../../../helpers/test_imports.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testWidgetsSafe('expanded checklist editor shows a single add row CTA', (
    tester,
  ) async {
    await pumpLocalizedApp(
      tester,
      home: Scaffold(
        body: ChecklistEditorSection(
          title: 'Steps',
          titles: const <String>[],
          addItemFieldLabel: 'Add a step',
          addItemButtonLabel: 'Add',
          deleteItemTooltip: 'Delete',
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpForStream();

    expect(find.widgetWithText(FilledButton, 'Add'), findsOneWidget);
    expect(find.text('Add steps'), findsNothing);
  });

  testWidgetsSafe('editing first checklist row keeps focus on same row', (
    tester,
  ) async {
    await pumpLocalizedApp(
      tester,
      home: _ChecklistEditorHarness(),
    );
    await tester.pumpForStream();

    final firstField = find.byType(TextFormField).first;
    await tester.tap(firstField);
    await tester.pump();
    await tester.enterText(firstField, 'Firstx');
    await tester.pump();

    final editables = tester.widgetList<EditableText>(
      find.byType(EditableText),
    );
    final firstEditable = editables.first;
    final secondEditable = editables.elementAt(1);
    expect(firstEditable.controller.text, 'Firstx');
    expect(secondEditable.controller.text, 'Second');
    expect(firstEditable.focusNode.hasFocus, isTrue);
  });
}

class _ChecklistEditorHarness extends StatefulWidget {
  @override
  State<_ChecklistEditorHarness> createState() =>
      _ChecklistEditorHarnessState();
}

class _ChecklistEditorHarnessState extends State<_ChecklistEditorHarness> {
  List<String> _titles = const <String>['First', 'Second'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChecklistEditorSection(
        title: 'Steps',
        titles: _titles,
        addItemFieldLabel: 'Add a step',
        addItemButtonLabel: 'Add',
        deleteItemTooltip: 'Delete',
        onChanged: (next) {
          setState(() => _titles = next);
        },
      ),
    );
  }
}
