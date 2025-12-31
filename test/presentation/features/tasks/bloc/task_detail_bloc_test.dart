import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/core/utils/not_found_entity.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart'
    show TaskRepository;
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';

import '../../../../fixtures/test_data.dart';
import '../../../../helpers/bloc_test_helpers.dart';
import '../../../../helpers/custom_matchers.dart';
import '../../../../helpers/fallback_values.dart';

/// Tests for [TaskDetailBloc] covering task creation, editing, and deletion.
///
/// Coverage:
/// - ✅ Initialization with and without taskId
/// - ✅ Loading task data
/// - ✅ Creating new tasks
/// - ✅ Updating existing tasks
/// - ✅ Deleting tasks
/// - ✅ Error handling for all operations
/// - ✅ Form field updates
///
/// Related: [TaskDetailBloc], [TaskRepository]
void main() {
  late BlocTestContext ctx;
  late TaskDetailBloc bloc;

  setUpAll(registerAllFallbackValues);

  setUp(() {
    ctx = BlocTestContext();
    // BlocTestContext already stubs projectRepo.getAll() and labelRepo.getAll()
    // with empty lists by default
  });

  tearDown(() {
    bloc.close();
  });

  group('TaskDetailBloc', () {
    group('initialization', () {
      test('initial state is TaskDetailInitial', () {
        bloc = TaskDetailBloc(
          taskRepository: ctx.taskRepo,
          projectRepository: ctx.projectRepo,
          labelRepository: ctx.labelRepo,
        );

        expect(bloc.state, isInitialState());
      });

      test('loads initial data when no taskId provided', () async {
        final projects = [TestData.project()];
        final labels = [TestData.label()];

        ctx.stubProjectsReturn(projects);
        ctx.stubLabelsReturn(labels);

        bloc = TaskDetailBloc(
          taskRepository: ctx.taskRepo,
          projectRepository: ctx.projectRepo,
          labelRepository: ctx.labelRepo,
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

        ctx.stubTaskById('task-1', task);
        ctx.stubProjectsReturn(projects);
        ctx.stubLabelsReturn(labels);

        bloc = TaskDetailBloc(
          taskRepository: ctx.taskRepo,
          projectRepository: ctx.projectRepo,
          labelRepository: ctx.labelRepo,
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

          ctx.stubProjectsReturn(projects);
          ctx.stubLabelsReturn(labels);

          return TaskDetailBloc(
            taskRepository: ctx.taskRepo,
            projectRepository: ctx.projectRepo,
            labelRepository: ctx.labelRepo,
            autoLoad: false,
          );
        },
        act: (bloc) => bloc.add(const TaskDetailEvent.loadInitialData()),
        expect: () => [
          isLoadingState(),
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
            () => ctx.projectRepo.getAll(),
          ).thenThrow(Exception('Failed to load projects'));
          when(() => ctx.labelRepo.getAll()).thenAnswer((_) async => []);

          return TaskDetailBloc(
            taskRepository: ctx.taskRepo,
            projectRepository: ctx.projectRepo,
            labelRepository: ctx.labelRepo,
            autoLoad: false,
          );
        },
        act: (bloc) => bloc.add(const TaskDetailEvent.loadInitialData()),
        expect: () => [
          isLoadingState(),
          isErrorState(),
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

          ctx.stubTaskById('task-1', task);
          ctx.stubProjectsReturn(projects);
          ctx.stubLabelsReturn(labels);

          return TaskDetailBloc(
            taskRepository: ctx.taskRepo,
            projectRepository: ctx.projectRepo,
            labelRepository: ctx.labelRepo,
            autoLoad: false,
          );
        },
        act: (bloc) => bloc.add(const TaskDetailEvent.get(taskId: 'task-1')),
        expect: () => [
          isLoadingState(),
          predicate<TaskDetailLoadSuccess>(
            (state) => state.task.id == 'task-1',
          ),
        ],
      );

      blocTest<TaskDetailBloc, TaskDetailState>(
        'emits failure when task not found',
        build: () {
          when(
            () => ctx.taskRepo.getById('nonexistent'),
          ).thenAnswer((_) async => null);

          return TaskDetailBloc(
            taskRepository: ctx.taskRepo,
            projectRepository: ctx.projectRepo,
            labelRepository: ctx.labelRepo,
            autoLoad: false,
          );
        },
        act: (bloc) =>
            bloc.add(const TaskDetailEvent.get(taskId: 'nonexistent')),
        expect: () => [
          isLoadingState(),
          predicate<TaskDetailOperationFailure>(
            (state) => state.errorDetails.error == NotFoundEntity.task,
          ),
        ],
      );

      blocTest<TaskDetailBloc, TaskDetailState>(
        'emits failure on repository error',
        build: () {
          when(
            () => ctx.taskRepo.getById(any()),
          ).thenThrow(Exception('Database error'));

          return TaskDetailBloc(
            taskRepository: ctx.taskRepo,
            projectRepository: ctx.projectRepo,
            labelRepository: ctx.labelRepo,
            autoLoad: false,
          );
        },
        act: (bloc) => bloc.add(const TaskDetailEvent.get(taskId: 'task-1')),
        expect: () => [
          isLoadingState(),
          isErrorState(),
        ],
      );
    });

    group('create event', () {
      blocTest<TaskDetailBloc, TaskDetailState>(
        'creates task and emits success',
        build: () {
          ctx.stubTaskCreateSuccess();

          return TaskDetailBloc(
            taskRepository: ctx.taskRepo,
            projectRepository: ctx.projectRepo,
            labelRepository: ctx.labelRepo,
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
          isSuccessState(),
        ],
        verify: (_) {
          verify(
            () => ctx.taskRepo.create(
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
            () => ctx.taskRepo.create(
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
            taskRepository: ctx.taskRepo,
            projectRepository: ctx.projectRepo,
            labelRepository: ctx.labelRepo,
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
          isErrorState(),
        ],
      );
    });

    group('update event', () {
      blocTest<TaskDetailBloc, TaskDetailState>(
        'updates task and emits success',
        build: () {
          ctx.stubTaskUpdateSuccess();
          when(
            () => ctx.taskRepo.updateNextAction(
              id: any(named: 'id'),
              isNextAction: any(named: 'isNextAction'),
              nextActionPriority: any(named: 'nextActionPriority'),
              nextActionNotes: any(named: 'nextActionNotes'),
            ),
          ).thenAnswer((_) async {});

          return TaskDetailBloc(
            taskRepository: ctx.taskRepo,
            projectRepository: ctx.projectRepo,
            labelRepository: ctx.labelRepo,
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
          isSuccessState(),
        ],
        verify: (_) {
          verify(
            () => ctx.taskRepo.update(
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
            () => ctx.taskRepo.updateNextAction(
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
            () => ctx.taskRepo.update(
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
            () => ctx.taskRepo.updateNextAction(
              id: any(named: 'id'),
              isNextAction: any(named: 'isNextAction'),
              nextActionPriority: any(named: 'nextActionPriority'),
              nextActionNotes: any(named: 'nextActionNotes'),
            ),
          ).thenAnswer((_) async {});

          return TaskDetailBloc(
            taskRepository: ctx.taskRepo,
            projectRepository: ctx.projectRepo,
            labelRepository: ctx.labelRepo,
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
          isErrorState(),
        ],
      );
    });

    group('delete event', () {
      blocTest<TaskDetailBloc, TaskDetailState>(
        'deletes task and emits success',
        build: () {
          ctx.stubTaskDeleteSuccess();

          return TaskDetailBloc(
            taskRepository: ctx.taskRepo,
            projectRepository: ctx.projectRepo,
            labelRepository: ctx.labelRepo,
            autoLoad: false,
          );
        },
        act: (bloc) => bloc.add(const TaskDetailEvent.delete(id: 'task-1')),
        wait: const Duration(milliseconds: 100),
        expect: () => [
          isSuccessState(),
        ],
        verify: (_) {
          verify(() => ctx.taskRepo.delete('task-1')).called(1);
        },
      );

      blocTest<TaskDetailBloc, TaskDetailState>(
        'emits failure when delete fails',
        build: () {
          when(
            () => ctx.taskRepo.delete(any()),
          ).thenThrow(Exception('Delete failed'));

          return TaskDetailBloc(
            taskRepository: ctx.taskRepo,
            projectRepository: ctx.projectRepo,
            labelRepository: ctx.labelRepo,
            autoLoad: false,
          );
        },
        act: (bloc) => bloc.add(const TaskDetailEvent.delete(id: 'task-1')),
        expect: () => [
          isErrorState(),
        ],
      );
    });
  });
}
