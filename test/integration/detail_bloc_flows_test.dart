/// Integration tests for critical application flows.
///
/// These tests verify end-to-end flows that span multiple components
/// but run in a controlled test environment with mocked dependencies.
///
/// Tests focus on:
/// - Task lifecycle (create → read → update → delete)
/// - Project lifecycle (create → read → update → delete)
/// - Label management flows
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/presentation/features/labels/bloc/label_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/project_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';

import '../fixtures/test_data.dart';
import '../helpers/bloc_test_patterns.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Mocks
// ═══════════════════════════════════════════════════════════════════════════

class MockTaskRepository extends Mock implements TaskRepositoryContract {}

class MockProjectRepository extends Mock implements ProjectRepositoryContract {}

class MockLabelRepository extends Mock implements LabelRepositoryContract {}

// ═══════════════════════════════════════════════════════════════════════════
// Test Setup
// ═══════════════════════════════════════════════════════════════════════════

void main() {
  setUpAll(() {
    initializeTalkerForTest();
    registerFallbackValue(const TaskQuery());
    registerFallbackValue(LabelType.label);
  });

  group('Task Detail Bloc Integration', () {
    late MockTaskRepository mockTaskRepo;
    late MockProjectRepository mockProjectRepo;
    late MockLabelRepository mockLabelRepo;

    setUp(() {
      mockTaskRepo = MockTaskRepository();
      mockProjectRepo = MockProjectRepository();
      mockLabelRepo = MockLabelRepository();
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
        when(() => mockLabelRepo.getAll()).thenAnswer((_) async => []);

        return TaskDetailBloc(
          taskRepository: mockTaskRepo,
          projectRepository: mockProjectRepo,
          labelRepository: mockLabelRepo,
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
        when(() => mockLabelRepo.getAll()).thenAnswer((_) async => []);

        return TaskDetailBloc(
          taskRepository: mockTaskRepo,
          projectRepository: mockProjectRepo,
          labelRepository: mockLabelRepo,
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
        when(() => mockLabelRepo.getAll()).thenAnswer((_) async => []);
        when(
          () => mockTaskRepo.create(
            name: any(named: 'name'),
            description: any(named: 'description'),
            completed: any(named: 'completed'),
            startDate: any(named: 'startDate'),
            deadlineDate: any(named: 'deadlineDate'),
            projectId: any(named: 'projectId'),
            repeatIcalRrule: any(named: 'repeatIcalRrule'),
            labelIds: any(named: 'labelIds'),
          ),
        ).thenAnswer((_) async {});

        return TaskDetailBloc(
          taskRepository: mockTaskRepo,
          projectRepository: mockProjectRepo,
          labelRepository: mockLabelRepo,
          autoLoad: false,
        );
      },
      act: (bloc) async {
        bloc.add(const TaskDetailEvent.loadInitialData());
        await Future<void>.delayed(const Duration(milliseconds: 100));
        bloc.add(
          const TaskDetailEvent.create(
            name: 'New Task',
            description: 'Created via integration test',
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
        when(() => mockLabelRepo.getAll()).thenAnswer((_) async => []);

        return TaskDetailBloc(
          taskRepository: mockTaskRepo,
          projectRepository: mockProjectRepo,
          labelRepository: mockLabelRepo,
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
          TestData.label(id: 'label-1', name: 'Urgent'),
          TestData.label(id: 'label-2', name: 'Important'),
        ];
        final task = TestData.task(
          id: 'task-1',
          name: 'Labeled Task',
          labels: labels,
        );

        when(
          () => mockTaskRepo.getById('task-1'),
        ).thenAnswer((_) async => task);
        when(() => mockProjectRepo.getAll()).thenAnswer((_) async => []);
        when(() => mockLabelRepo.getAll()).thenAnswer((_) async => labels);

        return TaskDetailBloc(
          taskRepository: mockTaskRepo,
          projectRepository: mockProjectRepo,
          labelRepository: mockLabelRepo,
          taskId: 'task-1',
        );
      },
      expect: () => [
        isA<TaskDetailLoadInProgress>(),
        isA<TaskDetailLoadSuccess>()
            .having((s) => s.task.labels.length, 'task labels', 2)
            .having((s) => s.availableLabels.length, 'available labels', 2),
      ],
    );
  });

  group('Project Detail Bloc Integration', () {
    blocTestSafe<ProjectDetailBloc, ProjectDetailState>(
      'loads project successfully',
      build: () {
        final mockProjectRepo = MockProjectRepository();
        final mockLabelRepo = MockLabelRepository();
        final project = TestData.project(
          id: 'project-1',
          name: 'Integration Test Project',
        );

        when(
          () => mockProjectRepo.getById(
            any(),
            withRelated: any(named: 'withRelated'),
          ),
        ).thenAnswer((_) async => project);
        when(mockLabelRepo.getAll).thenAnswer((_) async => []);

        return ProjectDetailBloc(
          projectRepository: mockProjectRepo,
          labelRepository: mockLabelRepo,
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
        final mockLabelRepo = MockLabelRepository();

        when(
          () => mockProjectRepo.delete('project-1'),
        ).thenAnswer((_) async {});
        when(mockLabelRepo.getAll).thenAnswer((_) async => []);

        return ProjectDetailBloc(
          projectRepository: mockProjectRepo,
          labelRepository: mockLabelRepo,
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

  group('Label Detail Bloc Integration', () {
    late MockLabelRepository mockLabelRepo;

    setUp(() {
      mockLabelRepo = MockLabelRepository();
    });

    blocTestSafe<LabelDetailBloc, LabelDetailState>(
      'loads label successfully',
      build: () {
        final label = TestData.label(
          id: 'label-1',
          name: 'Integration Test Label',
          color: '#FF0000',
        );

        when(
          () => mockLabelRepo.getById('label-1'),
        ).thenAnswer((_) async => label);

        return LabelDetailBloc(
          labelRepository: mockLabelRepo,
          labelId: 'label-1',
        );
      },
      expect: () => [
        isA<LabelDetailLoadInProgress>(),
        isA<LabelDetailLoadSuccess>().having(
          (s) => s.label.name,
          'label.name',
          'Integration Test Label',
        ),
      ],
    );

    blocTestSafe<LabelDetailBloc, LabelDetailState>(
      'updates label successfully',
      build: () {
        when(
          () => mockLabelRepo.update(
            id: any(named: 'id'),
            name: any(named: 'name'),
            color: any(named: 'color'),
            type: any(named: 'type'),
            iconName: any(named: 'iconName'),
          ),
        ).thenAnswer((_) async {});

        return LabelDetailBloc(labelRepository: mockLabelRepo);
      },
      act: (bloc) => bloc.add(
        const LabelDetailEvent.update(
          id: 'label-1',
          name: 'Updated Label',
          color: '#00FF00',
          type: LabelType.label,
        ),
      ),
      expect: () => [
        isA<LabelDetailOperationSuccess>().having(
          (s) => s.operation,
          'operation',
          EntityOperation.update,
        ),
      ],
    );

    blocTestSafe<LabelDetailBloc, LabelDetailState>(
      'creates label successfully',
      build: () {
        when(
          () => mockLabelRepo.create(
            name: any(named: 'name'),
            color: any(named: 'color'),
            type: any(named: 'type'),
            iconName: any(named: 'iconName'),
          ),
        ).thenAnswer((_) async {});

        return LabelDetailBloc(labelRepository: mockLabelRepo);
      },
      act: (bloc) => bloc.add(
        const LabelDetailEvent.create(
          name: 'New Label',
          color: '#0000FF',
          type: LabelType.value,
        ),
      ),
      expect: () => [
        isA<LabelDetailOperationSuccess>().having(
          (s) => s.operation,
          'operation',
          EntityOperation.create,
        ),
      ],
    );

    blocTestSafe<LabelDetailBloc, LabelDetailState>(
      'deletes label successfully',
      build: () {
        when(() => mockLabelRepo.delete('label-1')).thenAnswer((_) async {});

        return LabelDetailBloc(labelRepository: mockLabelRepo);
      },
      act: (bloc) => bloc.add(const LabelDetailEvent.delete(id: 'label-1')),
      expect: () => [
        isA<LabelDetailOperationSuccess>().having(
          (s) => s.operation,
          'operation',
          EntityOperation.delete,
        ),
      ],
    );
  });
}
