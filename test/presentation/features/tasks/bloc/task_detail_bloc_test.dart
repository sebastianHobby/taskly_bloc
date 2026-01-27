@Tags(['unit', 'tasks'])
library;

import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/telemetry.dart';

class MockTaskRepository extends Mock implements TaskRepositoryContract {}

class MockProjectRepository extends Mock implements ProjectRepositoryContract {}

class MockValueRepository extends Mock implements ValueRepositoryContract {}

class MockTaskWriteService extends Mock implements TaskWriteService {}

class MockAppErrorReporter extends Mock implements AppErrorReporter {}

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

  late MockTaskRepository taskRepository;
  late MockProjectRepository projectRepository;
  late MockValueRepository valueRepository;
  late MockTaskWriteService taskWriteService;
  late MockAppErrorReporter errorReporter;

  TaskDetailBloc buildBloc() {
    return TaskDetailBloc(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      valueRepository: valueRepository,
      taskWriteService: taskWriteService,
      errorReporter: errorReporter,
      autoLoad: false,
    );
  }

  setUp(() {
    taskRepository = MockTaskRepository();
    projectRepository = MockProjectRepository();
    valueRepository = MockValueRepository();
    taskWriteService = MockTaskWriteService();
    errorReporter = MockAppErrorReporter();
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
      when(
        () => taskWriteService.create(
          any(),
          context: any(named: 'context'),
        ),
      ).thenAnswer(
        (_) async => const CommandValidationFailure(
          ValidationFailure(
            formErrors: [
              ValidationError(code: 'invalid', messageKey: 'invalid'),
            ],
          ),
        ),
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(
      const TaskDetailEvent.create(
        command: CreateTaskCommand(name: 'Task', completed: false),
      ),
    ),
    expect: () => [isA<TaskDetailValidationFailure>()],
  );

  blocTestSafe<TaskDetailBloc, TaskDetailState>(
    'creates task with operation context metadata',
    build: () {
      when(
        () => taskWriteService.create(
          any(),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async => const CommandSuccess());
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
        () => taskWriteService.create(
          any(),
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
