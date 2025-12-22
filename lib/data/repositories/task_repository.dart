import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/domain/task.dart';
import 'package:taskly_bloc/domain/project_task_counts.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
import 'package:taskly_bloc/data/mappers/drift_to_domain.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';

class TaskRepository implements TaskRepositoryContract {
  TaskRepository({required this.driftDb});
  final AppDatabase driftDb;

  // Watch all tasks. If [withRelated] is true this will include joined
  // project/labels. Otherwise only tasks are loaded.
  @override
  Stream<List<Task>> watchAll({bool withRelated = false}) {
    if (!withRelated) {
      return (driftDb.select(driftDb.taskTable)
            ..orderBy([(t) => OrderingTerm(expression: t.name)]))
          .watch()
          .map((rows) => rows.map(taskFromTable).toList());
    }

    final joined =
        (driftDb.select(
          driftDb.taskTable,
        )..orderBy([(t) => OrderingTerm(expression: t.name)])).join([
          leftOuterJoin(
            driftDb.projectTable,
            driftDb.taskTable.projectId.equalsExp(driftDb.projectTable.id),
          ),
          leftOuterJoin(
            driftDb.taskLabelsTable,
            driftDb.taskTable.id.equalsExp(driftDb.taskLabelsTable.taskId),
          ),
          leftOuterJoin(
            driftDb.labelTable,
            driftDb.taskLabelsTable.labelId.equalsExp(driftDb.labelTable.id),
          ),
        ]);

    return joined.watch().map((rows) {
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

      final results = <Task>[];
      for (final entry in tasksById.entries) {
        final id = entry.key;
        final labelList =
            (labelsByTask[id]?.values.toList() ?? <LabelTableData>[])
              ..sort((a, b) => a.name.compareTo(b.name));

        final labels = labelList.map(labelFromTable).toList();
        final projectTable = projectByTask[id];
        final project = projectTable == null
            ? null
            : projectFromTable(projectTable);

        results.add(
          taskFromTable(
            entry.value,
            project: project,
            labels: labels,
          ),
        );
      }

      return results;
    });
  }

  @override
  Future<List<Task>> getAll({bool withRelated = false}) async {
    if (!withRelated) {
      final rows = await (driftDb.select(
        driftDb.taskTable,
      )..orderBy([(t) => OrderingTerm(expression: t.name)])).get();
      return rows.map(taskFromTable).toList();
    }

    final joined =
        (driftDb.select(
          driftDb.taskTable,
        )..orderBy([(t) => OrderingTerm(expression: t.name)])).join([
          leftOuterJoin(
            driftDb.projectTable,
            driftDb.taskTable.projectId.equalsExp(driftDb.projectTable.id),
          ),
          leftOuterJoin(
            driftDb.taskLabelsTable,
            driftDb.taskTable.id.equalsExp(driftDb.taskLabelsTable.taskId),
          ),
          leftOuterJoin(
            driftDb.labelTable,
            driftDb.taskLabelsTable.labelId.equalsExp(driftDb.labelTable.id),
          ),
        ]);

    final rows = await joined.get();
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

    final results = <Task>[];
    for (final entry in tasksById.entries) {
      final id = entry.key;
      final labelList =
          (labelsByTask[id]?.values.toList() ?? <LabelTableData>[])
            ..sort((a, b) => a.name.compareTo(b.name));

      final labels = labelList.map(labelFromTable).toList();
      final projectTable = projectByTask[id];
      final project = projectTable == null
          ? null
          : projectFromTable(projectTable);

      results.add(
        taskFromTable(
          entry.value,
          project: project,
          labels: labels,
        ),
      );
    }

    return results;
  }

  @override
  Future<Task?> get(String id, {bool withRelated = false}) async {
    if (!withRelated) {
      final data = await (driftDb.select(
        driftDb.taskTable,
      )..where((t) => t.id.equals(id))).getSingleOrNull();

      return data == null ? null : taskFromTable(data);
    }

    final joined =
        (driftDb.select(
          driftDb.taskTable,
        )..where((t) => t.id.equals(id))).join([
          leftOuterJoin(
            driftDb.projectTable,
            driftDb.taskTable.projectId.equalsExp(driftDb.projectTable.id),
          ),
          leftOuterJoin(
            driftDb.taskLabelsTable,
            driftDb.taskTable.id.equalsExp(driftDb.taskLabelsTable.taskId),
          ),
          leftOuterJoin(
            driftDb.labelTable,
            driftDb.taskLabelsTable.labelId.equalsExp(driftDb.labelTable.id),
          ),
        ]);

    final rows = await joined.get();
    if (rows.isEmpty) return null;

    TaskTableData? task;
    ProjectTableData? project;
    final Map<String, LabelTableData> labelMap = {};

    for (final row in rows) {
      task ??= row.readTable(driftDb.taskTable);
      project ??= row.readTableOrNull(driftDb.projectTable);

      final label = row.readTableOrNull(driftDb.labelTable);
      if (label != null) labelMap.putIfAbsent(label.id, () => label);
    }

    final labels = labelMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final projectModel = project == null ? null : projectFromTable(project);

    return taskFromTable(
      task!,
      project: projectModel,
      labels: labels.map(labelFromTable).toList(),
    );
  }

  @override
  Stream<Task?> watch(String taskId, {bool withRelated = false}) {
    if (!withRelated) {
      final sel = (driftDb.select(
        driftDb.taskTable,
      )..where((t) => t.id.equals(taskId))).watch();

      return sel.map((rows) {
        if (rows.isEmpty) return null;
        return taskFromTable(rows.first);
      });
    }

    final joined =
        (driftDb.select(
          driftDb.taskTable,
        )..where((t) => t.id.equals(taskId))).join([
          leftOuterJoin(
            driftDb.projectTable,
            driftDb.taskTable.projectId.equalsExp(driftDb.projectTable.id),
          ),
          leftOuterJoin(
            driftDb.taskLabelsTable,
            driftDb.taskTable.id.equalsExp(driftDb.taskLabelsTable.taskId),
          ),
          leftOuterJoin(
            driftDb.labelTable,
            driftDb.taskLabelsTable.labelId.equalsExp(driftDb.labelTable.id),
          ),
        ]);

    return joined.watch().map((rows) {
      if (rows.isEmpty) return null;

      TaskTableData? task;
      ProjectTableData? project;
      final Map<String, LabelTableData> labelMap = {};

      for (final row in rows) {
        task ??= row.readTable(driftDb.taskTable);
        project ??= row.readTableOrNull(driftDb.projectTable);

        final label = row.readTableOrNull(driftDb.labelTable);
        if (label != null) labelMap.putIfAbsent(label.id, () => label);
      }

      final labels = labelMap.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      final labelModels = labels.map(labelFromTable).toList();
      final projectModel = project == null ? null : projectFromTable(project);

      return taskFromTable(
        task!,
        project: projectModel,
        labels: labelModels,
      );
    });
  }

  @override
  Future<void> create({
    required String name,
    String? description,
    bool completed = false,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    String? repeatIcalRrule,
    List<String>? labelIds,
  }) async {
    final now = DateTime.now();
    final id = uuid.v4();

    final normalizedStartDate = dateOnlyOrNull(startDate);
    final normalizedDeadlineDate = dateOnlyOrNull(deadlineDate);

    final uniqueLabelIds = labelIds?.toSet().toList(growable: false);

    await driftDb.transaction(() async {
      await driftDb
          .into(driftDb.taskTable)
          .insert(
            TaskTableCompanion(
              id: Value(id),
              name: Value(name),
              description: Value(description),
              completed: Value(completed),
              startDate: Value(normalizedStartDate),
              deadlineDate: Value(normalizedDeadlineDate),
              projectId: Value(projectId),
              repeatIcalRrule: repeatIcalRrule == null
                  ? const Value.absent()
                  : Value(repeatIcalRrule),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      if (uniqueLabelIds != null) {
        for (final labelId in uniqueLabelIds) {
          await driftDb
              .into(driftDb.taskLabelsTable)
              .insert(
                TaskLabelsTableCompanion(
                  taskId: Value(id),
                  labelId: Value(labelId),
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }
      }
    });
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    required bool completed,
    String? description,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    String? repeatIcalRrule,
    List<String>? labelIds,
  }) async {
    final existing = await (driftDb.select(
      driftDb.taskTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing == null) {
      throw RepositoryNotFoundException('No task found to update');
    }

    final now = DateTime.now();

    final normalizedStartDate = dateOnlyOrNull(startDate);
    final normalizedDeadlineDate = dateOnlyOrNull(deadlineDate);

    final uniqueLabelIds = labelIds?.toSet().toList(growable: false);

    await driftDb.transaction(() async {
      await driftDb
          .update(driftDb.taskTable)
          .replace(
            TaskTableCompanion(
              id: Value(id),
              name: Value(name),
              description: Value(description),
              completed: Value(completed),
              startDate: Value(normalizedStartDate),
              deadlineDate: Value(normalizedDeadlineDate),
              projectId: Value(projectId),
              repeatIcalRrule: repeatIcalRrule == null
                  ? const Value.absent()
                  : Value(repeatIcalRrule),
              updatedAt: Value(now),
            ),
          );

      if (uniqueLabelIds != null) {
        final requested = uniqueLabelIds.toSet();
        final existing =
            (await (driftDb.select(
                  driftDb.taskLabelsTable,
                )..where((t) => t.taskId.equals(id))).get())
                .map((r) => r.labelId)
                .toSet();

        if (requested.length != existing.length ||
            !existing.containsAll(requested)) {
          await (driftDb.delete(
            driftDb.taskLabelsTable,
          )..where((t) => t.taskId.equals(id))).go();

          for (final labelId in uniqueLabelIds) {
            await driftDb
                .into(driftDb.taskLabelsTable)
                .insert(
                  TaskLabelsTableCompanion(
                    taskId: Value(id),
                    labelId: Value(labelId),
                  ),
                  mode: InsertMode.insertOrIgnore,
                );
          }
        }
      }
    });
  }

  @override
  Future<void> delete(String id) async {
    await driftDb
        .delete(driftDb.taskTable)
        .delete(TaskTableCompanion(id: Value(id)));
  }

  @override
  Stream<Map<String, ProjectTaskCounts>> watchTaskCountsByProject() {
    // Watch all tasks and aggregate counts by project
    return driftDb.select(driftDb.taskTable).watch().map(_aggregateCounts);
  }

  @override
  Future<Map<String, ProjectTaskCounts>> getTaskCountsByProject() async {
    final rows = await driftDb.select(driftDb.taskTable).get();
    return _aggregateCounts(rows);
  }

  Map<String, ProjectTaskCounts> _aggregateCounts(List<TaskTableData> rows) {
    final counts = <String, ({int total, int completed})>{};

    for (final row in rows) {
      final projectId = row.projectId;
      if (projectId != null) {
        final current = counts[projectId] ?? (total: 0, completed: 0);
        counts[projectId] = (
          total: current.total + 1,
          completed: current.completed + (row.completed ? 1 : 0),
        );
      }
    }

    return counts.map(
      (projectId, data) => MapEntry(
        projectId,
        ProjectTaskCounts(
          projectId: projectId,
          totalCount: data.total,
          completedCount: data.completed,
        ),
      ),
    );
  }
}
