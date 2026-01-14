/// Contract tests for detail bloc patterns.
///
/// These tests verify that all detail blocs follow consistent patterns
/// and that repositories emit data in formats that blocs can consume.
///
/// Contract tests use REAL components to catch interface drift.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/core/model/entity_operation.dart';
import 'package:taskly_bloc/shared/logging/talker_service.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/values/bloc/value_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/project_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';

import '../fixtures/test_data.dart';
import '../helpers/contract_test_helpers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Mocks
// ═══════════════════════════════════════════════════════════════════════════

class MockTaskRepository extends Mock implements TaskRepositoryContract {}

class MockProjectRepository extends Mock implements ProjectRepositoryContract {}

class MockValueRepository extends Mock implements ValueRepositoryContract {}

// ═══════════════════════════════════════════════════════════════════════════
// Contract Tests
// ═══════════════════════════════════════════════════════════════════════════

void main() {
  setUpAll(initializeTalkerForTest);

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

    testContract('ValueDetailState has all required factory constructors', () {
      const initial = ValueDetailState.initial();
      const loading = ValueDetailState.loadInProgress();
      const success = ValueDetailState.operationSuccess(
        operation: EntityOperation.create,
      );

      expect(initial, isA<ValueDetailInitial>());
      expect(loading, isA<ValueDetailLoadInProgress>());
      expect(success, isA<ValueDetailOperationSuccess>());
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
      const valueSuccess = ValueDetailState.operationSuccess(
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
        (valueSuccess as ValueDetailOperationSuccess).operation,
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
      const create = TaskDetailEvent.create(
        command: CreateTaskCommand(
          name: 'Test',
          completed: false,
          description: null,
        ),
      );
      const update = TaskDetailEvent.update(
        command: UpdateTaskCommand(
          id: 'id',
          name: 'Test',
          completed: false,
          description: null,
        ),
      );
      const delete = TaskDetailEvent.delete(id: 'id');
      const loadById = TaskDetailEvent.loadById(taskId: 'id');

      expect(create, isNotNull);
      expect(update, isNotNull);
      expect(delete, isNotNull);
      expect(loadById, isNotNull);
    });

    testContract('ProjectDetailEvent has all CRUD event factories', () {
      const create = ProjectDetailEvent.create(
        command: CreateProjectCommand(
          name: 'Test',
          completed: false,
        ),
      );
      const update = ProjectDetailEvent.update(
        command: UpdateProjectCommand(
          id: 'id',
          name: 'Test',
          completed: false,
        ),
      );
      const delete = ProjectDetailEvent.delete(id: 'id');
      const loadById = ProjectDetailEvent.loadById(projectId: 'id');

      expect(create, isNotNull);
      expect(update, isNotNull);
      expect(delete, isNotNull);
      expect(loadById, isNotNull);
    });

    testContract('ValueDetailEvent has all CRUD event factories', () {
      const create = ValueDetailEvent.create(
        command: CreateValueCommand(
          name: 'Test',
          color: '#000000',
          priority: ValuePriority.medium,
        ),
      );
      const update = ValueDetailEvent.update(
        command: UpdateValueCommand(
          id: 'id',
          name: 'Test',
          color: '#000000',
          priority: ValuePriority.medium,
        ),
      );
      const delete = ValueDetailEvent.delete(id: 'id');
      const loadById = ValueDetailEvent.loadById(valueId: 'id');

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

    testContract('Value repository returns types that bloc expects', () async {
      final mockRepo = MockValueRepository();
      final value = TestData.value(id: '1', name: 'Test');

      when(() => mockRepo.getById('1')).thenAnswer((_) async => value);
      final result = await mockRepo.getById('1');

      expect(result, isA<Value?>());
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
          values: const [],
        ),
        availableProjects: <Project>[],
        availableValues: <Value>[],
      );

      expect(
        (success as TaskDetailLoadSuccess).availableProjects,
        isA<List<Project>>(),
      );
    });

    testContract('TaskDetailBloc expects List<Value> from repository', () {
      final now = DateTime.now();
      final success = TaskDetailState.loadSuccess(
        task: Task(
          id: '1',
          name: 'Test',
          completed: false,
          createdAt: now,
          updatedAt: now,
          values: const [],
        ),
        availableProjects: <Project>[],
        availableValues: <Value>[],
      );

      expect(
        (success as TaskDetailLoadSuccess).availableValues,
        isA<List<Value>>(),
      );
    });

    testContract('ProjectDetailBloc expects List<Value> from repository', () {
      final now = DateTime.now();
      final success = ProjectDetailState.loadSuccess(
        project: Project(
          id: '1',
          name: 'Test',
          completed: false,
          createdAt: now,
          updatedAt: now,
          values: const [],
        ),
        availableValues: <Value>[],
      );

      expect(
        (success as ProjectDetailLoadSuccess).availableValues,
        isA<List<Value>>(),
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
      expect(task.values, isA<List<Value>>());

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
      expect(project.values, isA<List<Value>>());
    });

    testContract('Value model has required fields for bloc operations', () {
      final value = TestData.value(id: '1', name: 'Test');

      expect(value.id, isNotEmpty);
      expect(value.name, isNotEmpty);
      // color is optional (nullable)
      expect(() => value.color, returnsNormally);
      expect(value.priority, isA<ValuePriority>());
    });

    // ═══════════════════════════════════════════════════════════════════════
    // LabelType Enum Contracts
    // ═══════════════════════════════════════════════════════════════════════

    testContract('ValuePriority enum has expected values', () {
      // Blocs use these values priorities
      expect(ValuePriority.values, contains(ValuePriority.high));
      expect(ValuePriority.values, contains(ValuePriority.medium));
      expect(ValuePriority.values, contains(ValuePriority.low));
      // Note: 'none' is not a valid ValuePriority - use low/medium/high
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
        final mockValueRepo = MockValueRepository();

        final bloc = TaskDetailBloc(
          taskRepository: mockTaskRepo,
          projectRepository: mockProjectRepo,
          valueRepository: mockValueRepo,
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
        final mockValueRepo = MockValueRepository();

        final bloc = ProjectDetailBloc(
          projectRepository: mockProjectRepo,
          valueRepository: mockValueRepo,
        );

        expect(bloc, isNotNull);
        expect(bloc.state, isA<ProjectDetailInitial>());

        bloc.close();
      },
    );

    testContract(
      'ValueDetailBloc can be instantiated with required dependencies',
      () {
        final mockValueRepo = MockValueRepository();

        final bloc = ValueDetailBloc(valueRepository: mockValueRepo);

        expect(bloc, isNotNull);
        expect(bloc.state, isA<ValueDetailInitial>());

        bloc.close();
      },
    );
  });
}
