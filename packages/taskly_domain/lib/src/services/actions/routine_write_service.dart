import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/telemetry.dart';

/// Write facade for routine mutations.
///
/// Centralizes validation and side-effects for routine edits and actions.
final class RoutineWriteService {
  RoutineWriteService({required RoutineRepositoryContract routineRepository})
    : _routineRepository = routineRepository,
      _commandHandler = RoutineCommandHandler(
        routineRepository: routineRepository,
      );

  final RoutineRepositoryContract _routineRepository;
  final RoutineCommandHandler _commandHandler;

  Future<CommandResult> create(
    CreateRoutineCommand command, {
    OperationContext? context,
  }) {
    return _commandHandler.handleCreate(command, context: context);
  }

  Future<CommandResult> update(
    UpdateRoutineCommand command, {
    OperationContext? context,
  }) {
    return _commandHandler.handleUpdate(command, context: context);
  }

  Future<void> delete(String routineId, {OperationContext? context}) {
    return _routineRepository.delete(routineId, context: context);
  }

  Future<void> recordCompletion({
    required String routineId,
    DateTime? completedAtUtc,
    OperationContext? context,
  }) {
    return _routineRepository.recordCompletion(
      routineId: routineId,
      completedAtUtc: completedAtUtc,
      context: context,
    );
  }

  Future<bool> setPausedUntil(
    String routineId, {
    required DateTime? pausedUntilUtc,
    OperationContext? context,
  }) async {
    final routine = await _routineRepository.getById(routineId);
    if (routine == null) return false;

    final result = await _commandHandler.handleUpdate(
      UpdateRoutineCommand(
        id: routine.id,
        name: routine.name,
        valueId: routine.valueId,
        routineType: routine.routineType,
        targetCount: routine.targetCount,
        scheduleDays: routine.scheduleDays,
        minSpacingDays: routine.minSpacingDays,
        restDayBuffer: routine.restDayBuffer,
        preferredWeeks: routine.preferredWeeks,
        fixedDayOfMonth: routine.fixedDayOfMonth,
        fixedWeekday: routine.fixedWeekday,
        fixedWeekOfMonth: routine.fixedWeekOfMonth,
        isActive: routine.isActive,
        pausedUntilUtc: pausedUntilUtc,
      ),
      context: context,
    );

    return result is CommandSuccess;
  }
}
