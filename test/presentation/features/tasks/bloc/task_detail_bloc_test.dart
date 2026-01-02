import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';

import '../../../../fixtures/test_data.dart';
import '../../../../mocks/repository_mocks.dart';

void main() {
  late MockTaskRepositoryContract taskRepo;
  late MockProjectRepositoryContract projectRepo;
  late MockLabelRepositoryContract labelRepo;

  setUpAll(() {
    initializeTalkerForTest();
    registerFallbackValue(TestData.task());
    registerFallbackValue(TestData.project());
    registerFallbackValue(TestData.label());
  });

  setUp(() {
    taskRepo = MockTaskRepositoryContract();
    projectRepo = MockProjectRepositoryContract();
    labelRepo = MockLabelRepositoryContract();
  });

  group('TaskDetailBloc', () {
    TaskDetailBloc buildBloc({
      String? taskId,
      bool autoLoad = false,
    }) {
      return TaskDetailBloc(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        labelRepository: labelRepo,
        taskId: taskId,
        autoLoad: autoLoad,
      );
    }

    test('initial state is TaskDetailInitial', () {
      final bloc = buildBloc();
      expect(bloc.state, const TaskDetailInitial());
      bloc.close();
    });

    blocTest<TaskDetailBloc, TaskDetailState>(
      'loadInitialData emits loading then success with projects and labels',
      build: () {
        final projects = [TestData.project(id: 'p1')];
        final labels = [TestData.label(id: 'l1')];
        when(() => projectRepo.getAll()).thenAnswer((_) async => projects);
        when(() => labelRepo.getAll()).thenAnswer((_) async => labels);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const TaskDetailEvent.loadInitialData()),
      expect: () => [
        const TaskDetailLoadInProgress(),
        isA<TaskDetailInitialDataLoadSuccess>()
            .having((s) => s.availableProjects.length, 'projects', 1)
            .having((s) => s.availableLabels.length, 'labels', 1),
      ],
    );

    blocTest<TaskDetailBloc, TaskDetailState>(
      'loadInitialData emits failure when project fetch fails',
      build: () {
        when(
          () => projectRepo.getAll(),
        ).thenThrow(Exception('Failed to load projects'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const TaskDetailEvent.loadInitialData()),
      expect: () => [
        const TaskDetailLoadInProgress(),
        isA<TaskDetailOperationFailure>(),
      ],
    );

    blocTest<TaskDetailBloc, TaskDetailState>(
      'get emits loading then success with task',
      build: () {
        final task = TestData.task(id: 'task-123');
        final projects = [TestData.project(id: 'p1')];
        final labels = [TestData.label(id: 'l1')];
        when(() => taskRepo.getById('task-123')).thenAnswer((_) async => task);
        when(() => projectRepo.getAll()).thenAnswer((_) async => projects);
        when(() => labelRepo.getAll()).thenAnswer((_) async => labels);
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const TaskDetailEvent.loadById(taskId: 'task-123')),
      expect: () => [
        const TaskDetailLoadInProgress(),
        isA<TaskDetailLoadSuccess>()
            .having((s) => s.task.id, 'task.id', 'task-123')
            .having((s) => s.task.name, 'task.name', 'Test Task'),
      ],
    );

    blocTest<TaskDetailBloc, TaskDetailState>(
      'get emits failure when task not found',
      build: () {
        when(() => taskRepo.getById(any())).thenAnswer((_) async => null);
        when(() => projectRepo.getAll()).thenAnswer((_) async => []);
        when(() => labelRepo.getAll()).thenAnswer((_) async => []);
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const TaskDetailEvent.loadById(taskId: 'not-found')),
      expect: () => [
        const TaskDetailLoadInProgress(),
        isA<TaskDetailOperationFailure>(),
      ],
    );

    blocTest<TaskDetailBloc, TaskDetailState>(
      'create emits success',
      setUp: () {
        when(
          () => taskRepo.create(
            name: 'New Task',
            description: 'Task description',
          ),
        ).thenAnswer((_) async {});
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const TaskDetailEvent.create(
          name: 'New Task',
          description: 'Task description',
        ),
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<TaskDetailOperationSuccess>().having(
          (s) => s.operation,
          'operation',
          EntityOperation.create,
        ),
      ],
    );

    blocTest<TaskDetailBloc, TaskDetailState>(
      'create emits failure when repository throws',
      setUp: () {
        when(
          () => taskRepo.create(
            name: 'New Task',
          ),
        ).thenThrow(Exception('Create failed'));
      },
      build: buildBloc,
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

    blocTest<TaskDetailBloc, TaskDetailState>(
      'update emits success',
      setUp: () {
        when(
          () => taskRepo.update(
            id: 'task-1',
            name: 'Updated Task',
            completed: false,
          ),
        ).thenAnswer((_) async {});
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const TaskDetailEvent.update(
          id: 'task-1',
          name: 'Updated Task',
          description: null,
          completed: false,
        ),
      ),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<TaskDetailOperationSuccess>().having(
          (s) => s.operation,
          'operation',
          EntityOperation.update,
        ),
      ],
    );

    blocTest<TaskDetailBloc, TaskDetailState>(
      'update emits failure when repository throws',
      setUp: () {
        when(
          () => taskRepo.update(
            id: 'task-1',
            name: 'Updated Task',
            completed: false,
          ),
        ).thenThrow(Exception('Update failed'));
      },
      build: buildBloc,
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

    blocTest<TaskDetailBloc, TaskDetailState>(
      'delete emits success',
      setUp: () {
        when(() => taskRepo.delete('task-1')).thenAnswer((_) async {});
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const TaskDetailEvent.delete(id: 'task-1')),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<TaskDetailOperationSuccess>().having(
          (s) => s.operation,
          'operation',
          EntityOperation.delete,
        ),
      ],
    );

    blocTest<TaskDetailBloc, TaskDetailState>(
      'delete emits failure when repository throws',
      setUp: () {
        when(
          () => taskRepo.delete('task-1'),
        ).thenThrow(Exception('Delete failed'));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const TaskDetailEvent.delete(id: 'task-1')),
      expect: () => [
        isA<TaskDetailOperationFailure>(),
      ],
    );

    blocTest<TaskDetailBloc, TaskDetailState>(
      'autoLoad with taskId triggers get event',
      build: () {
        final task = TestData.task(id: 'auto-load-task');
        when(
          () => taskRepo.getById('auto-load-task'),
        ).thenAnswer((_) async => task);
        when(() => projectRepo.getAll()).thenAnswer((_) async => []);
        when(() => labelRepo.getAll()).thenAnswer((_) async => []);
        return TaskDetailBloc(
          taskRepository: taskRepo,
          projectRepository: projectRepo,
          labelRepository: labelRepo,
          taskId: 'auto-load-task',
        );
      },
      expect: () => [
        const TaskDetailLoadInProgress(),
        isA<TaskDetailLoadSuccess>().having(
          (s) => s.task.id,
          'task.id',
          'auto-load-task',
        ),
      ],
    );

    blocTest<TaskDetailBloc, TaskDetailState>(
      'autoLoad without taskId triggers loadInitialData',
      build: () {
        when(
          () => projectRepo.getAll(),
        ).thenAnswer((_) async => [TestData.project()]);
        when(
          () => labelRepo.getAll(),
        ).thenAnswer((_) async => [TestData.label()]);
        return TaskDetailBloc(
          taskRepository: taskRepo,
          projectRepository: projectRepo,
          labelRepository: labelRepo,
        );
      },
      expect: () => [
        const TaskDetailLoadInProgress(),
        isA<TaskDetailInitialDataLoadSuccess>(),
      ],
    );
  });
}
