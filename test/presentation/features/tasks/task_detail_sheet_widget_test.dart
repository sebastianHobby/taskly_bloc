@Tags(['widget', 'tasks'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/task_detail_view.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_form.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/theme/app_theme.dart';
import 'package:taskly_domain/core.dart';

class MockTaskDetailBloc extends MockBloc<TaskDetailEvent, TaskDetailState>
    implements TaskDetailBloc {}

class FakeNowService implements NowService {
  FakeNowService(this.now);

  final DateTime now;

  @override
  DateTime nowLocal() => now;

  @override
  DateTime nowUtc() => now.toUtc();
}

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

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      Provider<NowService>.value(
        value: FakeNowService(DateTime(2025, 1, 15, 9)),
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BlocProvider<TaskDetailBloc>.value(
              value: bloc,
              child: const TaskDetailSheet(),
            ),
          ),
        ),
      ),
    );
  }

  testWidgetsSafe('shows loading indicator while loading', (tester) async {
    when(() => bloc.state).thenReturn(const TaskDetailInitial());
    whenListen(
      bloc,
      const Stream<TaskDetailState>.empty(),
      initialState: const TaskDetailInitial(),
    );

    await pumpSheet(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgetsSafe('renders task form for create flow', (tester) async {
    final state = TaskDetailInitialDataLoadSuccess(
      availableProjects: const <Project>[],
      availableValues: const <Value>[],
    );

    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await pumpSheet(tester);
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

    await pumpSheet(tester);
    await tester.pumpForStream();

    expect(find.byType(TaskForm), findsOneWidget);
    expect(find.text('Edit Task'), findsWidgets);
  });
}
