@Tags(['widget', 'plan_my_day'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_imports.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/plan_my_day_bloc.dart';
import 'package:taskly_bloc/presentation/screens/view/my_day_values_gate.dart';
import 'package:taskly_bloc/presentation/screens/view/plan_my_day_page.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/settings.dart' as settings;
import 'package:taskly_ui/taskly_ui_tokens.dart';

class MockPlanMyDayBloc extends MockBloc<PlanMyDayEvent, PlanMyDayState>
    implements PlanMyDayBloc {}

class MockMyDayGateBloc extends MockBloc<MyDayGateEvent, MyDayGateState>
    implements MyDayGateBloc {}

class FakeNowService implements NowService {
  @override
  DateTime nowLocal() => DateTime(2025, 1, 15, 12);

  @override
  DateTime nowUtc() => DateTime.utc(2025, 1, 15, 12);
}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerFallbackValue(const PlanMyDayStarted());
  });
  setUp(setUpTestEnvironment);

  late MockPlanMyDayBloc planBloc;
  late MockMyDayGateBloc gateBloc;
  final nowService = FakeNowService();

  setUp(() {
    planBloc = MockPlanMyDayBloc();
    gateBloc = MockMyDayGateBloc();
  });

  PlanMyDayReady buildReady({
    required List<PlanMyDayValueSuggestionGroup> valueGroups,
    bool requiresValueSetup = false,
    bool requiresRatings = false,
    List<Task> dueTodayTasks = const <Task>[],
    List<Task> plannedTasks = const <Task>[],
    Set<String> selectedTaskIds = const <String>{},
    List<PlanMyDayRoutineItem> scheduledRoutines =
        const <PlanMyDayRoutineItem>[],
    List<PlanMyDayRoutineItem> flexibleRoutines =
        const <PlanMyDayRoutineItem>[],
    Set<String> selectedRoutineIds = const <String>{},
    List<Value> unratedValues = const <Value>[],
    PlanMyDayValueSort valueSort = PlanMyDayValueSort.lowestAverage,
    int dailyLimit = 8,
    bool overCapacity = false,
  }) {
    return PlanMyDayReady(
      needsPlan: true,
      dayKeyUtc: DateTime.utc(2025, 1, 15),
      globalSettings: const settings.GlobalSettings(),
      suggestionSignal: SuggestionSignal.ratingsBased,
      dailyLimit: dailyLimit,
      requiresValueSetup: requiresValueSetup,
      requiresRatings: requiresRatings,
      suggested: const <Task>[],
      dueTodayTasks: dueTodayTasks,
      plannedTasks: plannedTasks,
      scheduledRoutines: scheduledRoutines,
      flexibleRoutines: flexibleRoutines,
      selectedTaskIds: selectedTaskIds,
      selectedRoutineIds: selectedRoutineIds,
      allTasks: const <Task>[],
      routineSelectionsByValue: const <String, int>{},
      valueSuggestionGroups: valueGroups,
      unratedValues: unratedValues,
      valueSort: valueSort,
      overCapacity: overCapacity,
      toastRequestId: 0,
    );
  }

  void setTestSurfaceSize(WidgetTester tester, Size size) {
    tester.binding.window.physicalSizeTestValue = size;
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });
  }

  AppLocalizations l10nFor(WidgetTester tester) {
    return tester.element(find.byType(PlanMyDayPage)).l10n;
  }

  PlanMyDayRoutineItem buildRoutineItem({
    required String id,
    required String name,
    required RoutinePeriodType periodType,
    required RoutineScheduleMode scheduleMode,
    required bool selected,
    required bool isScheduled,
  }) {
    final routine = Routine(
      id: id,
      createdAt: DateTime.utc(2024, 12, 1),
      updatedAt: DateTime.utc(2025, 1, 1),
      name: name,
      projectId: 'project-1',
      periodType: periodType,
      scheduleMode: scheduleMode,
      targetCount: 3,
      scheduleDays: scheduleMode == RoutineScheduleMode.scheduled
          ? const <int>[1, 3, 5]
          : const <int>[],
    );
    final snapshot = RoutineCadenceSnapshot(
      routineId: id,
      periodType: periodType,
      periodStartUtc: DateTime.utc(2025, 1, 13),
      periodEndUtc: DateTime.utc(2025, 1, 19),
      targetCount: 3,
      completedCount: 1,
      remainingCount: 2,
      daysLeft: 3,
      status: RoutineStatus.onPace,
      nextRecommendedDayUtc: DateTime.utc(2025, 1, 17),
    );

    return PlanMyDayRoutineItem(
      routine: routine,
      snapshot: snapshot,
      selected: selected,
      completedToday: false,
      isCatchUpDay: false,
      isScheduled: isScheduled,
      isEligibleToday: true,
      lastScheduledDayUtc: DateTime.utc(2025, 1, 15),
      lastCompletedAtUtc: DateTime.utc(2025, 1, 12, 10),
      completionsInPeriod: const <RoutineCompletion>[],
      skipsInPeriod: const <RoutineSkip>[],
    );
  }

  testWidgetsSafe('plan my day shows loading state', (tester) async {
    const state = PlanMyDayLoading();
    const gateState = MyDayGateLoaded(needsValuesSetup: false);

    when(() => planBloc.state).thenReturn(state);
    whenListen(planBloc, Stream.value(state), initialState: state);
    when(() => gateBloc.state).thenReturn(gateState);
    whenListen(gateBloc, Stream.value(gateState), initialState: gateState);

    await tester.pumpWidgetWithBlocs(
      providers: [
        BlocProvider<PlanMyDayBloc>.value(value: planBloc),
        BlocProvider<MyDayGateBloc>.value(value: gateBloc),
      ],
      child: RepositoryProvider<NowService>.value(
        value: nowService,
        child: PlanMyDayPage(onCloseRequested: () {}),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgetsSafe('plan my day shows values gate when setup required', (
    tester,
  ) async {
    final state = buildReady(valueGroups: [], requiresValueSetup: true);
    const gateState = MyDayGateLoaded(needsValuesSetup: true);

    when(() => planBloc.state).thenReturn(state);
    whenListen(planBloc, Stream.value(state), initialState: state);
    when(() => gateBloc.state).thenReturn(gateState);
    whenListen(gateBloc, Stream.value(gateState), initialState: gateState);

    await tester.pumpWidgetWithBlocs(
      providers: [
        BlocProvider<PlanMyDayBloc>.value(value: planBloc),
        BlocProvider<MyDayGateBloc>.value(value: gateBloc),
      ],
      child: RepositoryProvider<NowService>.value(
        value: nowService,
        child: PlanMyDayPage(onCloseRequested: () {}),
      ),
    );

    expect(find.byType(MyDayValuesGate), findsOneWidget);
  });

  testWidgetsSafe('plan my day renders value suggestions', (tester) async {
    final value = TestData.value(id: 'value-1', name: 'Health');
    final task = TestData.task(
      id: 'task-1',
      name: 'Morning walk',
      values: [value],
    );
    final state = buildReady(
      valueGroups: [
        PlanMyDayValueSuggestionGroup(
          valueId: value.id,
          value: value,
          tasks: [task],
          averageRating: 7.4,
          trendDelta: -0.6,
          hasRatings: true,
          isTrendingDown: true,
          isLowAverage: false,
          visibleCount: 1,
          expanded: true,
        ),
      ],
    );
    const gateState = MyDayGateLoaded(needsValuesSetup: false);

    when(() => planBloc.state).thenReturn(state);
    whenListen(planBloc, Stream.value(state), initialState: state);
    when(() => gateBloc.state).thenReturn(gateState);
    whenListen(gateBloc, Stream.value(gateState), initialState: gateState);

    await tester.pumpWidgetWithBlocs(
      providers: [
        BlocProvider<PlanMyDayBloc>.value(value: planBloc),
        BlocProvider<MyDayGateBloc>.value(value: gateBloc),
      ],
      child: RepositoryProvider<NowService>.value(
        value: nowService,
        child: PlanMyDayPage(onCloseRequested: () {}),
      ),
    );
    await tester.pumpForStream();

    expect(find.text('Health'), findsOneWidget);
    expect(find.text('Morning walk'), findsOneWidget);
  });

  testWidgetsSafe('plan my day shows trend label for value group', (
    tester,
  ) async {
    final value = TestData.value(id: 'value-1', name: 'Family');
    final task = TestData.task(
      id: 'task-1',
      name: 'Call parents',
      values: [value],
    );
    final state = buildReady(
      valueGroups: [
        PlanMyDayValueSuggestionGroup(
          valueId: value.id,
          value: value,
          tasks: [task],
          averageRating: 6.1,
          trendDelta: -0.5,
          hasRatings: true,
          isTrendingDown: true,
          isLowAverage: true,
          visibleCount: 1,
          expanded: true,
        ),
      ],
    );
    const gateState = MyDayGateLoaded(needsValuesSetup: false);

    when(() => planBloc.state).thenReturn(state);
    whenListen(planBloc, Stream.value(state), initialState: state);
    when(() => gateBloc.state).thenReturn(gateState);
    whenListen(gateBloc, Stream.value(gateState), initialState: gateState);

    await tester.pumpWidgetWithBlocs(
      providers: [
        BlocProvider<PlanMyDayBloc>.value(value: planBloc),
        BlocProvider<MyDayGateBloc>.value(value: gateBloc),
      ],
      child: RepositoryProvider<NowService>.value(
        value: nowService,
        child: PlanMyDayPage(onCloseRequested: () {}),
      ),
    );
    await tester.pumpForStream();

    final l10n = l10nFor(tester);
    expect(find.text('Family'), findsOneWidget);
    expect(find.text(l10n.planMyDayTrendDownLabel('0.5')), findsOneWidget);
  });

  testWidgetsSafe(
    'plan my day renders sort label for highest average',
    (tester) async {
      final value = TestData.value(
        id: 'value-spotlight',
        name: 'Family',
      );
      final otherValue = TestData.value(
        id: 'value-other',
        name: 'Health',
      );
      final task = TestData.task(
        id: 'task-spotlight',
        name: 'Call parents',
        values: [value],
      );
      final otherTask = TestData.task(
        id: 'task-other',
        name: 'Morning walk',
        values: [otherValue],
      );

      final state = buildReady(
        valueGroups: [
          PlanMyDayValueSuggestionGroup(
            valueId: value.id,
            value: value,
            tasks: [task],
            averageRating: 5.9,
            trendDelta: -0.4,
            hasRatings: true,
            isTrendingDown: true,
            isLowAverage: true,
            visibleCount: 1,
            expanded: true,
          ),
          PlanMyDayValueSuggestionGroup(
            valueId: otherValue.id,
            value: otherValue,
            tasks: [otherTask],
            averageRating: 7.4,
            trendDelta: 0.2,
            hasRatings: true,
            isTrendingDown: false,
            isLowAverage: false,
            visibleCount: 1,
            expanded: true,
          ),
        ],
        valueSort: PlanMyDayValueSort.highestAverage,
      );
      const gateState = MyDayGateLoaded(needsValuesSetup: false);

      when(() => planBloc.state).thenReturn(state);
      whenListen(planBloc, Stream.value(state), initialState: state);
      when(() => gateBloc.state).thenReturn(gateState);
      whenListen(gateBloc, Stream.value(gateState), initialState: gateState);

      await tester.pumpWidgetWithBlocs(
        providers: [
          BlocProvider<PlanMyDayBloc>.value(value: planBloc),
          BlocProvider<MyDayGateBloc>.value(value: gateBloc),
        ],
        child: RepositoryProvider<NowService>.value(
          value: nowService,
          child: PlanMyDayPage(onCloseRequested: () {}),
        ),
      );
      await tester.pumpForStream();

      final label = l10nFor(tester).planMyDaySortHighestAverage;
      final header = l10nFor(tester).planMyDaySortByLabel(label);
      expect(find.text(header), findsOneWidget);
    },
  );

  testWidgetsSafe('plan my day sort menu dispatches sort change event', (
    tester,
  ) async {
    final valueA = TestData.value(id: 'value-a', name: 'Family');
    final valueB = TestData.value(id: 'value-b', name: 'Health');
    final taskA = TestData.task(
      id: 'task-a',
      name: 'Call parents',
      values: [valueA],
    );
    final taskB = TestData.task(
      id: 'task-b',
      name: 'Morning walk',
      values: [valueB],
    );
    final state = buildReady(
      valueGroups: [
        PlanMyDayValueSuggestionGroup(
          valueId: valueA.id,
          value: valueA,
          tasks: [taskA],
          averageRating: 5.0,
          trendDelta: -0.2,
          hasRatings: true,
          isTrendingDown: true,
          isLowAverage: true,
          visibleCount: 1,
          expanded: true,
        ),
        PlanMyDayValueSuggestionGroup(
          valueId: valueB.id,
          value: valueB,
          tasks: [taskB],
          averageRating: 7.0,
          trendDelta: -0.8,
          hasRatings: true,
          isTrendingDown: true,
          isLowAverage: false,
          visibleCount: 1,
          expanded: true,
        ),
      ],
      valueSort: PlanMyDayValueSort.lowestAverage,
    );
    const gateState = MyDayGateLoaded(needsValuesSetup: false);

    when(() => planBloc.state).thenReturn(state);
    whenListen(planBloc, Stream.value(state), initialState: state);
    when(() => gateBloc.state).thenReturn(gateState);
    whenListen(gateBloc, Stream.value(gateState), initialState: gateState);

    await tester.pumpWidgetWithBlocs(
      providers: [
        BlocProvider<PlanMyDayBloc>.value(value: planBloc),
        BlocProvider<MyDayGateBloc>.value(value: gateBloc),
      ],
      child: RepositoryProvider<NowService>.value(
        value: nowService,
        child: PlanMyDayPage(onCloseRequested: () {}),
      ),
    );
    await tester.pumpForStream();

    final sortMenu = tester.widget<PopupMenuButton<PlanMyDayValueSort>>(
      find.byKey(kPlanMyDayValueSortMenuButtonKey),
    );
    sortMenu.onSelected?.call(PlanMyDayValueSort.highestAverage);
    await tester.pumpForStream();

    verify(
      () => planBloc.add(
        any(
          that: isA<PlanMyDayValueSortChanged>().having(
            (event) => event.sort,
            'sort',
            PlanMyDayValueSort.highestAverage,
          ),
        ),
      ),
    ).called(1);
  });

  testWidgetsSafe('plan my day shows due and planned shelves', (
    tester,
  ) async {
    final dueTask = TestData.task(
      id: 'task-due',
      name: 'Pay rent',
      deadlineDate: DateTime(2025, 1, 15),
    );
    final plannedTask = TestData.task(
      id: 'task-plan',
      name: 'Prep meeting notes',
      startDate: DateTime(2025, 1, 15),
    );

    final state = buildReady(
      valueGroups: const [],
      dueTodayTasks: [dueTask],
      plannedTasks: [plannedTask],
      selectedTaskIds: {dueTask.id, plannedTask.id},
    );
    const gateState = MyDayGateLoaded(needsValuesSetup: false);

    when(() => planBloc.state).thenReturn(state);
    whenListen(planBloc, Stream.value(state), initialState: state);
    when(() => gateBloc.state).thenReturn(gateState);
    whenListen(gateBloc, Stream.value(gateState), initialState: gateState);

    await tester.pumpWidgetWithBlocs(
      providers: [
        BlocProvider<PlanMyDayBloc>.value(value: planBloc),
        BlocProvider<MyDayGateBloc>.value(value: gateBloc),
      ],
      child: RepositoryProvider<NowService>.value(
        value: nowService,
        child: PlanMyDayPage(onCloseRequested: () {}),
      ),
    );
    await tester.pumpForStream();

    final l10n = l10nFor(tester);
    expect(find.text(l10n.planMyDayDueTodayTitle), findsWidgets);
    expect(find.text(l10n.myDayPlannedSectionTitle), findsWidgets);
    expect(find.text('Pay rent'), findsOneWidget);
    expect(find.text('Prep meeting notes'), findsOneWidget);
  });

  testWidgetsSafe(
    'plan my day info card is dismissible and planned summary card is hidden',
    (tester) async {
      final state = buildReady(
        valueGroups: const [],
        plannedTasks: [
          TestData.task(
            id: 'task-plan',
            name: 'Prep meeting notes',
            startDate: DateTime(2025, 1, 15),
          ),
        ],
      );
      const gateState = MyDayGateLoaded(needsValuesSetup: false);

      when(() => planBloc.state).thenReturn(state);
      whenListen(planBloc, Stream.value(state), initialState: state);
      when(() => gateBloc.state).thenReturn(gateState);
      whenListen(gateBloc, Stream.value(gateState), initialState: gateState);

      await tester.pumpWidgetWithBlocs(
        providers: [
          BlocProvider<PlanMyDayBloc>.value(value: planBloc),
          BlocProvider<MyDayGateBloc>.value(value: gateBloc),
        ],
        child: RepositoryProvider<NowService>.value(
          value: nowService,
          child: PlanMyDayPage(onCloseRequested: () {}),
        ),
      );
      await tester.pumpForStream();

      final l10n = l10nFor(tester);
      expect(find.text(l10n.planMyDayInfoCardTitle), findsOneWidget);
      expect(find.text('Prep meeting notes'), findsOneWidget);

      await tester.tap(
        find
            .byTooltip(
              MaterialLocalizations.of(
                tester.element(find.byType(PlanMyDayPage)),
              ).closeButtonTooltip,
            )
            .first,
      );
      await tester.pumpForStream();

      expect(find.text(l10n.planMyDayInfoCardTitle), findsNothing);
    },
  );

  testWidgetsSafe(
    'plan my day limits sections on compact and expands on show more',
    (tester) async {
      setTestSurfaceSize(tester, const Size(375, 1200));
      final dueTasks = List.generate(
        5,
        (index) => TestData.task(
          id: 'task-$index',
          name: 'Task ${index + 1}',
          deadlineDate: DateTime(2025, 1, 15),
        ),
      );

      final state = buildReady(
        valueGroups: const [],
        dueTodayTasks: dueTasks,
      );
      const gateState = MyDayGateLoaded(needsValuesSetup: false);

      when(() => planBloc.state).thenReturn(state);
      whenListen(planBloc, Stream.value(state), initialState: state);
      when(() => gateBloc.state).thenReturn(gateState);
      whenListen(gateBloc, Stream.value(gateState), initialState: gateState);

      await tester.pumpWidgetWithBlocs(
        providers: [
          BlocProvider<PlanMyDayBloc>.value(value: planBloc),
          BlocProvider<MyDayGateBloc>.value(value: gateBloc),
        ],
        child: RepositoryProvider<NowService>.value(
          value: nowService,
          child: PlanMyDayPage(onCloseRequested: () {}),
        ),
      );
      await tester.pumpForStream();

      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 4'), findsOneWidget);
      expect(find.text('Task 5'), findsNothing);
      final l10n = l10nFor(tester);
      expect(find.text(l10n.myDayPlanShowMore(1, 5)), findsOneWidget);

      await tester.tap(find.text(l10n.myDayPlanShowMore(1, 5)));
      final foundTask5 = await tester.pumpUntilFound(find.text('Task 5'));
      expect(foundTask5, isTrue);

      expect(find.text('Task 5'), findsOneWidget);
    },
  );

  testWidgetsSafe(
    'plan my day splits routines by scheduled and flexible and supports scheduled deselect flow',
    (tester) async {
      setTestSurfaceSize(tester, const Size(800, 1800));
      final scheduled = buildRoutineItem(
        id: 'routine-scheduled',
        name: 'Gym',
        periodType: RoutinePeriodType.week,
        scheduleMode: RoutineScheduleMode.scheduled,
        selected: true,
        isScheduled: true,
      );
      final flexible = buildRoutineItem(
        id: 'routine-flex',
        name: 'Read',
        periodType: RoutinePeriodType.week,
        scheduleMode: RoutineScheduleMode.flexible,
        selected: false,
        isScheduled: false,
      );
      final state = buildReady(
        valueGroups: const [],
        scheduledRoutines: [scheduled],
        flexibleRoutines: [flexible],
        selectedRoutineIds: {scheduled.routine.id},
      );
      const gateState = MyDayGateLoaded(needsValuesSetup: false);

      when(() => planBloc.state).thenReturn(state);
      whenListen(planBloc, Stream.value(state), initialState: state);
      when(() => gateBloc.state).thenReturn(gateState);
      whenListen(gateBloc, Stream.value(gateState), initialState: gateState);

      await tester.pumpWidgetWithBlocs(
        providers: [
          BlocProvider<PlanMyDayBloc>.value(value: planBloc),
          BlocProvider<MyDayGateBloc>.value(value: gateBloc),
        ],
        child: RepositoryProvider<NowService>.value(
          value: nowService,
          child: PlanMyDayPage(onCloseRequested: () {}),
        ),
      );
      await tester.pumpForStream();

      final l10n = l10nFor(tester);
      expect(find.text(l10n.routinePanelScheduledTitle), findsOneWidget);
      expect(find.text(l10n.routinePanelFlexibleTitle), findsOneWidget);

      await tester.tap(find.text(l10n.skipLabel).first);
      await tester.pumpForStream();
      final foundSkipAction = await tester.pumpUntilFound(
        find.text(l10n.planMyDayRoutineSkipInstanceAction),
      );
      expect(foundSkipAction, isTrue);
      expect(find.text(l10n.moreOptionsLabel), findsNothing);
      expect(find.text(l10n.routinePauseLabel), findsOneWidget);
      expect(
        find.text(l10n.planMyDayRoutineSkipPeriodWeekAction),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.text(l10n.planMyDayRoutineSkipInstanceAction),
      );
      await tester.tap(find.text(l10n.planMyDayRoutineSkipInstanceAction));
      await tester.pumpForStream();

      final captured = verify(() => planBloc.add(captureAny())).captured;
      expect(captured, isNotEmpty);
      expect(captured.last, isA<PlanMyDaySkipRoutineInstanceRequested>());
    },
  );

  testWidgetsSafe(
    'plan my day hides limit and over-capacity UI while still showing suggestions',
    (tester) async {
      final value = TestData.value(id: 'value-1', name: 'Health');
      final task = TestData.task(
        id: 'task-1',
        name: 'Morning walk',
        values: [value],
      );
      final state = buildReady(
        valueGroups: [
          PlanMyDayValueSuggestionGroup(
            valueId: value.id,
            value: value,
            tasks: [task],
            averageRating: 7.4,
            trendDelta: -0.6,
            hasRatings: true,
            isTrendingDown: true,
            isLowAverage: false,
            visibleCount: 1,
            expanded: true,
          ),
        ],
        dailyLimit: 1,
        overCapacity: true,
      );
      const gateState = MyDayGateLoaded(needsValuesSetup: false);

      when(() => planBloc.state).thenReturn(state);
      whenListen(planBloc, Stream.value(state), initialState: state);
      when(() => gateBloc.state).thenReturn(gateState);
      whenListen(gateBloc, Stream.value(gateState), initialState: gateState);

      await tester.pumpWidgetWithBlocs(
        providers: [
          BlocProvider<PlanMyDayBloc>.value(value: planBloc),
          BlocProvider<MyDayGateBloc>.value(value: gateBloc),
        ],
        child: RepositoryProvider<NowService>.value(
          value: nowService,
          child: PlanMyDayPage(onCloseRequested: () {}),
        ),
      );
      await tester.pumpForStream();

      final l10n = l10nFor(tester);
      expect(find.text(l10n.planMyDayLimitLabel(1)), findsNothing);
      expect(find.byTooltip(l10n.planMyDayDecreaseLimitTooltip), findsNothing);
      expect(find.byTooltip(l10n.planMyDayIncreaseLimitTooltip), findsNothing);
      expect(find.text(l10n.planMyDayOverCapacityMessage(0, 1)), findsNothing);
      expect(find.text('Health'), findsOneWidget);
      expect(find.text('Morning walk'), findsOneWidget);
    },
  );

  testWidgetsSafe(
    'plan my day reschedules all due tasks on quick pick',
    (tester) async {
      setTestSurfaceSize(tester, const Size(800, 1800));
      final dueTask = TestData.task(
        id: 'task-due',
        name: 'Pay rent',
        deadlineDate: DateTime(2025, 1, 15),
      );

      final state = buildReady(
        valueGroups: const [],
        dueTodayTasks: [dueTask],
        selectedTaskIds: {dueTask.id},
      );
      const gateState = MyDayGateLoaded(needsValuesSetup: false);

      when(() => planBloc.state).thenReturn(state);
      whenListen(planBloc, Stream.value(state), initialState: state);
      when(() => gateBloc.state).thenReturn(gateState);
      whenListen(gateBloc, Stream.value(gateState), initialState: gateState);

      await tester.pumpWidgetWithBlocs(
        providers: [
          BlocProvider<PlanMyDayBloc>.value(value: planBloc),
          BlocProvider<MyDayGateBloc>.value(value: gateBloc),
        ],
        child: RepositoryProvider<NowService>.value(
          value: nowService,
          child: PlanMyDayPage(onCloseRequested: () {}),
        ),
      );
      await tester.pumpForStream();

      final l10n = l10nFor(tester);
      await tester.tap(find.text(l10n.planMyDayRescheduleAllDueAction));
      final foundTomorrow = await tester.pumpUntilFound(
        find.widgetWithText(ListTile, l10n.dateTomorrow),
      );
      expect(foundTomorrow, isTrue);

      final tomorrowTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, l10n.dateTomorrow),
      );
      expect(tomorrowTile.onTap, isNotNull);
      tomorrowTile.onTap!();
      await tester.pumpForStream();

      final captured = verify(() => planBloc.add(captureAny())).captured;
      final event = captured.single as PlanMyDayBulkRescheduleDueRequested;

      expect(event.newDayUtc, DateTime.utc(2025, 1, 16));
    },
  );

  testWidgetsSafe(
    'plan my day reschedules all planned tasks on quick pick',
    (tester) async {
      setTestSurfaceSize(tester, const Size(800, 1800));
      final plannedTask = TestData.task(
        id: 'task-plan',
        name: 'Prep meeting notes',
        startDate: DateTime(2025, 1, 15),
      );

      final state = buildReady(
        valueGroups: const [],
        plannedTasks: [plannedTask],
        selectedTaskIds: {plannedTask.id},
      );
      const gateState = MyDayGateLoaded(needsValuesSetup: false);

      when(() => planBloc.state).thenReturn(state);
      whenListen(planBloc, Stream.value(state), initialState: state);
      when(() => gateBloc.state).thenReturn(gateState);
      whenListen(gateBloc, Stream.value(gateState), initialState: gateState);

      await tester.pumpWidgetWithBlocs(
        providers: [
          BlocProvider<PlanMyDayBloc>.value(value: planBloc),
          BlocProvider<MyDayGateBloc>.value(value: gateBloc),
        ],
        child: RepositoryProvider<NowService>.value(
          value: nowService,
          child: PlanMyDayPage(onCloseRequested: () {}),
        ),
      );
      await tester.pumpForStream();

      final l10n = l10nFor(tester);
      await tester.tap(find.text(l10n.planMyDayRescheduleAllAction));
      final foundTomorrow = await tester.pumpUntilFound(
        find.widgetWithText(ListTile, l10n.dateTomorrow),
      );
      expect(foundTomorrow, isTrue);

      final tomorrowTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, l10n.dateTomorrow),
      );
      expect(tomorrowTile.onTap, isNotNull);
      tomorrowTile.onTap!();
      await tester.pumpForStream();

      final captured = verify(() => planBloc.add(captureAny())).captured;
      final event = captured.single as PlanMyDayBulkReschedulePlannedRequested;

      expect(event.newDayUtc, DateTime.utc(2025, 1, 16));
    },
  );

  testWidgetsSafe(
    'plan my day sizes bottom fade based on last child height',
    (tester) async {
      setTestSurfaceSize(tester, const Size(800, 1200));
      final dueTask = TestData.task(
        id: 'task-due',
        name: 'Pay rent',
        deadlineDate: DateTime(2025, 1, 15),
      );
      final plannedTask = TestData.task(
        id: 'task-plan',
        name: 'Prep meeting notes',
        startDate: DateTime(2025, 1, 15),
      );

      final state = buildReady(
        valueGroups: const [],
        dueTodayTasks: [dueTask],
        plannedTasks: [plannedTask],
        selectedTaskIds: {dueTask.id, plannedTask.id},
      );
      const gateState = MyDayGateLoaded(needsValuesSetup: false);

      when(() => planBloc.state).thenReturn(state);
      whenListen(planBloc, Stream.value(state), initialState: state);
      when(() => gateBloc.state).thenReturn(gateState);
      whenListen(gateBloc, Stream.value(gateState), initialState: gateState);

      await tester.pumpWidgetWithBlocs(
        providers: [
          BlocProvider<PlanMyDayBloc>.value(value: planBloc),
          BlocProvider<MyDayGateBloc>.value(value: gateBloc),
        ],
        child: RepositoryProvider<NowService>.value(
          value: nowService,
          child: PlanMyDayPage(onCloseRequested: () {}),
        ),
      );
      await tester.pumpForStream();
      await tester.pump();
      await tester.pump();

      final context = tester.element(find.byType(PlanMyDayPage));
      final tokens = TasklyTokens.of(context);

      final lastChildSize = tester.getSize(
        find.byKey(kPlanMyDayLastChildKey),
      );
      final fadeSize = tester.getSize(find.byKey(kPlanMyDayBottomFadeKey));

      final expectedFade = (lastChildSize.height * 0.5).clamp(
        tokens.spaceMd,
        tokens.spaceXl,
      );
      final expectedCovered = (lastChildSize.height * 0.3).clamp(
        tokens.spaceXs2,
        expectedFade - 1,
      );
      final expectedBottomPadding = (expectedFade - expectedCovered).clamp(
        0,
        expectedFade,
      );

      expect(
        fadeSize.height,
        moreOrLessEquals(expectedFade.toDouble(), epsilon: 0.5),
      );

      final listView = tester.widget<ListView>(find.byType(ListView));
      final padding = listView.padding! as EdgeInsets;
      expect(
        padding.bottom,
        moreOrLessEquals(expectedBottomPadding.toDouble(), epsilon: 0.5),
      );
    },
  );
}
