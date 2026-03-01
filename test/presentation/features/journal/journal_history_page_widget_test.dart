@Tags(['widget', 'journal'])
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_history_page.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
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
  late BehaviorSubject<List<TrackerGroup>> groupsSubject;
  late BehaviorSubject<List<JournalEntry>> entriesSubject;
  late BehaviorSubject<List<TrackerEvent>> eventsSubject;

  setUp(() {
    repository = MockJournalRepositoryContract();
    homeDayKeyService = MockHomeDayKeyService();
    settingsRepository = MockSettingsRepositoryContract();
    defsSubject = BehaviorSubject<List<TrackerDefinition>>.seeded(const []);
    groupsSubject = BehaviorSubject<List<TrackerGroup>>.seeded(const []);
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
    ).thenAnswer((_) => groupsSubject);
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
      () => settingsRepository.load(
        SettingsKey.microLearningSeen('journal_starter_pack_start_01b'),
      ),
    ).thenAnswer((_) async => true);
    when(
      () => settingsRepository.load(
        SettingsKey.pageDisplay(PageKey.journal),
      ),
    ).thenAnswer((_) async => null);
    when(
      () => settingsRepository.load(
        SettingsKey.pageJournalFilters(PageKey.journal),
      ),
    ).thenAnswer((_) async => null);
    when(
      () => settingsRepository.save<JournalHistoryFilterPreferences?>(
        SettingsKey.pageJournalFilters(PageKey.journal),
        any<JournalHistoryFilterPreferences?>(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => settingsRepository.save<JournalHistoryFilterPreferences?>(
        SettingsKey.pageJournalFilters(PageKey.journal),
        any<JournalHistoryFilterPreferences?>(),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await defsSubject.close();
    await groupsSubject.close();
    await entriesSubject.close();
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
            child: const JournalHistoryPage(),
          ),
        ),
      ],
    );

    await tester.pumpWidgetWithRouter(router: router);
  }

  testWidgetsSafe('applied filters can be reset', (tester) async {
    when(
      () => settingsRepository.load(
        SettingsKey.pageJournalFilters(PageKey.journal),
      ),
    ).thenAnswer(
      (_) async => JournalHistoryFilterPreferences(
        rangeStartIsoDayUtc: '2025-01-10',
        rangeEndIsoDayUtc: '2025-01-10',
        factorTrackerIds: const <String>[],
        factorGroupId: null,
        lookbackDays: 30,
      ),
    );

    final moodDef = TrackerDefinition(
      id: 'mood',
      name: 'Mood',
      scope: 'entry',
      valueType: 'rating',
      createdAt: DateTime(2025, 1, 10),
      updatedAt: DateTime(2025, 1, 10),
      systemKey: 'mood',
    );
    defsSubject.add([moodDef]);
    entriesSubject.add([_entry(DateTime(2025, 1, 10), text: 'Note')]);
    eventsSubject.add([
      _event('mood-1', 'mood', 'entry-1', 4, DateTime(2025, 1, 10)),
    ]);

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.text('Applied filters'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pumpForStream();

    expect(find.text('Applied filters'), findsNothing);
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
