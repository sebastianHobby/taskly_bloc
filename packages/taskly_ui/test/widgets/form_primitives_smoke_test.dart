import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';
import 'package:taskly_ui/taskly_ui_primitives.dart';

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: FormBuilder(child: child),
    ),
  );
}

enum _Mode { one, two }

const _chipPreset = TasklyFormChipPreset(
  borderRadius: 20,
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  iconSize: 18,
  clearIconSize: 16,
  clearHitPadding: 4,
  minHeight: 40,
);

const _formPreset = TasklyFormPreset(
  chip: _chipPreset,
  ux: TasklyFormUxPreset(
    sectionGapCompact: 8,
    sectionGapRegular: 12,
    subsectionGap: 8,
    notesContentPadding: EdgeInsets.all(8),
    notesMinLinesCompact: 2,
    notesMinLinesRegular: 3,
    notesMaxLinesCompact: 3,
    notesMaxLinesRegular: 4,
    selectorFill: true,
    selectorFocusWidth: 1.2,
  ),
);

void main() {
  testWidgets('renders and interacts with core form primitives', (
    tester,
  ) async {
    var actionTap = 0;
    var stepperValue = 2;
    Color selectedColor = Colors.red;
    var selectedPriority = 1;

    await tester.pumpWidget(
      _host(
        SingleChildScrollView(
          child: Column(
            children: [
              TasklyFormActionRow(
                cancelLabel: 'Cancel',
                confirmLabel: 'Confirm',
                onCancel: () => actionTap++,
                onConfirm: () => actionTap++,
              ),
              TasklyFormSelectorRow(
                label: 'Priority',
                child: const Text('Child'),
              ),
              TasklyFormSectionLabel(text: 'details'),
              TasklyFormNotesContainer(
                child: const Text('Notes'),
              ),
              TasklyFormDateCard(
                rows: [
                  TasklyFormDateRow(
                    icon: Icons.calendar_today,
                    label: 'Start',
                    placeholderLabel: 'None',
                    valueLabel: '2026-02-22',
                    hasValue: true,
                    onTap: () => actionTap++,
                    onClear: () => actionTap++,
                  ),
                ],
              ),
              TasklyFormPrioritySegmented(
                segments: const [
                  TasklyFormPrioritySegment(label: 'P1', value: 1),
                  TasklyFormPrioritySegment(label: 'P2', value: 2),
                ],
                value: selectedPriority,
                onChanged: (value) => selectedPriority = value ?? 0,
              ),
              TasklyFormStepper(
                value: stepperValue,
                min: 1,
                max: 3,
                onChanged: (value) => stepperValue = value,
              ),
              TasklyFormChoiceGrid(
                values: const [1, 2, 3],
                isSelected: (value) => value == 2,
                labelBuilder: (value) => '$value',
                onTap: (_) => actionTap++,
              ),
              TasklyFormColorPalettePicker(
                colors: const [Colors.red, Colors.blue],
                selectedColor: selectedColor,
                onSelected: (color) => selectedColor = color,
              ),
              TasklyFormQuickPickChips(
                items: [
                  TasklyFormQuickPickItem(
                    label: 'Today',
                    onTap: () => actionTap++,
                    emphasized: true,
                  ),
                ],
                preset: _formPreset,
              ),
              TasklyFormInlineChip(
                label: 'Add',
                icon: Icons.add,
                onTap: () => actionTap++,
                preset: _chipPreset,
                valueLabel: 'Set',
                hasValue: true,
              ),
              TasklyFormRecurrenceChip(
                onTap: () => actionTap++,
                onClear: () => actionTap++,
                emptyLabel: 'Repeat',
                hasValue: true,
                valueLabel: 'Every day',
                preset: _chipPreset,
              ),
              TasklyFormChipRow(
                chips: const [Chip(label: Text('A'))],
              ),
              TasklyFormRowGroup(
                children: const [Chip(label: Text('B'))],
              ),
              TasklyFormValueChip(
                model: const TasklyFormValueChipModel(
                  label: 'Health',
                  color: Colors.green,
                  icon: Icons.favorite,
                ),
                onTap: () => actionTap++,
                isSelected: true,
                isPrimary: true,
                preset: _chipPreset,
              ),
              const PriorityPill(priority: 1),
              const MetaIconLabel(
                icon: Icons.timer,
                label: 'Soon',
                color: Colors.orange,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Cancel'));
    await tester.tap(find.text('Confirm'));
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(actionTap, greaterThanOrEqualTo(2));
    expect(stepperValue, 2);
    expect(selectedPriority, 1);
    expect(selectedColor, Colors.red);
    expect(find.byType(TasklyFormValueChip), findsOneWidget);
    expect(find.byType(TasklyFormRecurrenceChip), findsOneWidget);
  });

  testWidgets('renders form builder field wrappers and updates values', (
    tester,
  ) async {
    _Mode? selectedMode;
    double? sliderValue;
    bool? switchValue;

    await tester.pumpWidget(
      _host(
        SingleChildScrollView(
          child: Column(
            children: [
              const TasklyFormTitleField(
                name: 'title',
                hintText: 'Title',
                maxLength: 20,
              ),
              const TasklyFormNotesField(
                name: 'notes',
                hintText: 'Notes',
                contentPadding: EdgeInsets.all(8),
                minLines: 2,
                maxLines: 3,
              ),
              FormBuilderEnumRadioGroup<_Mode>(
                name: 'mode',
                values: _Mode.values,
                labelBuilder: (value) => value.name,
                descriptionBuilder: (value) => 'desc ${value.name}',
                onChanged: (value) => selectedMode = value,
              ),
              FormBuilderSegmentedField<_Mode>(
                name: 'seg',
                values: _Mode.values,
                initialValue: _Mode.one,
                labelBuilder: (value) => Text(value.name),
                onChanged: (value) => selectedMode = value,
              ),
              FormBuilderSliderField(
                name: 'slider',
                min: 0,
                max: 1,
                unit: '%',
                onChanged: (value) => sliderValue = value,
              ),
              FormBuilderSwitchTile(
                name: 'switch',
                title: 'Enabled',
                onChanged: (value) => switchValue = value,
              ),
            ],
          ),
        ),
      ),
    );

    final radio = tester.widget<RadioListTile<_Mode>>(
      find.byType(RadioListTile<_Mode>).last,
    );
    radio.onChanged?.call(_Mode.two);
    await tester.pump();

    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged?.call(1);
    await tester.pump();

    final switchTile = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    switchTile.onChanged?.call(true);
    await tester.pump();

    expect(selectedMode, isNotNull);
    expect(sliderValue, 1.0);
    expect(switchValue, isTrue);
  });

  testWidgets('renders TasklyFormSheet with title and content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TasklyFormSheet(
            title: 'Sheet title',
            preset: _formPreset,
            child: const SizedBox(height: 200, child: Text('Sheet body')),
          ),
        ),
      ),
    );

    expect(find.text('Sheet title'), findsOneWidget);
    expect(find.text('Sheet body'), findsOneWidget);
  });
}
