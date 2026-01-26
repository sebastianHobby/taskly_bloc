import 'package:taskly_domain/src/core/editing/command_result.dart';
import 'package:taskly_domain/src/core/editing/routine/routine_commands.dart';
import 'package:taskly_domain/src/core/editing/validation_error.dart';
import 'package:taskly_domain/src/core/editing/validation_failure.dart';
import 'package:taskly_domain/src/core/editing/validators/routine_validators.dart';
import 'package:taskly_domain/src/forms/field_key.dart';
import 'package:taskly_domain/src/interfaces/routine_repository_contract.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

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
      valueId: command.valueId,
      projectId: command.projectId,
      routineType: command.routineType,
      targetCount: command.targetCount,
      scheduleDays: command.scheduleDays,
      minSpacingDays: command.minSpacingDays,
      restDayBuffer: command.restDayBuffer,
      preferredWeeks: command.preferredWeeks,
      fixedDayOfMonth: command.fixedDayOfMonth,
      fixedWeekday: command.fixedWeekday,
      fixedWeekOfMonth: command.fixedWeekOfMonth,
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
      valueId: command.valueId,
      projectId: command.projectId,
      routineType: command.routineType,
      targetCount: command.targetCount,
      scheduleDays: command.scheduleDays,
      minSpacingDays: command.minSpacingDays,
      restDayBuffer: command.restDayBuffer,
      preferredWeeks: command.preferredWeeks,
      fixedDayOfMonth: command.fixedDayOfMonth,
      fixedWeekday: command.fixedWeekday,
      fixedWeekOfMonth: command.fixedWeekOfMonth,
      isActive: command.isActive,
      pausedUntilUtc: command.pausedUntilUtc,
      context: context,
    );

    return const CommandResult.success();
  }

  ValidationFailure? _validate(dynamic command) {
    final name = (command as dynamic).name as String;
    final valueId = (command as dynamic).valueId as String;
    final routineType = (command as dynamic).routineType;
    final targetCount = (command as dynamic).targetCount as int?;
    final scheduleDays = (command as dynamic).scheduleDays as List<int>;
    final preferredWeeks = (command as dynamic).preferredWeeks as List<int>;
    final fixedDayOfMonth = (command as dynamic).fixedDayOfMonth as int?;
    final fixedWeekday = (command as dynamic).fixedWeekday as int?;
    final fixedWeekOfMonth = (command as dynamic).fixedWeekOfMonth as int?;

    final fieldErrors = <FieldKey, List<ValidationError>>{};
    fieldErrors[RoutineFieldKeys.name] = RoutineValidators.name(name);
    final valueErrors = RoutineValidators.valueId(valueId);
    if (valueErrors.isNotEmpty) {
      fieldErrors[RoutineFieldKeys.valueId] = valueErrors;
    }

    final targetErrors = RoutineValidators.targetCount(
      targetCount,
      routineType: routineType,
    );
    if (targetErrors.isNotEmpty) {
      fieldErrors[RoutineFieldKeys.targetCount] = targetErrors;
    }

    final scheduleErrors = RoutineValidators.scheduleDays(
      scheduleDays,
      routineType: routineType,
    );
    if (scheduleErrors.isNotEmpty) {
      fieldErrors[RoutineFieldKeys.scheduleDays] = scheduleErrors;
    }

    final preferredWeekErrors = RoutineValidators.preferredWeeks(
      preferredWeeks,
      routineType: routineType,
    );
    if (preferredWeekErrors.isNotEmpty) {
      fieldErrors[RoutineFieldKeys.preferredWeeks] = preferredWeekErrors;
    }

    final fixedErrors = RoutineValidators.fixedMonthlyFields(
      fixedDayOfMonth: fixedDayOfMonth,
      fixedWeekday: fixedWeekday,
      fixedWeekOfMonth: fixedWeekOfMonth,
      routineType: routineType,
    );
    if (fixedErrors.isNotEmpty) {
      fieldErrors[RoutineFieldKeys.fixedDayOfMonth] = fixedErrors;
    }

    final pruned = Map<FieldKey, List<ValidationError>>.fromEntries(
      fieldErrors.entries.where((entry) => entry.value.isNotEmpty),
    );
    if (pruned.isEmpty) return null;
    return ValidationFailure(fieldErrors: pruned);
  }
}
