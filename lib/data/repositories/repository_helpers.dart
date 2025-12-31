import 'package:drift/drift.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/mappers/drift_to_domain.dart';
import 'package:taskly_bloc/domain/domain.dart';

/// Converts aggregated label map to sorted domain Label list.
List<Label> sortedLabelsFromMap(Map<String, LabelTableData>? labelMap) {
  if (labelMap == null || labelMap.isEmpty) return const [];

  final sorted = labelMap.values.toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  return sorted.map(labelFromTable).toList();
}

/// Aggregated result for project queries with labels.
class ProjectAggregation {
  /// Process join rows to aggregate projects with their labels.
  factory ProjectAggregation.fromRows({
    required Iterable<TypedResult> rows,
    required AppDatabase driftDb,
  }) {
    final Map<String, ProjectTableData> projectsById = {};
    final Map<String, Map<String, LabelTableData>> labelsByProject = {};

    for (final row in rows) {
      final project = row.readTable(driftDb.projectTable);
      final id = project.id;

      projectsById.putIfAbsent(id, () => project);

      final label = row.readTableOrNull(driftDb.labelTable);
      if (label != null) {
        labelsByProject
            .putIfAbsent(id, () => <String, LabelTableData>{})
            .putIfAbsent(label.id, () => label);
      }
    }

    return ProjectAggregation._(
      projectsById: projectsById,
      labelsByProject: labelsByProject,
    );
  }
  ProjectAggregation._({
    required this.projectsById,
    required this.labelsByProject,
  });

  final Map<String, ProjectTableData> projectsById;
  final Map<String, Map<String, LabelTableData>> labelsByProject;

  /// Convert to list of domain Project objects.
  List<Project> toProjects() {
    return projectsById.entries.map((entry) {
      final labels = sortedLabelsFromMap(labelsByProject[entry.key]);
      return projectFromTable(entry.value, labels: labels);
    }).toList();
  }

  /// Convert to a single Project (takes the first if multiple exist).
  /// Returns null if no projects were aggregated.
  Project? toSingleProject() {
    if (projectsById.isEmpty) return null;

    final entry = projectsById.entries.first;
    final labels = sortedLabelsFromMap(labelsByProject[entry.key]);
    return projectFromTable(entry.value, labels: labels);
  }
}

/// Aggregated result for task queries with project and labels.
class TaskAggregation {
  /// Process join rows to aggregate tasks with their project and labels.
  factory TaskAggregation.fromRows({
    required Iterable<TypedResult> rows,
    required AppDatabase driftDb,
  }) {
    final Map<String, TaskTableData> tasksById = {};
    final Map<String, ProjectTableData?> projectByTask = {};
    final Map<String, Map<String, LabelTableData>> labelsByTask = {};

    for (final row in rows) {
      final task = row.readTable(driftDb.taskTable);
      final taskId = task.id;

      tasksById.putIfAbsent(taskId, () => task);

      projectByTask.putIfAbsent(
        taskId,
        () => row.readTableOrNull(driftDb.projectTable),
      );

      final label = row.readTableOrNull(driftDb.labelTable);
      if (label != null) {
        labelsByTask
            .putIfAbsent(taskId, () => <String, LabelTableData>{})
            .putIfAbsent(label.id, () => label);
      }
    }

    return TaskAggregation._(
      tasksById: tasksById,
      projectByTask: projectByTask,
      labelsByTask: labelsByTask,
    );
  }
  TaskAggregation._({
    required this.tasksById,
    required this.projectByTask,
    required this.labelsByTask,
  });

  final Map<String, TaskTableData> tasksById;
  final Map<String, ProjectTableData?> projectByTask;
  final Map<String, Map<String, LabelTableData>> labelsByTask;

  /// Convert to list of domain Task objects.
  List<Task> toTasks() {
    return tasksById.entries.map((entry) {
      final id = entry.key;
      final labels = sortedLabelsFromMap(labelsByTask[id]);
      final projectTable = projectByTask[id];
      final project = projectTable == null
          ? null
          : projectFromTable(projectTable);

      return taskFromTable(
        entry.value,
        project: project,
        labels: labels,
      );
    }).toList();
  }

  /// Convert to a single Task (takes the first if multiple exist).
  /// Returns null if no tasks were aggregated.
  Task? toSingleTask() {
    if (tasksById.isEmpty) return null;

    final entry = tasksById.entries.first;
    final id = entry.key;
    final labels = sortedLabelsFromMap(labelsByTask[id]);
    final projectTable = projectByTask[id];
    final project = projectTable == null
        ? null
        : projectFromTable(projectTable);

    return taskFromTable(
      entry.value,
      project: project,
      labels: labels,
    );
  }
}
