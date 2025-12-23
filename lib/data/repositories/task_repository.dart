import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/domain/task.dart';
import 'package:taskly_bloc/domain/project_task_counts.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
import 'package:taskly_bloc/data/repositories/repository_helpers.dart';
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

    return _taskWithRelatedJoin().watch().map((rows) {
      return TaskAggregation.fromRows(rows: rows, driftDb: driftDb).toTasks();
    });
  }

  /// Creates the standard join query for tasks with project and labels.
  JoinedSelectStatement<HasResultSet, dynamic> _taskWithRelatedJoin({
    Expression<bool>? where,
  }) {
    final query = driftDb.select(driftDb.taskTable)
      ..orderBy([(t) => OrderingTerm(expression: t.name)]);

    if (where != null) {
      query.where((t) => where);
    }

    return query.join([
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
  }

  @override
  Future<List<Task>> getAll({bool withRelated = false}) async {
    if (!withRelated) {
      final rows = await (driftDb.select(
        driftDb.taskTable,
      )..orderBy([(t) => OrderingTerm(expression: t.name)])).get();
      return rows.map(taskFromTable).toList();
    }

    final rows = await _taskWithRelatedJoin().get();
    return TaskAggregation.fromRows(rows: rows, driftDb: driftDb).toTasks();
  }

  @override
  Future<Task?> get(String id, {bool withRelated = false}) async {
    if (!withRelated) {
      final data = await (driftDb.select(
        driftDb.taskTable,
      )..where((t) => t.id.equals(id))).getSingleOrNull();

      return data == null ? null : taskFromTable(data);
    }

    final joined = (driftDb.select(driftDb.taskTable)
          ..where((t) => t.id.equals(id)))
        .join([
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
    return TaskAggregation.fromRows(rows: rows, driftDb: driftDb)
        .toSingleTask();
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

    final joined = (driftDb.select(driftDb.taskTable)
          ..where((t) => t.id.equals(taskId)))
        .join([
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
      return TaskAggregation.fromRows(rows: rows, driftDb: driftDb)
          .toSingleTask();
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
