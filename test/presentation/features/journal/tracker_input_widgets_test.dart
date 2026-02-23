@Tags(['widget', 'journal'])
library;

import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/tracker_input_widgets.dart';
import 'package:taskly_domain/journal.dart';

import '../../../helpers/test_imports.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testWidgetsSafe('TrackerChoiceInput renders chips and toggles selection', (
    tester,
  ) async {
    String? selected;
    final choices = [
      _choice('home', 'Home'),
      _choice('work', 'Work'),
    ];

    await tester.pumpApp(
      Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            return TrackerChoiceInput(
              choices: choices,
              selectedKey: selected,
              enabled: true,
              onSelected: (value) => setState(() => selected = value),
            );
          },
        ),
      ),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Home'));
    await tester.pumpForStream();

    expect(selected, 'home');
  });

  testWidgetsSafe('TrackerChoiceInput opens bottom sheet for long lists', (
    tester,
  ) async {
    String? selected;
    final choices = [
      for (final label in [
        'Home',
        'Work',
        'Gym',
        'Travel',
        'Social',
        'Cafe',
        'Park',
      ])
        _choice(label.toLowerCase(), label),
    ];

    await tester.pumpApp(
      Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            return TrackerChoiceInput(
              choices: choices,
              selectedKey: selected,
              enabled: true,
              onSelected: (value) => setState(() => selected = value),
            );
          },
        ),
      ),
    );

    final trigger = find.byType(ListTile);
    await tester.ensureVisible(trigger);
    await tester.tap(trigger, warnIfMissed: false);
    await tester.pumpForStream();

    expect(find.text('Work'), findsOneWidget);
    final workTile = find.widgetWithText(ListTile, 'Work');
    await tester.ensureVisible(workTile);
    await tester.pumpUntilCondition(
      () => workTile.hitTestable().evaluate().isNotEmpty,
    );
    await tester.tap(workTile.hitTestable().first, warnIfMissed: false);
    await tester.pumpForStream();

    expect(selected, 'work');
  });

  testWidgetsSafe('TrackerQuantityInput clamps with stepper controls', (
    tester,
  ) async {
    var value = 0;

    await tester.pumpApp(
      Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            return TrackerQuantityInput(
              value: value,
              min: 0,
              max: 4,
              step: 2,
              enabled: true,
              onChanged: (next) => setState(() => value = next),
            );
          },
        ),
      ),
    );

    final addButton = find.byIcon(Icons.add);
    await tester.tap(addButton);
    await tester.pumpForStream();
    await tester.tap(addButton);
    await tester.pumpForStream();
    await tester.tap(addButton);
    await tester.pumpForStream();

    expect(value, 4);
  });

  testWidgetsSafe('TrackerQuantityInput edit sheet can clear value', (
    tester,
  ) async {
    var value = 3;

    await tester.pumpApp(
      Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            return TrackerQuantityInput(
              value: value,
              enabled: true,
              onChanged: (next) => setState(() => value = next),
              onClear: () => setState(() => value = 0),
            );
          },
        ),
      ),
    );

    await tester.tap(find.widgetWithText(TextButton, '3'));
    await tester.pumpForStream();

    final clear = find.text('Clear');
    await tester.ensureVisible(clear);
    await tester.pumpUntilCondition(
      () => clear.hitTestable().evaluate().isNotEmpty,
    );
    await tester.tap(clear.hitTestable().first, warnIfMissed: false);
    await tester.pumpForStream();

    expect(value, 0);
  });
}

TrackerDefinitionChoice _choice(String key, String label) {
  final now = DateTime.utc(2025, 1, 1);
  return TrackerDefinitionChoice(
    id: 'choice-$key',
    trackerId: 'tracker-1',
    choiceKey: key,
    label: label,
    createdAt: now,
    updatedAt: now,
    sortOrder: 0,
    isActive: true,
    userId: null,
  );
}
