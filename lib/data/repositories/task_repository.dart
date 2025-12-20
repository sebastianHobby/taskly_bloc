import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart';
import 'package:taskly_bloc/core/domain/label.dart';
import 'package:taskly_bloc/core/domain/value.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/core/domain/task.dart';
export 'package:taskly_bloc/core/domain/task.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
import 'package:taskly_bloc/data/mappers/drift_to_domain.dart';
import 'package:taskly_bloc/data/repositories/contracts/task_repository_contract.dart';

// Domain Task is defined in `lib/core/domain/task.dart` and exported above.

class TaskRepository implements TaskRepositoryContract {
  TaskRepository({required this.driftDb});
  final AppDatabase driftDb;

  // Watch all tasks. If [withRelated] is true this will include joined
  // project/labels/values. Otherwise only tasks are loaded.
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
          leftOuterJoin(
            driftDb.taskValuesTable,
            driftDb.taskTable.id.equalsExp(driftDb.taskValuesTable.taskId),
          ),
          leftOuterJoin(
            driftDb.valueTable,
            driftDb.taskValuesTable.valueId.equalsExp(driftDb.valueTable.id),
          ),
        ]);

    return joined.watch().map((rows) {
      final Map<String, TaskTableData> tasksById = {};
      final Map<String, ProjectTableData?> projectByTask = {};
      final Map<String, Map<String, LabelTableData>> labelsByTask = {};
      final Map<String, Map<String, ValueTableData>> valuesByTask = {};

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
          final m = labelsByTask.putIfAbsent(
            taskId,
            () => <String, LabelTableData>{},
          );
          m.putIfAbsent(label.id, () => label);
        }

        final value = row.readTableOrNull(driftDb.valueTable);
        if (value != null) {
          final m = valuesByTask.putIfAbsent(
            taskId,
            () => <String, ValueTableData>{},
          );
          m.putIfAbsent(value.id, () => value);
        }
      }

      final results = <Task>[];
      for (final entry in tasksById.entries) {
        final id = entry.key;
        final labelList =
            labelsByTask[id]?.values.toList() ?? <LabelTableData>[];
        labelList.sort((a, b) => a.name.compareTo(b.name));
        final valueList =
            valuesByTask[id]?.values.toList() ?? <ValueTableData>[];
        valueList.sort((a, b) => a.name.compareTo(b.name));

        final labels = labelList.map(labelFromTable).toList();
        final values = valueList.map(valueFromTable).toList();
        final projectTable = projectByTask[id];
        final project = projectTable == null
            ? null
            : projectFromTable(projectTable);

        results.add(
          taskFromTable(
            entry.value,
            project: project,
            values: values,
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
          leftOuterJoin(
            driftDb.taskValuesTable,
            driftDb.taskTable.id.equalsExp(driftDb.taskValuesTable.taskId),
          ),
          leftOuterJoin(
            driftDb.valueTable,
            driftDb.taskValuesTable.valueId.equalsExp(driftDb.valueTable.id),
          ),
        ]);

    final rows = await joined.get();
    final Map<String, TaskTableData> tasksById = {};
    final Map<String, ProjectTableData?> projectByTask = {};
    final Map<String, Map<String, LabelTableData>> labelsByTask = {};
    final Map<String, Map<String, ValueTableData>> valuesByTask = {};

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
        final m = labelsByTask.putIfAbsent(
          taskId,
          () => <String, LabelTableData>{},
        );
        m.putIfAbsent(label.id, () => label);
      }

      final value = row.readTableOrNull(driftDb.valueTable);
      if (value != null) {
        final m = valuesByTask.putIfAbsent(
          taskId,
          () => <String, ValueTableData>{},
        );
        m.putIfAbsent(value.id, () => value);
      }
    }

    final results = <Task>[];
    for (final entry in tasksById.entries) {
      final id = entry.key;
      final labelList = labelsByTask[id]?.values.toList() ?? <LabelTableData>[];
      labelList.sort((a, b) => a.name.compareTo(b.name));
      final valueList = valuesByTask[id]?.values.toList() ?? <ValueTableData>[];
      valueList.sort((a, b) => a.name.compareTo(b.name));

      final labels = labelList.map(labelFromTable).toList();
      final values = valueList.map(valueFromTable).toList();
      final projectTable = projectByTask[id];
      final project = projectTable == null
          ? null
          : projectFromTable(projectTable);

      results.add(
        taskFromTable(
          entry.value,
          project: project,
          values: values,
          labels: labels,
        ),
      );
    }

    return results;
  }

  // Get single task as a domain model. If [withRelated] is true the returned
  // model will include project, labels and values. This returns a Future for
  // the current snapshot; use [watchTask] to subscribe to changes.
  /// Backwards-compatible name.
  Future<Task?> getTask(String id, {bool withRelated = false}) async {
    return get(id, withRelated: withRelated);
  }

  @override
  Future<Task?> get(String id, {bool withRelated = false}) async {
    return watch(id, withRelated: withRelated).first;
  }

  // Watch a single task by id. Returns null if the task does not exist.
  /// Backwards-compatible name.
  Stream<Task?> watchTask(String taskId, {bool withRelated = false}) {
    return watch(taskId, withRelated: withRelated);
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
          leftOuterJoin(
            driftDb.taskValuesTable,
            driftDb.taskTable.id.equalsExp(driftDb.taskValuesTable.taskId),
          ),
          leftOuterJoin(
            driftDb.valueTable,
            driftDb.taskValuesTable.valueId.equalsExp(driftDb.valueTable.id),
          ),
        ]);

    return joined.watch().map((rows) {
      if (rows.isEmpty) return null;

      TaskTableData? task;
      ProjectTableData? project;
      final Map<String, LabelTableData> labelMap = {};
      final Map<String, ValueTableData> valueMap = {};

      for (final row in rows) {
        task ??= row.readTable(driftDb.taskTable);
        project ??= row.readTableOrNull(driftDb.projectTable);

        final label = row.readTableOrNull(driftDb.labelTable);
        if (label != null) labelMap.putIfAbsent(label.id, () => label);

        final value = row.readTableOrNull(driftDb.valueTable);
        if (value != null) valueMap.putIfAbsent(value.id, () => value);
      }

      final labels = labelMap.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      final values = valueMap.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      final labelModels = labels.map(labelFromTable).toList();
      final valueModels = values.map(valueFromTable).toList();
      final projectModel = project == null ? null : projectFromTable(project);

      return taskFromTable(
        task!,
        project: projectModel,
        values: valueModels,
        labels: labelModels,
      );
    });
  }

  Future<bool> updateTask(
    TaskTableCompanion updateCompanion, {
    List<ValueModel>? values,
    List<Label>? labels,
  }) async {
    return driftDb.transaction(() async {
      final bool success = await driftDb
          .update(driftDb.taskTable)
          .replace(updateCompanion);
      if (!success) {
        throw RepositoryNotFoundException('No task found to update');
      }

      final taskId = updateCompanion.id.present
          ? updateCompanion.id.value
          : throw RepositoryNotFoundException('Task id required for links');

      if (values != null) {
        // remove existing links
        await (driftDb.delete(
          driftDb.taskValuesTable,
        )..where((t) => t.taskId.equals(taskId))).go();
        // insert new links
        for (final v in values) {
          await driftDb
              .into(driftDb.taskValuesTable)
              .insert(
                TaskValuesTableCompanion(
                  taskId: Value(taskId),
                  valueId: Value(v.id),
                ),
              );
        }
      }

      if (labels != null) {
        await (driftDb.delete(
          driftDb.taskLabelsTable,
        )..where((t) => t.taskId.equals(taskId))).go();
        for (final l in labels) {
          await driftDb
              .into(driftDb.taskLabelsTable)
              .insert(
                TaskLabelsTableCompanion(
                  taskId: Value(taskId),
                  labelId: Value(l.id),
                ),
              );
        }
      }

      return success;
    });
  }

  Future<int> deleteTask(TaskTableCompanion deleteCompanion) async {
    return driftDb.delete(driftDb.taskTable).delete(deleteCompanion);
  }

  Future<int> createTask(
    TaskTableCompanion createCompanion, {
    List<ValueModel>? values,
    List<Label>? labels,
  }) async {
    return driftDb.transaction(() async {
      // ensure id present so we can insert links
      final id = createCompanion.id.present
          ? createCompanion.id.value
          : uuid.v4();

      final companionWithId = createCompanion.copyWith(id: Value(id));
      final rowId = await driftDb
          .into(driftDb.taskTable)
          .insert(companionWithId);

      if (values != null) {
        for (final v in values) {
          await driftDb
              .into(driftDb.taskValuesTable)
              .insert(
                TaskValuesTableCompanion(
                  taskId: Value(id),
                  valueId: Value(v.id),
                ),
              );
        }
      }

      if (labels != null) {
        for (final l in labels) {
          await driftDb
              .into(driftDb.taskLabelsTable)
              .insert(
                TaskLabelsTableCompanion(
                  taskId: Value(id),
                  labelId: Value(l.id),
                ),
              );
        }
      }

      return rowId;
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
    List<String>? valueIds,
    List<String>? labelIds,
  }) async {
    final now = DateTime.now();
    final id = uuid.v4();

    await driftDb.transaction(() async {
      await driftDb
          .into(driftDb.taskTable)
          .insert(
            TaskTableCompanion(
              id: Value(id),
              name: Value(name),
              description: Value(description),
              completed: Value(completed),
              startDate: Value(startDate),
              deadlineDate: Value(deadlineDate),
              projectId: Value(projectId),
              repeatIcalRrule: Value(repeatIcalRrule),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      if (valueIds != null) {
        for (final valueId in valueIds) {
          await driftDb
              .into(driftDb.taskValuesTable)
              .insert(
                TaskValuesTableCompanion(
                  taskId: Value(id),
                  valueId: Value(valueId),
                ),
              );
        }
      }

      if (labelIds != null) {
        for (final labelId in labelIds) {
          await driftDb
              .into(driftDb.taskLabelsTable)
              .insert(
                TaskLabelsTableCompanion(
                  taskId: Value(id),
                  labelId: Value(labelId),
                ),
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
    List<String>? valueIds,
    List<String>? labelIds,
  }) async {
    final now = DateTime.now();

    await driftDb.transaction(() async {
      final success = await driftDb
          .update(driftDb.taskTable)
          .replace(
            TaskTableCompanion(
              id: Value(id),
              name: Value(name),
              description: Value(description),
              completed: Value(completed),
              startDate: Value(startDate),
              deadlineDate: Value(deadlineDate),
              projectId: Value(projectId),
              repeatIcalRrule: Value(repeatIcalRrule),
              updatedAt: Value(now),
            ),
          );
      if (!success) {
        throw RepositoryNotFoundException('No task found to update');
      }

      if (valueIds != null) {
        await (driftDb.delete(
          driftDb.taskValuesTable,
        )..where((t) => t.taskId.equals(id))).go();

        for (final valueId in valueIds) {
          await driftDb
              .into(driftDb.taskValuesTable)
              .insert(
                TaskValuesTableCompanion(
                  taskId: Value(id),
                  valueId: Value(valueId),
                ),
              );
        }
      }

      if (labelIds != null) {
        await (driftDb.delete(
          driftDb.taskLabelsTable,
        )..where((t) => t.taskId.equals(id))).go();

        for (final labelId in labelIds) {
          await driftDb
              .into(driftDb.taskLabelsTable)
              .insert(
                TaskLabelsTableCompanion(
                  taskId: Value(id),
                  labelId: Value(labelId),
                ),
              );
        }
      }
    });
  }

  @override
  Future<void> delete(String id) async {
    await deleteTask(TaskTableCompanion(id: Value(id)));
  }
}
