@Tags(['unit', 'journal'])
library;

import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_history_bloc.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';

class MockJournalRepository extends Mock implements JournalRepositoryContract {}

class MockHomeDayKeyService extends Mock implements HomeDayKeyService {}

class MockSettingsRepository extends Mock
    implements SettingsRepositoryContract {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
    registerFallbackValue(
      TrackerGroup(
        id: 'g-1',
        name: 'Group',
        createdAt: DateTime.utc(2025, 1, 1),
        updatedAt: DateTime.utc(2025, 1, 1),
      ),
    );
    registerFallbackValue(
      TrackerDefinitionChoice(
        id: 'c-1',
        trackerId: 't-1',
        choiceKey: 'choice',
        label: 'Choice',
        createdAt: DateTime.utc(2025, 1, 1),
        updatedAt: DateTime.utc(2025, 1, 1),
      ),
    );
    registerFallbackValue(SettingsKey.microLearningSeen('fallback-tip-id'));
    registerFallbackValue(SettingsKey.pageDisplay(PageKey.journal));
    registerFallbackValue(SettingsKey.pageJournalFilters(PageKey.journal));
  });
  setUp(setUpTestEnvironment);

  late MockJournalRepository repository;
  late MockHomeDayKeyService dayKeyService;
  late MockSettingsRepository settingsRepository;
  late TestStreamController<List<TrackerDefinition>> defsController;
  late TestStreamController<List<JournalEntry>> entriesController;
  late TestStreamController<List<TrackerStateDay>> dayStateController;
  late TestStreamController<List<TrackerEvent>> eventsController;
  late TestStreamController<List<TrackerGroup>> groupsController;

  JournalHistoryBloc buildBloc() {
    return JournalHistoryBloc(
      repository: repository,
      dayKeyService: dayKeyService,
      settingsRepository: settingsRepository,
      nowUtc: () => DateTime.utc(2026, 1, 28, 9),
    );
  }

  setUp(() {
    repository = MockJournalRepository();
    dayKeyService = MockHomeDayKeyService();
    settingsRepository = MockSettingsRepository();

    defsController = TestStreamController.seeded(<TrackerDefinition>[]);
    entriesController = TestStreamController.seeded(<JournalEntry>[]);
    dayStateController = TestStreamController.seeded(<TrackerStateDay>[]);
    eventsController = TestStreamController.seeded(<TrackerEvent>[]);
    groupsController = TestStreamController.seeded(<TrackerGroup>[]);

    when(
      () => repository.watchTrackerDefinitions(),
    ).thenAnswer((_) => defsController.stream);
    when(
      () => repository.watchJournalEntriesByQuery(any()),
    ).thenAnswer((_) => entriesController.stream);
    when(
      () => repository.watchTrackerStateDay(range: any(named: 'range')),
    ).thenAnswer((_) => dayStateController.stream);
    when(
      () => repository.watchTrackerEvents(
        range: any(named: 'range'),
        anchorType: any(named: 'anchorType'),
      ),
    ).thenAnswer((_) => eventsController.stream);
    when(
      () => repository.watchTrackerGroups(),
    ).thenAnswer((_) => groupsController.stream);

    when(
      () => repository.saveTrackerGroup(any(), context: any(named: 'context')),
    ).thenAnswer((_) async {});
    when(
      () => repository.saveTrackerDefinition(
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => repository.saveTrackerDefinitionChoice(
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => dayKeyService.todayDayKeyUtc(),
    ).thenReturn(DateTime.utc(2026, 1, 28));
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
      () => settingsRepository.save<bool>(
        any(),
        any<bool>(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => settingsRepository.save<bool>(
        any(),
        any<bool>(),
      ),
    ).thenAnswer((_) async {});
    when(
      () => settingsRepository.save<DisplayPreferences?>(
        any(),
        any<DisplayPreferences?>(),
      ),
    ).thenAnswer((_) async {});
    when(
      () => settingsRepository.save<JournalHistoryFilterPreferences?>(
        any(),
        any<JournalHistoryFilterPreferences?>(),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await defsController.close();
    await entriesController.close();
    await dayStateController.close();
    await eventsController.close();
    await groupsController.close();
  });

  blocTestSafe<JournalHistoryBloc, JournalHistoryState>(
    'filters days by selected factors',
    build: buildBloc,
    act: (bloc) {
      final moodTracker = TrackerDefinition(
        id: 'mood-1',
        name: 'Mood',
        scope: 'entry',
        valueType: 'rating',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        valueKind: 'rating',
        opKind: 'set',
        isActive: true,
        isOutcome: true,
        systemKey: 'mood',
      );

      final energyTracker = TrackerDefinition(
        id: 'energy-1',
        name: 'Energy',
        scope: 'entry',
        valueType: 'rating',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        valueKind: 'rating',
        opKind: 'set',
        isActive: true,
      );
      defsController.emit([moodTracker, energyTracker]);

      final day1 = DateTime.utc(2026, 1, 10);
      final day2 = DateTime.utc(2026, 1, 11);

      entriesController.emit([
        JournalEntry(
          id: 'e1',
          entryDate: day1,
          entryTime: day1,
          occurredAt: day1,
          localDate: day1,
          createdAt: day1,
          updatedAt: day1,
        ),
        JournalEntry(
          id: 'e2',
          entryDate: day2,
          entryTime: day2,
          occurredAt: day2,
          localDate: day2,
          createdAt: day2,
          updatedAt: day2,
        ),
      ]);

      eventsController.emit([
        TrackerEvent(
          id: 'ev1',
          trackerId: 'mood-1',
          anchorType: 'entry',
          entryId: 'e1',
          op: 'set',
          value: 2,
          occurredAt: day1,
          recordedAt: day1,
        ),
        TrackerEvent(
          id: 'ev2',
          trackerId: 'mood-1',
          anchorType: 'entry',
          entryId: 'e2',
          op: 'set',
          value: 5,
          occurredAt: day2,
          recordedAt: day2,
        ),
        TrackerEvent(
          id: 'ev3',
          trackerId: 'energy-1',
          anchorType: 'entry',
          entryId: 'e2',
          op: 'set',
          value: 4,
          occurredAt: day2,
          recordedAt: day2,
        ),
      ]);

      bloc.add(
        JournalHistoryFiltersChanged(
          JournalHistoryFilters.initial().copyWith(
            factorTrackerIds: const {'energy-1'},
          ),
        ),
      );
    },
    verify: (bloc) {
      expect(
        bloc.state,
        isA<JournalHistoryLoaded>()
            .having((s) => s.days.length, 'days.length', 1)
            .having(
              (s) => s.filters.factorTrackerIds,
              'filters.factorTrackerIds',
              contains('energy-1'),
            ),
      );
    },
  );

  testSafe(
    'builds query with search and explicit date range filters',
    () async {
      final bloc = buildBloc();
      addTearDown(bloc.close);

      bloc.add(const JournalHistoryStarted());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final start = DateTime.utc(2026, 1, 1);
      final end = DateTime.utc(2026, 1, 7);
      bloc.add(
        JournalHistoryFiltersChanged(
          JournalHistoryFilters.initial().copyWith(
            searchText: 'gratitude',
            rangeStart: start,
            rangeEnd: end,
          ),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 40));

      final captured = verify(
        () => repository.watchJournalEntriesByQuery(captureAny()),
      ).captured;
      final query = captured.last as JournalQuery;

      expect(
        query.filter.shared.whereType<JournalTextPredicate>().single.value,
        'gratitude',
      );

      final datePredicate = query.filter.shared
          .whereType<JournalDatePredicate>()
          .single;
      expect(datePredicate.operator, DateOperator.between);
      expect(dateOnly(datePredicate.startDate!), dateOnly(start));
      expect(dateOnly(datePredicate.endDate!), dateOnly(end));
    },
  );

  testSafe('load more increases lookback when no explicit range', () async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(const JournalHistoryStarted());
    await Future<void>.delayed(const Duration(milliseconds: 30));

    bloc.add(const JournalHistoryLoadMoreRequested());
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final state = bloc.state as JournalHistoryLoaded;
    expect(state.filters.lookbackDays, 60);
  });

  testSafe('load more is ignored when explicit range is active', () async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    final start = DateTime.utc(2026, 1, 1);
    final end = DateTime.utc(2026, 1, 2);

    bloc.add(const JournalHistoryStarted());
    await Future<void>.delayed(const Duration(milliseconds: 30));

    bloc.add(
      JournalHistoryFiltersChanged(
        JournalHistoryFilters.initial().copyWith(
          rangeStart: start,
          rangeEnd: end,
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));

    bloc.add(const JournalHistoryLoadMoreRequested());
    await Future<void>.delayed(const Duration(milliseconds: 30));

    final state = bloc.state as JournalHistoryLoaded;
    expect(state.filters.rangeStart, start);
    expect(state.filters.rangeEnd, end);
    expect(state.filters.lookbackDays, 30);
  });

  testSafe('starter pack dismissed marks seen and hides prompt', () async {
    when(
      () => settingsRepository.load(
        SettingsKey.microLearningSeen('journal_starter_pack_start_01b'),
      ),
    ).thenAnswer((_) async => false);

    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(const JournalHistoryStarted());
    await Future<void>.delayed(const Duration(milliseconds: 40));

    final loadedBefore = bloc.state as JournalHistoryLoaded;
    expect(loadedBefore.showStarterPack, isTrue);

    bloc.add(const JournalHistoryStarterPackDismissed());
    await Future<void>.delayed(const Duration(milliseconds: 30));

    final loadedAfter = bloc.state as JournalHistoryLoaded;
    expect(loadedAfter.showStarterPack, isFalse);

    verify(
      () => settingsRepository.save(
        SettingsKey.microLearningSeen('journal_starter_pack_start_01b'),
        true,
      ),
    ).called(1);
  });

  testSafe('starter pack with empty selection only dismisses', () async {
    when(
      () => settingsRepository.load(
        SettingsKey.microLearningSeen('journal_starter_pack_start_01b'),
      ),
    ).thenAnswer((_) async => false);

    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(const JournalHistoryStarted());
    await Future<void>.delayed(const Duration(milliseconds: 30));

    bloc.add(const JournalHistoryStarterPackApplied(<String>{}));
    await Future<void>.delayed(const Duration(milliseconds: 40));

    final loaded = bloc.state as JournalHistoryLoaded;
    expect(loaded.showStarterPack, isFalse);

    verifyNever(
      () => repository.saveTrackerDefinition(
        any(),
        context: any(named: 'context'),
      ),
    );
    verify(
      () => settingsRepository.save(
        SettingsKey.microLearningSeen('journal_starter_pack_start_01b'),
        true,
      ),
    ).called(1);
  });

  testSafe(
    'starter pack apply creates hobbies group, trackers, and choices',
    () async {
      when(
        () => settingsRepository.load(
          SettingsKey.microLearningSeen('journal_starter_pack_start_01b'),
        ),
      ).thenAnswer((_) async => false);

      var defs = <TrackerDefinition>[];
      var groups = <TrackerGroup>[];
      defsController.emit(defs);
      groupsController.emit(groups);

      when(
        () =>
            repository.saveTrackerGroup(any(), context: any(named: 'context')),
      ).thenAnswer((invocation) async {
        final requested = invocation.positionalArguments.first as TrackerGroup;
        final saved = requested.copyWith(id: 'group-hobbies');
        groups = [saved];
        groupsController.emit(groups);
      });

      when(
        () => repository.saveTrackerDefinition(
          any(),
          context: any(named: 'context'),
        ),
      ).thenAnswer((invocation) async {
        final requested =
            invocation.positionalArguments.first as TrackerDefinition;
        final saved = requested.copyWith(
          id: 'def-${requested.name.toLowerCase().replaceAll(' ', '-')}',
        );
        defs = [...defs, saved];
        defsController.emit(defs);
      });

      final bloc = buildBloc();
      addTearDown(bloc.close);

      bloc.add(const JournalHistoryStarted());
      await Future<void>.delayed(const Duration(milliseconds: 30));

      bloc.add(
        const JournalHistoryStarterPackApplied(<String>{
          'running',
          'social_time',
        }),
      );
      await Future<void>.delayed(const Duration(milliseconds: 120));

      verify(
        () =>
            repository.saveTrackerGroup(any(), context: any(named: 'context')),
      ).called(1);

      verify(
        () => repository.saveTrackerDefinition(
          any(),
          context: any(named: 'context'),
        ),
      ).called(2);

      verify(
        () => repository.saveTrackerDefinitionChoice(
          any(),
          context: any(named: 'context'),
        ),
      ).called(4);

      verify(
        () => settingsRepository.save(
          SettingsKey.microLearningSeen('journal_starter_pack_start_01b'),
          true,
        ),
      ).called(1);
    },
  );

  testSafe('density toggle persists compact/rich preference', () async {
    when(
      () => settingsRepository.load(
        SettingsKey.pageDisplay(PageKey.journal),
      ),
    ).thenAnswer(
      (_) async => const DisplayPreferences(density: DisplayDensity.compact),
    );

    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(const JournalHistoryStarted());
    await Future<void>.delayed(const Duration(milliseconds: 30));

    bloc.add(const JournalHistoryDensityToggled());
    await Future<void>.delayed(const Duration(milliseconds: 30));

    final state = bloc.state as JournalHistoryLoaded;
    expect(state.density, DisplayDensity.standard);
    verify(
      () => settingsRepository.save<DisplayPreferences?>(
        SettingsKey.pageDisplay(PageKey.journal),
        const DisplayPreferences(density: DisplayDensity.standard),
      ),
    ).called(1);
  });

  testSafe('restores and persists journal filter preferences', () async {
    when(
      () => settingsRepository.load(
        SettingsKey.pageJournalFilters(PageKey.journal),
      ),
    ).thenAnswer(
      (_) async => const JournalHistoryFilterPreferences(
        factorTrackerIds: <String>['energy-1'],
        factorGroupId: 'group-1',
        lookbackDays: 60,
      ),
    );

    final moodTracker = TrackerDefinition(
      id: 'mood-1',
      name: 'Mood',
      scope: 'entry',
      valueType: 'rating',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      systemKey: 'mood',
    );
    final factorTracker = TrackerDefinition(
      id: 'energy-1',
      name: 'Energy',
      scope: 'entry',
      valueType: 'rating',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      source: 'user',
    );
    defsController.emit([moodTracker, factorTracker]);

    final bloc = buildBloc();
    addTearDown(bloc.close);
    bloc.add(const JournalHistoryStarted());
    await Future<void>.delayed(const Duration(milliseconds: 40));

    final startedState = bloc.state as JournalHistoryLoaded;
    expect(startedState.filters.lookbackDays, 60);
    expect(startedState.filters.factorTrackerIds, contains('energy-1'));
    expect(startedState.filters.factorGroupId, 'group-1');

    bloc.add(
      JournalHistoryFiltersChanged(
        startedState.filters.copyWith(
          factorGroupId: null,
          factorTrackerIds: const <String>{},
          lookbackDays: 30,
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 40));

    verify(
      () => settingsRepository.save<JournalHistoryFilterPreferences?>(
        SettingsKey.pageJournalFilters(PageKey.journal),
        any<JournalHistoryFilterPreferences?>(),
      ),
    ).called(greaterThan(0));
  });

  testSafe('builds top insight only when thresholds are met', () async {
    final moodTracker = TrackerDefinition(
      id: 'mood-1',
      name: 'Mood',
      scope: 'entry',
      valueType: 'rating',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      valueKind: 'rating',
      opKind: 'set',
      isActive: true,
      isOutcome: true,
      systemKey: 'mood',
    );
    final factorTracker = TrackerDefinition(
      id: 'social-1',
      name: 'Social time',
      scope: 'entry',
      valueType: 'yes_no',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      isActive: true,
    );
    defsController.emit([moodTracker, factorTracker]);

    final entries = <JournalEntry>[];
    final events = <TrackerEvent>[];
    for (var i = 0; i < 20; i++) {
      final day = DateTime.utc(2026, 1, 20 - i, 10);
      final entryId = 'entry-$i';
      entries.add(
        JournalEntry(
          id: entryId,
          entryDate: day,
          entryTime: day,
          occurredAt: day,
          localDate: day,
          createdAt: day,
          updatedAt: day,
        ),
      );
      events.add(
        TrackerEvent(
          id: 'mood-$i',
          trackerId: 'mood-1',
          anchorType: 'entry',
          entryId: entryId,
          op: 'set',
          value: i < 10 ? 5 : 3,
          occurredAt: day,
          recordedAt: day,
        ),
      );
      if (i < 10) {
        events.add(
          TrackerEvent(
            id: 'factor-$i',
            trackerId: 'social-1',
            anchorType: 'entry',
            entryId: entryId,
            op: 'set',
            value: true,
            occurredAt: day,
            recordedAt: day,
          ),
        );
      }
    }
    entriesController.emit(entries);
    eventsController.emit(events);

    final bloc = buildBloc();
    addTearDown(bloc.close);
    bloc.add(const JournalHistoryStarted());
    await Future<void>.delayed(const Duration(milliseconds: 40));

    final state = bloc.state as JournalHistoryLoaded;
    expect(state.topInsight, isNotNull);
    expect(state.showInsightsNudge, isFalse);
  });

  testSafe('exposes only user-defined factors for filter picker', () async {
    defsController.emit([
      TrackerDefinition(
        id: 'mood-1',
        name: 'Mood',
        scope: 'entry',
        valueType: 'rating',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        systemKey: 'mood',
      ),
      TrackerDefinition(
        id: 'system-1',
        name: 'System tracker',
        scope: 'entry',
        valueType: 'yes_no',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        source: 'system',
      ),
      TrackerDefinition(
        id: 'user-1',
        name: 'Energy',
        scope: 'entry',
        valueType: 'rating',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        source: 'user',
      ),
    ]);

    final bloc = buildBloc();
    addTearDown(bloc.close);
    bloc.add(const JournalHistoryStarted());
    await Future<void>.delayed(const Duration(milliseconds: 40));

    final state = bloc.state as JournalHistoryLoaded;
    expect(state.factorDefinitions.map((d) => d.id), ['user-1']);
  });
}
