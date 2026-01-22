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
    priority: t.priority,
    isPinned: t.isPinned,
    values: values ?? const <Value>[],
    primaryValueId: t.primaryValueId,
    secondaryValueId: t.secondaryValueId,
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
