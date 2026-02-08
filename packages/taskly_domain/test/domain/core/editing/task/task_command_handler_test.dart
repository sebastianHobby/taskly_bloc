@Tags(['unit'])
library;

import '../../../../helpers/test_imports.dart';

import 'package:taskly_domain/src/core/editing/command_result.dart';
import 'package:taskly_domain/src/core/editing/task/task_command_handler.dart';
import 'package:taskly_domain/src/core/editing/task/task_commands.dart';
import 'package:taskly_domain/src/forms/field_key.dart';
import 'package:taskly_domain/src/interfaces/project_repository_contract.dart';
import 'package:taskly_domain/src/interfaces/task_repository_contract.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';
import 'package:taskly_domain/core.dart';

void main() {
  testSafe(
    'handleCreate validates name and does not call repository',
    () async {
      final repo = _RecordingTaskRepository();
      final projectRepo = _RecordingProjectRepository();
      final handler = TaskCommandHandler(
        taskRepository: repo,
        projectRepository: projectRepo,
      );

      const cmd = CreateTaskCommand(name: '   ', completed: false);
      final result = await handler.handleCreate(cmd);

      expect(result, isA<CommandValidationFailure>());
      final failure = (result as CommandValidationFailure).failure;

      expect(failure.fieldErrors.keys, contains(TaskFieldKeys.name));
      expect(repo.createCalls, 0);
    },
  );

  testSafe('handleCreate trims name and forwards args to repository', () async {
    final repo = _RecordingTaskRepository();
    final projectRepo = _RecordingProjectRepository()
      ..projectsById['p1'] = _projectWithPrimary('p1', 'v1');
    final handler = TaskCommandHandler(
      taskRepository: repo,
      projectRepository: projectRepo,
    );

    final ctx = OperationContext(
      correlationId: 'c1',
      feature: 'test',
      intent: 'create_task',
      operation: 'task.create',
    );

    final cmd = CreateTaskCommand(
      name: '  Hello  ',
      completed: true,
      description: 'd',
      startDate: DateTime.utc(2026, 1, 1),
      deadlineDate: DateTime.utc(2026, 1, 2),
      projectId: 'p1',
      priority: 2,
      repeatIcalRrule: 'RRULE:FREQ=DAILY',
      repeatFromCompletion: true,
      seriesEnded: true,
      valueIds: const ['v2'],
    );

    final result = await handler.handleCreate(cmd, context: ctx);

    expect(result, isA<CommandSuccess>());
    expect(repo.createCalls, 1);
    expect(repo.lastCreatedName, 'Hello');
    expect(repo.lastCreatedContext, ctx);
    expect(repo.lastCreatedValueIds, ['v2']);
  });

  testSafe('handleUpdate validates deadline after start', () async {
    final repo = _RecordingTaskRepository();
    final projectRepo = _RecordingProjectRepository();
    final handler = TaskCommandHandler(
      taskRepository: repo,
      projectRepository: projectRepo,
    );

    final cmd = UpdateTaskCommand(
      id: 't1',
      name: 'Task',
      completed: false,
      startDate: DateTime.utc(2026, 1, 2),
      deadlineDate: DateTime.utc(2026, 1, 1),
    );

    final result = await handler.handleUpdate(cmd);

    expect(result, isA<CommandValidationFailure>());
    final failure = (result as CommandValidationFailure).failure;

    expect(failure.fieldErrors.keys, contains(TaskFieldKeys.deadlineDate));
    expect(repo.updateCalls, 0);
  });

  testSafe('handleCreate validates max lengths', () async {
    final repo = _RecordingTaskRepository();
    final projectRepo = _RecordingProjectRepository();
    final handler = TaskCommandHandler(
      taskRepository: repo,
      projectRepository: projectRepo,
    );

    final cmd = CreateTaskCommand(
      name: List.filled(121, 'a').join(),
      completed: false,
      description: List.filled(201, 'b').join(),
      repeatIcalRrule: List.filled(501, 'c').join(),
    );

    final result = await handler.handleCreate(cmd);

    expect(result, isA<CommandValidationFailure>());
    final failure = (result as CommandValidationFailure).failure;

    expect(failure.fieldErrors.keys, contains(TaskFieldKeys.name));
    expect(failure.fieldErrors.keys, contains(TaskFieldKeys.description));
    expect(failure.fieldErrors.keys, contains(TaskFieldKeys.repeatIcalRrule));
    expect(repo.createCalls, 0);
  });

  testSafe(
    'handleCreate rejects tags when no project is selected',
    () async {
      final repo = _RecordingTaskRepository();
      final projectRepo = _RecordingProjectRepository();
      final handler = TaskCommandHandler(
        taskRepository: repo,
        projectRepository: projectRepo,
      );

      const cmd = CreateTaskCommand(
        name: 'Task',
        completed: false,
        valueIds: ['v1'],
      );

      final result = await handler.handleCreate(cmd);

      expect(result, isA<CommandValidationFailure>());
      final failure = (result as CommandValidationFailure).failure;
      expect(failure.fieldErrors.keys, contains(TaskFieldKeys.valueIds));
      expect(repo.createCalls, 0);
    },
  );

  testSafe('handleUpdate forwards args to repository', () async {
    final repo = _RecordingTaskRepository();
    final projectRepo = _RecordingProjectRepository()
      ..projectsById['p1'] = _projectWithPrimary('p1', 'v1');
    final handler = TaskCommandHandler(
      taskRepository: repo,
      projectRepository: projectRepo,
    );

    final ctx = OperationContext(
      correlationId: 'c2',
      feature: 'test',
      intent: 'update_task',
      operation: 'task.update',
    );

    final cmd = UpdateTaskCommand(
      id: 't1',
      name: '  Updated  ',
      completed: true,
      description: 'desc',
      startDate: DateTime.utc(2026, 1, 1),
      deadlineDate: DateTime.utc(2026, 1, 2),
      projectId: 'p1',
      priority: 1,
      valueIds: const ['v2', 'v3'],
    );

    final result = await handler.handleUpdate(cmd, context: ctx);

    expect(result, isA<CommandSuccess>());
    expect(repo.updateCalls, 1);
    expect(repo.lastUpdatedId, 't1');
    expect(repo.lastUpdatedName, 'Updated');
    expect(repo.lastUpdatedContext, ctx);
  });

  testSafe(
    'handleCreate rejects tags that match the project primary value',
    () async {
      final repo = _RecordingTaskRepository();
      final projectRepo = _RecordingProjectRepository()
        ..projectsById['p1'] = _projectWithPrimary('p1', 'v1');
      final handler = TaskCommandHandler(
        taskRepository: repo,
        projectRepository: projectRepo,
      );

      const cmd = CreateTaskCommand(
        name: 'Task',
        completed: false,
        projectId: 'p1',
        valueIds: ['v1'],
      );

      final result = await handler.handleCreate(cmd);

      expect(result, isA<CommandValidationFailure>());
      final failure = (result as CommandValidationFailure).failure;
      expect(failure.fieldErrors.keys, contains(TaskFieldKeys.valueIds));
      expect(repo.createCalls, 0);
    },
  );
}

final class _RecordingTaskRepository implements TaskRepositoryContract {
  int createCalls = 0;
  int updateCalls = 0;

  String? lastCreatedName;
  List<String>? lastCreatedValueIds;
  OperationContext? lastCreatedContext;

  String? lastUpdatedId;
  String? lastUpdatedName;
  OperationContext? lastUpdatedContext;

  @override
  Future<void> create({
    required String name,
    String? description,
    bool completed = false,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    int? priority,
    String? repeatIcalRrule,
    bool repeatFromCompletion = false,
    bool seriesEnded = false,
    List<String>? valueIds,
    OperationContext? context,
  }) async {
    createCalls++;
    lastCreatedName = name;
    lastCreatedValueIds = valueIds;
    lastCreatedContext = context;
  }

  @override
  Future<String> createReturningId({
    required String name,
    String? description,
    bool completed = false,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    int? priority,
    String? repeatIcalRrule,
    bool repeatFromCompletion = false,
    bool seriesEnded = false,
    List<String>? valueIds,
    OperationContext? context,
  }) async {
    createCalls++;
    lastCreatedName = name;
    lastCreatedValueIds = valueIds;
    lastCreatedContext = context;
    return 'task-1';
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    required bool completed,
    String? description,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    int? priority,
    String? repeatIcalRrule,
    bool? repeatFromCompletion,
    bool? seriesEnded,
    List<String>? valueIds,
    bool? isPinned,
    OperationContext? context,
  }) async {
    updateCalls++;
    lastUpdatedId = id;
    lastUpdatedName = name;
    lastUpdatedContext = context;
  }

  @override
  Future<void> setMyDaySnoozedUntil({
    required String id,
    required DateTime? untilUtc,
    OperationContext? context,
  }) async {
    // Not used by these tests.
  }

  @override
  Future<Map<String, TaskSnoozeStats>> getSnoozeStats({
    required DateTime sinceUtc,
    required DateTime untilUtc,
  }) async {
    return const <String, TaskSnoozeStats>{};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _RecordingProjectRepository implements ProjectRepositoryContract {
  final Map<String, Project> projectsById = {};

  @override
  Future<Project?> getById(String id) async => projectsById[id];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Project _projectWithPrimary(String id, String primaryValueId) {
  return Project(
    id: id,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    name: 'Project $id',
    completed: false,
    values: [
      Value(
        id: primaryValueId,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        name: 'V$primaryValueId',
      ),
    ],
    primaryValueId: primaryValueId,
  );
}
