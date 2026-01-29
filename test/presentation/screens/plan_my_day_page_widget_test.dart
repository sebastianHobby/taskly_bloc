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
  setUpAll(setUpAllTestEnvironment);
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
  }) {
    return PlanMyDayReady(
      needsPlan: true,
      dayKeyUtc: DateTime.utc(2025, 1, 15),
      globalSettings: const settings.GlobalSettings(),
      suggestionSignal: SuggestionSignal.behaviorBased,
      steps: const [
        PlanMyDayStep.valuesStep,
        PlanMyDayStep.summary,
      ],
      currentStep: PlanMyDayStep.valuesStep,
      dueWindowDays: 3,
      showAvailableToStart: true,
      showDueSoon: true,
      requiresValueSetup: requiresValueSetup,
      requiresRatings: requiresRatings,
      countRoutinesAgainstValues: false,
      suggested: const <Task>[],
      triageDue: const <Task>[],
      triageStarts: const <Task>[],
      scheduledRoutines: const <PlanMyDayRoutineItem>[],
      flexibleRoutines: const <PlanMyDayRoutineItem>[],
      allRoutines: const <PlanMyDayRoutineItem>[],
      selectedTaskIds: const <String>{},
      selectedRoutineIds: const <String>{},
      allTasks: const <Task>[],
      routineSelectionsByValue: const <String, int>{},
      valueSuggestionGroups: valueGroups,
      valueSort: PlanMyDayValueSort.attentionFirst,
      spotlightTaskId: null,
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
}
