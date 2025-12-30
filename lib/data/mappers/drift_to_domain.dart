import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' as drift;
import 'package:taskly_bloc/domain/domain.dart';

Label labelFromTable(drift.LabelTableData t) {
  return Label(
    id: t.id,
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
    name: t.name,
    color: t.color,
    type: LabelType.values.byName(t.type.name),
    iconName: t.iconName,
  );
}

Project projectFromTable(
  drift.ProjectTableData t, {
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
    repeatFromCompletion: t.repeatFromCompletion,
    seriesEnded: t.seriesEnded,
    labels: labels ?? const <Label>[],
  );
}

Task taskFromTable(
  drift.TaskTableData t, {
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
    repeatFromCompletion: t.repeatFromCompletion,
    seriesEnded: t.seriesEnded,
    isNextAction: t.isNextAction,
    nextActionPriority: t.nextActionPriority,
    markedNextActionAt: t.markedNextActionAt,
    nextActionNotes: t.nextActionNotes,
    project: project,
    labels: labels ?? const <Label>[],
  );
}
