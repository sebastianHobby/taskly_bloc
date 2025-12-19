import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_detail_bloc.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;
  late TaskTableData sampleTask;

  setUpAll(() {
    registerFallbackValue(TaskTableCompanion(id: const Value('f')));
  });

  setUp(() {
    mockRepository = MockTaskRepository();
    sampleTask = TaskTableData(
      id: 't1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: 'Task 1',
      completed: false,
    );
  });

  blocTest<TaskDetailBloc, TaskDetailState>(
    'get emits loadInProgress then loadSuccess when repository returns a task',
    setUp: () {
      when(
        () => mockRepository.getTaskById('t1'),
      ).thenAnswer((_) async => sampleTask);
    },
    build: () => TaskDetailBloc(taskRepository: mockRepository, taskId: 't1'),
    expect: () => <TaskDetailState>[
      const TaskDetailState.loadInProgress(),
      TaskDetailState.loadSuccess(task: sampleTask),
    ],
  );

  blocTest<TaskDetailBloc, TaskDetailState>(
    'get emits operationFailure when repository returns null',
    setUp: () {
      when(
        () => mockRepository.getTaskById('missing'),
      ).thenAnswer((_) async => null);
    },
    build: () =>
        TaskDetailBloc(taskRepository: mockRepository, taskId: 'missing'),
    expect: () => <TaskDetailState>[
      const TaskDetailState.loadInProgress(),
      const TaskDetailState.operationFailure(
        errorDetails: TaskDetailError(message: 'Task not found'),
      ),
    ],
  );

  blocTest<TaskDetailBloc, TaskDetailState>(
    'create emits operationSuccess on successful create',
    setUp: () {
      when(() => mockRepository.createTask(any())).thenAnswer((_) async => 1);
    },
    build: () => TaskDetailBloc(taskRepository: mockRepository),
    act: (bloc) =>
        bloc.add(const TaskDetailEvent.create(name: 'n', description: null)),
    expect: () => <TaskDetailState>[
      const TaskDetailState.operationSuccess(
        message: 'Task created successfully.',
      ),
    ],
  );

  blocTest<TaskDetailBloc, TaskDetailState>(
    'update emits operationSuccess on successful update',
    setUp: () {
      when(
        () => mockRepository.updateTask(any()),
      ).thenAnswer((_) async => 1);
    },
    build: () => TaskDetailBloc(taskRepository: mockRepository),
    act: (bloc) => bloc.add(
      const TaskDetailEvent.update(
        id: 't1',
        name: 'n',
        description: null,
        completed: false,
      ),
    ),
    expect: () => <TaskDetailState>[
      const TaskDetailState.operationSuccess(
        message: 'Task updated successfully.',
      ),
    ],
  );
}
