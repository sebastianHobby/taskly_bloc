@Tags(['widget', 'journal'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_today_page.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/queries.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/feature_mocks.dart';

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockJournalRepositoryContract repository;
  late BehaviorSubject<List<TrackerDefinition>> defsSubject;
  late BehaviorSubject<List<JournalEntry>> entriesSubject;
  late BehaviorSubject<List<TrackerEvent>> eventsSubject;
  late BehaviorSubject<List<TrackerEvent>> weekEventsSubject;
  late BehaviorSubject<List<TrackerStateDay>> dayStatesSubject;

  setUp(() {
    repository = MockJournalRepositoryContract();
    defsSubject = BehaviorSubject<List<TrackerDefinition>>();
    entriesSubject = BehaviorSubject<List<JournalEntry>>();
    eventsSubject = BehaviorSubject<List<TrackerEvent>>();
    weekEventsSubject = BehaviorSubject<List<TrackerEvent>>();
    dayStatesSubject = BehaviorSubject<List<TrackerStateDay>>();

    when(
      () => repository.watchTrackerDefinitions(),
    ).thenAnswer((_) => defsSubject);
    when(
      () => repository.watchJournalEntriesByQuery(any()),
    ).thenAnswer((_) => entriesSubject);
    when(
      () => repository.watchTrackerEvents(
        range: any(named: 'range'),
        anchorType: any(named: 'anchorType'),
        entryId: any(named: 'entryId'),
        anchorDate: any(named: 'anchorDate'),
        trackerId: any(named: 'trackerId'),
      ),
    ).thenAnswer((invocation) {
      final range = invocation.namedArguments[#range] as DateRange?;
      if (range != null && range.end.difference(range.start).inDays >= 6) {
        return weekEventsSubject;
      }
      return eventsSubject;
    });
    when(
      () => repository.watchTrackerStateDay(range: any(named: 'range')),
    ).thenAnswer((_) => dayStatesSubject);
  });

  tearDown(() async {
    await defsSubject.close();
    await entriesSubject.close();
    await eventsSubject.close();
    await weekEventsSubject.close();
    await dayStatesSubject.close();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpApp(
      RepositoryProvider.value(
        value: repository,
        child: JournalTodayPage(day: DateTime(2025, 1, 15)),
      ),
    );
  }

  testWidgetsSafe('shows loading state before streams emit', (tester) async {
    await pumpPage(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgetsSafe('shows error state when streams fail', (tester) async {
    when(
      () => repository.watchTrackerDefinitions(),
    ).thenAnswer((_) => Stream<List<TrackerDefinition>>.error('boom'));

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.textContaining('Failed to load Journal data'), findsOneWidget);
  });

  testWidgetsSafe('renders journal entries when loaded', (tester) async {
    final day = DateTime(2025, 1, 15);
    final entry = _entry(day, text: 'Nice day');
    final moodDef = _trackerDef('mood', 'Mood', systemKey: 'mood');
    final moodEvent = _event('event-1', 'mood', entry.id, 4, day);
    final dayState = _dayState('state-1', 'mood', day, 4);

    defsSubject.add([moodDef]);
    entriesSubject.add([entry]);
    eventsSubject.add([moodEvent]);
    weekEventsSubject.add([moodEvent]);
    dayStatesSubject.add([dayState]);

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.text('Daily summary'), findsOneWidget);
    expect(find.text('Entries'), findsOneWidget);
    expect(find.text('Nice day'), findsOneWidget);
  });

  testWidgetsSafe('updates list when entries change', (tester) async {
    final day = DateTime(2025, 1, 15);
    final entryA = _entry(day, text: 'First');
    final entryB = _entry(day, id: 'entry-2', text: 'Second');
    final moodDef = _trackerDef('mood', 'Mood', systemKey: 'mood');
    final moodEvent = _event('event-1', 'mood', entryA.id, 3, day);
    final dayState = _dayState('state-1', 'mood', day, 3);

    defsSubject.add([moodDef]);
    entriesSubject.add([entryA]);
    eventsSubject.add([moodEvent]);
    weekEventsSubject.add([moodEvent]);
    dayStatesSubject.add([dayState]);

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.text('First'), findsOneWidget);

    entriesSubject.add([entryA, entryB]);
    await tester.pumpForStream();

    expect(find.text('Second'), findsOneWidget);
  });
}

JournalEntry _entry(DateTime day, {String? id, String? text}) {
  final when = DateTime(day.year, day.month, day.day, 9);
  return JournalEntry(
    id: id ?? 'entry-1',
    entryDate: day,
    entryTime: when,
    occurredAt: when,
    localDate: day,
    createdAt: when,
    updatedAt: when,
    journalText: text,
  );
}

TrackerDefinition _trackerDef(
  String id,
  String name, {
  String? systemKey,
}) {
  final now = DateTime(2025, 1, 15);
  return TrackerDefinition(
    id: id,
    name: name,
    scope: 'day',
    valueType: 'rating',
    createdAt: now,
    updatedAt: now,
    systemKey: systemKey,
  );
}

TrackerEvent _event(
  String id,
  String trackerId,
  String entryId,
  Object value,
  DateTime when,
) {
  return TrackerEvent(
    id: id,
    trackerId: trackerId,
    anchorType: 'entry',
    op: 'set',
    occurredAt: when,
    recordedAt: when,
    entryId: entryId,
    value: value,
  );
}

TrackerStateDay _dayState(
  String id,
  String trackerId,
  DateTime day,
  Object value,
) {
  return TrackerStateDay(
    id: id,
    anchorType: 'day',
    anchorDate: day,
    trackerId: trackerId,
    updatedAt: day,
    value: value,
  );
}
