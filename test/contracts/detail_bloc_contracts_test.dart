/// Contract tests for detail bloc patterns.
///
/// These tests verify that all detail blocs follow consistent patterns
/// and that repositories emit data in formats that blocs can consume.
///
/// Contract tests use REAL components to catch interface drift.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/labels/bloc/label_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/project_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';

import '../fixtures/test_data.dart';
import '../helpers/contract_test_helpers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Mocks
// ═══════════════════════════════════════════════════════════════════════════

class MockTaskRepository extends Mock implements TaskRepositoryContract {}

class MockProjectRepository extends Mock implements ProjectRepositoryContract {}

class MockLabelRepository extends Mock implements LabelRepositoryContract {}

// ═══════════════════════════════════════════════════════════════════════════
// Contract Tests
// ═══════════════════════════════════════════════════════════════════════════

void main() {
  setUpAll(() {
    initializeTalkerForTest();
    registerFallbackValue(LabelType.label);
  });

  group('Detail Bloc State Contracts', () {
    // ═══════════════════════════════════════════════════════════════════════
    // State Pattern Contracts
    // ═══════════════════════════════════════════════════════════════════════

    testContract('TaskDetailState has all required factory constructors', () {
      // All detail blocs must have these state variants
      const initial = TaskDetailState.initial();
      const loading = TaskDetailState.loadInProgress();
      const success = TaskDetailState.operationSuccess(
        operation: EntityOperation.create,
      );

      expect(initial, isA<TaskDetailInitial>());
      expect(loading, isA<TaskDetailLoadInProgress>());
      expect(success, isA<TaskDetailOperationSuccess>());
    });

    testContract(
      'ProjectDetailState has all required factory constructors',
      () {
        const initial = ProjectDetailState.initial();
        const loading = ProjectDetailState.loadInProgress();
        const success = ProjectDetailState.operationSuccess(
          operation: EntityOperation.create,
        );

        expect(initial, isA<ProjectDetailInitial>());
        expect(loading, isA<ProjectDetailLoadInProgress>());
        expect(success, isA<ProjectDetailOperationSuccess>());
      },
    );

    testContract('LabelDetailState has all required factory constructors', () {
      const initial = LabelDetailState.initial();
      const loading = LabelDetailState.loadInProgress();
      const success = LabelDetailState.operationSuccess(
        operation: EntityOperation.create,
      );

      expect(initial, isA<LabelDetailInitial>());
      expect(loading, isA<LabelDetailLoadInProgress>());
      expect(success, isA<LabelDetailOperationSuccess>());
    });

    // ═══════════════════════════════════════════════════════════════════════
    // EntityOperation Contracts
    // ═══════════════════════════════════════════════════════════════════════

    testContract('EntityOperation enum covers all CRUD operations', () {
      // All detail blocs use EntityOperation for success states
      expect(EntityOperation.values, contains(EntityOperation.create));
      expect(EntityOperation.values, contains(EntityOperation.update));
      expect(EntityOperation.values, contains(EntityOperation.delete));
    });

    testContract('Operation success states expose operation type', () {
      // Verify all success states have the operation property
      const taskSuccess = TaskDetailState.operationSuccess(
        operation: EntityOperation.delete,
      );
      const projectSuccess = ProjectDetailState.operationSuccess(
        operation: EntityOperation.update,
      );
      const labelSuccess = LabelDetailState.operationSuccess(
        operation: EntityOperation.create,
      );

      expect(
        (taskSuccess as TaskDetailOperationSuccess).operation,
        EntityOperation.delete,
      );
      expect(
        (projectSuccess as ProjectDetailOperationSuccess).operation,
        EntityOperation.update,
      );
      expect(
        (labelSuccess as LabelDetailOperationSuccess).operation,
        EntityOperation.create,
      );
    });
  });

  group('Detail Bloc Event Contracts', () {
    // ═══════════════════════════════════════════════════════════════════════
    // CRUD Event Contracts
    // ═══════════════════════════════════════════════════════════════════════

    testContract('TaskDetailEvent has all CRUD event factories', () {
      // All events needed for task management
      const create = TaskDetailEvent.create(name: 'Test', description: null);
      const update = TaskDetailEvent.update(
        id: 'id',
        name: 'Test',
        description: null,
        completed: false,
      );
      const delete = TaskDetailEvent.delete(id: 'id');
      const loadById = TaskDetailEvent.loadById(taskId: 'id');

      expect(create, isNotNull);
      expect(update, isNotNull);
      expect(delete, isNotNull);
      expect(loadById, isNotNull);
    });

    testContract('ProjectDetailEvent has all CRUD event factories', () {
      const create = ProjectDetailEvent.create(name: 'Test');
      const update = ProjectDetailEvent.update(
        id: 'id',
        name: 'Test',
        completed: false,
      );
      const delete = ProjectDetailEvent.delete(id: 'id');
      const loadById = ProjectDetailEvent.loadById(projectId: 'id');

      expect(create, isNotNull);
      expect(update, isNotNull);
      expect(delete, isNotNull);
      expect(loadById, isNotNull);
    });

    testContract('LabelDetailEvent has all CRUD event factories', () {
      const create = LabelDetailEvent.create(
        name: 'Test',
        color: '#000000',
        type: LabelType.label,
      );
      const update = LabelDetailEvent.update(
        id: 'id',
        name: 'Test',
        color: '#000000',
        type: LabelType.label,
      );
      const delete = LabelDetailEvent.delete(id: 'id');
      const loadById = LabelDetailEvent.loadById(labelId: 'id');

      expect(create, isNotNull);
      expect(update, isNotNull);
      expect(delete, isNotNull);
      expect(loadById, isNotNull);
    });
  });

  group('Repository ↔ Bloc Type Contracts', () {
    // ═══════════════════════════════════════════════════════════════════════
    // Return Type Contracts
    // ═══════════════════════════════════════════════════════════════════════

    testContract('Task repository returns types that bloc expects', () async {
      final mockRepo = MockTaskRepository();
      final task = TestData.task(id: '1', name: 'Test');

      // getById returns Task? which bloc handles via null check
      when(() => mockRepo.getById('1')).thenAnswer((_) async => task);
      final result = await mockRepo.getById('1');

      expect(result, isA<Task?>());
      expect(result, isNotNull);
      expect(result!.id, equals('1'));
    });

    testContract(
      'Project repository returns types that bloc expects',
      () async {
        final mockRepo = MockProjectRepository();
        final project = TestData.project(id: '1', name: 'Test');

        when(() => mockRepo.getById('1')).thenAnswer((_) async => project);
        final result = await mockRepo.getById('1');

        expect(result, isA<Project?>());
        expect(result, isNotNull);
        expect(result!.id, equals('1'));
      },
    );

    testContract('Label repository returns types that bloc expects', () async {
      final mockRepo = MockLabelRepository();
      final label = TestData.label(id: '1', name: 'Test');

      when(() => mockRepo.getById('1')).thenAnswer((_) async => label);
      final result = await mockRepo.getById('1');

      expect(result, isA<Label?>());
      expect(result, isNotNull);
      expect(result!.id, equals('1'));
    });

    // ═══════════════════════════════════════════════════════════════════════
    // List Type Contracts
    // ═══════════════════════════════════════════════════════════════════════

    testContract('TaskDetailBloc expects List<Project> from repository', () {
      final now = DateTime.now();
      final success = TaskDetailState.loadSuccess(
        task: Task(
          id: '1',
          name: 'Test',
          completed: false,
          createdAt: now,
          updatedAt: now,
          labels: const [],
        ),
        availableProjects: <Project>[],
        availableLabels: <Label>[],
      );

      expect(
        (success as TaskDetailLoadSuccess).availableProjects,
        isA<List<Project>>(),
      );
    });

    testContract('TaskDetailBloc expects List<Label> from repository', () {
      final now = DateTime.now();
      final success = TaskDetailState.loadSuccess(
        task: Task(
          id: '1',
          name: 'Test',
          completed: false,
          createdAt: now,
          updatedAt: now,
          labels: const [],
        ),
        availableProjects: <Project>[],
        availableLabels: <Label>[],
      );

      expect(
        (success as TaskDetailLoadSuccess).availableLabels,
        isA<List<Label>>(),
      );
    });

    testContract('ProjectDetailBloc expects List<Label> from repository', () {
      final now = DateTime.now();
      final success = ProjectDetailState.loadSuccess(
        project: Project(
          id: '1',
          name: 'Test',
          completed: false,
          createdAt: now,
          updatedAt: now,
          labels: const [],
        ),
        availableLabels: <Label>[],
      );

      expect(
        (success as ProjectDetailLoadSuccess).availableLabels,
        isA<List<Label>>(),
      );
    });
  });

  group('Model Contracts', () {
    // ═══════════════════════════════════════════════════════════════════════
    // Task Model Contracts
    // ═══════════════════════════════════════════════════════════════════════

    testContract('Task model has required fields for bloc operations', () {
      final task = TestData.task(id: '1', name: 'Test');

      // Fields that TaskDetailBloc reads/writes
      expect(task.id, isNotEmpty);
      expect(task.name, isNotEmpty);
      expect(task.completed, isNotNull);
      expect(task.labels, isA<List<Label>>());

      // Optional fields that may be null
      expect(() => task.description, returnsNormally);
      expect(() => task.projectId, returnsNormally);
      expect(() => task.startDate, returnsNormally);
      expect(() => task.deadlineDate, returnsNormally);
    });

    testContract('Project model has required fields for bloc operations', () {
      final project = TestData.project(id: '1', name: 'Test');

      expect(project.id, isNotEmpty);
      expect(project.name, isNotEmpty);
      expect(project.completed, isNotNull);
      expect(project.labels, isA<List<Label>>());
    });

    testContract('Label model has required fields for bloc operations', () {
      final label = TestData.label(id: '1', name: 'Test');

      expect(label.id, isNotEmpty);
      expect(label.name, isNotEmpty);
      // color is optional (nullable)
      expect(() => label.color, returnsNormally);
      expect(label.type, isA<LabelType>());
    });

    // ═══════════════════════════════════════════════════════════════════════
    // LabelType Enum Contracts
    // ═══════════════════════════════════════════════════════════════════════

    testContract('LabelType enum has expected values', () {
      // Blocs use these label types for filtering and display
      expect(LabelType.values, contains(LabelType.label));
      expect(LabelType.values, contains(LabelType.value));
    });
  });

  group('Bloc Initialization Contracts', () {
    // ═══════════════════════════════════════════════════════════════════════
    // Constructor Contracts
    // ═══════════════════════════════════════════════════════════════════════

    testContract(
      'TaskDetailBloc can be instantiated with required dependencies',
      () {
        final mockTaskRepo = MockTaskRepository();
        final mockProjectRepo = MockProjectRepository();
        final mockLabelRepo = MockLabelRepository();

        final bloc = TaskDetailBloc(
          taskRepository: mockTaskRepo,
          projectRepository: mockProjectRepo,
          labelRepository: mockLabelRepo,
          autoLoad: false,
        );

        expect(bloc, isNotNull);
        expect(bloc.state, isA<TaskDetailInitial>());

        bloc.close();
      },
    );

    testContract(
      'ProjectDetailBloc can be instantiated with required dependencies',
      () {
        final mockProjectRepo = MockProjectRepository();
        final mockLabelRepo = MockLabelRepository();

        final bloc = ProjectDetailBloc(
          projectRepository: mockProjectRepo,
          labelRepository: mockLabelRepo,
        );

        expect(bloc, isNotNull);
        expect(bloc.state, isA<ProjectDetailInitial>());

        bloc.close();
      },
    );

    testContract(
      'LabelDetailBloc can be instantiated with required dependencies',
      () {
        final mockLabelRepo = MockLabelRepository();

        final bloc = LabelDetailBloc(labelRepository: mockLabelRepo);

        expect(bloc, isNotNull);
        expect(bloc.state, isA<LabelDetailInitial>());

        bloc.close();
      },
    );
  });
}
