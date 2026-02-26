@Tags(['widget', 'journal', 'golden'])
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_hub_page.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_insights_page.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_entry_editor_route_page.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/theme/app_theme.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/services.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/feature_mocks.dart';
import '../../../mocks/presentation_mocks.dart';

class _FakeNowService implements NowService {
  _FakeNowService(this.now);

  final DateTime now;

  @override
  DateTime nowLocal() => now;

  @override
  DateTime nowUtc() => now.toUtc();
}

class _MockSettingsRepositoryContract extends Mock
    implements SettingsRepositoryContract {}

void main() {
  setUpAll(() async {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });

  setUp(setUpTestEnvironment);

  late MockJournalRepositoryContract repository;
  late MockHomeDayKeyService homeDayKeyService;
  late _MockSettingsRepositoryContract settingsRepository;
  late BehaviorSubject<List<TrackerDefinition>> defsSubject;
  late BehaviorSubject<List<JournalEntry>> entriesSubject;
  late BehaviorSubject<List<TrackerEvent>> eventsSubject;
  late BehaviorSubject<List<TrackerGroup>> groupsSubject;

  setUp(() {
    repository = MockJournalRepositoryContract();
    homeDayKeyService = MockHomeDayKeyService();
    settingsRepository = _MockSettingsRepositoryContract();
    defsSubject = BehaviorSubject<List<TrackerDefinition>>.seeded(const []);
    entriesSubject = BehaviorSubject<List<JournalEntry>>.seeded(const []);
    eventsSubject = BehaviorSubject<List<TrackerEvent>>.seeded(const []);
    groupsSubject = BehaviorSubject<List<TrackerGroup>>.seeded(const []);

    when(() => homeDayKeyService.todayDayKeyUtc()).thenReturn(
      DateTime.utc(2025, 10, 24),
    );
    when(() => repository.watchTrackerDefinitions()).thenAnswer(
      (_) => defsSubject,
    );
    when(
      () => repository.watchTrackerGroups(),
    ).thenAnswer((_) => groupsSubject);
    when(() => repository.watchJournalEntriesByQuery(any())).thenAnswer(
      (_) => entriesSubject,
    );
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
    ).thenAnswer((_) => Stream.value(const <TrackerStateDay>[]));
    when(
      () => repository.getJournalEntryById(any()),
    ).thenAnswer((_) async => null);
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
      () => settingsRepository.load(SettingsKey.pageDisplay(PageKey.journal)),
    ).thenAnswer((_) async => null);
    when(
      () => settingsRepository.load(
        SettingsKey.pageJournalFilters(PageKey.journal),
      ),
    ).thenAnswer((_) async => null);
    when(
      () => settingsRepository.save(
        SettingsKey.microLearningSeen('journal_starter_pack_start_01b'),
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => settingsRepository.save<DisplayPreferences?>(
        SettingsKey.pageDisplay(PageKey.journal),
        any<DisplayPreferences?>(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => settingsRepository.save<JournalHistoryFilterPreferences?>(
        SettingsKey.pageJournalFilters(PageKey.journal),
        any<JournalHistoryFilterPreferences?>(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await defsSubject.close();
    await entriesSubject.close();
    await eventsSubject.close();
    await groupsSubject.close();
  });

  testWidgetsSafe('journal home and insights dark snapshots', (tester) async {
    final day = DateTime(2025, 10, 24, 8, 30);
    final moodDef = _trackerDef('mood', 'Mood', systemKey: 'mood');
    final waterDef = _trackerDef(
      'water',
      'Water',
      valueType: 'quantity',
      valueKind: 'number',
      unitKind: 'oz',
    );
    final socialDef = _trackerDef('social', 'Social Energy');
    defsSubject.add([moodDef, waterDef, socialDef]);

    final entryA = _entry(day, id: 'entry-a', text: 'Feeling optimistic.');
    final entryB = _entry(
      DateTime(2025, 10, 24, 13, 15),
      id: 'entry-b',
      text: 'Midday coffee break.',
    );
    entriesSubject.add([entryA, entryB]);
    eventsSubject.add([
      _event('mood-a', moodDef.id, entryA.id, 4, day),
      _event(
        'mood-b',
        moodDef.id,
        entryB.id,
        3,
        DateTime(2025, 10, 24, 13, 15),
      ),
      _event('water-a', waterDef.id, entryA.id, 24, day),
      _event(
        'water-b',
        waterDef.id,
        entryB.id,
        24,
        DateTime(2025, 10, 24, 13, 15),
      ),
      _event('social-a', socialDef.id, entryA.id, 4, day),
    ]);

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
                value: _FakeNowService(DateTime(2025, 10, 24, 9)),
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
          path: '/journal/insights',
          builder: (_, __) => MultiRepositoryProvider(
            providers: [
              RepositoryProvider<JournalRepositoryContract>.value(
                value: repository,
              ),
              RepositoryProvider<NowService>.value(
                value: _FakeNowService(DateTime(2025, 10, 24, 9)),
              ),
              RepositoryProvider<HomeDayKeyService>.value(
                value: homeDayKeyService,
              ),
              RepositoryProvider<SettingsRepositoryContract>.value(
                value: settingsRepository,
              ),
            ],
            child: const JournalInsightsPage(),
          ),
        ),
        GoRoute(
          path: '/journal/quick-capture',
          builder: (_, __) => MultiRepositoryProvider(
            providers: [
              RepositoryProvider<JournalRepositoryContract>.value(
                value: repository,
              ),
              RepositoryProvider<NowService>.value(
                value: _FakeNowService(DateTime(2025, 10, 24, 9)),
              ),
              RepositoryProvider<AppErrorReporter>.value(
                value: AppErrorReporter(
                  messengerKey: GlobalKey<ScaffoldMessengerState>(),
                ),
              ),
            ],
            child: Scaffold(
              body: JournalEntryEditorRoutePage(
                entryId: null,
                preselectedTrackerIds: <String>{},
                selectedDayLocal: DateTime(2025, 10, 24),
                quickCapture: true,
              ),
            ),
          ),
        ),
      ],
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.tasklyTheme(),
        darkTheme: AppTheme.tasklyTheme(),
        themeMode: ThemeMode.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );

    await tester.pumpForStream();
    final homeReady = await tester.pumpUntilFound(find.byType(JournalHubPage));
    expect(homeReady, isTrue);
    await expectLater(
      find.byType(MaterialApp).first,
      matchesGoldenFile('goldens/journal_home_dark_harness.png'),
    );

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpForStream();
    final filterReady = await tester.pumpUntilFound(find.byType(BottomSheet));
    expect(filterReady, isTrue);
    await expectLater(
      find.byType(MaterialApp).first,
      matchesGoldenFile('goldens/journal_filter_sheet_dark_harness.png'),
    );
    router.pop();
    await tester.pumpForStream();
    final homeReadyAfterFilter = await tester.pumpUntilFound(
      find.byType(JournalHubPage),
    );
    expect(homeReadyAfterFilter, isTrue);

    router.go('/journal/quick-capture');
    await tester.pumpForStream();
    final captureReady = await tester.pumpUntilFound(find.text('New Moment'));
    expect(captureReady, isTrue);
    await expectLater(
      find.byType(MaterialApp).first,
      matchesGoldenFile('goldens/journal_quick_capture_dark_harness.png'),
    );

    router.go('/journal/insights');
    await tester.pumpForStream();
    final insightsReady = await tester.pumpUntilFound(
      find.byType(JournalInsightsPage),
    );
    expect(insightsReady, isTrue);
    await expectLater(
      find.byType(MaterialApp).first,
      matchesGoldenFile('goldens/journal_insights_dark_harness.png'),
    );
  });
}

JournalEntry _entry(DateTime when, {required String id, String? text}) {
  return JournalEntry(
    id: id,
    entryDate: when,
    entryTime: when,
    occurredAt: when,
    localDate: DateTime(when.year, when.month, when.day),
    createdAt: when,
    updatedAt: when,
    journalText: text,
  );
}

TrackerDefinition _trackerDef(
  String id,
  String name, {
  String? systemKey,
  String valueType = 'rating',
  String? valueKind,
  String? unitKind,
}) {
  final now = DateTime(2025, 10, 24);
  return TrackerDefinition(
    id: id,
    name: name,
    scope: 'entry',
    valueType: valueType,
    valueKind: valueKind,
    unitKind: unitKind,
    createdAt: now,
    updatedAt: now,
    source: 'user',
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
