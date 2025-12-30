import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/core/utils/not_found_entity.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';

import '../../../../fixtures/test_data.dart';
import '../../../../mocks/repository_mocks.dart';

void main() {
  late MockTaskRepository mockTaskRepository;
  late MockProjectRepository mockProjectRepository;
  late MockLabelRepository mockLabelRepository;
  late TaskDetailBloc bloc;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(TestData.task());
    registerFallbackValue(TestData.project());
    registerFallbackValue(TestData.label());
  });

  setUp(() {
    mockTaskRepository = MockTaskRepository();
    mockProjectRepository = MockProjectRepository();
    mockLabelRepository = MockLabelRepository();

    // TaskDetailBloc dispatches a load event in its constructor.
    // Provide safe defaults so tests that don't care about these values
    // don't fail due to unstubbed repository calls.
    when(
      () => mockProjectRepository.getAll(),
    ).thenAnswer((_) async => <Project>[]);
    when(
      () => mockLabelRepository.getAll(),
    ).thenAnswer((_) async => <Label>[]);
  });

  tearDown(() {
    bloc.close();
  });

  group('TaskDetailBloc', () {
    group('initialization', () {
      test('initial state is TaskDetailInitial', () {
        bloc = TaskDetailBloc(
          taskRepository: mockTaskRepository,
          projectRepository: mockProjectRepository,
          labelRepository: mockLabelRepository,
        );

        expect(bloc.state, isA<TaskDetailInitial>());
      });

      test('loads initial data when no taskId provided', () async {
        final projects = [TestData.project()];
        final labels = [TestData.label()];

        when(
          () => mockProjectRepository.getAll(),
        ).thenAnswer((_) async => projects);
        when(
          () => mockLabelRepository.getAll(),
        ).thenAnswer((_) async => labels);

        bloc = TaskDetailBloc(
          taskRepository: mockTaskRepository,
          projectRepository: mockProjectRepository,
          labelRepository: mockLabelRepository,
        );

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<TaskDetailLoadInProgress>(),
            predicate<TaskDetailInitialDataLoadSuccess>(
              (state) =>
                  state.availableProjects.length == projects.length &&
                  state.availableProjects.first.id == projects.first.id &&
                  state.availableLabels.length == labels.length &&
                  state.availableLabels.first.id == labels.first.id,
            ),
          ]),
        );
      });

      test('loads task when taskId provided', () async {
        final task = TestData.task(id: 'task-1');
        final projects = [TestData.project()];
        final labels = [TestData.label()];

        when(
          () => mockTaskRepository.getById('task-1'),
        ).thenAnswer((_) async => task);
        when(
          () => mockProjectRepository.getAll(),
        ).thenAnswer((_) async => projects);
        when(
          () => mockLabelRepository.getAll(),
        ).thenAnswer((_) async => labels);

        bloc = TaskDetailBloc(
          taskRepository: mockTaskRepository,
          projectRepository: mockProjectRepository,
          labelRepository: mockLabelRepository,
          taskId: 'task-1',
        );

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<TaskDetailLoadInProgress>(),
            predicate<TaskDetailLoadSuccess>(
              (state) =>
                  state.task.id == task.id &&
                  state.availableProjects.length == projects.length &&
                  state.availableProjects.first.id == projects.first.id &&
                  state.availableLabels.length == labels.length &&
                  state.availableLabels.first.id == labels.first.id,
            ),
          ]),
        );
      });
    });

    group('loadInitialData event', () {
      blocTest<TaskDetailBloc, TaskDetailState>(
        'emits success state with projects and labels',
        build: () {
          final projects = [TestData.project()];
          final labels = [TestData.label()];

          when(
            () => mockProjectRepository.getAll(),
          ).thenAnswer((_) async => projects);
          when(
            () => mockLabelRepository.getAll(),
          ).thenAnswer((_) async => labels);

          return TaskDetailBloc(
            taskRepository: mockTaskRepository,
            projectRepository: mockProjectRepository,
            labelRepository: mockLabelRepository,
            autoLoad: false,
          );
        },
        act: (bloc) => bloc.add(const TaskDetailEvent.loadInitialData()),
        expect: () => [
          isA<TaskDetailLoadInProgress>(),
          predicate<TaskDetailInitialDataLoadSuccess>(
            (state) =>
                state.availableProjects.isNotEmpty &&
                state.availableLabels.isNotEmpty,
          ),
        ],
      );

      blocTest<TaskDetailBloc, TaskDetailState>(
        'emits failure state on error',
        build: () {
          when(
            () => mockProjectRepository.getAll(),
          ).thenThrow(Exception('Failed to load projects'));
          when(() => mockLabelRepository.getAll()).thenAnswer((_) async => []);

          return TaskDetailBloc(
            taskRepository: mockTaskRepository,
            projectRepository: mockProjectRepository,
            labelRepository: mockLabelRepository,
            autoLoad: false,
          );
        },
        act: (bloc) => bloc.add(const TaskDetailEvent.loadInitialData()),
        expect: () => [
          isA<TaskDetailLoadInProgress>(),
          isA<TaskDetailOperationFailure>(),
        ],
      );
    });

    group('get event', () {
      blocTest<TaskDetailBloc, TaskDetailState>(
        'emits load success when task exists',
        build: () {
          final task = TestData.task(id: 'task-1');
          final projects = [TestData.project()];
          final labels = [TestData.label()];

          when(
            () => mockTaskRepository.getById('task-1'),
          ).thenAnswer((_) async => task);
          when(
            () => mockProjectRepository.getAll(),
          ).thenAnswer((_) async => projects);
          when(
            () => mockLabelRepository.getAll(),
          ).thenAnswer((_) async => labels);

          return TaskDetailBloc(
            taskRepository: mockTaskRepository,
            projectRepository: mockProjectRepository,
            labelRepository: mockLabelRepository,
            autoLoad: false,
          );
        },
        act: (bloc) => bloc.add(const TaskDetailEvent.get(taskId: 'task-1')),
        expect: () => [
          isA<TaskDetailLoadInProgress>(),
          predicate<TaskDetailLoadSuccess>(
            (state) => state.task.id == 'task-1',
          ),
        ],
      );

      blocTest<TaskDetailBloc, TaskDetailState>(
        'emits failure when task not found',
        build: () {
          when(
            () => mockTaskRepository.getById('nonexistent'),
          ).thenAnswer((_) async => null);

          return TaskDetailBloc(
            taskRepository: mockTaskRepository,
            projectRepository: mockProjectRepository,
            labelRepository: mockLabelRepository,
            autoLoad: false,
          );
        },
        act: (bloc) =>
            bloc.add(const TaskDetailEvent.get(taskId: 'nonexistent')),
        expect: () => [
          isA<TaskDetailLoadInProgress>(),
          predicate<TaskDetailOperationFailure>(
            (state) => state.errorDetails.error == NotFoundEntity.task,
          ),
        ],
      );

      blocTest<TaskDetailBloc, TaskDetailState>(
        'emits failure on repository error',
        build: () {
          when(
            () => mockTaskRepository.getById(any()),
          ).thenThrow(Exception('Database error'));

          return TaskDetailBloc(
            taskRepository: mockTaskRepository,
            projectRepository: mockProjectRepository,
            labelRepository: mockLabelRepository,
            autoLoad: false,
          );
        },
        act: (bloc) => bloc.add(const TaskDetailEvent.get(taskId: 'task-1')),
        expect: () => [
          isA<TaskDetailLoadInProgress>(),
          isA<TaskDetailOperationFailure>(),
        ],
      );
    });

    group('create event', () {
      blocTest<TaskDetailBloc, TaskDetailState>(
        'creates task and emits success',
        build: () {
          when(
            () => mockTaskRepository.create(
              name: any(named: 'name'),
              description: any(named: 'description'),
              completed: any(named: 'completed'),
              startDate: any(named: 'startDate'),
              deadlineDate: any(named: 'deadlineDate'),
              projectId: any(named: 'projectId'),
              repeatIcalRrule: any(named: 'repeatIcalRrule'),
              labelIds: any(named: 'labelIds'),
              isNextAction: any(named: 'isNextAction'),
              nextActionPriority: any(named: 'nextActionPriority'),
              nextActionNotes: any(named: 'nextActionNotes'),
            ),
          ).thenAnswer((_) async {});

          return TaskDetailBloc(
            taskRepository: mockTaskRepository,
            projectRepository: mockProjectRepository,
            labelRepository: mockLabelRepository,
            autoLoad: false,
          );
        },
        act: (bloc) => bloc.add(
          const TaskDetailEvent.create(
            name: 'New Task',
            description: 'Task description',
          ),
        ),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          predicate<TaskDetailOperationSuccess>(
            (state) => state.operation == EntityOperation.create,
          ),
        ],
        verify: (_) {
          verify(
            () => mockTaskRepository.create(
              name: 'New Task',
              description: 'Task description',
              startDate: any(named: 'startDate'),
              deadlineDate: any(named: 'deadlineDate'),
              projectId: any(named: 'projectId'),
              repeatIcalRrule: any(named: 'repeatIcalRrule'),
              labelIds: any(named: 'labelIds'),
              isNextAction: any(named: 'isNextAction'),
              nextActionPriority: any(named: 'nextActionPriority'),
              nextActionNotes: any(named: 'nextActionNotes'),
            ),
          ).called(1);
        },
      );

      blocTest<TaskDetailBloc, TaskDetailState>(
        'emits failure when create fails',
        build: () {
          when(
            () => mockTaskRepository.create(
              name: any(named: 'name'),
              description: any(named: 'description'),
              completed: any(named: 'completed'),
              startDate: any(named: 'startDate'),
              deadlineDate: any(named: 'deadlineDate'),
              projectId: any(named: 'projectId'),
              repeatIcalRrule: any(named: 'repeatIcalRrule'),
              labelIds: any(named: 'labelIds'),
              isNextAction: any(named: 'isNextAction'),
              nextActionPriority: any(named: 'nextActionPriority'),
              nextActionNotes: any(named: 'nextActionNotes'),
            ),
          ).thenThrow(Exception('Create failed'));

          return TaskDetailBloc(
            taskRepository: mockTaskRepository,
            projectRepository: mockProjectRepository,
            labelRepository: mockLabelRepository,
            autoLoad: false,
          );
        },
        act: (bloc) => bloc.add(
          const TaskDetailEvent.create(
            name: 'New Task',
            description: null,
          ),
        ),
        expect: () => [
          isA<TaskDetailOperationFailure>(),
        ],
      );
    });

    group('update event', () {
      blocTest<TaskDetailBloc, TaskDetailState>(
        'updates task and emits success',
        build: () {
          when(
            () => mockTaskRepository.update(
              id: any(named: 'id'),
              name: any(named: 'name'),
              description: any(named: 'description'),
              completed: any(named: 'completed'),
              projectId: any(named: 'projectId'),
              startDate: any(named: 'startDate'),
              deadlineDate: any(named: 'deadlineDate'),
              repeatIcalRrule: any(named: 'repeatIcalRrule'),
              labelIds: any(named: 'labelIds'),
            ),
          ).thenAnswer((_) async {});

          when(
            () => mockTaskRepository.updateNextAction(
              id: any(named: 'id'),
              isNextAction: any(named: 'isNextAction'),
              nextActionPriority: any(named: 'nextActionPriority'),
              nextActionNotes: any(named: 'nextActionNotes'),
            ),
          ).thenAnswer((_) async {});

          return TaskDetailBloc(
            taskRepository: mockTaskRepository,
            projectRepository: mockProjectRepository,
            labelRepository: mockLabelRepository,
            autoLoad: false,
          );
        },
        act: (bloc) => bloc.add(
          const TaskDetailEvent.update(
            id: 'task-1',
            name: 'Updated Task',
            description: 'Updated description',
            completed: true,
          ),
        ),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          predicate<TaskDetailOperationSuccess>(
            (state) => state.operation == EntityOperation.update,
          ),
        ],
        verify: (_) {
          verify(
            () => mockTaskRepository.update(
              id: 'task-1',
              name: 'Updated Task',
              description: 'Updated description',
              completed: true,
              projectId: any(named: 'projectId'),
              startDate: any(named: 'startDate'),
              deadlineDate: any(named: 'deadlineDate'),
              repeatIcalRrule: any(named: 'repeatIcalRrule'),
              labelIds: any(named: 'labelIds'),
            ),
          ).called(1);

          verify(
            () => mockTaskRepository.updateNextAction(
              id: 'task-1',
              isNextAction: any(named: 'isNextAction'),
              nextActionPriority: any(named: 'nextActionPriority'),
              nextActionNotes: any(named: 'nextActionNotes'),
            ),
          ).called(1);
        },
      );

      blocTest<TaskDetailBloc, TaskDetailState>(
        'emits failure when update fails',
        build: () {
          when(
            () => mockTaskRepository.update(
              id: any(named: 'id'),
              name: any(named: 'name'),
              description: any(named: 'description'),
              completed: any(named: 'completed'),
              projectId: any(named: 'projectId'),
              startDate: any(named: 'startDate'),
              deadlineDate: any(named: 'deadlineDate'),
              repeatIcalRrule: any(named: 'repeatIcalRrule'),
              labelIds: any(named: 'labelIds'),
            ),
          ).thenThrow(Exception('Update failed'));

          when(
            () => mockTaskRepository.updateNextAction(
              id: any(named: 'id'),
              isNextAction: any(named: 'isNextAction'),
              nextActionPriority: any(named: 'nextActionPriority'),
              nextActionNotes: any(named: 'nextActionNotes'),
            ),
          ).thenAnswer((_) async {});

          return TaskDetailBloc(
            taskRepository: mockTaskRepository,
            projectRepository: mockProjectRepository,
            labelRepository: mockLabelRepository,
            autoLoad: false,
          );
        },
        act: (bloc) => bloc.add(
          const TaskDetailEvent.update(
            id: 'task-1',
            name: 'Updated Task',
            description: null,
            completed: false,
          ),
        ),
        expect: () => [
          isA<TaskDetailOperationFailure>(),
        ],
      );
    });

    group('delete event', () {
      blocTest<TaskDetailBloc, TaskDetailState>(
        'deletes task and emits success',
        build: () {
          when(() => mockTaskRepository.delete(any())).thenAnswer((_) async {});

          return TaskDetailBloc(
            taskRepository: mockTaskRepository,
            projectRepository: mockProjectRepository,
            labelRepository: mockLabelRepository,
            autoLoad: false,
          );
        },
        act: (bloc) => bloc.add(const TaskDetailEvent.delete(id: 'task-1')),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          predicate<TaskDetailOperationSuccess>(
            (state) => state.operation == EntityOperation.delete,
          ),
        ],
        verify: (_) {
          verify(() => mockTaskRepository.delete('task-1')).called(1);
        },
      );

      blocTest<TaskDetailBloc, TaskDetailState>(
        'emits failure when delete fails',
        build: () {
          when(
            () => mockTaskRepository.delete(any()),
          ).thenThrow(Exception('Delete failed'));

          return TaskDetailBloc(
            taskRepository: mockTaskRepository,
            projectRepository: mockProjectRepository,
            labelRepository: mockLabelRepository,
            autoLoad: false,
          );
        },
        act: (bloc) => bloc.add(const TaskDetailEvent.delete(id: 'task-1')),
        expect: () => [
          isA<TaskDetailOperationFailure>(),
        ],
      );
    });
  });
}
