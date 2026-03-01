@Tags(['widget', 'journal', 'golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_entry_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_history_page.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_hub_page.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_insights_page.dart';
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
  final skipInCi = Platform.environment['CI'] == 'true';

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

  void seedHomeData() {
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
  }

  void seedInsightsData() {
    final moodDef = _trackerDef('mood', 'Mood', systemKey: 'mood');
    final socialDef = _trackerDef('social', 'Social Time');
    defsSubject.add([moodDef, socialDef]);

    final entries = <JournalEntry>[];
    final events = <TrackerEvent>[];
    final start = DateTime(2025, 9, 25, 10);
    for (var i = 0; i < 30; i++) {
      final when = start.add(Duration(days: i));
      final id = 'entry-$i';
      entries.add(_entry(when, id: id, text: 'Day $i'));
      final hasSocial = i.isEven;
      final mood = hasSocial ? 4 : 3;
      events.add(_event('mood-$i', moodDef.id, id, mood, when));
      if (hasSocial) {
        events.add(_event('social-$i', socialDef.id, id, 1, when));
      }
    }
    entriesSubject.add(entries);
    eventsSubject.add(events);
  }

  GoRouter buildRouter({required String initialLocation}) {
    return GoRouter(
      initialLocation: initialLocation,
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
          path: '/journal/history',
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
            child: const JournalHistoryPage(),
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
  }

  Future<void> pumpHarness(
    WidgetTester tester, {
    required GoRouter router,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.tasklyTheme(),
        darkTheme: AppTheme.tasklyTheme(),
        themeMode: ThemeMode.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpForStream();
  }

  testWidgetsSafe('journal home dark snapshot', (tester) async {
    seedHomeData();
    final router = buildRouter(initialLocation: '/journal');
    await pumpHarness(tester, router: router);
    final ready = await tester.pumpUntilFound(find.byType(JournalHubPage));
    expect(ready, isTrue);

    await expectLater(
      find.byType(MaterialApp).first,
      matchesGoldenFile('goldens/journal_home_dark_harness.png'),
    );
  }, skip: skipInCi);

  testWidgetsSafe('journal filter sheet dark snapshot', (tester) async {
    seedHomeData();
    final router = buildRouter(initialLocation: '/journal/history');
    await pumpHarness(tester, router: router);
    final ready = await tester.pumpUntilFound(find.byType(JournalHistoryPage));
    expect(ready, isTrue);

    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpForStream();
    final filterReady = await tester.pumpUntilFound(find.byType(BottomSheet));
    expect(filterReady, isTrue);

    await expectLater(
      find.byType(MaterialApp).first,
      matchesGoldenFile('goldens/journal_filter_sheet_dark_harness.png'),
    );
  }, skip: skipInCi);

  testWidgetsSafe('journal quick capture dark snapshot', (tester) async {
    seedHomeData();
    final router = buildRouter(initialLocation: '/journal/quick-capture');
    await pumpHarness(tester, router: router);
    final ready = await tester.pumpUntilFound(find.text('New Moment'));
    expect(ready, isTrue);
    await tester.tap(find.text('Good'));
    await tester.pumpForStream();
    await tester.pumpForStream();
    await tester.pumpForStream();

    await expectLater(
      find.byType(MaterialApp).first,
      matchesGoldenFile('goldens/journal_quick_capture_dark_harness.png'),
    );
  }, skip: skipInCi);

  testWidgetsSafe('journal insights dark snapshot', (tester) async {
    seedInsightsData();
    final router = buildRouter(initialLocation: '/journal/insights');
    await pumpHarness(tester, router: router);
    final ready = await tester.pumpUntilFound(find.byType(JournalInsightsPage));
    expect(ready, isTrue);

    await expectLater(
      find.byType(MaterialApp).first,
      matchesGoldenFile('goldens/journal_insights_dark_harness.png'),
    );
  }, skip: skipInCi);
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
