@Tags(['unit'])
library;

import '../../../../helpers/test_imports.dart';

import 'package:taskly_domain/src/core/editing/command_result.dart';
import 'package:taskly_domain/src/core/editing/routine/routine_command_handler.dart';
import 'package:taskly_domain/src/core/editing/routine/routine_commands.dart';
import 'package:taskly_domain/src/forms/field_key.dart';
import 'package:taskly_domain/src/interfaces/routine_repository_contract.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';
import 'package:taskly_domain/routines.dart';

void main() {
  testSafe(
    'handleCreate validates required fields and blocks repository',
    () async {
      final repo = _RecordingRoutineRepository();
      final handler = RoutineCommandHandler(routineRepository: repo);

      const command = CreateRoutineCommand(
        name: '   ',
        projectId: '',
        periodType: RoutinePeriodType.week,
        scheduleMode: RoutineScheduleMode.scheduled,
        targetCount: 0,
        scheduleDays: <int>[],
      );

      final result = await handler.handleCreate(command);

      expect(result, isA<CommandValidationFailure>());
      final failure = (result as CommandValidationFailure).failure;
      expect(failure.fieldErrors.keys, contains(RoutineFieldKeys.name));
      expect(failure.fieldErrors.keys, contains(RoutineFieldKeys.projectId));
      expect(repo.createCalls, 0);
    },
  );

  testSafe('handleCreate trims name and forwards command payload', () async {
    final repo = _RecordingRoutineRepository();
    final handler = RoutineCommandHandler(routineRepository: repo);
    final context = OperationContext(
      correlationId: 'c1',
      feature: 'routine',
      intent: 'create',
      operation: 'routine.create',
    );

    final command = CreateRoutineCommand(
      name: '  Morning reset  ',
      projectId: 'p1',
      periodType: RoutinePeriodType.week,
      scheduleMode: RoutineScheduleMode.scheduled,
      targetCount: 3,
      scheduleDays: const <int>[1, 3, 5],
      scheduleMonthDays: const <int>[1, 15],
      scheduleTimeMinutes: 480,
      minSpacingDays: 1,
      restDayBuffer: 2,
      isActive: true,
      pausedUntilUtc: DateTime.utc(2026, 2, 1),
      checklistTitles: const <String>['One', 'Two'],
    );

    final result = await handler.handleCreate(command, context: context);

    expect(result, isA<CommandSuccess>());
    expect(repo.createCalls, 1);
    expect(repo.lastCreatedName, 'Morning reset');
    expect(repo.lastCreatedProjectId, 'p1');
    expect(repo.lastCreatedScheduleDays, <int>[1, 3, 5]);
    expect(repo.lastCreatedContext, context);
  });

  testSafe('handleUpdate validates monthly schedule day bounds', () async {
    final repo = _RecordingRoutineRepository();
    final handler = RoutineCommandHandler(routineRepository: repo);

    const command = UpdateRoutineCommand(
      id: 'r1',
      name: 'Routine',
      projectId: 'p1',
      periodType: RoutinePeriodType.month,
      scheduleMode: RoutineScheduleMode.scheduled,
      targetCount: 1,
      scheduleMonthDays: <int>[0, 32],
    );

    final result = await handler.handleUpdate(command);

    expect(result, isA<CommandValidationFailure>());
    final failure = (result as CommandValidationFailure).failure;
    expect(
      failure.fieldErrors.keys,
      contains(RoutineFieldKeys.scheduleMonthDays),
    );
    expect(repo.updateCalls, 0);
  });

  testSafe('handleUpdate forwards trimmed name and context', () async {
    final repo = _RecordingRoutineRepository();
    final handler = RoutineCommandHandler(routineRepository: repo);
    final context = OperationContext(
      correlationId: 'c2',
      feature: 'routine',
      intent: 'update',
      operation: 'routine.update',
    );

    const command = UpdateRoutineCommand(
      id: 'r1',
      name: '  Evening review  ',
      projectId: 'p2',
      periodType: RoutinePeriodType.day,
      scheduleMode: RoutineScheduleMode.flexible,
      targetCount: 1,
      checklistTitles: <String>['Done'],
    );

    final result = await handler.handleUpdate(command, context: context);

    expect(result, isA<CommandSuccess>());
    expect(repo.updateCalls, 1);
    expect(repo.lastUpdatedId, 'r1');
    expect(repo.lastUpdatedName, 'Evening review');
    expect(repo.lastUpdatedContext, context);
  });
}

final class _RecordingRoutineRepository implements RoutineRepositoryContract {
  int createCalls = 0;
  int updateCalls = 0;

  String? lastCreatedName;
  String? lastCreatedProjectId;
  List<int>? lastCreatedScheduleDays;
  OperationContext? lastCreatedContext;

  String? lastUpdatedId;
  String? lastUpdatedName;
  OperationContext? lastUpdatedContext;

  @override
  Future<void> create({
    required String name,
    required String projectId,
    required RoutinePeriodType periodType,
    required RoutineScheduleMode scheduleMode,
    required int targetCount,
    List<int> scheduleDays = const <int>[],
    List<int> scheduleMonthDays = const <int>[],
    int? scheduleTimeMinutes,
    int? minSpacingDays,
    int? restDayBuffer,
    bool isActive = true,
    DateTime? pausedUntilUtc,
    List<String> checklistTitles = const <String>[],
    OperationContext? context,
  }) async {
    createCalls++;
    lastCreatedName = name;
    lastCreatedProjectId = projectId;
    lastCreatedScheduleDays = scheduleDays;
    lastCreatedContext = context;
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    required String projectId,
    required RoutinePeriodType periodType,
    required RoutineScheduleMode scheduleMode,
    required int targetCount,
    List<int>? scheduleDays,
    List<int>? scheduleMonthDays,
    int? scheduleTimeMinutes,
    int? minSpacingDays,
    int? restDayBuffer,
    bool? isActive,
    DateTime? pausedUntilUtc,
    List<String> checklistTitles = const <String>[],
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
