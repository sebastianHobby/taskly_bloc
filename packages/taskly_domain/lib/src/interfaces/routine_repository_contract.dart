import 'package:taskly_domain/src/routines/model/routine.dart';
import 'package:taskly_domain/src/routines/model/routine_completion.dart';
import 'package:taskly_domain/src/routines/model/routine_skip.dart';
import 'package:taskly_domain/src/routines/model/routine_period_type.dart';
import 'package:taskly_domain/src/routines/model/routine_schedule_mode.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

abstract class RoutineRepositoryContract {
  Stream<List<Routine>> watchAll({bool includeInactive = true});

  Future<List<Routine>> getAll({bool includeInactive = true});

  Stream<Routine?> watchById(String id);

  Future<Routine?> getById(String id);

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
  });

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
  });

  Future<void> delete(String id, {OperationContext? context});

  Stream<List<RoutineCompletion>> watchCompletions();

  Stream<List<RoutineSkip>> watchSkips();

  Future<List<RoutineCompletion>> getCompletions();

  Future<List<RoutineSkip>> getSkips();

  Future<void> recordCompletion({
    required String routineId,
    DateTime? completedAtUtc,
    DateTime? completedDayLocal,
    int? completedTimeLocalMinutes,
    OperationContext? context,
  });

  Future<bool> removeLatestCompletionForDay({
    required String routineId,
    required DateTime dayKeyUtc,
    OperationContext? context,
  });

  Future<void> recordSkip({
    required String routineId,
    required RoutineSkipPeriodType periodType,
    required DateTime periodKeyUtc,
    OperationContext? context,
  });
}
