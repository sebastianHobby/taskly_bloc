@Tags(['widget', 'journal'])
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_hub_page.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/services.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/feature_mocks.dart';
import '../../../mocks/presentation_mocks.dart';

class FakeNowService implements NowService {
  FakeNowService(this.now);

  final DateTime now;

  @override
  DateTime nowLocal() => now;

  @override
  DateTime nowUtc() => now.toUtc();
}

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
  late BehaviorSubject<List<TrackerEvent>> eventsSubject;
  late BehaviorSubject<List<TrackerStateDay>> dayStatesSubject;

  setUp(() {
    repository = MockJournalRepositoryContract();
    homeDayKeyService = MockHomeDayKeyService();
    defsSubject = BehaviorSubject<List<TrackerDefinition>>();
    entriesSubject = BehaviorSubject<List<JournalEntry>>();
    eventsSubject = BehaviorSubject<List<TrackerEvent>>();
    dayStatesSubject = BehaviorSubject<List<TrackerStateDay>>();

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
      () => repository.watchTrackerEvents(
        range: any(named: 'range'),
        anchorType: any(named: 'anchorType'),
        entryId: any(named: 'entryId'),
        anchorDate: any(named: 'anchorDate'),
        trackerId: any(named: 'trackerId'),
      ),
    ).thenAnswer((_) => eventsSubject);
    when(
      () => repository.watchTrackerStateDay(range: any(named: 'range')),
    ).thenAnswer((_) => dayStatesSubject);
  });

  tearDown(() async {
    await defsSubject.close();
    await entriesSubject.close();
    await eventsSubject.close();
    await dayStatesSubject.close();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/journal',
      routes: [
        GoRoute(
          path: '/journal',
          builder: (_, __) => MultiRepositoryProvider(
            providers: [
              RepositoryProvider<JournalRepositoryContract>.value(
                value: repository,
              ),
              RepositoryProvider<NowService>.value(
                value: FakeNowService(DateTime(2025, 1, 15, 9)),
              ),
              RepositoryProvider<HomeDayKeyService>.value(
                value: homeDayKeyService,
              ),
            ],
            child: const JournalHubPage(),
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

  testWidgetsSafe('renders content when loaded', (tester) async {
    final day = DateTime(2025, 1, 15);
    final entry = _entry(day, text: 'Morning note');
    final moodDef = _trackerDef('mood', 'Mood', systemKey: 'mood');
    final moodEvent = _event('event-1', 'mood', entry.id, 4, day);
    final dayState = _dayState('state-1', 'mood', day, 4);

    defsSubject.add([moodDef]);
    entriesSubject.add([entry]);
    eventsSubject.add([moodEvent]);
    dayStatesSubject.add([dayState]);

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.text('Morning note'), findsOneWidget);
    expect(find.byTooltip('Add entry'), findsOneWidget);
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
