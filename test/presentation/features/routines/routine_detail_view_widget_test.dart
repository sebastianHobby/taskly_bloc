@Tags(['widget', 'routines'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/routines/bloc/routine_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/routines/view/routine_detail_view.dart';
import 'package:taskly_bloc/presentation/features/routines/widgets/routine_form.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/routines.dart';

class MockRoutineDetailBloc
    extends MockBloc<RoutineDetailEvent, RoutineDetailState>
    implements RoutineDetailBloc {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockRoutineDetailBloc bloc;

  setUp(() {
    bloc = MockRoutineDetailBloc();
  });

  Future<void> pumpView(WidgetTester tester, Widget child) async {
    await tester.pumpWidgetWithBloc<RoutineDetailBloc>(
      bloc: bloc,
      child: Material(child: child),
    );
  }

  testWidgetsSafe('shows loading indicator while loading', (tester) async {
    const state = RoutineDetailState.loadInProgress();
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await pumpView(tester, const RoutineDetailSheetView());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgetsSafe('renders routine form for edit flow', (tester) async {
    final value = TestData.value(name: 'Health');
    final project = TestData.projectWithValues(
      id: 'project-1',
      name: 'Project',
      values: [value],
    );
    final routine = Routine(
      id: 'routine-1',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      name: 'Morning Stretch',
      projectId: project.id,
      periodType: RoutinePeriodType.week,
      scheduleMode: RoutineScheduleMode.scheduled,
      targetCount: 1,
      scheduleDays: const [1],
      value: value,
    );
    final state = RoutineDetailState.loadSuccess(
      routine: routine,
      availableProjects: [project],
      checklistTitles: const <String>[],
    );
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await pumpView(
      tester,
      const RoutineDetailSheetView(routineId: 'routine-1'),
    );

    expect(find.byType(RoutineForm), findsOneWidget);
    expect(find.text('Morning Stretch'), findsOneWidget);
  });

  testWidgetsSafe('renders routine form for create flow', (tester) async {
    final value = TestData.value(name: 'Focus');
    final project = TestData.projectWithValues(
      id: 'project-1',
      name: 'Project',
      values: [value],
    );
    final state = RoutineDetailState.initialDataLoadSuccess(
      availableProjects: [project],
    );
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await pumpView(tester, const RoutineDetailSheetView());

    expect(find.byType(RoutineForm), findsOneWidget);
  });

  testWidgetsSafe(
    'create flow uses defaultProjectId when draft project is empty',
    (tester) async {
      final value = TestData.value(name: 'Health');
      final project = TestData.projectWithValues(
        id: 'project-1',
        name: 'Project Alpha',
        values: [value],
      );
      final state = RoutineDetailState.initialDataLoadSuccess(
        availableProjects: [project],
      );
      when(() => bloc.state).thenReturn(state);
      whenListen(bloc, Stream.value(state), initialState: state);

      await pumpView(
        tester,
        const RoutineDetailSheetView(defaultProjectId: 'project-1'),
      );

      expect(find.text('Project Alpha'), findsWidgets);
    },
  );
}
