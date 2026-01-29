@Tags(['widget', 'projects'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/projects/view/project_detail_page.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';

class MockProjectRepository extends Mock implements ProjectRepositoryContract {}

class MockProjectNextActionsRepository extends Mock
    implements ProjectNextActionsRepositoryContract {}

class MockSessionDayKeyService extends Mock implements SessionDayKeyService {}

class MockEditorLauncher extends Mock implements EditorLauncher {}

class MockTaskRepository extends Mock implements TaskRepositoryContract {}

class MockSettingsRepository extends Mock
    implements SettingsRepositoryContract {}

class MockGlobalSettingsBloc
    extends MockBloc<GlobalSettingsEvent, GlobalSettingsState>
    implements GlobalSettingsBloc {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockProjectRepository projectRepository;
  late MockTaskRepository taskRepository;
  late MockSettingsRepository settingsRepository;
  late OccurrenceReadService occurrenceReadService;
  late MockProjectNextActionsRepository nextActionsRepository;
  late MockSessionDayKeyService sessionDayKeyService;
  late MockEditorLauncher editorLauncher;
  late MockGlobalSettingsBloc globalSettingsBloc;

  late BehaviorSubject<DateTime> dayKeySubject;
  late BehaviorSubject<Project?> projectSubject;
  late BehaviorSubject<List<Task>> tasksSubject;
  late BehaviorSubject<List<ProjectNextAction>> nextActionsSubject;
  late BehaviorSubject<List<CompletionHistoryData>> completionsSubject;
  late BehaviorSubject<List<RecurrenceExceptionData>> exceptionsSubject;

  setUp(() {
    projectRepository = MockProjectRepository();
    taskRepository = MockTaskRepository();
    settingsRepository = MockSettingsRepository();
    occurrenceReadService = OccurrenceReadService(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      homeDayKeyService: HomeDayKeyService(
        settingsRepository: settingsRepository,
        clock: _FakeClock(DateTime.utc(2025, 1, 15)),
      ),
    );
    nextActionsRepository = MockProjectNextActionsRepository();
    sessionDayKeyService = MockSessionDayKeyService();
    editorLauncher = MockEditorLauncher();
    globalSettingsBloc = MockGlobalSettingsBloc();

    dayKeySubject = BehaviorSubject<DateTime>.seeded(DateTime.utc(2025, 1, 15));
    projectSubject = BehaviorSubject<Project?>();
    tasksSubject = BehaviorSubject<List<Task>>.seeded(const <Task>[]);
    nextActionsSubject = BehaviorSubject<List<ProjectNextAction>>.seeded(
      const <ProjectNextAction>[],
    );
    completionsSubject = BehaviorSubject.seeded(
      const <CompletionHistoryData>[],
    );
    exceptionsSubject = BehaviorSubject.seeded(
      const <RecurrenceExceptionData>[],
    );

    when(() => globalSettingsBloc.state).thenReturn(
      const GlobalSettingsState(isLoading: false),
    );

    when(() => sessionDayKeyService.todayDayKeyUtc).thenReturn(dayKeySubject);
    when(
      () => projectRepository.watchById(any()),
    ).thenAnswer((_) => projectSubject.stream);
    when(
      () => taskRepository.watchAll(any()),
    ).thenAnswer((_) => tasksSubject.stream);
    when(
      () => taskRepository.watchCompletionHistory(),
    ).thenAnswer((_) => completionsSubject.stream);
    when(
      () => taskRepository.watchRecurrenceExceptions(),
    ).thenAnswer((_) => exceptionsSubject.stream);
    when(
      () => nextActionsRepository.watchForProject(any()),
    ).thenAnswer((_) => nextActionsSubject.stream);
  });

  tearDown(() async {
    await dayKeySubject.close();
    await projectSubject.close();
    await tasksSubject.close();
    await nextActionsSubject.close();
    await completionsSubject.close();
    await exceptionsSubject.close();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpApp(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ProjectRepositoryContract>.value(
            value: projectRepository,
          ),
          RepositoryProvider<OccurrenceReadService>.value(
            value: occurrenceReadService,
          ),
          RepositoryProvider<ProjectNextActionsRepositoryContract>.value(
            value: nextActionsRepository,
          ),
          RepositoryProvider<SessionDayKeyService>.value(
            value: sessionDayKeyService,
          ),
          RepositoryProvider<EditorLauncher>.value(value: editorLauncher),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<GlobalSettingsBloc>.value(value: globalSettingsBloc),
          ],
          child: const ProjectDetailPage(projectId: 'project-1'),
        ),
      ),
    );
  }

  testWidgetsSafe('shows loading state before project loads', (tester) async {
    await pumpPage(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgetsSafe('shows error state when project stream errors', (
    tester,
  ) async {
    await pumpPage(tester);

    projectSubject.addError(Exception('project failed'));
    await tester.pumpForStream();

    expect(find.textContaining('project failed'), findsOneWidget);
  });

  testWidgetsSafe('renders project details when loaded', (tester) async {
    await pumpPage(tester);

    final project = TestData.project(name: 'Alpha Project');
    projectSubject.add(project);
    tasksSubject.add([TestData.task(name: 'Task One')]);
    await tester.pumpForStream();

    expect(find.text('Alpha Project'), findsWidgets);
    expect(find.text('Task One'), findsOneWidget);
  });

  testWidgetsSafe('updates task list when tasks change', (tester) async {
    await pumpPage(tester);

    final project = TestData.project(name: 'Beta Project');
    projectSubject.add(project);
    tasksSubject.add([TestData.task(name: 'Task A')]);
    await tester.pumpForStream();

    expect(find.text('Task A'), findsOneWidget);

    tasksSubject.add([
      TestData.task(name: 'Task A'),
      TestData.task(name: 'Task B'),
    ]);
    await tester.pumpForStream();

    expect(find.text('Task B'), findsOneWidget);
  });
}

class _FakeClock implements Clock {
  _FakeClock(this.now);

  final DateTime now;

  @override
  DateTime nowLocal() => now;

  @override
  DateTime nowUtc() => now.toUtc();
}
