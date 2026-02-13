import 'package:taskly_domain/src/core/editing/command_result.dart';
import 'package:taskly_domain/src/core/editing/routine/routine_commands.dart';
import 'package:taskly_domain/src/core/editing/validation_error.dart';
import 'package:taskly_domain/src/core/editing/validation_failure.dart';
import 'package:taskly_domain/src/core/editing/validators/routine_validators.dart';
import 'package:taskly_domain/src/forms/field_key.dart';
import 'package:taskly_domain/src/interfaces/routine_repository_contract.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';
import 'package:taskly_domain/routines.dart';

final class RoutineCommandHandler {
  RoutineCommandHandler({
    required RoutineRepositoryContract routineRepository,
  }) : _routineRepository = routineRepository;

  final RoutineRepositoryContract _routineRepository;

  Future<CommandResult> handleCreate(
    CreateRoutineCommand command, {
    OperationContext? context,
  }) async {
    final failure = _validate(command);
    if (failure != null) return CommandResult.validationFailure(failure);

    await _routineRepository.create(
      name: command.name.trim(),
      projectId: command.projectId,
      periodType: command.periodType,
      scheduleMode: command.scheduleMode,
      targetCount: command.targetCount,
      scheduleDays: command.scheduleDays,
      scheduleMonthDays: command.scheduleMonthDays,
      scheduleTimeMinutes: command.scheduleTimeMinutes,
      minSpacingDays: command.minSpacingDays,
      restDayBuffer: command.restDayBuffer,
      isActive: command.isActive,
      pausedUntilUtc: command.pausedUntilUtc,
      context: context,
    );

    return const CommandResult.success();
  }

  Future<CommandResult> handleUpdate(
    UpdateRoutineCommand command, {
    OperationContext? context,
  }) async {
    final failure = _validate(command);
    if (failure != null) return CommandResult.validationFailure(failure);

    await _routineRepository.update(
      id: command.id,
      name: command.name.trim(),
      projectId: command.projectId,
      periodType: command.periodType,
      scheduleMode: command.scheduleMode,
      targetCount: command.targetCount,
      scheduleDays: command.scheduleDays,
      scheduleMonthDays: command.scheduleMonthDays,
      scheduleTimeMinutes: command.scheduleTimeMinutes,
      minSpacingDays: command.minSpacingDays,
      restDayBuffer: command.restDayBuffer,
      isActive: command.isActive,
      pausedUntilUtc: command.pausedUntilUtc,
      context: context,
    );

    return const CommandResult.success();
  }

  ValidationFailure? _validate(dynamic command) {
    final name = (command as dynamic).name as String;
    final projectId = (command as dynamic).projectId as String;
    final periodType = (command as dynamic).periodType as RoutinePeriodType;
    final scheduleMode =
        (command as dynamic).scheduleMode as RoutineScheduleMode;
    final targetCount = (command as dynamic).targetCount as int?;
    final scheduleDays = (command as dynamic).scheduleDays as List<int>;
    final scheduleMonthDays =
        (command as dynamic).scheduleMonthDays as List<int>;

    final fieldErrors = <FieldKey, List<ValidationError>>{};
    fieldErrors[RoutineFieldKeys.name] = RoutineValidators.name(name);
    final projectErrors = RoutineValidators.projectId(projectId);
    if (projectErrors.isNotEmpty) {
      fieldErrors[RoutineFieldKeys.projectId] = projectErrors;
    }

    final targetErrors = RoutineValidators.targetCount(
      targetCount,
      periodType: periodType,
      scheduleMode: scheduleMode,
    );
    if (targetErrors.isNotEmpty) {
      fieldErrors[RoutineFieldKeys.targetCount] = targetErrors;
    }

    final scheduleErrors = RoutineValidators.scheduleDays(
      scheduleDays,
      periodType: periodType,
      scheduleMode: scheduleMode,
    );
    if (scheduleErrors.isNotEmpty) {
      fieldErrors[RoutineFieldKeys.scheduleDays] = scheduleErrors;
    }

    final monthDayErrors = RoutineValidators.scheduleMonthDays(
      scheduleMonthDays,
      periodType: periodType,
      scheduleMode: scheduleMode,
    );
    if (monthDayErrors.isNotEmpty) {
      fieldErrors[RoutineFieldKeys.scheduleMonthDays] = monthDayErrors;
    }

    final pruned = Map<FieldKey, List<ValidationError>>.fromEntries(
      fieldErrors.entries.where((entry) => entry.value.isNotEmpty),
    );
    if (pruned.isEmpty) return null;
    return ValidationFailure(fieldErrors: pruned);
  }
}
