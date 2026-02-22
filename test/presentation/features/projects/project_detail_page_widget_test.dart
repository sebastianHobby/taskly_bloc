@Tags(['widget', 'projects'])
library;

import 'dart:async';

import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/presentation_mocks.dart';
import '../../../mocks/fake_repositories.dart';
import '../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/projects/view/project_detail_page.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';

class MockProjectRepository extends Mock implements ProjectRepositoryContract {}

class MockEditorLauncher extends Mock implements EditorLauncher {}

class MockTaskRepository extends Mock implements TaskRepositoryContract {}

class MockRoutineRepository extends Mock implements RoutineRepositoryContract {}

class MockAppLifecycleEvents extends Mock implements AppLifecycleEvents {}

class MockGlobalSettingsBloc
    extends MockBloc<GlobalSettingsEvent, GlobalSettingsState>
    implements GlobalSettingsBloc {}

class FakeBuildContext extends Fake implements BuildContext {}

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
    registerFallbackValue(FakeBuildContext());
  });
  setUp(setUpTestEnvironment);

  late MockProjectRepository projectRepository;
  late MockTaskRepository taskRepository;
  late MockRoutineRepository routineRepository;
  late MockValueRepositoryContract valueRepository;
  late FakeSettingsRepository settingsRepository;
  late AppErrorReporter errorReporter;
  late OccurrenceReadService occurrenceReadService;
  late SessionDayKeyService sessionDayKeyService;
  late MockHomeDayKeyService dayKeyService;
  late MockTemporalTriggerService temporalTriggerService;
  late MockAppLifecycleEvents appLifecycleEvents;
  late SessionStreamCacheManager cacheManager;
  late SessionSharedDataService sharedDataService;
  late DemoModeService demoModeService;
  late DemoDataProvider demoDataProvider;
  late RoutineWriteService routineWriteService;
  late MockEditorLauncher editorLauncher;
  late MockGlobalSettingsBloc globalSettingsBloc;

  late TestStreamController<TemporalTriggerEvent> temporalController;
  late BehaviorSubject<Project?> projectSubject;
  late BehaviorSubject<List<Task>> tasksSubject;
  late BehaviorSubject<List<CompletionHistoryData>> completionsSubject;
  late BehaviorSubject<List<RecurrenceExceptionData>> exceptionsSubject;
  late BehaviorSubject<List<Routine>> routinesSubject;
  late BehaviorSubject<List<RoutineCompletion>> routineCompletionsSubject;
  late BehaviorSubject<List<RoutineSkip>> routineSkipsSubject;
  const speedDialInitDelay = Duration(milliseconds: 1);

  setUp(() {
    projectRepository = MockProjectRepository();
    taskRepository = MockTaskRepository();
    routineRepository = MockRoutineRepository();
    valueRepository = MockValueRepositoryContract();
    appLifecycleEvents = MockAppLifecycleEvents();
    demoModeService = DemoModeService();
    demoDataProvider = DemoDataProvider();
    settingsRepository = FakeSettingsRepository();
    cacheManager = SessionStreamCacheManager(
      appLifecycleService: appLifecycleEvents,
    );
    sharedDataService = SessionSharedDataService(
      cacheManager: cacheManager,
      valueRepository: valueRepository,
      projectRepository: projectRepository,
      taskRepository: taskRepository,
      demoModeService: demoModeService,
      demoDataProvider: demoDataProvider,
    );
    routineWriteService = RoutineWriteService(
      routineRepository: routineRepository,
    );
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );
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
    projectSubject =
        BehaviorSubject<Project?>(); // ignore-unseeded-subject (loading test)
    tasksSubject = BehaviorSubject<List<Task>>.seeded(const <Task>[]);
    completionsSubject = BehaviorSubject.seeded(
      const <CompletionHistoryData>[],
    );
    exceptionsSubject = BehaviorSubject.seeded(
      const <RecurrenceExceptionData>[],
    );
    routinesSubject = BehaviorSubject.seeded(const <Routine>[]);
    routineCompletionsSubject = BehaviorSubject.seeded(
      const <RoutineCompletion>[],
    );
    routineSkipsSubject = BehaviorSubject.seeded(const <RoutineSkip>[]);

    when(() => appLifecycleEvents.events).thenAnswer(
      (_) => const Stream<AppLifecycleEvent>.empty(),
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
    when(
      () => routineRepository.watchAll(includeInactive: true),
    ).thenAnswer((_) => routinesSubject.stream);
    when(
      () => routineRepository.getAll(includeInactive: true),
    ).thenAnswer((_) async => routinesSubject.valueOrNull ?? const <Routine>[]);
    when(
      () => routineRepository.watchCompletions(),
    ).thenAnswer((_) => routineCompletionsSubject.stream);
    when(
      () => routineRepository.watchSkips(),
    ).thenAnswer((_) => routineSkipsSubject.stream);
    when(
      () => routineRepository.getCompletions(),
    ).thenAnswer(
      (_) async =>
          routineCompletionsSubject.valueOrNull ?? const <RoutineCompletion>[],
    );
    when(
      () => routineRepository.getSkips(),
    ).thenAnswer(
      (_) async => routineSkipsSubject.valueOrNull ?? const <RoutineSkip>[],
    );
    when(() => valueRepository.watchAll()).thenAnswer(
      (_) => const Stream<List<Value>>.empty(),
    );
    when(() => valueRepository.getAll()).thenAnswer(
      (_) async => const <Value>[],
    );
  });

  tearDown(() async {
    await temporalController.close();
    await sessionDayKeyService.dispose();
    await projectSubject.close();
    await tasksSubject.close();
    await completionsSubject.close();
    await exceptionsSubject.close();
    await routinesSubject.close();
    await routineCompletionsSubject.close();
    await routineSkipsSubject.close();
    await cacheManager.dispose();
    await demoModeService.dispose();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    String projectId = 'project-1',
  }) async {
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
          RepositoryProvider<RoutineRepositoryContract>.value(
            value: routineRepository,
          ),
          RepositoryProvider<AppErrorReporter>.value(value: errorReporter),
          RepositoryProvider<SessionSharedDataService>.value(
            value: sharedDataService,
          ),
          RepositoryProvider<RoutineWriteService>.value(
            value: routineWriteService,
          ),
          RepositoryProvider<EditorLauncher>.value(value: editorLauncher),
          RepositoryProvider<NowService>.value(
            value: FakeNowService(DateTime(2025, 1, 15, 9)),
          ),
          RepositoryProvider<DemoModeService>.value(value: demoModeService),
          RepositoryProvider<SettingsRepositoryContract>.value(
            value: settingsRepository,
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<GlobalSettingsBloc>.value(value: globalSettingsBloc),
          ],
          child: ProjectDetailPage(projectId: projectId),
        ),
      ),
    );
    await tester.pump(speedDialInitDelay);
  }

  Routine buildRoutine({
    required String id,
    required String name,
    required String projectId,
  }) {
    return Routine(
      id: id,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      name: name,
      projectId: projectId,
      periodType: RoutinePeriodType.week,
      scheduleMode: RoutineScheduleMode.scheduled,
      targetCount: 1,
      scheduleDays: const [1],
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

  testWidgetsSafe('shows compact notes preview by default', (tester) async {
    await pumpPage(tester);

    final project = TestData.project(
      id: 'project-1',
      name: 'Notes Project',
      description: 'Project notes preview text',
    );
    projectSubject.add(project);
    tasksSubject.add(const <Task>[]);
    await tester.pumpForStream();

    expect(find.byKey(const Key('project-notes-preview-card')), findsOneWidget);
    expect(find.byType(FleatherEditor), findsOneWidget);
    expect(find.byKey(const Key('project-notes-done-button')), findsNothing);
  });

  testWidgetsSafe('expands and collapses notes editor on demand', (
    tester,
  ) async {
    await pumpPage(tester);

    final project = TestData.project(
      id: 'project-1',
      name: 'Notes Project',
      description: 'Expand me',
    );
    projectSubject.add(project);
    tasksSubject.add(const <Task>[]);
    await tester.pumpForStream();

    await tester.tap(find.byKey(const Key('project-notes-preview-card')));
    await tester.pumpForStream();

    expect(find.byKey(const Key('project-notes-done-button')), findsOneWidget);
    expect(find.byType(FleatherToolbar), findsNothing);

    await tester.tap(find.byType(FleatherEditor));
    await tester.pumpForStream();

    expect(find.byType(FleatherToolbar), findsOneWidget);

    await tester.tap(find.byKey(const Key('project-notes-done-button')));
    await tester.pumpForStream();

    expect(find.byKey(const Key('project-notes-preview-card')), findsOneWidget);
    expect(find.byKey(const Key('project-notes-done-button')), findsNothing);
  });

  testWidgetsSafe(
    'shows combined empty state when project has no tasks and no routines',
    (tester) async {
      await pumpPage(tester);

      final project = TestData.project(
        id: 'project-1',
        name: 'Routine Project',
      );
      projectSubject.add(project);
      tasksSubject.add(const <Task>[]);
      routinesSubject.add(const <Routine>[]);
      await tester.pumpForStream();

      final l10n = tester.element(find.byType(ProjectDetailPage)).l10n;
      expect(find.text(l10n.projectDetailEmptyTitle), findsOneWidget);
      expect(find.text(l10n.addTaskAction), findsOneWidget);
      expect(find.text(l10n.tasksTitle), findsNothing);
      expect(find.text(l10n.routinesTitle), findsNothing);
    },
  );

  testWidgetsSafe('shows routine log action for project routines', (
    tester,
  ) async {
    await pumpPage(tester);

    final project = TestData.project(id: 'project-1', name: 'Routine Project');
    final routine = buildRoutine(
      id: 'routine-1',
      name: 'Morning Flow',
      projectId: project.id,
    );

    projectSubject.add(project);
    tasksSubject.add(const <Task>[]);
    routinesSubject.add([routine]);
    await tester.pumpForStream();

    final l10n = tester.element(find.byType(ProjectDetailPage)).l10n;
    expect(find.text('Tasks'), findsNothing);
    expect(find.text(l10n.routinesTitle), findsOneWidget);
    expect(find.text('Morning Flow'), findsOneWidget);
    expect(find.text(l10n.routineLogLabel), findsOneWidget);
  });

  testWidgetsSafe('shows routine unlog action when completed today', (
    tester,
  ) async {
    await pumpPage(tester);

    final project = TestData.project(id: 'project-1', name: 'Routine Project');
    final routine = buildRoutine(
      id: 'routine-1',
      name: 'Morning Flow',
      projectId: project.id,
    );
    final completion = RoutineCompletion(
      id: 'completion-1',
      routineId: routine.id,
      completedAtUtc: DateTime.utc(2025, 1, 15, 9),
      createdAtUtc: DateTime.utc(2025, 1, 15, 9),
      completedDayLocal: DateTime(2025, 1, 15),
      completedTimeLocalMinutes: 9 * 60,
    );

    projectSubject.add(project);
    tasksSubject.add(const <Task>[]);
    routinesSubject.add([routine]);
    routineCompletionsSubject.add([completion]);
    await tester.pumpForStream();

    final l10n = tester.element(find.byType(ProjectDetailPage)).l10n;
    expect(find.text(l10n.routineUnlogLabel), findsOneWidget);
  });

  testWidgetsSafe(
    'shows only task section when tasks exist and routines do not',
    (
      tester,
    ) async {
      await pumpPage(tester);

      final project = TestData.project(id: 'project-1', name: 'Task Project');
      projectSubject.add(project);
      tasksSubject.add([TestData.task(name: 'Task One')]);
      routinesSubject.add(const <Routine>[]);
      await tester.pumpForStream();

      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Routines'), findsNothing);
      expect(find.text('Task One'), findsOneWidget);
    },
  );

  testWidgetsSafe('shows inbox empty state when inbox has no tasks', (
    tester,
  ) async {
    final inboxId = ProjectGroupingRef.inbox().stableKey;
    await pumpPage(tester, projectId: inboxId);

    projectSubject.add(TestData.project(id: inboxId, name: 'Inbox'));
    tasksSubject.add(const <Task>[]);
    await tester.pumpForStream();

    expect(find.text('Capture first, organize later'), findsOneWidget);
    expect(find.text('Quick add'), findsOneWidget);
  });

  testWidgetsSafe(
    'does not force overview restart after routine editor closes',
    (
      tester,
    ) async {
      final completer = Completer<void>();
      when(
        () => editorLauncher.openRoutineEditor(
          any(),
          routineId: any(named: 'routineId'),
          defaultProjectId: any(named: 'defaultProjectId'),
          openToProjectPicker: any(named: 'openToProjectPicker'),
          showDragHandle: any(named: 'showDragHandle'),
        ),
      ).thenAnswer((_) => completer.future);

      await pumpPage(tester);

      final project = TestData.project(
        id: 'project-1',
        name: 'Routine Project',
      );
      projectSubject.add(project);
      tasksSubject.add(const <Task>[]);
      await tester.pumpForStream();

      verify(() => projectRepository.watchById('project-1')).called(1);
      clearInteractions(projectRepository);

      final speedDial = tester.widget<TaskRoutineAddSpeedDial>(
        find.byType(TaskRoutineAddSpeedDial),
      );
      speedDial.onCreateRoutine();
      await tester.pump();

      completer.complete();
      await tester.pumpForStream();

      verify(
        () => editorLauncher.openRoutineEditor(
          any(),
          routineId: null,
          defaultProjectId: 'project-1',
          openToProjectPicker: false,
          showDragHandle: true,
        ),
      ).called(1);
      verifyNever(() => projectRepository.watchById('project-1'));
    },
  );
}

class _FakeClock implements Clock {
  _FakeClock(this.now);

  final DateTime now;

  @override
  DateTime nowLocal() => now;

  @override
  DateTime nowUtc() => now.toUtc();
}
