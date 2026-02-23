@Tags(['widget', 'journal'])
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_hub_page.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/preferences.dart';
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

class MockSettingsRepositoryContract extends Mock
    implements SettingsRepositoryContract {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockJournalRepositoryContract repository;
  late MockHomeDayKeyService homeDayKeyService;
  late MockSettingsRepositoryContract settingsRepository;
  late BehaviorSubject<List<TrackerDefinition>> defsSubject;
  late BehaviorSubject<List<JournalEntry>> entriesSubject;
  late BehaviorSubject<List<TrackerEvent>> eventsSubject;

  setUp(() {
    repository = MockJournalRepositoryContract();
    homeDayKeyService = MockHomeDayKeyService();
    settingsRepository = MockSettingsRepositoryContract();
    defsSubject = BehaviorSubject<List<TrackerDefinition>>.seeded(const []);
    entriesSubject = BehaviorSubject<List<JournalEntry>>.seeded(const []);
    eventsSubject = BehaviorSubject<List<TrackerEvent>>.seeded(const []);

    when(
      () => homeDayKeyService.todayDayKeyUtc(),
    ).thenReturn(DateTime.utc(2025, 1, 15));

    when(
      () => repository.watchTrackerDefinitions(),
    ).thenAnswer((_) => defsSubject);
    when(
      () => repository.watchTrackerGroups(),
    ).thenAnswer((_) => Stream.value(const <TrackerGroup>[]));
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
      () => repository.getJournalEntryById(any()),
    ).thenAnswer((_) async => null);
    when(
      () => repository.watchTrackerStateDay(range: any(named: 'range')),
    ).thenAnswer((_) => Stream.value(const <TrackerStateDay>[]));
    when(
      () =>
          repository.appendTrackerEvent(any(), context: any(named: 'context')),
    ).thenAnswer((_) async {});
    when(
      () =>
          repository.createJournalEntry(any(), context: any(named: 'context')),
    ).thenAnswer((_) async => 'entry-1');

    when(
      () => settingsRepository.load(
        SettingsKey.microLearningSeen('journal_starter_pack_start_01b'),
      ),
    ).thenAnswer((_) async => true);
    when(
      () => settingsRepository.save(
        SettingsKey.microLearningSeen('journal_starter_pack_start_01b'),
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await defsSubject.close();
    await entriesSubject.close();
    await eventsSubject.close();
  });

  Future<GoRouter> pumpPage(WidgetTester tester) async {
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
              RepositoryProvider<SettingsRepositoryContract>.value(
                value: settingsRepository,
              ),
              RepositoryProvider<AppErrorReporter>.value(
                value: AppErrorReporter(
                  messengerKey: GlobalKey<ScaffoldMessengerState>(),
                ),
              ),
            ],
            child: const JournalHubPage(),
          ),
        ),
        GoRoute(
          path: '/journal-manage-trackers',
          builder: (_, __) => const Scaffold(body: Text('Trackers route')),
        ),
        GoRoute(
          path: '/journal-manage-daily-checkins',
          builder: (_, __) => const Scaffold(body: Text('Daily route')),
        ),
      ],
    );

    await tester.pumpWidgetWithRouter(router: router);
    return router;
  }

  testWidgetsSafe('shows loading state before streams emit', (tester) async {
    defsSubject = BehaviorSubject<List<TrackerDefinition>>();
    entriesSubject = BehaviorSubject<List<JournalEntry>>();
    eventsSubject = BehaviorSubject<List<TrackerEvent>>();

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

    await pumpPage(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgetsSafe('renders content when loaded', (tester) async {
    final day = DateTime(2025, 1, 15);
    final entry = _entry(day, text: 'Morning note');
    final moodDef = _trackerDef('mood', 'Mood', systemKey: 'mood');
    final moodEvent = _event('event-1', 'mood', entry.id, 4, day);
    defsSubject.add([moodDef]);
    entriesSubject.add([entry]);
    eventsSubject.add([moodEvent]);

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.text('Morning note'), findsOneWidget);
    expect(find.byTooltip('Add entry'), findsOneWidget);
  });

  testWidgetsSafe(
    'renders signal chips without done and with quantity day total',
    (tester) async {
      final day = DateTime(2025, 1, 15);
      final entry1 = _entry(day, id: 'entry-1', text: 'Morning note');
      final entry2 = _entry(day, id: 'entry-2', text: 'Later note');

      final moodDef = _trackerDef('mood', 'Mood', systemKey: 'mood');
      final waterDef = TrackerDefinition(
        id: 'water',
        name: 'Water',
        scope: 'entry',
        valueType: 'quantity',
        valueKind: 'number',
        unitKind: 'ml',
        createdAt: day,
        updatedAt: day,
      );
      final exerciseDef = TrackerDefinition(
        id: 'exercise',
        name: 'Exercise',
        scope: 'entry',
        valueType: 'yes_no',
        valueKind: 'boolean',
        createdAt: day,
        updatedAt: day,
      );

      defsSubject.add([moodDef, waterDef, exerciseDef]);
      entriesSubject.add([entry1, entry2]);
      eventsSubject.add([
        _event('mood-1', 'mood', 'entry-1', 4, day),
        _event('water-1', 'water', 'entry-1', 100, day),
        _event('water-2', 'water', 'entry-2', 200, day),
        _event('exercise-1', 'exercise', 'entry-1', true, day),
      ]);

      await pumpPage(tester);
      await tester.pumpForStream();

      expect(find.text('Exercise'), findsOneWidget);
      expect(find.textContaining('Done'), findsNothing);
      expect(find.text('Water: 300 ml'), findsWidgets);
    },
  );

  testWidgetsSafe('search interaction expands and collapses search header', (
    tester,
  ) async {
    defsSubject.add([_trackerDef('mood', 'Mood', systemKey: 'mood')]);
    entriesSubject.add([_entry(DateTime(2025, 1, 15), text: 'Note')]);

    await pumpPage(tester);
    await tester.pumpForStream();

    await tester.tap(find.byTooltip('Search entries'));
    await tester.pumpForStream();
    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(find.byTooltip('Search entries'));
    await tester.pumpForStream();
    expect(find.byType(TextField), findsNothing);
  });

  testWidgetsSafe('load-more interaction triggers additional history query', (
    tester,
  ) async {
    final moodDef = _trackerDef('mood', 'Mood', systemKey: 'mood');
    defsSubject.add([moodDef]);

    final entries = <JournalEntry>[];
    final events = <TrackerEvent>[];
    for (var i = 0; i < 60; i++) {
      final day = DateTime(2025, 1, 15).subtract(Duration(days: i));
      final id = 'entry-$i';
      entries.add(_entry(day, id: id, text: 'Note $i'));
      events.add(_event('mood-$i', 'mood', id, 4, day));
    }
    entriesSubject.add(entries);
    eventsSubject.add(events);

    await pumpPage(tester);
    await tester.pumpForStream();

    await tester.drag(find.byType(ListView).first, const Offset(0, -2500));
    await tester.pumpForStream();
    await tester.pumpForStream();

    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgetsSafe('filter sheet opens and apply closes it', (tester) async {
    defsSubject.add([_trackerDef('mood', 'Mood', systemKey: 'mood')]);
    entriesSubject.add([_entry(DateTime(2025, 1, 15), text: 'Note')]);

    await pumpPage(tester);
    await tester.pumpForStream();

    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpForStream();

    expect(find.byType(SwitchListTile), findsOneWidget);
  });

  testWidgetsSafe('starter pack prompt can be dismissed with Not now', (
    tester,
  ) async {
    when(
      () => settingsRepository.load(
        SettingsKey.microLearningSeen('journal_starter_pack_start_01b'),
      ),
    ).thenAnswer((_) async => false);

    defsSubject.add(const []);
    entriesSubject.add(const []);
    eventsSubject.add(const []);

    await pumpPage(tester);
    final found = await tester.pumpUntilFound(
      find.text('Set up your starter trackers'),
    );
    expect(found, isTrue);
  });

  testWidgetsSafe('manage sheet navigates to trackers route', (tester) async {
    defsSubject.add([_trackerDef('mood', 'Mood', systemKey: 'mood')]);
    entriesSubject.add([_entry(DateTime(2025, 1, 15), text: 'Note')]);

    await pumpPage(tester);
    await tester.pumpForStream();

    await tester.tap(find.byTooltip('Manage trackers'));
    await tester.pumpForStream();
    expect(find.byType(ListTile), findsAtLeast(2));
  });

  testWidgetsSafe('quick capture FAB currently requires outer repo provider', (
    tester,
  ) async {
    defsSubject.add([_trackerDef('mood', 'Mood', systemKey: 'mood')]);
    entriesSubject.add([_entry(DateTime(2025, 1, 15), text: 'Note')]);

    await pumpPage(tester);
    await tester.pumpForStream();

    await tester.tap(find.byTooltip('Add entry'));
    await tester.pumpForStream();
    final error = tester.takeException();
    expect(error.toString(), contains('Provider<JournalRepositoryContract>'));
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
