@Tags(['widget', 'plan_my_day'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_imports.dart';
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
  }) {
    return PlanMyDayReady(
      needsPlan: true,
      dayKeyUtc: DateTime.utc(2025, 1, 15),
      globalSettings: const settings.GlobalSettings(),
      suggestionSignal: SuggestionSignal.behaviorBased,
      dailyLimit: 8,
      requiresValueSetup: requiresValueSetup,
      requiresRatings: requiresRatings,
      suggested: const <Task>[],
      dueTodayTasks: dueTodayTasks,
      plannedTasks: plannedTasks,
      scheduledRoutines: const <PlanMyDayRoutineItem>[],
      flexibleRoutines: const <PlanMyDayRoutineItem>[],
      allRoutines: const <PlanMyDayRoutineItem>[],
      selectedTaskIds: selectedTaskIds,
      selectedRoutineIds: const <String>{},
      allTasks: const <Task>[],
      routineSelectionsByValue: const <String, int>{},
      valueSuggestionGroups: valueGroups,
      valueSort: PlanMyDayValueSort.attentionFirst,
      spotlightTaskId: null,
      overCapacity: false,
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
          attentionNeeded: false,
          neglectScore: 0,
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

  testWidgetsSafe('plan my day shows due and yesterday shelves', (
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

    expect(find.text('Due Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Pay rent'), findsOneWidget);
    expect(find.text('Prep meeting notes'), findsOneWidget);
  });

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
      expect(find.text('Show 1 more (5)'), findsOneWidget);

      await tester.tap(find.text('Show 1 more (5)'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Task 5'), findsOneWidget);
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

      await tester.tap(find.text('Reschedule all due'));
      await tester.pump(const Duration(milliseconds: 300));

      final tomorrowTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Tomorrow'),
      );
      expect(tomorrowTile.onTap, isNotNull);
      tomorrowTile.onTap!();
      await tester.pump(const Duration(milliseconds: 300));

      final captured = verify(() => planBloc.add(captureAny())).captured;
      final event = captured.single as PlanMyDayBulkRescheduleDueRequested;

      expect(event.newDayUtc, DateTime.utc(2025, 1, 16));
    },
  );

  testWidgetsSafe(
    'plan my day reschedules all yesterday tasks on quick pick',
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

      await tester.tap(find.text('Reschedule all'));
      await tester.pump(const Duration(milliseconds: 300));

      final tomorrowTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Tomorrow'),
      );
      expect(tomorrowTile.onTap, isNotNull);
      tomorrowTile.onTap!();
      await tester.pump(const Duration(milliseconds: 300));

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
