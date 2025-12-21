import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';

Label labelFromTable(LabelTableData t) {
  return Label(
    id: t.id,
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
    name: t.name,
    color: t.color,
  );
}

Project projectFromTable(
  ProjectTableData t, {
  List<Label>? labels,
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
    labels: labels,
  );
}

Task taskFromTable(
  TaskTableData t, {
  Project? project,
  List<Label>? labels,
}) {
  return Task(
    id: t.id,
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
    name: t.name,
    completed: t.completed,
    startDate: dateOnlyOrNull(t.startDate),
    deadlineDate: dateOnlyOrNull(t.deadlineDate),
    description: t.description,
    projectId: t.projectId,
    repeatIcalRrule: t.repeatIcalRrule,
    project: project,
    labels: labels,
  );
}
