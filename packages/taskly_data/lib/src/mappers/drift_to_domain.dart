import 'package:taskly_data/src/infrastructure/drift/drift_database.dart'
    as drift;
import 'package:taskly_domain/taskly_domain.dart';

Value valueFromTable(drift.ValueTableData t) {
  return Value(
    id: t.id,
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
    name: t.name,
    color: t.color,
    priority: t.priority ?? ValuePriority.medium,
    iconName: t.iconName,
  );
}

Project projectFromTable(
  drift.ProjectTableData t, {
  List<Value>? values,
  int taskCount = 0,
  int completedTaskCount = 0,
}) {
  return Project(
    id: t.id,
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
    name: t.name,
    completed: t.completed,
    taskCount: taskCount,
    completedTaskCount: completedTaskCount,
    description: t.description,
    startDate: dateOnlyOrNull(t.startDate),
    deadlineDate: dateOnlyOrNull(t.deadlineDate),
    repeatIcalRrule: t.repeatIcalRrule,
    repeatFromCompletion: t.repeatFromCompletion,
    seriesEnded: t.seriesEnded,
    lastProgressAt: t.lastProgressAt,
    priority: t.priority,
    isPinned: t.isPinned,
    values: values ?? const <Value>[],
    primaryValueId: t.primaryValueId,
  );
}

Task taskFromTable(
  drift.TaskTableData t, {
  Project? project,
  List<Value>? values,
}) {
  return Task(
    id: t.id,
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
    name: t.name,
    completed: t.completed,
    description: t.description,
    startDate: dateOnlyOrNull(t.startDate),
    deadlineDate: dateOnlyOrNull(t.deadlineDate),
    myDaySnoozedUntilUtc: t.myDaySnoozedUntilUtc,
    projectId: t.projectId,
    repeatIcalRrule: t.repeatIcalRrule,
    repeatFromCompletion: t.repeatFromCompletion,
    seriesEnded: t.seriesEnded,
    priority: t.priority,
    isPinned: t.isPinned,
    project: project,
    values: values ?? const <Value>[],
    overridePrimaryValueId: t.overridePrimaryValueId,
    overrideSecondaryValueId: t.overrideSecondaryValueId,
  );
}

ProjectAnchorState projectAnchorStateFromTable(
  drift.ProjectAnchorStateTableData t,
) {
  return ProjectAnchorState(
    id: t.id,
    projectId: t.projectId,
    lastAnchoredAtUtc: t.lastAnchoredAt,
    createdAtUtc: t.createdAt,
    updatedAtUtc: t.updatedAt,
  );
}

Routine routineFromTable(drift.RoutinesTableData t, {Value? value}) {
  return Routine(
    id: t.id,
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
    name: t.name,
    projectId: t.projectId,
    periodType: RoutinePeriodType.values.firstWhere(
      (value) => value.name == t.periodType,
      orElse: () => RoutinePeriodType.week,
    ),
    scheduleMode: RoutineScheduleMode.values.firstWhere(
      (value) => value.name == t.scheduleMode,
      orElse: () => RoutineScheduleMode.flexible,
    ),
    targetCount: t.targetCount,
    scheduleDays: t.scheduleDays ?? const <int>[],
    scheduleMonthDays: t.scheduleMonthDays ?? const <int>[],
    scheduleTimeMinutes: t.scheduleTimeMinutes,
    minSpacingDays: t.minSpacingDays,
    restDayBuffer: t.restDayBuffer,
    isActive: t.isActive,
    pausedUntil: t.pausedUntil,
    value: value,
  );
}

RoutineCompletion routineCompletionFromTable(
  drift.RoutineCompletionsTableData t,
) {
  return RoutineCompletion(
    id: t.id,
    routineId: t.routineId,
    completedAtUtc: t.completedAt,
    createdAtUtc: t.createdAt,
    completedDayLocal: t.completedDayLocal,
    completedTimeLocalMinutes: t.completedTimeLocalMinutes,
  );
}

RoutineSkip routineSkipFromTable(drift.RoutineSkipsTableData t) {
  return RoutineSkip(
    id: t.id,
    routineId: t.routineId,
    periodType: RoutineSkipPeriodType.values.firstWhere(
      (value) => value.name == t.periodType,
      orElse: () => RoutineSkipPeriodType.week,
    ),
    periodKeyUtc: t.periodKey,
    createdAtUtc: t.createdAt,
  );
}
