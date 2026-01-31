@Tags(['widget', 'journal'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_history_page.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/services.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/feature_mocks.dart';
import '../../../mocks/presentation_mocks.dart';

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockJournalRepositoryContract repository;
  late MockHomeDayKeyService homeDayKeyService;
  late BehaviorSubject<List<TrackerDefinition>> defsSubject;
  late BehaviorSubject<List<JournalEntry>> entriesSubject;
  late BehaviorSubject<List<TrackerStateDay>> dayStatesSubject;
  late BehaviorSubject<List<TrackerEvent>> eventsSubject;

  setUp(() {
    repository = MockJournalRepositoryContract();
    homeDayKeyService = MockHomeDayKeyService();
    defsSubject = BehaviorSubject<List<TrackerDefinition>>();
    entriesSubject = BehaviorSubject<List<JournalEntry>>();
    dayStatesSubject = BehaviorSubject<List<TrackerStateDay>>();
    eventsSubject = BehaviorSubject<List<TrackerEvent>>();

    when(
      () => homeDayKeyService.todayDayKeyUtc(),
    ).thenReturn(DateTime.utc(2025, 1, 15));

    when(
      () => repository.watchTrackerDefinitions(),
    ).thenAnswer((_) => defsSubject);
    when(
      () => repository.watchJournalEntriesByQuery(any()),
    ).thenAnswer((_) => entriesSubject);
    when(
      () => repository.watchTrackerStateDay(range: any(named: 'range')),
    ).thenAnswer((_) => dayStatesSubject);
    when(
      () => repository.watchTrackerEvents(
        range: any(named: 'range'),
        anchorType: any(named: 'anchorType'),
        entryId: any(named: 'entryId'),
        anchorDate: any(named: 'anchorDate'),
        trackerId: any(named: 'trackerId'),
      ),
    ).thenAnswer((_) => eventsSubject);
  });

  tearDown(() async {
    await defsSubject.close();
    await entriesSubject.close();
    await dayStatesSubject.close();
    await eventsSubject.close();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/journal/history',
      routes: [
        GoRoute(
          path: '/journal/history',
          builder: (_, __) => MultiRepositoryProvider(
            providers: [
              RepositoryProvider<JournalRepositoryContract>.value(
                value: repository,
              ),
              RepositoryProvider<HomeDayKeyService>.value(
                value: homeDayKeyService,
              ),
            ],
            child: const JournalHistoryPage(),
          ),
        ),
      ],
    );

    await tester.pumpWidgetWithRouter(router: router);
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

    expect(find.textContaining('Failed to load history'), findsOneWidget);
  });

  testWidgetsSafe('renders history content when loaded', (tester) async {
    final day = DateTime.utc(2025, 1, 15);
    final entry = _entry(day, text: 'Note 1');
    final moodDef = _trackerDef('mood', 'Mood', systemKey: 'mood');
    final moodEvent = _event('event-1', 'mood', entry.id, 4, day);
    final dayState = _dayState('state-1', 'mood', day, 4);

    defsSubject.add([moodDef]);
    entriesSubject.add([entry]);
    dayStatesSubject.add([dayState]);
    eventsSubject.add([moodEvent]);

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.text('History'), findsOneWidget);
    expect(find.text('Note 1'), findsOneWidget);
  });

  testWidgetsSafe('updates list when entries change', (tester) async {
    final day = DateTime.utc(2025, 1, 15);
    final entryA = _entry(day, text: 'Entry A');
    final entryB = _entry(day, id: 'entry-2', text: 'Entry B');
    final moodDef = _trackerDef('mood', 'Mood', systemKey: 'mood');

    defsSubject.add([moodDef]);
    entriesSubject.add([entryA]);
    dayStatesSubject.add([_dayState('state-1', 'mood', day, 3)]);
    eventsSubject.add([_event('event-1', 'mood', entryA.id, 3, day)]);

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.text('Entry A'), findsOneWidget);

    entriesSubject.add([entryA, entryB]);
    eventsSubject.add([
      _event('event-1', 'mood', entryA.id, 3, day),
      _event('event-2', 'mood', entryB.id, 5, day),
    ]);
    await tester.pumpForStream();

    expect(find.text('Entry B'), findsOneWidget);
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
