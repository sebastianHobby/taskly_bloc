@Tags(['unit', 'tasks'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_domain/taskly_domain.dart';

import '../../../../mocks/feature_mocks.dart';
import '../../../../mocks/repository_mocks.dart';

class MockMyDayRepositoryContract extends Mock
    implements MyDayRepositoryContract {}

class MockHomeDayKeyService extends Mock implements HomeDayKeyService {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
    registerFallbackValue(
      const CreateTaskCommand(name: 'Test', completed: false),
    );
    registerFallbackValue(
      const UpdateTaskCommand(id: 'task-1', name: 'Test', completed: false),
    );
    registerFallbackValue(
      const OperationContext(
        correlationId: 'corr-1',
        feature: 'tasks',
        intent: 'test',
        operation: 'test',
      ),
    );
  });

  setUp(setUpTestEnvironment);

  late MockTaskRepositoryContract taskRepository;
  late MockProjectRepositoryContract projectRepository;
  late MockTaskChecklistRepositoryContract taskChecklistRepository;
  late MockValueRepositoryContract valueRepository;
  late MockOccurrenceCommandService occurrenceCommandService;
  late TaskWriteService taskWriteService;
  late MockMyDayRepositoryContract myDayRepository;
  late MockHomeDayKeyService homeDayKeyService;
  late TaskMyDayWriteService taskMyDayWriteService;
  late AppErrorReporter errorReporter;
  late DemoModeService demoModeService;
  late DemoDataProvider demoDataProvider;

  TaskDetailBloc buildBloc() {
    return TaskDetailBloc(
      taskRepository: taskRepository,
      taskChecklistRepository: taskChecklistRepository,
      projectRepository: projectRepository,
      valueRepository: valueRepository,
      taskWriteService: taskWriteService,
      taskMyDayWriteService: taskMyDayWriteService,
      errorReporter: errorReporter,
      demoModeService: demoModeService,
      demoDataProvider: demoDataProvider,
      autoLoad: false,
    );
  }

  setUp(() {
    taskRepository = MockTaskRepositoryContract();
    projectRepository = MockProjectRepositoryContract();
    taskChecklistRepository = MockTaskChecklistRepositoryContract();
    valueRepository = MockValueRepositoryContract();
    occurrenceCommandService = MockOccurrenceCommandService();
    taskWriteService = TaskWriteService(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      occurrenceCommandService: occurrenceCommandService,
    );
    myDayRepository = MockMyDayRepositoryContract();
    homeDayKeyService = MockHomeDayKeyService();
    taskMyDayWriteService = TaskMyDayWriteService(
      taskWriteService: taskWriteService,
      myDayRepository: myDayRepository,
      dayKeyService: homeDayKeyService,
    );
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );
    demoModeService = DemoModeService();
    demoDataProvider = DemoDataProvider();

    addTearDown(demoModeService.dispose);
  });

  blocTestSafe<TaskDetailBloc, TaskDetailState>(
    'loads initial data for create flow',
    build: () {
      when(
        () => projectRepository.getAll(),
      ).thenAnswer((_) async => [TestData.project()]);
      when(
        () => valueRepository.getAll(),
      ).thenAnswer((_) async => [TestData.value()]);
      return buildBloc();
    },
    act: (bloc) => bloc.add(const TaskDetailEvent.loadInitialData()),
    expect: () => [
      const TaskDetailLoadInProgress(),
      isA<TaskDetailInitialDataLoadSuccess>()
          .having((s) => s.availableProjects.length, 'projects', 1)
          .having((s) => s.availableValues.length, 'values', 1),
    ],
  );

  blocTestSafe<TaskDetailBloc, TaskDetailState>(
    'emits failure when task is not found',
    build: () {
      when(
        () => taskRepository.getById('missing'),
      ).thenAnswer((_) async => null);
      return buildBloc();
    },
    act: (bloc) => bloc.add(const TaskDetailEvent.loadById(taskId: 'missing')),
    expect: () => [
      const TaskDetailLoadInProgress(),
      isA<TaskDetailOperationFailure>().having(
        (s) => s.errorDetails.error,
        'error',
        NotFoundEntity.task,
      ),
    ],
  );

  blocTestSafe<TaskDetailBloc, TaskDetailState>(
    'emits validation failure when create command fails validation',
    build: () {
      return buildBloc();
    },
    act: (bloc) => bloc.add(
      const TaskDetailEvent.create(
        command: CreateTaskCommand(name: '', completed: false),
      ),
    ),
    expect: () => [isA<TaskDetailValidationFailure>()],
  );

  blocTestSafe<TaskDetailBloc, TaskDetailState>(
    'creates task with operation context metadata',
    build: () {
      when(
        () => taskRepository.create(
          name: any(named: 'name'),
          description: any(named: 'description'),
          completed: any(named: 'completed'),
          startDate: any(named: 'startDate'),
          deadlineDate: any(named: 'deadlineDate'),
          projectId: any(named: 'projectId'),
          priority: any(named: 'priority'),
          repeatIcalRrule: any(named: 'repeatIcalRrule'),
          repeatFromCompletion: any(named: 'repeatFromCompletion'),
          seriesEnded: any(named: 'seriesEnded'),
          valueIds: any(named: 'valueIds'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});
      return buildBloc();
    },
    act: (bloc) => bloc.add(
      const TaskDetailEvent.create(
        command: CreateTaskCommand(name: 'Task', completed: false),
      ),
    ),
    expect: () => [isA<TaskDetailOperationSuccess>()],
    verify: (_) {
      final captured = verify(
        () => taskRepository.create(
          name: any(named: 'name'),
          description: any(named: 'description'),
          completed: any(named: 'completed'),
          startDate: any(named: 'startDate'),
          deadlineDate: any(named: 'deadlineDate'),
          projectId: any(named: 'projectId'),
          priority: any(named: 'priority'),
          repeatIcalRrule: any(named: 'repeatIcalRrule'),
          repeatFromCompletion: any(named: 'repeatFromCompletion'),
          seriesEnded: any(named: 'seriesEnded'),
          valueIds: any(named: 'valueIds'),
          context: captureAny(named: 'context'),
        ),
      ).captured;
      final context = captured.single as OperationContext;
      expect(context.feature, 'tasks');
      expect(context.screen, 'task_detail');
      expect(context.intent, 'task_create_requested');
      expect(context.operation, 'tasks.create');
      expect(context.correlationId, isNotEmpty);
    },
  );
}
