import 'package:drift/drift.dart' as drift_pkg;
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/src/mappers/drift_to_domain.dart';
import 'package:taskly_domain/core.dart';

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
    required $ValueTableTable primaryValueTable,
  }) {
    final Map<String, ProjectTableData> projectsById = {};
    final Map<String, Map<String, ValueTableData>> valuesByProject = {};

    for (final row in rows) {
      final project = row.readTable(driftDb.projectTable);
      final id = project.id;

      projectsById.putIfAbsent(id, () => project);

      final primary = row.readTableOrNull(primaryValueTable);
      if (primary != null) {
        valuesByProject
            .putIfAbsent(id, () => <String, ValueTableData>{})
            .putIfAbsent(primary.id, () => primary);
      }
    }

    return ProjectAggregation._(
      projectsById: projectsById,
      valuesByProject: valuesByProject,
    );
  }
  ProjectAggregation._({
    required this.projectsById,
    required this.valuesByProject,
  });

  final Map<String, ProjectTableData> projectsById;
  final Map<String, Map<String, ValueTableData>> valuesByProject;

  /// Convert to list of domain Project objects.
  List<Project> toProjects() {
    return projectsById.entries.map((entry) {
      final values = sortedValuesFromMap(valuesByProject[entry.key]);
      return projectFromTable(entry.value, values: values);
    }).toList();
  }

  /// Convert to a single Project (takes the first if multiple exist).
  /// Returns null if no projects were aggregated.
  Project? toSingleProject() {
    if (projectsById.isEmpty) return null;

    final entry = projectsById.entries.first;
    final values = sortedValuesFromMap(valuesByProject[entry.key]);
    return projectFromTable(entry.value, values: values);
  }
}

/// Aggregated result for task queries with project and values.
class TaskAggregation {
  /// Process join rows to aggregate tasks with their project and values.
  factory TaskAggregation.fromRows({
    required Iterable<drift_pkg.TypedResult> rows,
    required AppDatabase driftDb,
    required $ValueTableTable projectPrimaryValueTable,
    required $ValueTableTable overridePrimaryValueTable,
    required $ValueTableTable overrideSecondaryValueTable,
  }) {
    final Map<String, TaskTableData> tasksById = {};
    final Map<String, ProjectTableData?> projectByTask = {};
    final Map<String, Map<String, ValueTableData>> valuesByTask = {};

    final Map<String, Map<String, ValueTableData>> valuesByProject = {};

    for (final row in rows) {
      final task = row.readTable(driftDb.taskTable);
      final taskId = task.id;

      tasksById.putIfAbsent(taskId, () => task);

      projectByTask.putIfAbsent(
        taskId,
        () => row.readTableOrNull(driftDb.projectTable),
      );

      final overridePrimary = row.readTableOrNull(overridePrimaryValueTable);
      if (overridePrimary != null) {
        valuesByTask
            .putIfAbsent(taskId, () => <String, ValueTableData>{})
            .putIfAbsent(overridePrimary.id, () => overridePrimary);
      }
      final overrideSecondary = row.readTableOrNull(
        overrideSecondaryValueTable,
      );
      if (overrideSecondary != null) {
        valuesByTask
            .putIfAbsent(taskId, () => <String, ValueTableData>{})
            .putIfAbsent(overrideSecondary.id, () => overrideSecondary);
      }

      final projectTable = projectByTask[taskId];
      final projectId = projectTable?.id;
      if (projectId != null) {
        final projectPrimary = row.readTableOrNull(projectPrimaryValueTable);
        if (projectPrimary != null) {
          valuesByProject
              .putIfAbsent(projectId, () => <String, ValueTableData>{})
              .putIfAbsent(projectPrimary.id, () => projectPrimary);
        }
      }
    }

    return TaskAggregation._(
      tasksById: tasksById,
      projectByTask: projectByTask,
      valuesByTask: valuesByTask,
      valuesByProject: valuesByProject,
    );
  }
  TaskAggregation._({
    required this.tasksById,
    required this.projectByTask,
    required this.valuesByTask,
    required this.valuesByProject,
  });

  final Map<String, TaskTableData> tasksById;
  final Map<String, ProjectTableData?> projectByTask;
  final Map<String, Map<String, ValueTableData>> valuesByTask;

  final Map<String, Map<String, ValueTableData>> valuesByProject;

  List<Value> _overrideValuesList(
    TaskTableData task,
    Map<String, ValueTableData> overrideValues,
  ) {
    final overridePrimaryId = task.overridePrimaryValueId;
    if (overridePrimaryId == null) return const <Value>[];

    final primary = overrideValues[overridePrimaryId];
    final secondaryId = task.overrideSecondaryValueId;
    final secondary = secondaryId == null ? null : overrideValues[secondaryId];

    final list = <Value>[];
    if (primary != null) list.add(valueFromTable(primary));
    if (secondary != null && secondary.id != primary?.id) {
      list.add(valueFromTable(secondary));
    }
    return list;
  }

  /// Convert to list of domain Task objects.
  List<Task> toTasks() {
    return tasksById.entries.map((entry) {
      final id = entry.key;
      final overrideValues =
          valuesByTask[id] ?? const <String, ValueTableData>{};
      final projectTable = projectByTask[id];
      final project = projectTable == null
          ? null
          : projectFromTable(
              projectTable,
              values: sortedValuesFromMap(valuesByProject[projectTable.id]),
            );

      final explicitOverrideValues = _overrideValuesList(
        entry.value,
        overrideValues,
      );

      return taskFromTable(
        entry.value,
        project: project,
        values: explicitOverrideValues,
      );
    }).toList();
  }

  /// Convert to a single Task (takes the first if multiple exist).
  /// Returns null if no tasks were aggregated.
  Task? toSingleTask() {
    if (tasksById.isEmpty) return null;

    final entry = tasksById.entries.first;
    final id = entry.key;
    final overrideValues = valuesByTask[id] ?? const <String, ValueTableData>{};
    final projectTable = projectByTask[id];
    final project = projectTable == null
        ? null
        : projectFromTable(
            projectTable,
            values: sortedValuesFromMap(valuesByProject[projectTable.id]),
          );

    final explicitOverrideValues = _overrideValuesList(
      entry.value,
      overrideValues,
    );

    return taskFromTable(
      entry.value,
      project: project,
      values: explicitOverrideValues,
    );
  }
}
