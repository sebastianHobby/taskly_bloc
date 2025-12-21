import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/value_repository_contract.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_detail_bloc.dart';

class MockTaskRepository extends Mock implements TaskRepositoryContract {}

class MockProjectRepository extends Mock implements ProjectRepositoryContract {}

class MockValueRepository extends Mock implements ValueRepositoryContract {}

class MockLabelRepository extends Mock implements LabelRepositoryContract {}

void main() {
  late MockTaskRepository mockRepository;
  late MockProjectRepository mockProjectRepository;
  late MockValueRepository mockValueRepository;
  late MockLabelRepository mockLabelRepository;

  setUp(() {
    mockRepository = MockTaskRepository();
    mockProjectRepository = MockProjectRepository();
    mockValueRepository = MockValueRepository();
    mockLabelRepository = MockLabelRepository();
    when(
      () => mockProjectRepository.getAll(),
    ).thenAnswer((_) async => <Project>[]);
    when(
      () => mockValueRepository.getAll(),
    ).thenAnswer((_) async => <ValueModel>[]);
    when(() => mockLabelRepository.getAll()).thenAnswer((_) async => <Label>[]);
  });

  blocTest<TaskDetailBloc, TaskDetailState>(
    'create emits operationFailure when repository throws',
    setUp: () {
      when(
        () => mockRepository.create(
          name: any(named: 'name'),
          description: any(named: 'description'),
          projectId: any(named: 'projectId'),
          valueIds: any(named: 'valueIds'),
          labelIds: any(named: 'labelIds'),
        ),
      ).thenThrow(Exception('oh no'));
    },
    build: () => TaskDetailBloc(
      taskRepository: mockRepository,
      projectRepository: mockProjectRepository,
      valueRepository: mockValueRepository,
      labelRepository: mockLabelRepository,
    ),
    act: (bloc) =>
        bloc.add(const TaskDetailEvent.create(name: 'n', description: null)),
    expect: () => <dynamic>[
      isA<TaskDetailLoadInProgress>(),
      isA<TaskDetailOperationFailure>(),
      isA<TaskDetailInitialDataLoadSuccess>(),
    ],
  );

  blocTest<TaskDetailBloc, TaskDetailState>(
    'update emits operationFailure when repository throws',
    setUp: () {
      final now = DateTime.now();
      final loadedTask = Task(
        id: 't1',
        createdAt: now,
        updatedAt: now,
        name: 'Task 1',
        completed: false,
      );

      when(
        () => mockRepository.get('t1', withRelated: true),
      ).thenAnswer((_) async => loadedTask);

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
          valueIds: any(named: 'valueIds'),
          labelIds: any(named: 'labelIds'),
        ),
      ).thenThrow(Exception('bad'));
    },
    build: () => TaskDetailBloc(
      taskRepository: mockRepository,
      projectRepository: mockProjectRepository,
      valueRepository: mockValueRepository,
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
    wait: const Duration(milliseconds: 10),
    expect: () => <dynamic>[
      isA<TaskDetailLoadInProgress>(),
      isA<TaskDetailLoadSuccess>(),
      isA<TaskDetailOperationFailure>(),
    ],
  );

  blocTest<TaskDetailBloc, TaskDetailState>(
    'delete emits operationFailure when repository throws',
    setUp: () {
      when(
        () => mockRepository.delete('t1'),
      ).thenThrow(Exception('bad delete'));
    },
    build: () => TaskDetailBloc(
      taskRepository: mockRepository,
      projectRepository: mockProjectRepository,
      valueRepository: mockValueRepository,
      labelRepository: mockLabelRepository,
    ),
    act: (bloc) async {
      await Future<void>.delayed(const Duration(milliseconds: 1));
      bloc.add(const TaskDetailEvent.delete(id: 't1'));
    },
    wait: const Duration(milliseconds: 10),
    expect: () => <dynamic>[
      isA<TaskDetailLoadInProgress>(),
      isA<TaskDetailInitialDataLoadSuccess>(),
      isA<TaskDetailOperationFailure>(),
    ],
  );

  blocTest<TaskDetailBloc, TaskDetailState>(
    'loadInitialData emits operationFailure when a dependency throws',
    setUp: () {
      when(() => mockProjectRepository.getAll()).thenThrow(Exception('boom'));
    },
    build: () => TaskDetailBloc(
      taskRepository: mockRepository,
      projectRepository: mockProjectRepository,
      valueRepository: mockValueRepository,
      labelRepository: mockLabelRepository,
    ),
    expect: () => <dynamic>[
      isA<TaskDetailLoadInProgress>(),
      isA<TaskDetailOperationFailure>(),
    ],
  );

  blocTest<TaskDetailBloc, TaskDetailState>(
    'update emits operationSuccess without preloading',
    setUp: () {
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
          valueIds: any(named: 'valueIds'),
          labelIds: any(named: 'labelIds'),
        ),
      ).thenAnswer((_) async {});
    },
    build: () => TaskDetailBloc(
      taskRepository: mockRepository,
      projectRepository: mockProjectRepository,
      valueRepository: mockValueRepository,
      labelRepository: mockLabelRepository,
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
    wait: const Duration(milliseconds: 10),
    expect: () => <dynamic>[
      const TaskDetailState.loadInProgress(),
      isA<TaskDetailInitialDataLoadSuccess>(),
      const TaskDetailState.operationSuccess(
        message: 'Task updated successfully.',
      ),
    ],
  );
}
