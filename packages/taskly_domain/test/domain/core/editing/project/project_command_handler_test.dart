@Tags(['unit'])
library;

import '../../../../helpers/test_imports.dart';

import 'package:taskly_domain/src/core/editing/command_result.dart';
import 'package:taskly_domain/src/core/editing/project/project_command_handler.dart';
import 'package:taskly_domain/src/core/editing/project/project_commands.dart';
import 'package:taskly_domain/src/core/editing/validators/project_validators.dart';
import 'package:taskly_domain/src/forms/field_key.dart';
import 'package:taskly_domain/src/interfaces/project_repository_contract.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

void main() {
  testSafe(
    'handleCreate validates name and does not call repository',
    () async {
      final repo = _RecordingProjectRepository();
      final handler = ProjectCommandHandler(projectRepository: repo);

      const cmd = CreateProjectCommand(
        name: '   ',
        completed: false,
        valueIds: ['v1'],
      );
      final result = await handler.handleCreate(cmd);

      expect(result, isA<CommandValidationFailure>());
      final failure = (result as CommandValidationFailure).failure;

      expect(failure.fieldErrors.keys, contains(ProjectFieldKeys.name));
      expect(repo.createCalls, 0);
    },
  );

  testSafe('handleUpdate validates deadline after start', () async {
    final repo = _RecordingProjectRepository();
    final handler = ProjectCommandHandler(projectRepository: repo);

    final cmd = UpdateProjectCommand(
      id: 'p1',
      name: 'Proj',
      completed: false,
      valueIds: const ['v1'],
      startDate: DateTime.utc(2026, 1, 2),
      deadlineDate: DateTime.utc(2026, 1, 1),
    );

    final result = await handler.handleUpdate(cmd);

    expect(result, isA<CommandValidationFailure>());
    final failure = (result as CommandValidationFailure).failure;

    expect(failure.fieldErrors.keys, contains(ProjectFieldKeys.deadlineDate));
    expect(repo.updateCalls, 0);
  });

  testSafe('handleCreate trims name and forwards args to repository', () async {
    final repo = _RecordingProjectRepository();
    final handler = ProjectCommandHandler(projectRepository: repo);

    final ctx = OperationContext(
      correlationId: 'c1',
      feature: 'test',
      intent: 'create_project',
      operation: 'project.create',
    );

    final cmd = CreateProjectCommand(
      name: '  P  ',
      completed: false,
      valueIds: const ['v1'],
    );

    final result = await handler.handleCreate(cmd, context: ctx);

    expect(result, isA<CommandSuccess>());
    expect(repo.createCalls, 1);
    expect(repo.lastCreatedName, 'P');
    expect(repo.lastCreatedContext, ctx);
    expect(repo.lastCreatedValueIds, ['v1']);
  });

  testSafe('handleCreate rejects more than one project value', () async {
    final repo = _RecordingProjectRepository();
    final handler = ProjectCommandHandler(projectRepository: repo);

    const cmd = CreateProjectCommand(
      name: 'Project',
      completed: false,
      valueIds: ['v1', 'v2'],
    );

    final result = await handler.handleCreate(cmd);

    expect(result, isA<CommandValidationFailure>());
    final failure = (result as CommandValidationFailure).failure;

    expect(failure.fieldErrors.keys, contains(ProjectFieldKeys.valueIds));
    expect(repo.createCalls, 0);
  });

  testSafe('handleCreate validates max lengths', () async {
    final repo = _RecordingProjectRepository();
    final handler = ProjectCommandHandler(projectRepository: repo);

    final cmd = CreateProjectCommand(
      name: List.filled(121, 'a').join(),
      completed: false,
      description: List.filled(
        ProjectValidators.maxDescriptionLength + 1,
        'b',
      ).join(),
      repeatIcalRrule: List.filled(501, 'c').join(),
      valueIds: const ['v1'],
    );

    final result = await handler.handleCreate(cmd);

    expect(result, isA<CommandValidationFailure>());
    final failure = (result as CommandValidationFailure).failure;

    expect(failure.fieldErrors.keys, contains(ProjectFieldKeys.name));
    expect(failure.fieldErrors.keys, contains(ProjectFieldKeys.description));
    expect(
      failure.fieldErrors.keys,
      contains(ProjectFieldKeys.repeatIcalRrule),
    );
    expect(repo.createCalls, 0);
  });

  testSafe('handleCreate requires start date when recurrence is set', () async {
    final repo = _RecordingProjectRepository();
    final handler = ProjectCommandHandler(projectRepository: repo);

    const cmd = CreateProjectCommand(
      name: 'Project',
      completed: false,
      repeatIcalRrule: 'FREQ=WEEKLY',
      valueIds: ['v1'],
    );

    final result = await handler.handleCreate(cmd);

    expect(result, isA<CommandValidationFailure>());
    final failure = (result as CommandValidationFailure).failure;
    expect(failure.fieldErrors.keys, contains(ProjectFieldKeys.startDate));
    expect(repo.createCalls, 0);
  });

  testSafe('handleUpdate forwards args to repository', () async {
    final repo = _RecordingProjectRepository();
    final handler = ProjectCommandHandler(projectRepository: repo);

    final ctx = OperationContext(
      correlationId: 'c2',
      feature: 'test',
      intent: 'update_project',
      operation: 'project.update',
    );

    final cmd = UpdateProjectCommand(
      id: 'p1',
      name: '  Updated  ',
      completed: true,
      description: 'd',
      startDate: DateTime.utc(2026, 1, 1),
      deadlineDate: DateTime.utc(2026, 1, 2),
      priority: 1,
      valueIds: const ['v1'],
    );

    final result = await handler.handleUpdate(cmd, context: ctx);

    expect(result, isA<CommandSuccess>());
    expect(repo.updateCalls, 1);
    expect(repo.lastUpdatedId, 'p1');
    expect(repo.lastUpdatedName, 'Updated');
    expect(repo.lastUpdatedContext, ctx);
  });
}

final class _RecordingProjectRepository implements ProjectRepositoryContract {
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
    String? repeatIcalRrule,
    bool repeatFromCompletion = false,
    bool seriesEnded = false,
    List<String>? valueIds,
    int? priority,
    OperationContext? context,
  }) async {
    createCalls++;
    lastCreatedName = name;
    lastCreatedValueIds = valueIds;
    lastCreatedContext = context;
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    required bool completed,
    String? description,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? repeatIcalRrule,
    bool? repeatFromCompletion,
    bool? seriesEnded,
    List<String>? valueIds,
    int? priority,
    bool? isPinned,
    OperationContext? context,
  }) async {
    updateCalls++;
    lastUpdatedId = id;
    lastUpdatedName = name;
    lastUpdatedContext = context;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
