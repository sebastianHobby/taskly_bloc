import 'package:taskly_bloc/domain/time/date_only.dart';
import 'package:taskly_bloc/data/infrastructure/drift/drift_database.dart'
    as drift;
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/core/model/value_priority.dart';

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
  String? primaryValueId,
}) {
  return Project(
    id: t.id,
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
    name: t.name,
    completed: t.completed,
    description: t.description,
    startDate: dateOnlyOrNull(t.startDate),
    deadlineDate: dateOnlyOrNull(t.deadlineDate),
    repeatIcalRrule: t.repeatIcalRrule,
    repeatFromCompletion: t.repeatFromCompletion,
    seriesEnded: t.seriesEnded,
    priority: t.priority,
    isPinned: t.isPinned,
    values: values ?? const <Value>[],
    primaryValueId: primaryValueId,
  );
}

Task taskFromTable(
  drift.TaskTableData t, {
  Project? project,
  List<Value>? values,
  String? primaryValueId,
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
    projectId: t.projectId,
    repeatIcalRrule: t.repeatIcalRrule,
    repeatFromCompletion: t.repeatFromCompletion,
    seriesEnded: t.seriesEnded,
    priority: t.priority,
    isPinned: t.isPinned,
    project: project,
    values: values ?? const <Value>[],
    primaryValueId: primaryValueId,
  );
}
