import 'package:taskly_domain/src/routines/model/routine.dart';
import 'package:taskly_domain/src/routines/model/routine_completion.dart';
import 'package:taskly_domain/src/routines/model/routine_skip.dart';
import 'package:taskly_domain/src/routines/model/routine_type.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

abstract class RoutineRepositoryContract {
  Stream<List<Routine>> watchAll({bool includeInactive = true});

  Future<List<Routine>> getAll({bool includeInactive = true});

  Stream<Routine?> watchById(String id);

  Future<Routine?> getById(String id);

  Future<void> create({
    required String name,
    required String valueId,
    required RoutineType routineType,
    required int targetCount,
    List<int> scheduleDays = const <int>[],
    int? minSpacingDays,
    int? restDayBuffer,
    List<int> preferredWeeks = const <int>[],
    int? fixedDayOfMonth,
    int? fixedWeekday,
    int? fixedWeekOfMonth,
    bool isActive = true,
    DateTime? pausedUntilUtc,
    OperationContext? context,
  });

  Future<void> update({
    required String id,
    required String name,
    required String valueId,
    required RoutineType routineType,
    required int targetCount,
    List<int>? scheduleDays,
    int? minSpacingDays,
    int? restDayBuffer,
    List<int>? preferredWeeks,
    int? fixedDayOfMonth,
    int? fixedWeekday,
    int? fixedWeekOfMonth,
    bool? isActive,
    DateTime? pausedUntilUtc,
    OperationContext? context,
  });

  Future<void> delete(String id, {OperationContext? context});

  Stream<List<RoutineCompletion>> watchCompletions();

  Stream<List<RoutineSkip>> watchSkips();

  Future<List<RoutineCompletion>> getCompletions();

  Future<List<RoutineSkip>> getSkips();

  Future<void> recordCompletion({
    required String routineId,
    DateTime? completedAtUtc,
    OperationContext? context,
  });

  Future<void> recordSkip({
    required String routineId,
    required RoutineSkipPeriodType periodType,
    required DateTime periodKeyUtc,
    OperationContext? context,
  });
}
