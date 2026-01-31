@Tags(['widget', 'projects'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/presentation_mocks.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/projects/view/project_detail_page.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';

class MockProjectRepository extends Mock implements ProjectRepositoryContract {}

class MockEditorLauncher extends Mock implements EditorLauncher {}

class MockTaskRepository extends Mock implements TaskRepositoryContract {}

class MockSettingsRepository extends Mock
    implements SettingsRepositoryContract {}

class MockGlobalSettingsBloc
    extends MockBloc<GlobalSettingsEvent, GlobalSettingsState>
    implements GlobalSettingsBloc {}

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

  late MockProjectRepository projectRepository;
  late MockTaskRepository taskRepository;
  late MockSettingsRepository settingsRepository;
  late OccurrenceReadService occurrenceReadService;
  late SessionDayKeyService sessionDayKeyService;
  late MockHomeDayKeyService dayKeyService;
  late MockTemporalTriggerService temporalTriggerService;
  late MockEditorLauncher editorLauncher;
  late MockGlobalSettingsBloc globalSettingsBloc;

  late TestStreamController<TemporalTriggerEvent> temporalController;
  late BehaviorSubject<Project?> projectSubject;
  late BehaviorSubject<List<Task>> tasksSubject;
  late BehaviorSubject<List<CompletionHistoryData>> completionsSubject;
  late BehaviorSubject<List<RecurrenceExceptionData>> exceptionsSubject;
  const speedDialInitDelay = Duration(milliseconds: 1);

  setUp(() {
    projectRepository = MockProjectRepository();
    taskRepository = MockTaskRepository();
    settingsRepository = MockSettingsRepository();
    occurrenceReadService = OccurrenceReadService(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      dayKeyService: HomeDayKeyService(
        settingsRepository: settingsRepository,
        clock: _FakeClock(DateTime.utc(2025, 1, 15)),
      ),
    );
    dayKeyService = MockHomeDayKeyService();
    temporalTriggerService = MockTemporalTriggerService();
    sessionDayKeyService = SessionDayKeyService(
      dayKeyService: dayKeyService,
      temporalTriggerService: temporalTriggerService,
    );
    editorLauncher = MockEditorLauncher();
    globalSettingsBloc = MockGlobalSettingsBloc();

    temporalController = TestStreamController.seeded(const AppResumed());
    projectSubject = BehaviorSubject<Project?>();
    tasksSubject = BehaviorSubject<List<Task>>.seeded(const <Task>[]);
    completionsSubject = BehaviorSubject.seeded(
      const <CompletionHistoryData>[],
    );
    exceptionsSubject = BehaviorSubject.seeded(
      const <RecurrenceExceptionData>[],
    );

    when(() => globalSettingsBloc.state).thenReturn(
      const GlobalSettingsState(isLoading: false),
    );

    when(() => temporalTriggerService.events).thenAnswer(
      (_) => temporalController.stream,
    );
    when(
      () => dayKeyService.todayDayKeyUtc(),
    ).thenReturn(DateTime.utc(2025, 1, 15));
    sessionDayKeyService.start();
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
  });

  tearDown(() async {
    await temporalController.close();
    await sessionDayKeyService.dispose();
    await projectSubject.close();
    await tasksSubject.close();
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
          RepositoryProvider<SessionDayKeyService>.value(
            value: sessionDayKeyService,
          ),
          RepositoryProvider<EditorLauncher>.value(value: editorLauncher),
          RepositoryProvider<NowService>.value(
            value: FakeNowService(DateTime(2025, 1, 15, 9)),
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<GlobalSettingsBloc>.value(value: globalSettingsBloc),
          ],
          child: const ProjectDetailPage(projectId: 'project-1'),
        ),
      ),
    );
    await tester.pump(speedDialInitDelay);
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
