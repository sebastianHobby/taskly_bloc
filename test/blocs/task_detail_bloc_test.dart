import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/utils/detail_bloc_error.dart';
import 'package:taskly_bloc/core/utils/not_found_entity.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_detail_bloc.dart';

import '../mocks/repository_mocks.dart';

void main() {
  late MockTaskRepository mockRepository;
  late MockProjectRepository mockProjectRepository;
  late MockLabelRepository mockLabelRepository;
  late Task sampleTask;

  setUp(() {
    mockRepository = MockTaskRepository();
    mockProjectRepository = MockProjectRepository();
    mockLabelRepository = MockLabelRepository();
    // default stubs for initial data load
    when(
      () => mockProjectRepository.getAll(),
    ).thenAnswer((_) async => <Project>[]);
    when(() => mockLabelRepository.getAll()).thenAnswer((_) async => <Label>[]);
    final now = DateTime.now();
    sampleTask = Task(
      id: 't1',
      createdAt: now,
      updatedAt: now,
      name: 'Task 1',
      completed: false,
    );
  });

  blocTest<TaskDetailBloc, TaskDetailState>(
    'get emits loadInProgress then loadSuccess when repository returns a task',
    setUp: () {
      when(
        () => mockRepository.getById('t1'),
      ).thenAnswer((_) async => sampleTask);
    },
    build: () => TaskDetailBloc(
      taskRepository: mockRepository,
      projectRepository: mockProjectRepository,
      labelRepository: mockLabelRepository,
      taskId: 't1',
    ),
    expect: () => <Object>[
      isA<TaskDetailLoadInProgress>(),
      isA<TaskDetailLoadSuccess>(),
    ],
  );

  blocTest<TaskDetailBloc, TaskDetailState>(
    'get emits operationFailure when repository returns null',
    setUp: () {
      when(
        () => mockRepository.getById('missing'),
      ).thenAnswer((_) async => null);
    },
    build: () => TaskDetailBloc(
      taskRepository: mockRepository,
      projectRepository: mockProjectRepository,
      labelRepository: mockLabelRepository,
      taskId: 'missing',
    ),
    expect: () => <TaskDetailState>[
      const TaskDetailState.loadInProgress(),
      const TaskDetailState.operationFailure(
        errorDetails: DetailBlocError<Task>(error: NotFoundEntity.task),
      ),
    ],
  );

  blocTest<TaskDetailBloc, TaskDetailState>(
    'create emits operationSuccess on successful create',
    setUp: () {
      when(
        () => mockRepository.create(
          name: any(named: 'name'),
          description: any(named: 'description'),
          projectId: any(named: 'projectId'),
          labelIds: any(named: 'labelIds'),
        ),
      ).thenAnswer((_) async {});
    },
    build: () => TaskDetailBloc(
      taskRepository: mockRepository,
      projectRepository: mockProjectRepository,
      labelRepository: mockLabelRepository,
    ),
    act: (bloc) =>
        bloc.add(const TaskDetailEvent.create(name: 'n', description: null)),
    wait: const Duration(milliseconds: 100),
    expect: () => <Object>[
      isA<TaskDetailLoadInProgress>(),
      isA<TaskDetailInitialDataLoadSuccess>(),
      isA<TaskDetailOperationSuccess>(),
    ],
  );

  blocTest<TaskDetailBloc, TaskDetailState>(
    'update emits operationSuccess on successful update',
    setUp: () {
      when(
        () => mockRepository.getById('t1'),
      ).thenAnswer((_) async => sampleTask);
      when(
        () => mockRepository.update(
          id: any(named: 'id'),
          name: any(named: 'name'),
          completed: any(named: 'completed'),
          description: any(named: 'description'),
          startDate: any(named: 'startDate'),
          deadlineDate: any(named: 'deadlineDate'),
          projectId: any(named: 'projectId'),
          repeatIcalRrule: any(named: 'repeatIcalRrule'),
          labelIds: any(named: 'labelIds'),
        ),
      ).thenAnswer((_) async {});
    },
    build: () => TaskDetailBloc(
      taskRepository: mockRepository,
      projectRepository: mockProjectRepository,
      labelRepository: mockLabelRepository,
      taskId: 't1',
    ),
    act: (bloc) async {
      await Future<void>.delayed(const Duration(milliseconds: 1));
      bloc.add(
        const TaskDetailEvent.update(
          id: 't1',
          name: 'n',
          description: null,
          completed: false,
        ),
      );
    },
    wait: const Duration(milliseconds: 100),
    expect: () => <Object>[
      isA<TaskDetailLoadInProgress>(),
      isA<TaskDetailLoadSuccess>(),
      isA<TaskDetailOperationSuccess>(),
    ],
  );
}
