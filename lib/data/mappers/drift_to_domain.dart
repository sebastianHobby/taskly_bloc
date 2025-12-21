import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';

Label labelFromTable(LabelTableData t) {
  return Label(
    id: t.id,
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
    name: t.name,
  );
}

ValueModel valueFromTable(ValueTableData t) {
  return ValueModel(
    id: t.id,
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
    name: t.name,
  );
}

Project projectFromTable(
  ProjectTableData t, {
  List<ValueModel>? values,
  List<Label>? labels,
}) {
  return Project(
    id: t.id,
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
    name: t.name,
    completed: t.completed,
    values: values,
    labels: labels,
  );
}

Task taskFromTable(
  TaskTableData t, {
  Project? project,
  List<ValueModel>? values,
  List<Label>? labels,
}) {
  return Task(
    id: t.id,
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
    name: t.name,
    completed: t.completed,
    startDate: t.startDate,
    deadlineDate: t.deadlineDate,
    description: t.description,
    projectId: t.projectId,
    repeatIcalRrule: t.repeatIcalRrule,
    project: project,
    values: values,
    labels: labels,
  );
}
