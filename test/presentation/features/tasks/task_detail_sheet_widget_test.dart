@Tags(['widget', 'tasks'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/task_detail_view.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_form.dart';
import 'package:taskly_domain/core.dart';

class MockTaskDetailBloc extends MockBloc<TaskDetailEvent, TaskDetailState>
    implements TaskDetailBloc {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });

  setUp(setUpTestEnvironment);

  late MockTaskDetailBloc bloc;

  setUp(() {
    bloc = MockTaskDetailBloc();
  });

  testWidgetsSafe('shows loading indicator while loading', (tester) async {
    when(() => bloc.state).thenReturn(const TaskDetailInitial());
    whenListen(
      bloc,
      const Stream<TaskDetailState>.empty(),
      initialState: const TaskDetailInitial(),
    );

    await tester.pumpWidgetWithBloc<TaskDetailBloc>(
      bloc: bloc,
      child: const TaskDetailSheet(),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgetsSafe('renders task form for create flow', (tester) async {
    final state = TaskDetailInitialDataLoadSuccess(
      availableProjects: const <Project>[],
      availableValues: const <Value>[],
    );

    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await tester.pumpWidgetWithBloc<TaskDetailBloc>(
      bloc: bloc,
      child: const TaskDetailSheet(),
    );
    await tester.pumpForStream();

    expect(find.byType(TaskForm), findsOneWidget);
    expect(find.text('New Task'), findsOneWidget);
  });

  testWidgetsSafe('renders task form for edit flow', (tester) async {
    final task = TestData.task(name: 'Edit Task');
    final state = TaskDetailLoadSuccess(
      availableProjects: const <Project>[],
      availableValues: const <Value>[],
      task: task,
    );

    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await tester.pumpWidgetWithBloc<TaskDetailBloc>(
      bloc: bloc,
      child: const TaskDetailSheet(),
    );
    await tester.pumpForStream();

    expect(find.byType(TaskForm), findsOneWidget);
    expect(find.text('Edit Task'), findsOneWidget);
  });
}
