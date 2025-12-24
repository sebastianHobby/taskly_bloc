import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/mappers/drift_to_domain.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/domain/contracts/occurrence_stream_expander_contract.dart';
import 'package:taskly_bloc/domain/contracts/occurrence_write_helper_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/project_task_counts.dart';
import 'package:taskly_bloc/domain/task.dart';

class TaskRepository implements TaskRepositoryContract {
  TaskRepository({
    required this.driftDb,
    required this.occurrenceExpander,
    required this.occurrenceWriteHelper,
  });
  final AppDatabase driftDb;
  final OccurrenceStreamExpanderContract occurrenceExpander;
  final OccurrenceWriteHelperContract occurrenceWriteHelper;

  // Shared streams using RxDart for efficient multi-subscriber support
  // Single database query shared across all blocs (6-7 subscribers)
  ValueStream<List<Task>>? _sharedTasksWithRelated;
  ValueStream<List<Task>>? _sharedTasksSimple;

  // Watch all tasks. If [withRelated] is true this will include joined
  // project/labels. Otherwise only tasks are loaded.
  //
  // Uses RxDart shareValue() to share a single database query across
  // multiple subscribers (6-7 active blocs). This eliminates duplicate
  // queries and ensures all blocs see consistent data.
  @override
  Stream<List<Task>> watchAll({bool withRelated = false}) {
    if (!withRelated) {
      _sharedTasksSimple ??=
          (driftDb.select(driftDb.taskTable)
                ..orderBy([(t) => OrderingTerm(expression: t.name)]))
              .watch()
              .map((rows) => rows.map(taskFromTable).toList())
              .shareValue();
      return _sharedTasksSimple!;
    }

    _sharedTasksWithRelated ??= _taskWithRelatedJoin().watch().map((rows) {
      return TaskAggregation.fromRows(rows: rows, driftDb: driftDb).toTasks();
    }).shareValue();
    return _sharedTasksWithRelated!;
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

    final joined =
        (driftDb.select(driftDb.taskTable)..where((t) => t.id.equals(id))).join(
          [
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
          ],
        );

    final rows = await joined.get();
    return TaskAggregation.fromRows(
      rows: rows,
      driftDb: driftDb,
    ).toSingleTask();
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
      return TaskAggregation.fromRows(
        rows: rows,
        driftDb: driftDb,
      ).toSingleTask();
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
    bool repeatFromCompletion = false,
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
              repeatFromCompletion: Value(repeatFromCompletion),
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
    bool? repeatFromCompletion,
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
              repeatFromCompletion: repeatFromCompletion == null
                  ? Value(existing.repeatFromCompletion)
                  : Value(repeatFromCompletion),
              seriesEnded: Value(existing.seriesEnded),
              createdAt: Value(existing.createdAt),
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

  // ===========================================================================
  // OCCURRENCE METHODS
  // ===========================================================================

  @override
  Future<List<Task>> getOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    // Fetch all tasks
    final taskRows = await driftDb.select(driftDb.taskTable).get();
    final tasks = taskRows.map(taskFromTable).toList();

    // Fetch all completions and exceptions
    final completionRows = await driftDb
        .select(driftDb.taskCompletionHistoryTable)
        .get();
    final exceptionRows = await driftDb
        .select(driftDb.taskRecurrenceExceptionsTable)
        .get();

    // Convert to DTOs
    final completions = completionRows.map(_toCompletionData).toList();
    final exceptions = exceptionRows.map(_toExceptionData).toList();

    // Expand occurrences using the expander
    return occurrenceExpander.expandTaskOccurrencesSync(
      tasks: tasks,
      completions: completions,
      exceptions: exceptions,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  }

  @override
  Stream<List<Task>> watchOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    // Create streams of domain objects
    final tasksStream = driftDb
        .select(driftDb.taskTable)
        .watch()
        .map((rows) => rows.map(taskFromTable).toList());

    final completionsStream = driftDb
        .select(driftDb.taskCompletionHistoryTable)
        .watch()
        .map((rows) => rows.map(_toCompletionData).toList());

    final exceptionsStream = driftDb
        .select(driftDb.taskRecurrenceExceptionsTable)
        .watch()
        .map((rows) => rows.map(_toExceptionData).toList());

    // Use the expander (includes debounce)
    return occurrenceExpander.expandTaskOccurrences(
      tasksStream: tasksStream,
      completionsStream: completionsStream,
      exceptionsStream: exceptionsStream,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  }

  /// Converts a completion history row to a DTO.
  CompletionHistoryData _toCompletionData(TaskCompletionHistoryTableData row) {
    return CompletionHistoryData(
      id: row.id,
      entityId: row.taskId,
      occurrenceDate: row.occurrenceDate,
      originalOccurrenceDate: row.originalOccurrenceDate,
      completedAt: row.completedAt,
      notes: row.notes,
    );
  }

  /// Converts an exception row to a DTO.
  RecurrenceExceptionData _toExceptionData(
    TaskRecurrenceExceptionsTableData row,
  ) {
    return RecurrenceExceptionData(
      id: row.id,
      entityId: row.taskId,
      originalDate: row.originalDate,
      exceptionType: row.exceptionType == ExceptionType.skip
          ? RecurrenceExceptionType.skip
          : RecurrenceExceptionType.reschedule,
      newDate: row.newDate,
      newDeadline: row.newDeadline,
    );
  }

  @override
  Future<void> completeOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
  }) => occurrenceWriteHelper.completeTaskOccurrence(
    taskId: taskId,
    occurrenceDate: occurrenceDate,
    originalOccurrenceDate: originalOccurrenceDate,
    notes: notes,
  );

  @override
  Future<void> uncompleteOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
  }) => occurrenceWriteHelper.uncompleteTaskOccurrence(
    taskId: taskId,
    occurrenceDate: occurrenceDate,
  );

  @override
  Future<void> skipOccurrence({
    required String taskId,
    required DateTime originalDate,
  }) => occurrenceWriteHelper.skipTaskOccurrence(
    taskId: taskId,
    originalDate: originalDate,
  );

  @override
  Future<void> rescheduleOccurrence({
    required String taskId,
    required DateTime originalDate,
    required DateTime newDate,
    DateTime? newDeadline,
  }) => occurrenceWriteHelper.rescheduleTaskOccurrence(
    taskId: taskId,
    originalDate: originalDate,
    newDate: newDate,
    newDeadline: newDeadline,
  );

  @override
  Future<void> removeException({
    required String taskId,
    required DateTime originalDate,
  }) => occurrenceWriteHelper.removeTaskException(
    taskId: taskId,
    originalDate: originalDate,
  );

  @override
  Future<void> stopSeries(String taskId) =>
      occurrenceWriteHelper.stopTaskSeries(taskId);

  @override
  Future<void> completeSeries(String taskId) =>
      occurrenceWriteHelper.completeTaskSeries(taskId);

  @override
  Future<void> convertToOneTime(String taskId) =>
      occurrenceWriteHelper.convertTaskToOneTime(taskId);
}
