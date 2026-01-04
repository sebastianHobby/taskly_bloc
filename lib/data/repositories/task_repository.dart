import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/data/mappers/drift_to_domain.dart';
import 'package:taskly_bloc/data/repositories/mappers/task_predicate_mapper.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
import 'package:taskly_bloc/data/repositories/repository_helpers.dart';
import 'package:taskly_bloc/domain/interfaces/occurrence_stream_expander_contract.dart';
import 'package:taskly_bloc/domain/interfaces/occurrence_write_helper_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/filtering/evaluation_context.dart';
import 'package:taskly_bloc/domain/models/project_task_counts.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_filter_evaluator.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/models/task.dart';

class _OccurrenceRangeKey {
  const _OccurrenceRangeKey({
    required this.rangeStart,
    required this.rangeEnd,
  });

  final DateTime rangeStart;
  final DateTime rangeEnd;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _OccurrenceRangeKey &&
        other.rangeStart == rangeStart &&
        other.rangeEnd == rangeEnd;
  }

  @override
  int get hashCode => Object.hash(rangeStart, rangeEnd);
}

class TaskRepository implements TaskRepositoryContract {
  TaskRepository({
    required this.driftDb,
    required this.occurrenceExpander,
    required this.occurrenceWriteHelper,
    required this.idGenerator,
  }) : _predicateMapper = TaskPredicateMapper(driftDb: driftDb);

  final AppDatabase driftDb;
  final OccurrenceStreamExpanderContract occurrenceExpander;
  final OccurrenceWriteHelperContract occurrenceWriteHelper;
  final IdGenerator idGenerator;
  final TaskPredicateMapper _predicateMapper;

  // Tier-based shared streams for common query patterns
  // Reduces concurrent queries from 6-7 down to 2-3
  ValueStream<List<Task>>? _sharedInboxStream;
  ValueStream<List<Task>>? _sharedTodayStream;
  ValueStream<List<Task>>? _sharedUpcomingStream;

  final Map<_OccurrenceRangeKey, ValueStream<List<Task>>>
  _occurrenceStreamCache = {};

  /// Watch tasks with optional filtering, sorting, and occurrence expansion.
  ///
  /// If [query] is null, returns all tasks with related entities.
  /// All filtering happens at the database level for optimal performance.
  @override
  Stream<List<Task>> watchAll([TaskQuery? query]) {
    query ??= TaskQuery.all();

    // Route to shared streams for common patterns
    if (_isInboxQuery(query)) {
      return _getOrCreateInboxStream(query);
    } else if (_isTodayQuery(query)) {
      return _getOrCreateTodayStream(query);
    } else if (_isUpcomingQuery(query)) {
      return _getOrCreateUpcomingStream(query);
    }

    // Build unique query for non-common patterns
    return _buildAndExecuteQuery(query);
  }

  @override
  Future<int> count([TaskQuery? query]) async {
    query ??= TaskQuery.all();

    if (query.shouldExpandOccurrences) {
      return (await _buildAndExecuteQuery(query).first).length;
    }

    final countExp = driftDb.taskTable.id.count();
    final statement = driftDb.selectOnly(driftDb.taskTable)
      ..addColumns([countExp]);

    final where = _whereExpressionFromFilter(query.filter, driftDb.taskTable);
    if (where != null) statement.where(where);

    final row = await statement.getSingle();
    return row.read(countExp) ?? 0;
  }

  @override
  Stream<int> watchCount([TaskQuery? query]) {
    query ??= TaskQuery.all();

    if (query.shouldExpandOccurrences) {
      return _buildAndExecuteQuery(
        query,
      ).map((items) => items.length).distinct();
    }

    final countExp = driftDb.taskTable.id.count();
    final statement = driftDb.selectOnly(driftDb.taskTable)
      ..addColumns([countExp]);

    final where = _whereExpressionFromFilter(query.filter, driftDb.taskTable);
    if (where != null) statement.where(where);

    return statement
        .watchSingle()
        .map((row) => row.read(countExp) ?? 0)
        .distinct();
  }

  /// Get a single task by ID with related entities.
  @override
  Future<Task?> getById(String id) async {
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

  /// Watch a single task by ID with related entities.
  @override
  Stream<Task?> watchById(String taskId) {
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
  Future<List<Task>> queryTasks(TaskQuery query) async {
    return _buildAndExecuteQuery(query).first;
  }

  @override
  Future<List<Task>> getTasksByProject(String projectId) async {
    final query = TaskQuery.forProject(projectId: projectId);
    return queryTasks(query);
  }

  @override
  Future<List<Task>> getTasksByLabel(String labelId) async {
    final query = TaskQuery.forLabel(labelId: labelId);
    return queryTasks(query);
  }

  @override
  Future<List<Task>> getTasksByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final joined =
        (driftDb.select(driftDb.taskTable)..where((t) => t.id.isIn(ids))).join(
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
    return TaskAggregation.fromRows(rows: rows, driftDb: driftDb).toTasks();
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
    talker.debug('[TaskRepository] create: name="$name", projectId=$projectId');
    final now = DateTime.now();
    final id = idGenerator.taskId();

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
          // Generate deterministic v5 ID for junction
          final junctionId = idGenerator.taskLabelId(
            taskId: id,
            labelId: labelId,
          );
          await driftDb
              .into(driftDb.taskLabelsTable)
              .insert(
                TaskLabelsTableCompanion(
                  id: Value(junctionId),
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
    int? priority,
    String? repeatIcalRrule,
    bool? repeatFromCompletion,
    List<String>? labelIds,
  }) async {
    talker.debug('[TaskRepository] update: id=$id, name="$name"');
    final existing = await (driftDb.select(
      driftDb.taskTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing == null) {
      talker.warning('[TaskRepository] update failed: task not found id=$id');
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
              priority: priority == null
                  ? Value(existing.priority)
                  : Value(priority),
              repeatIcalRrule: repeatIcalRrule == null
                  ? const Value.absent()
                  : Value(repeatIcalRrule),
              repeatFromCompletion: repeatFromCompletion == null
                  ? Value(existing.repeatFromCompletion)
                  : Value(repeatFromCompletion),
              seriesEnded: Value(existing.seriesEnded),
              lastReviewedAt: Value(existing.lastReviewedAt),
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
    talker.debug('[TaskRepository] delete: id=$id');
    await driftDb
        .delete(driftDb.taskTable)
        .delete(TaskTableCompanion(id: Value(id)));
  }

  @override
  Future<void> updateLastReviewedAt({
    required String id,
    required DateTime reviewedAt,
  }) async {
    talker.debug('[TaskRepository] updateLastReviewedAt: id=$id');
    await (driftDb.update(
      driftDb.taskTable,
    )..where((t) => t.id.equals(id))).write(
      TaskTableCompanion(
        lastReviewedAt: Value(reviewedAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Stream<Map<String, ProjectTaskCounts>> watchTaskCountsByProject() {
    // Watch all tasks and aggregate counts by project
    return driftDb.select(driftDb.taskTable).watch().map(_aggregateCounts);
  }

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
    final normalizedRangeStart = dateOnly(rangeStart);
    final normalizedRangeEnd = dateOnly(rangeEnd);
    final key = _OccurrenceRangeKey(
      rangeStart: normalizedRangeStart,
      rangeEnd: normalizedRangeEnd,
    );

    final cached = _occurrenceStreamCache[key];
    if (cached != null) {
      return cached;
    }

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
    final stream = occurrenceExpander.expandTaskOccurrences(
      tasksStream: tasksStream,
      completionsStream: completionsStream,
      exceptionsStream: exceptionsStream,
      rangeStart: normalizedRangeStart,
      rangeEnd: normalizedRangeEnd,
    );

    final shared = stream.shareValue();
    _occurrenceStreamCache[key] = shared;
    return shared;
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

  Future<void> removeException({
    required String taskId,
    required DateTime originalDate,
  }) => occurrenceWriteHelper.removeTaskException(
    taskId: taskId,
    originalDate: originalDate,
  );

  Future<void> stopSeries(String taskId) =>
      occurrenceWriteHelper.stopTaskSeries(taskId);

  Future<void> completeSeries(String taskId) =>
      occurrenceWriteHelper.completeTaskSeries(taskId);

  Future<void> convertToOneTime(String taskId) =>
      occurrenceWriteHelper.convertTaskToOneTime(taskId);

  // ===========================================================================
  // UNIFIED QUERY BUILDER - 100% SQL COVERAGE + TWO-PHASE FILTERING
  // ===========================================================================

  /// Builds and executes a query with optional occurrence expansion.
  ///
  /// For queries WITH occurrence expansion (two-phase filtering):
  /// - Phase 1: Non-date rules applied at SQL level (get candidate tasks)
  /// - Phase 2: Date rules applied post-expansion (filter virtual occurrences)
  ///
  /// For queries WITHOUT occurrence expansion:
  /// - All rules applied at SQL level for optimal performance
  Stream<List<Task>> _buildAndExecuteQuery(TaskQuery query) {
    final QueryFilter<TaskPredicate> sqlFilter = query.shouldExpandOccurrences
        ? _removeDatePredicates(query.filter)
        : query.filter;

    // Start with base query
    final select = driftDb.select(driftDb.taskTable);

    select.where((t) {
      return _whereExpressionFromFilter(sqlFilter, t) ?? const Constant(true);
    });

    // Apply ordering
    if (query.sortCriteria.isNotEmpty) {
      final orderingFuncs = <OrderingTerm Function($TaskTableTable)>[];
      for (final criterion in query.sortCriteria) {
        switch (criterion.field) {
          case SortField.name:
            orderingFuncs.add(
              ($TaskTableTable t) => OrderingTerm(
                expression: t.name,
                mode: criterion.direction == SortDirection.ascending
                    ? OrderingMode.asc
                    : OrderingMode.desc,
              ),
            );
          case SortField.startDate:
            orderingFuncs.add(
              ($TaskTableTable t) => OrderingTerm(
                expression: t.startDate,
                mode: criterion.direction == SortDirection.ascending
                    ? OrderingMode.asc
                    : OrderingMode.desc,
              ),
            );
          case SortField.deadlineDate:
            orderingFuncs.add(
              ($TaskTableTable t) => OrderingTerm(
                expression: t.deadlineDate,
                mode: criterion.direction == SortDirection.ascending
                    ? OrderingMode.asc
                    : OrderingMode.desc,
              ),
            );
          case SortField.createdDate:
            orderingFuncs.add(
              ($TaskTableTable t) => OrderingTerm(
                expression: t.createdAt,
                mode: criterion.direction == SortDirection.ascending
                    ? OrderingMode.asc
                    : OrderingMode.desc,
              ),
            );
          case SortField.updatedDate:
            orderingFuncs.add(
              ($TaskTableTable t) => OrderingTerm(
                expression: t.updatedAt,
                mode: criterion.direction == SortDirection.ascending
                    ? OrderingMode.asc
                    : OrderingMode.desc,
              ),
            );
        }
      }
      select.orderBy(orderingFuncs);
    }

    // Build the join query if labels are needed
    final JoinedSelectStatement<HasResultSet, dynamic> joinQuery;
    if (query.needsLabels) {
      joinQuery = select.join([
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
    } else {
      joinQuery = select.join([
        leftOuterJoin(
          driftDb.projectTable,
          driftDb.taskTable.projectId.equalsExp(driftDb.projectTable.id),
        ),
      ]);
    }

    // Map results to Task objects
    Stream<List<Task>> stream = joinQuery.watch().map((rows) {
      if (query.needsLabels) {
        return TaskAggregation.fromRows(rows: rows, driftDb: driftDb).toTasks();
      } else {
        return rows.map((row) {
          final taskData = row.readTable(driftDb.taskTable);
          final projectData = row.readTableOrNull(driftDb.projectTable);
          return taskFromTable(
            taskData,
            project: projectData != null ? projectFromTable(projectData) : null,
          );
        }).toList();
      }
    });

    // Apply occurrence expansion if needed (with two-phase date filtering)
    if (query.shouldExpandOccurrences) {
      final expansion = query.occurrenceExpansion!;
      final completionsStream = driftDb
          .select(driftDb.taskCompletionHistoryTable)
          .watch()
          .map((rows) => rows.map(_toCompletionData).toList());

      final exceptionsStream = driftDb
          .select(driftDb.taskRecurrenceExceptionsTable)
          .watch()
          .map((rows) => rows.map(_toExceptionData).toList());

      final evaluator = TaskFilterEvaluator();
      final context = EvaluationContext();
      bool postExpansionFilter(Task task) {
        return evaluator.matches(task, query.filter, context);
      }

      stream = occurrenceExpander.expandTaskOccurrences(
        tasksStream: stream,
        completionsStream: completionsStream,
        exceptionsStream: exceptionsStream,
        rangeStart: expansion.rangeStart,
        rangeEnd: expansion.rangeEnd,
        postExpansionFilter: postExpansionFilter,
      );
    }

    return stream;
  }

  QueryFilter<TaskPredicate> _removeDatePredicates(
    QueryFilter<TaskPredicate> filter,
  ) {
    final shared = filter.shared
        .where((p) => p is! TaskDatePredicate)
        .toList(growable: false);

    final orGroups = filter.orGroups
        .map(
          (group) => group
              .where((p) => p is! TaskDatePredicate)
              .toList(growable: false),
        )
        .toList(growable: false);

    return QueryFilter<TaskPredicate>(shared: shared, orGroups: orGroups);
  }

  Expression<bool>? _whereExpressionFromFilter(
    QueryFilter<TaskPredicate> filter,
    $TaskTableTable t,
  ) {
    return _predicateMapper.whereExpressionFromFilter(
      filter: filter,
      predicateToExpression: (p) =>
          _predicateMapper.predicateToExpression(p, t),
    );
  }

  /// Checks if a query matches the inbox tier.
  bool _isInboxQuery(TaskQuery query) {
    if (query.filter.orGroups.isNotEmpty) return false;
    final predicates = query.filter.shared;
    if (predicates.length != 2) return false;

    final hasNotCompleted = predicates.any(
      (p) =>
          p is TaskBoolPredicate &&
          p.field == TaskBoolField.completed &&
          p.operator == BoolOperator.isFalse,
    );

    final hasNoProject = predicates.any(
      (p) => p is TaskProjectPredicate && p.operator == ProjectOperator.isNull,
    );

    return hasNotCompleted && hasNoProject;
  }

  /// Checks if a query matches the today tier.
  bool _isTodayQuery(TaskQuery query) {
    if (query.filter.orGroups.isNotEmpty) return false;
    final predicates = query.filter.shared;
    if (predicates.length != 2) return false;

    final hasNotCompleted = predicates.any(
      (p) =>
          p is TaskBoolPredicate &&
          p.field == TaskBoolField.completed &&
          p.operator == BoolOperator.isFalse,
    );

    final hasDeadlineOnOrBefore = predicates.any((p) {
      if (p is! TaskDatePredicate) return false;
      return p.field == TaskDateField.deadlineDate &&
          p.operator == DateOperator.onOrBefore;
    });

    return hasNotCompleted && hasDeadlineOnOrBefore;
  }

  /// Checks if a query matches the upcoming tier.
  bool _isUpcomingQuery(TaskQuery query) {
    if (query.filter.orGroups.isNotEmpty) return false;
    final predicates = query.filter.shared;
    if (predicates.length != 2) return false;

    final hasNotCompleted = predicates.any(
      (p) =>
          p is TaskBoolPredicate &&
          p.field == TaskBoolField.completed &&
          p.operator == BoolOperator.isFalse,
    );

    final hasDeadlineNotNull = predicates.any(
      (p) =>
          p is TaskDatePredicate &&
          p.field == TaskDateField.deadlineDate &&
          p.operator == DateOperator.isNotNull,
    );

    return hasNotCompleted && hasDeadlineNotNull;
  }

  /// Gets or creates the shared inbox stream with tier-based caching.
  Stream<List<Task>> _getOrCreateInboxStream(TaskQuery query) {
    if (_sharedInboxStream == null) {
      final stream = _buildAndExecuteQuery(query).map((tasks) {
        developer.log(
          'INBOX STREAM emitting ${tasks.length} tasks: ${tasks.map((t) => "${t.name}(completed=${t.completed})").join(", ")}',
          name: 'TaskRepository',
        );
        return tasks;
      });
      _sharedInboxStream = stream.shareValue();
    }
    return _sharedInboxStream!;
  }

  /// Gets or creates the shared today stream with tier-based caching.
  Stream<List<Task>> _getOrCreateTodayStream(TaskQuery query) {
    if (_sharedTodayStream == null) {
      final stream = _buildAndExecuteQuery(query).map((tasks) {
        developer.log(
          'TODAY STREAM emitting ${tasks.length} tasks: ${tasks.map((t) => "${t.name}(deadline=${t.deadlineDate})").join(", ")}',
          name: 'TaskRepository',
        );
        return tasks;
      });
      _sharedTodayStream = stream.shareValue();
    }
    return _sharedTodayStream!;
  }

  /// Gets or creates the shared upcoming stream with tier-based caching.
  Stream<List<Task>> _getOrCreateUpcomingStream(TaskQuery query) {
    if (_sharedUpcomingStream == null) {
      final stream = _buildAndExecuteQuery(query).map((tasks) {
        developer.log(
          'UPCOMING STREAM emitting ${tasks.length} tasks: ${tasks.map((t) => "${t.name}(deadline=${t.deadlineDate})").join(", ")}',
          name: 'TaskRepository',
        );
        return tasks;
      });
      _sharedUpcomingStream = stream.shareValue();
    }
    return _sharedUpcomingStream!;
  }
}
