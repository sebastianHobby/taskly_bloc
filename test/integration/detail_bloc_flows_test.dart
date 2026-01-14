/// Integration tests for critical application flows.
///
/// These tests verify end-to-end flows that span multiple components
/// but run in a controlled test environment with mocked dependencies.
///
/// Tests focus on:
/// - Task lifecycle (create → read → update → delete)
/// - Project lifecycle (create → read → update → delete)
/// - Value management flows
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/core/model/entity_operation.dart';
import 'package:taskly_bloc/shared/logging/talker_service.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/presentation/features/values/bloc/value_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/project_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';

import '../fixtures/test_data.dart';
import '../helpers/bloc_test_patterns.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Mocks
// ═══════════════════════════════════════════════════════════════════════════

class MockTaskRepository extends Mock implements TaskRepositoryContract {}

class MockProjectRepository extends Mock implements ProjectRepositoryContract {}

class MockValueRepository extends Mock implements ValueRepositoryContract {}

// ═══════════════════════════════════════════════════════════════════════════
// Test Setup
// ═══════════════════════════════════════════════════════════════════════════

void main() {
  setUpAll(() {
    initializeTalkerForTest();
    registerFallbackValue(const TaskQuery());
    registerFallbackValue(ValuePriority.low);
  });

  group('Task Detail Bloc Integration', () {
    late MockTaskRepository mockTaskRepo;
    late MockProjectRepository mockProjectRepo;
    late MockValueRepository mockValueRepo;

    setUp(() {
      mockTaskRepo = MockTaskRepository();
      mockProjectRepo = MockProjectRepository();
      mockValueRepo = MockValueRepository();
    });

    blocTestSafe<TaskDetailBloc, TaskDetailState>(
      'loads task successfully',
      build: () {
        final task = TestData.task(
          id: 'task-1',
          name: 'Integration Test Task',
        );
        when(
          () => mockTaskRepo.getById('task-1'),
        ).thenAnswer((_) async => task);
        when(() => mockProjectRepo.getAll()).thenAnswer((_) async => []);
        when(() => mockValueRepo.getAll()).thenAnswer((_) async => []);

        return TaskDetailBloc(
          taskRepository: mockTaskRepo,
          projectRepository: mockProjectRepo,
          valueRepository: mockValueRepo,
          taskId: 'task-1',
        );
      },
      expect: () => [
        isA<TaskDetailLoadInProgress>(),
        isA<TaskDetailLoadSuccess>().having(
          (s) => s.task.name,
          'task.name',
          'Integration Test Task',
        ),
      ],
      verify: (_) {
        verify(() => mockTaskRepo.getById('task-1')).called(1);
      },
    );

    blocTestSafe<TaskDetailBloc, TaskDetailState>(
      'handles task not found',
      build: () {
        when(
          () => mockTaskRepo.getById('missing'),
        ).thenAnswer((_) async => null);
        when(() => mockProjectRepo.getAll()).thenAnswer((_) async => []);
        when(() => mockValueRepo.getAll()).thenAnswer((_) async => []);

        return TaskDetailBloc(
          taskRepository: mockTaskRepo,
          projectRepository: mockProjectRepo,
          valueRepository: mockValueRepo,
          taskId: 'missing',
        );
      },
      expect: () => [
        isA<TaskDetailLoadInProgress>(),
        isA<TaskDetailOperationFailure>(),
      ],
    );

    blocTestSafe<TaskDetailBloc, TaskDetailState>(
      'creates task successfully',
      build: () {
        when(() => mockProjectRepo.getAll()).thenAnswer((_) async => []);
        when(() => mockValueRepo.getAll()).thenAnswer((_) async => []);
        when(
          () => mockTaskRepo.create(
            name: any(named: 'name'),
            description: any(named: 'description'),
            completed: any(named: 'completed'),
            startDate: any(named: 'startDate'),
            deadlineDate: any(named: 'deadlineDate'),
            projectId: any(named: 'projectId'),
            priority: any(named: 'priority'),
            repeatIcalRrule: any(named: 'repeatIcalRrule'),
            valueIds: any(named: 'valueIds'),
          ),
        ).thenAnswer((_) async {});

        return TaskDetailBloc(
          taskRepository: mockTaskRepo,
          projectRepository: mockProjectRepo,
          valueRepository: mockValueRepo,
          autoLoad: false,
        );
      },
      act: (bloc) async {
        bloc.add(const TaskDetailEvent.loadInitialData());
        await Future<void>.delayed(const Duration(milliseconds: 100));
        bloc.add(
          const TaskDetailEvent.create(
            command: CreateTaskCommand(
              name: 'New Task',
              completed: false,
              description: 'Created via integration test',
            ),
          ),
        );
      },
      expect: () => [
        isA<TaskDetailLoadInProgress>(),
        isA<TaskDetailInitialDataLoadSuccess>(),
        isA<TaskDetailOperationSuccess>().having(
          (s) => s.operation,
          'operation',
          EntityOperation.create,
        ),
      ],
    );

    blocTestSafe<TaskDetailBloc, TaskDetailState>(
      'loads task with project reference',
      build: () {
        final project = TestData.project(id: 'project-1', name: 'My Project');
        final task = TestData.task(
          id: 'task-1',
          name: 'Task in Project',
          projectId: 'project-1',
        );

        when(
          () => mockTaskRepo.getById('task-1'),
        ).thenAnswer((_) async => task);
        when(() => mockProjectRepo.getAll()).thenAnswer((_) async => [project]);
        when(() => mockValueRepo.getAll()).thenAnswer((_) async => []);

        return TaskDetailBloc(
          taskRepository: mockTaskRepo,
          projectRepository: mockProjectRepo,
          valueRepository: mockValueRepo,
          taskId: 'task-1',
        );
      },
      expect: () => [
        isA<TaskDetailLoadInProgress>(),
        isA<TaskDetailLoadSuccess>()
            .having((s) => s.task.projectId, 'projectId', 'project-1')
            .having((s) => s.availableProjects.length, 'projects', 1),
      ],
    );

    blocTestSafe<TaskDetailBloc, TaskDetailState>(
      'loads task with labels',
      build: () {
        final labels = [
          TestData.value(id: 'label-1', name: 'Urgent'),
          TestData.value(id: 'label-2', name: 'Important'),
        ];
        final task = TestData.task(
          id: 'task-1',
          name: 'Labeled Task',
          values: labels,
        );

        when(
          () => mockTaskRepo.getById('task-1'),
        ).thenAnswer((_) async => task);
        when(() => mockProjectRepo.getAll()).thenAnswer((_) async => []);
        when(() => mockValueRepo.getAll()).thenAnswer((_) async => labels);

        return TaskDetailBloc(
          taskRepository: mockTaskRepo,
          projectRepository: mockProjectRepo,
          valueRepository: mockValueRepo,
          taskId: 'task-1',
        );
      },
      expect: () => [
        isA<TaskDetailLoadInProgress>(),
        isA<TaskDetailLoadSuccess>()
            .having((s) => s.task.values.length, 'task values', 2)
            .having((s) => s.availableValues.length, 'available values', 2),
      ],
    );
  });

  group('Project Detail Bloc Integration', () {
    blocTestSafe<ProjectDetailBloc, ProjectDetailState>(
      'loads project successfully',
      build: () {
        final mockProjectRepo = MockProjectRepository();
        final mockValueRepo = MockValueRepository();
        final project = TestData.project(
          id: 'project-1',
          name: 'Integration Test Project',
        );

        when(
          () => mockProjectRepo.getById(any()),
        ).thenAnswer((_) async => project);
        when(mockValueRepo.getAll).thenAnswer((_) async => []);

        return ProjectDetailBloc(
          projectRepository: mockProjectRepo,
          valueRepository: mockValueRepo,
        );
      },
      act: (bloc) =>
          bloc.add(const ProjectDetailEvent.loadById(projectId: 'project-1')),
      expect: () => [
        isA<ProjectDetailLoadInProgress>(),
        isA<ProjectDetailLoadSuccess>().having(
          (s) => s.project.name,
          'project.name',
          'Integration Test Project',
        ),
      ],
    );

    blocTestSafe<ProjectDetailBloc, ProjectDetailState>(
      'deletes project successfully',
      build: () {
        final mockProjectRepo = MockProjectRepository();
        final mockValueRepo = MockValueRepository();

        when(
          () => mockProjectRepo.delete('project-1'),
        ).thenAnswer((_) async {});
        when(mockValueRepo.getAll).thenAnswer((_) async => []);

        return ProjectDetailBloc(
          projectRepository: mockProjectRepo,
          valueRepository: mockValueRepo,
        );
      },
      act: (bloc) => bloc.add(const ProjectDetailEvent.delete(id: 'project-1')),
      expect: () => [
        isA<ProjectDetailOperationSuccess>().having(
          (s) => s.operation,
          'operation',
          EntityOperation.delete,
        ),
      ],
    );
  });

  group('Value Detail Bloc Integration', () {
    late MockValueRepository mockValueRepo;

    setUp(() {
      mockValueRepo = MockValueRepository();
    });

    blocTestSafe<ValueDetailBloc, ValueDetailState>(
      'loads value successfully',
      build: () {
        final value = TestData.value(
          id: 'value-1',
          name: 'Integration Test Value',
          color: '#FF0000',
        );

        when(
          () => mockValueRepo.getById('value-1'),
        ).thenAnswer((_) async => value);

        return ValueDetailBloc(
          valueRepository: mockValueRepo,
          valueId: 'value-1',
        );
      },
      expect: () => [
        isA<ValueDetailLoadInProgress>(),
        isA<ValueDetailLoadSuccess>().having(
          (s) => s.value.name,
          'value.name',
          'Integration Test Value',
        ),
      ],
    );

    blocTestSafe<ValueDetailBloc, ValueDetailState>(
      'updates value successfully',
      build: () {
        when(
          () => mockValueRepo.update(
            id: any(named: 'id'),
            name: any(named: 'name'),
            color: any(named: 'color'),
            priority: any(named: 'priority'),
            iconName: any(named: 'iconName'),
          ),
        ).thenAnswer((_) async {
          return;
        });

        return ValueDetailBloc(valueRepository: mockValueRepo);
      },
      act: (bloc) => bloc.add(
        const ValueDetailEvent.update(
          command: UpdateValueCommand(
            id: 'value-1',
            name: 'Updated Value',
            color: '#00FF00',
            priority: ValuePriority.medium,
          ),
        ),
      ),
      expect: () => [
        isA<ValueDetailOperationSuccess>().having(
          (s) => s.operation,
          'operation',
          EntityOperation.update,
        ),
      ],
    );

    blocTestSafe<ValueDetailBloc, ValueDetailState>(
      'creates value successfully',
      build: () {
        when(
          () => mockValueRepo.create(
            name: any(named: 'name'),
            color: any(named: 'color'),
            priority: any(named: 'priority'),
            iconName: any(named: 'iconName'),
          ),
        ).thenAnswer((_) async {
          return;
        });

        return ValueDetailBloc(valueRepository: mockValueRepo);
      },
      act: (bloc) => bloc.add(
        const ValueDetailEvent.create(
          command: CreateValueCommand(
            name: 'New Value',
            color: '#0000FF',
            priority: ValuePriority.high,
          ),
        ),
      ),
      expect: () => [
        isA<ValueDetailOperationSuccess>().having(
          (s) => s.operation,
          'operation',
          EntityOperation.create,
        ),
      ],
    );

    blocTestSafe<ValueDetailBloc, ValueDetailState>(
      'deletes value successfully',
      build: () {
        when(() => mockValueRepo.delete('value-1')).thenAnswer((_) async {
          return;
        });

        return ValueDetailBloc(valueRepository: mockValueRepo);
      },
      act: (bloc) => bloc.add(const ValueDetailEvent.delete(id: 'value-1')),
      expect: () => [
        isA<ValueDetailOperationSuccess>().having(
          (s) => s.operation,
          'operation',
          EntityOperation.delete,
        ),
      ],
    );
  });
}
