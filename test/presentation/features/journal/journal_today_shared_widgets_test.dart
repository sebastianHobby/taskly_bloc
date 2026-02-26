@Tags(['widget', 'journal'])
library;

import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/journal_today_shared_widgets.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/preferences.dart';

import '../../../helpers/test_imports.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testWidgetsSafe(
    'JournalLogCard deduplicates by tracker and uses day quantity totals',
    (
      tester,
    ) async {
      final day = DateTime(2025, 1, 15, 9);
      final entry = JournalEntry(
        id: 'entry-1',
        entryDate: day,
        entryTime: day,
        occurredAt: day,
        localDate: day,
        createdAt: day,
        updatedAt: day,
        journalText: 'Morning note',
      );

      final defs = {
        'mood': TrackerDefinition(
          id: 'mood',
          name: 'Mood',
          scope: 'entry',
          valueType: 'rating',
          createdAt: day,
          updatedAt: day,
          systemKey: 'mood',
        ),
        'water': TrackerDefinition(
          id: 'water',
          name: 'Water',
          scope: 'entry',
          valueType: 'quantity',
          valueKind: 'number',
          unitKind: 'ml',
          createdAt: day,
          updatedAt: day,
        ),
        'exercise': TrackerDefinition(
          id: 'exercise',
          name: 'Exercise',
          scope: 'entry',
          valueType: 'yes_no',
          valueKind: 'boolean',
          createdAt: day,
          updatedAt: day,
        ),
      };

      final events = [
        TrackerEvent(
          id: 'mood-1',
          trackerId: 'mood',
          anchorType: 'entry',
          entryId: 'entry-1',
          op: 'set',
          value: 4,
          occurredAt: day,
          recordedAt: day,
        ),
        TrackerEvent(
          id: 'water-1',
          trackerId: 'water',
          anchorType: 'entry',
          entryId: 'entry-1',
          op: 'add',
          value: 100,
          occurredAt: day,
          recordedAt: day,
        ),
        TrackerEvent(
          id: 'water-2',
          trackerId: 'water',
          anchorType: 'entry',
          entryId: 'entry-1',
          op: 'add',
          value: 200,
          occurredAt: day.add(const Duration(minutes: 1)),
          recordedAt: day.add(const Duration(minutes: 1)),
        ),
        TrackerEvent(
          id: 'exercise-1',
          trackerId: 'exercise',
          anchorType: 'entry',
          entryId: 'entry-1',
          op: 'set',
          value: true,
          occurredAt: day,
          recordedAt: day,
        ),
      ];

      await tester.pumpApp(
        Scaffold(
          body: JournalLogCard(
            entry: entry,
            events: events,
            definitionById: defs,
            moodTrackerId: 'mood',
            dayQuantityTotalsByTrackerId: const <String, double>{'water': 300},
            density: DisplayDensity.standard,
            onTap: () {},
          ),
        ),
      );

      await tester.pumpForStream();

      expect(find.text('Morning note'), findsOneWidget);
      expect(find.text('Exercise'), findsOneWidget);
      expect(find.text('Water: 300 ml'), findsOneWidget);
    },
  );

  testWidgetsSafe('JournalLogCard collapses chips to +more indicator', (
    tester,
  ) async {
    final day = DateTime(2025, 1, 15, 9);
    final entry = JournalEntry(
      id: 'entry-1',
      entryDate: day,
      entryTime: day,
      occurredAt: day,
      localDate: day,
      createdAt: day,
      updatedAt: day,
    );

    final defs = {
      for (final id in ['a', 'b', 'c', 'd', 'e'])
        id: TrackerDefinition(
          id: id,
          name: 'Tracker $id',
          scope: 'entry',
          valueType: 'yes_no',
          valueKind: 'boolean',
          createdAt: day,
          updatedAt: day,
        ),
    };

    final events = [
      for (final id in ['a', 'b', 'c', 'd', 'e'])
        TrackerEvent(
          id: 'event-$id',
          trackerId: id,
          anchorType: 'entry',
          entryId: 'entry-1',
          op: 'set',
          value: true,
          occurredAt: day,
          recordedAt: day,
        ),
    ];

    await tester.pumpApp(
      Scaffold(
        body: JournalLogCard(
          entry: entry,
          events: events,
          definitionById: defs,
          moodTrackerId: null,
          dayQuantityTotalsByTrackerId: const <String, double>{},
          density: DisplayDensity.standard,
          onTap: () {},
        ),
      ),
    );

    await tester.pumpForStream();

    expect(find.textContaining('+'), findsOneWidget);
  });
}
