import 'package:drift/drift.dart' as drift_pkg;
import 'package:taskly_bloc/data/infrastructure/drift/drift_database.dart';
import 'package:taskly_bloc/data/mappers/drift_to_domain.dart';
import 'package:taskly_bloc/domain/domain.dart';

/// Converts aggregated value map to sorted domain Value list.
List<Value> sortedValuesFromMap(Map<String, ValueTableData>? valueMap) {
  if (valueMap == null || valueMap.isEmpty) return const [];

  final sorted = valueMap.values.toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  return sorted.map(valueFromTable).toList();
}

/// Aggregated result for project queries with values.
class ProjectAggregation {
  /// Process join rows to aggregate projects with their values.
  factory ProjectAggregation.fromRows({
    required Iterable<drift_pkg.TypedResult> rows,
    required AppDatabase driftDb,
  }) {
    final Map<String, ProjectTableData> projectsById = {};
    final Map<String, Map<String, ValueTableData>> valuesByProject = {};
    final Map<String, String?> primaryValueIdByProject = {};

    for (final row in rows) {
      final project = row.readTable(driftDb.projectTable);
      final id = project.id;

      projectsById.putIfAbsent(id, () => project);

      final projectValue = row.readTableOrNull(driftDb.projectValuesTable);
      if (projectValue?.isPrimary ?? false) {
        primaryValueIdByProject[id] ??= projectValue!.valueId;
      }

      final value = row.readTableOrNull(driftDb.valueTable);
      if (value != null) {
        valuesByProject
            .putIfAbsent(id, () => <String, ValueTableData>{})
            .putIfAbsent(value.id, () => value);
      }
    }

    return ProjectAggregation._(
      projectsById: projectsById,
      valuesByProject: valuesByProject,
      primaryValueIdByProject: primaryValueIdByProject,
    );
  }
  ProjectAggregation._({
    required this.projectsById,
    required this.valuesByProject,
    required this.primaryValueIdByProject,
  });

  final Map<String, ProjectTableData> projectsById;
  final Map<String, Map<String, ValueTableData>> valuesByProject;
  final Map<String, String?> primaryValueIdByProject;

  /// Convert to list of domain Project objects.
  List<Project> toProjects() {
    return projectsById.entries.map((entry) {
      final values = sortedValuesFromMap(valuesByProject[entry.key]);
      return projectFromTable(
        entry.value,
        values: values,
        primaryValueId: primaryValueIdByProject[entry.key],
      );
    }).toList();
  }

  /// Convert to a single Project (takes the first if multiple exist).
  /// Returns null if no projects were aggregated.
  Project? toSingleProject() {
    if (projectsById.isEmpty) return null;

    final entry = projectsById.entries.first;
    final values = sortedValuesFromMap(valuesByProject[entry.key]);
    return projectFromTable(
      entry.value,
      values: values,
      primaryValueId: primaryValueIdByProject[entry.key],
    );
  }
}

/// Aggregated result for task queries with project and values.
class TaskAggregation {
  /// Process join rows to aggregate tasks with their project and values.
  factory TaskAggregation.fromRows({
    required Iterable<drift_pkg.TypedResult> rows,
    required AppDatabase driftDb,
    required $ProjectValuesTableTable projectValuesTable,
    required $ValueTableTable projectValueTable,
    required $ValueTableTable taskValueTable,
  }) {
    final Map<String, TaskTableData> tasksById = {};
    final Map<String, ProjectTableData?> projectByTask = {};
    final Map<String, Map<String, ValueTableData>> valuesByTask = {};
    final Map<String, String?> primaryValueIdByTask = {};

    final Map<String, Map<String, ValueTableData>> valuesByProject = {};
    final Map<String, String?> primaryValueIdByProject = {};

    for (final row in rows) {
      final task = row.readTable(driftDb.taskTable);
      final taskId = task.id;

      tasksById.putIfAbsent(taskId, () => task);

      projectByTask.putIfAbsent(
        taskId,
        () => row.readTableOrNull(driftDb.projectTable),
      );

      final taskValueJoin = row.readTableOrNull(driftDb.taskValuesTable);
      if (taskValueJoin?.isPrimary ?? false) {
        primaryValueIdByTask[taskId] ??= taskValueJoin!.valueId;
      }

      final taskValue = row.readTableOrNull(taskValueTable);
      if (taskValue != null) {
        valuesByTask
            .putIfAbsent(taskId, () => <String, ValueTableData>{})
            .putIfAbsent(taskValue.id, () => taskValue);
      }

      final projectTable = projectByTask[taskId];
      final projectId = projectTable?.id;
      if (projectId != null) {
        final projectValueJoin = row.readTableOrNull(projectValuesTable);
        if (projectValueJoin?.isPrimary ?? false) {
          primaryValueIdByProject[projectId] ??= projectValueJoin!.valueId;
        }

        final projectValue = row.readTableOrNull(projectValueTable);
        if (projectValue != null) {
          valuesByProject
              .putIfAbsent(projectId, () => <String, ValueTableData>{})
              .putIfAbsent(projectValue.id, () => projectValue);
        }
      }
    }

    return TaskAggregation._(
      tasksById: tasksById,
      projectByTask: projectByTask,
      valuesByTask: valuesByTask,
      primaryValueIdByTask: primaryValueIdByTask,
      valuesByProject: valuesByProject,
      primaryValueIdByProject: primaryValueIdByProject,
    );
  }
  TaskAggregation._({
    required this.tasksById,
    required this.projectByTask,
    required this.valuesByTask,
    required this.primaryValueIdByTask,
    required this.valuesByProject,
    required this.primaryValueIdByProject,
  });

  final Map<String, TaskTableData> tasksById;
  final Map<String, ProjectTableData?> projectByTask;
  final Map<String, Map<String, ValueTableData>> valuesByTask;
  final Map<String, String?> primaryValueIdByTask;

  final Map<String, Map<String, ValueTableData>> valuesByProject;
  final Map<String, String?> primaryValueIdByProject;

  /// Convert to list of domain Task objects.
  List<Task> toTasks() {
    return tasksById.entries.map((entry) {
      final id = entry.key;
      final values = sortedValuesFromMap(valuesByTask[id]);
      final projectTable = projectByTask[id];
      final project = projectTable == null
          ? null
          : projectFromTable(
              projectTable,
              values: sortedValuesFromMap(valuesByProject[projectTable.id]),
              primaryValueId: primaryValueIdByProject[projectTable.id],
            );

      return taskFromTable(
        entry.value,
        project: project,
        values: values,
        primaryValueId: primaryValueIdByTask[id],
      );
    }).toList();
  }

  /// Convert to a single Task (takes the first if multiple exist).
  /// Returns null if no tasks were aggregated.
  Task? toSingleTask() {
    if (tasksById.isEmpty) return null;

    final entry = tasksById.entries.first;
    final id = entry.key;
    final values = sortedValuesFromMap(valuesByTask[id]);
    final projectTable = projectByTask[id];
    final project = projectTable == null
        ? null
        : projectFromTable(
            projectTable,
            values: sortedValuesFromMap(valuesByProject[projectTable.id]),
            primaryValueId: primaryValueIdByProject[projectTable.id],
          );

    return taskFromTable(
      entry.value,
      project: project,
      values: values,
      primaryValueId: primaryValueIdByTask[id],
    );
  }
}
