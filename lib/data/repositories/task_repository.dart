import 'package:taskly_bloc/core/utils/app_log.dart';

import 'package:drift/drift.dart' as drift_pkg;
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/data/mappers/drift_to_domain.dart';
import 'package:taskly_bloc/data/repositories/mappers/task_predicate_mapper.dart';
import 'package:taskly_bloc/data/repositories/query_stream_cache.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
import 'package:taskly_bloc/data/repositories/repository_helpers.dart';
import 'package:taskly_bloc/domain/interfaces/occurrence_stream_expander_contract.dart';
import 'package:taskly_bloc/domain/interfaces/occurrence_write_helper_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/filtering/evaluation_context.dart';
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
  final Map<DateTime, ValueStream<List<Task>>> _sharedTodayStreamsByDate = {};
  ValueStream<List<Task>>? _sharedUpcomingStream;

  // Generic query-keyed cache for stable, non-date queries.
  final QueryStreamCache<TaskQuery, List<Task>> _sharedWatchAllCache =
      QueryStreamCache(maxEntries: 32);

  final Map<_OccurrenceRangeKey, ValueStream<List<Task>>>
  _occurrenceStreamCache = {};

  /// Watch tasks with optional filtering, sorting, and occurrence expansion.
  ///
  /// If [query] is null, returns all tasks with related entities.
  /// All filtering happens at the database level for optimal performance.
  @override
  Stream<List<Task>> watchAll([TaskQuery? query]) {
    final normalizedQuery = query ?? TaskQuery.all();

    // Route to shared streams for common patterns.
    if (isInboxQuery(normalizedQuery)) {
      return getOrCreateInboxStream(normalizedQuery);
    } else if (isTodayQuery(normalizedQuery)) {
      return getOrCreateTodayStream(normalizedQuery);
    } else if (isUpcomingQuery(normalizedQuery)) {
      return getOrCreateUpcomingStream(normalizedQuery);
    }

    // Conservative policy: don't cache date-based queries by default.
    if (normalizedQuery.hasDateFilter ||
        normalizedQuery.shouldExpandOccurrences) {
      return buildAndExecuteQuery(normalizedQuery);
    }

    return _sharedWatchAllCache.getOrCreate(
      normalizedQuery,
      () => buildAndExecuteQuery(normalizedQuery),
    );
  }

  @override
  Future<List<Task>> getAll([TaskQuery? query]) async {
    final normalizedQuery = query ?? TaskQuery.all();
    return buildAndExecuteQuery(normalizedQuery).first;
  }

  @override
  Stream<int> watchAllCount([TaskQuery? query]) {
    query ??= TaskQuery.all();

    if (query.shouldExpandOccurrences) {
      return buildAndExecuteQuery(
        query,
      ).map((List<Task> items) => items.length).distinct();
    }

    final countExp = driftDb.taskTable.id.count();
    final statement = driftDb.selectOnly(driftDb.taskTable)
      ..addColumns([countExp]);

    final where = whereExpressionFromFilter(query.filter, driftDb.taskTable);
    if (where != null) statement.where(where);

    return statement
        .watchSingle()
        .map((row) => row.read(countExp) ?? 0)
        .distinct();
  }

  /// Get a single task by ID with related entities.
  @override
  Future<Task?> getById(String id) async {
    final taskValueTable = driftDb.valueTable.createAlias('task_value');
    final projectValuesTable = driftDb.projectValuesTable.createAlias(
      'project_values_for_task',
    );
    final projectValueTable = driftDb.valueTable.createAlias('project_value');

    final joined =
        (driftDb.select(driftDb.taskTable)..where((t) => t.id.equals(id))).join(
          [
            drift_pkg.leftOuterJoin(
              driftDb.projectTable,
              driftDb.taskTable.projectId.equalsExp(driftDb.projectTable.id),
            ),
            drift_pkg.leftOuterJoin(
              driftDb.taskValuesTable,
              driftDb.taskTable.id.equalsExp(driftDb.taskValuesTable.taskId),
            ),
            drift_pkg.leftOuterJoin(
              taskValueTable,
              driftDb.taskValuesTable.valueId.equalsExp(taskValueTable.id),
            ),
            drift_pkg.leftOuterJoin(
              projectValuesTable,
              driftDb.projectTable.id.equalsExp(projectValuesTable.projectId),
            ),
            drift_pkg.leftOuterJoin(
              projectValueTable,
              projectValuesTable.valueId.equalsExp(projectValueTable.id),
            ),
          ],
        );

    final rows = await joined.get();
    return TaskAggregation.fromRows(
      rows: rows,
      driftDb: driftDb,
      projectValuesTable: projectValuesTable,
      projectValueTable: projectValueTable,
      taskValueTable: taskValueTable,
    ).toSingleTask();
  }

  /// Watch a single task by ID with related entities.
  @override
  Stream<Task?> watchById(String taskId) {
    final taskValueTable = driftDb.valueTable.createAlias('task_value');
    final projectValuesTable = driftDb.projectValuesTable.createAlias(
      'project_values_for_task',
    );
    final projectValueTable = driftDb.valueTable.createAlias('project_value');

    final joined =
        (driftDb.select(
          driftDb.taskTable,
        )..where((t) => t.id.equals(taskId))).join([
          drift_pkg.leftOuterJoin(
            driftDb.projectTable,
            driftDb.taskTable.projectId.equalsExp(driftDb.projectTable.id),
          ),
          drift_pkg.leftOuterJoin(
            driftDb.taskValuesTable,
            driftDb.taskTable.id.equalsExp(driftDb.taskValuesTable.taskId),
          ),
          drift_pkg.leftOuterJoin(
            taskValueTable,
            driftDb.taskValuesTable.valueId.equalsExp(taskValueTable.id),
          ),
          drift_pkg.leftOuterJoin(
            projectValuesTable,
            driftDb.projectTable.id.equalsExp(projectValuesTable.projectId),
          ),
          drift_pkg.leftOuterJoin(
            projectValueTable,
            projectValuesTable.valueId.equalsExp(projectValueTable.id),
          ),
        ]);

    return joined.watch().map((rows) {
      return TaskAggregation.fromRows(
        rows: rows,
        driftDb: driftDb,
        projectValuesTable: projectValuesTable,
        projectValueTable: projectValueTable,
        taskValueTable: taskValueTable,
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
    int? priority,
    String? repeatIcalRrule,
    bool repeatFromCompletion = false,
    List<String>? valueIds,
  }) async {
    talker.debug('[TaskRepository] create: name="$name", projectId=$projectId');
    final now = DateTime.now();
    final id = idGenerator.taskId();

    final normalizedStartDate = dateOnlyOrNull(startDate);
    final normalizedDeadlineDate = dateOnlyOrNull(deadlineDate);

    await driftDb.transaction(() async {
      await driftDb
          .into(driftDb.taskTable)
          .insert(
            TaskTableCompanion(
              id: drift_pkg.Value(id),
              name: drift_pkg.Value(name),
              description: drift_pkg.Value(description),
              completed: drift_pkg.Value(completed),
              startDate: drift_pkg.Value(normalizedStartDate),
              deadlineDate: drift_pkg.Value(normalizedDeadlineDate),
              projectId: drift_pkg.Value(projectId),
              priority: drift_pkg.Value(priority),
              isPinned: const drift_pkg.Value(false),
              repeatIcalRrule: repeatIcalRrule == null
                  ? const drift_pkg.Value<String>.absent()
                  : drift_pkg.Value(repeatIcalRrule),
              repeatFromCompletion: drift_pkg.Value(repeatFromCompletion),
              seriesEnded: const drift_pkg.Value(false),
              createdAt: drift_pkg.Value(now),
              updatedAt: drift_pkg.Value(now),
            ),
          );

      if (valueIds != null) {
        final primaryValueId = valueIds.isEmpty ? null : valueIds.first;
        for (final valueId in valueIds) {
          final taskValueId = idGenerator.taskValueId(
            taskId: id,
            valueId: valueId,
          );
          await driftDb
              .into(driftDb.taskValuesTable)
              .insert(
                TaskValuesTableCompanion(
                  id: drift_pkg.Value(taskValueId),
                  taskId: drift_pkg.Value(id),
                  valueId: drift_pkg.Value(valueId),
                  isPrimary: drift_pkg.Value(valueId == primaryValueId),
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
    int? priority,
    String? repeatIcalRrule,
    bool? repeatFromCompletion,
    List<String>? valueIds,
    bool? isPinned,
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

    await driftDb.transaction(() async {
      await driftDb
          .update(driftDb.taskTable)
          .replace(
            TaskTableCompanion(
              id: drift_pkg.Value(id),
              name: drift_pkg.Value(name),
              description: drift_pkg.Value(description),
              completed: drift_pkg.Value(completed),
              startDate: drift_pkg.Value(normalizedStartDate),
              deadlineDate: drift_pkg.Value(normalizedDeadlineDate),
              projectId: drift_pkg.Value(projectId),
              priority: drift_pkg.Value(priority),
              isPinned: isPinned == null
                  ? drift_pkg.Value(existing.isPinned)
                  : drift_pkg.Value(isPinned),
              repeatIcalRrule: repeatIcalRrule == null
                  ? const drift_pkg.Value<String>.absent()
                  : drift_pkg.Value(repeatIcalRrule),
              repeatFromCompletion: repeatFromCompletion == null
                  ? drift_pkg.Value(existing.repeatFromCompletion)
                  : drift_pkg.Value(repeatFromCompletion),
              seriesEnded: drift_pkg.Value(existing.seriesEnded),
              createdAt: drift_pkg.Value(existing.createdAt),
              updatedAt: drift_pkg.Value(now),
            ),
          );

      if (valueIds != null) {
        await (driftDb.delete(
          driftDb.taskValuesTable,
        )..where((t) => t.taskId.equals(id))).go();

        final primaryValueId = valueIds.isEmpty ? null : valueIds.first;
        for (final valueId in valueIds) {
          final taskValueId = idGenerator.taskValueId(
            taskId: id,
            valueId: valueId,
          );
          await driftDb
              .into(driftDb.taskValuesTable)
              .insert(
                TaskValuesTableCompanion(
                  id: drift_pkg.Value(taskValueId),
                  taskId: drift_pkg.Value(id),
                  valueId: drift_pkg.Value(valueId),
                  isPrimary: drift_pkg.Value(valueId == primaryValueId),
                ),
              );
        }
      }
    });
  }

  @override
  Future<void> setPinned({
    required String id,
    required bool isPinned,
  }) async {
    talker.debug('[TaskRepository] setPinned: id=$id, isPinned=$isPinned');
    await (driftDb.update(
      driftDb.taskTable,
    )..where((t) => t.id.equals(id))).write(
      TaskTableCompanion(
        isPinned: drift_pkg.Value(isPinned),
        updatedAt: drift_pkg.Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    talker.debug('[TaskRepository] delete: id=$id');
    await driftDb
        .delete(driftDb.taskTable)
        .delete(TaskTableCompanion(id: drift_pkg.Value(id)));
  }

  @override
  Future<void> updateLastReviewedAt({
    required String id,
    required DateTime reviewedAt,
  }) async {
    // TODO(attention-migration): This is now handled by AttentionResolutions table
    // The method is kept for interface compatibility but is a no-op
    talker.debug(
      '[TaskRepository] updateLastReviewedAt: id=$id (no-op - migrated to AttentionResolutions)',
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
    final completions = completionRows.map(toCompletionData).toList();
    final exceptions = exceptionRows.map(toExceptionData).toList();

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
        .map((rows) => rows.map(toCompletionData).toList());

    final exceptionsStream = driftDb
        .select(driftDb.taskRecurrenceExceptionsTable)
        .watch()
        .map((rows) => rows.map(toExceptionData).toList());

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
  CompletionHistoryData toCompletionData(TaskCompletionHistoryTableData row) {
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
  RecurrenceExceptionData toExceptionData(
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
  Stream<List<Task>> buildAndExecuteQuery(TaskQuery query) {
    final QueryFilter<TaskPredicate> sqlFilter = query.shouldExpandOccurrences
        ? removeDatePredicates(query.filter)
        : query.filter;

    // Start with base query
    final select = driftDb.select(driftDb.taskTable);

    select.where((t) {
      return whereExpressionFromFilter(sqlFilter, t) ??
          const drift_pkg.Constant(true);
    });

    // Apply ordering
    if (query.sortCriteria.isNotEmpty) {
      final orderingFuncs =
          <drift_pkg.OrderingTerm Function($TaskTableTable)>[];
      for (final criterion in query.sortCriteria) {
        switch (criterion.field) {
          case SortField.name:
            orderingFuncs.add(
              ($TaskTableTable t) => drift_pkg.OrderingTerm(
                expression: t.name,
                mode: criterion.direction == SortDirection.ascending
                    ? drift_pkg.OrderingMode.asc
                    : drift_pkg.OrderingMode.desc,
              ),
            );
          case SortField.startDate:
            orderingFuncs.add(
              ($TaskTableTable t) => drift_pkg.OrderingTerm(
                expression: t.startDate,
                mode: criterion.direction == SortDirection.ascending
                    ? drift_pkg.OrderingMode.asc
                    : drift_pkg.OrderingMode.desc,
              ),
            );
          case SortField.deadlineDate:
            orderingFuncs.add(
              ($TaskTableTable t) => drift_pkg.OrderingTerm(
                expression: t.deadlineDate,
                mode: criterion.direction == SortDirection.ascending
                    ? drift_pkg.OrderingMode.asc
                    : drift_pkg.OrderingMode.desc,
              ),
            );
          case SortField.createdDate:
            orderingFuncs.add(
              ($TaskTableTable t) => drift_pkg.OrderingTerm(
                expression: t.createdAt,
                mode: criterion.direction == SortDirection.ascending
                    ? drift_pkg.OrderingMode.asc
                    : drift_pkg.OrderingMode.desc,
              ),
            );
          case SortField.updatedDate:
            orderingFuncs.add(
              ($TaskTableTable t) => drift_pkg.OrderingTerm(
                expression: t.updatedAt,
                mode: criterion.direction == SortDirection.ascending
                    ? drift_pkg.OrderingMode.asc
                    : drift_pkg.OrderingMode.desc,
              ),
            );
        }
      }
      select.orderBy(orderingFuncs);
    }

    final taskValueTable = driftDb.valueTable.createAlias('task_value');
    final projectValuesTable = driftDb.projectValuesTable.createAlias(
      'project_values_for_task',
    );
    final projectValueTable = driftDb.valueTable.createAlias('project_value');

    // Build the join query - include task values AND project values.
    final joinQuery = select.join([
      drift_pkg.leftOuterJoin(
        driftDb.projectTable,
        driftDb.taskTable.projectId.equalsExp(driftDb.projectTable.id),
      ),
      drift_pkg.leftOuterJoin(
        driftDb.taskValuesTable,
        driftDb.taskTable.id.equalsExp(driftDb.taskValuesTable.taskId),
      ),
      drift_pkg.leftOuterJoin(
        taskValueTable,
        driftDb.taskValuesTable.valueId.equalsExp(taskValueTable.id),
      ),
      drift_pkg.leftOuterJoin(
        projectValuesTable,
        driftDb.projectTable.id.equalsExp(projectValuesTable.projectId),
      ),
      drift_pkg.leftOuterJoin(
        projectValueTable,
        projectValuesTable.valueId.equalsExp(projectValueTable.id),
      ),
    ]);

    // Map results to Task objects
    Stream<List<Task>> stream = joinQuery.watch().map((rows) {
      return TaskAggregation.fromRows(
        rows: rows,
        driftDb: driftDb,
        projectValuesTable: projectValuesTable,
        projectValueTable: projectValueTable,
        taskValueTable: taskValueTable,
      ).toTasks();
    });

    // Apply occurrence expansion if needed (with two-phase date filtering)
    if (query.shouldExpandOccurrences) {
      final expansion = query.occurrenceExpansion!;
      final completionsStream = driftDb
          .select(driftDb.taskCompletionHistoryTable)
          .watch()
          .map((rows) => rows.map(toCompletionData).toList());

      final exceptionsStream = driftDb
          .select(driftDb.taskRecurrenceExceptionsTable)
          .watch()
          .map((rows) => rows.map(toExceptionData).toList());

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

  QueryFilter<TaskPredicate> removeDatePredicates(
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

  drift_pkg.Expression<bool>? whereExpressionFromFilter(
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
  bool isInboxQuery(TaskQuery query) {
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
  bool isTodayQuery(TaskQuery query) {
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
  bool isUpcomingQuery(TaskQuery query) {
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
  Stream<List<Task>> getOrCreateInboxStream(TaskQuery query) {
    if (_sharedInboxStream == null) {
      final stream = buildAndExecuteQuery(query).map((tasks) {
        AppLog.routineThrottled(
          'task_repo.inbox_stream',
          const Duration(seconds: 10),
          'data.task_repository',
          'INBOX stream emitting ${tasks.length} tasks',
        );
        return tasks;
      });
      _sharedInboxStream = stream.shareValue();
    }
    return _sharedInboxStream!;
  }

  DateTime? extractTodayCutoffDate(TaskQuery query) {
    // TaskQuery.today(now: ...) encodes the cutoff as a date-only predicate.
    for (final p in query.filter.shared.whereType<TaskDatePredicate>()) {
      if (p.field == TaskDateField.deadlineDate &&
          p.operator == DateOperator.onOrBefore) {
        return p.date;
      }
    }
    return null;
  }

  /// Gets or creates the shared today stream with tier-based caching.
  Stream<List<Task>> getOrCreateTodayStream(TaskQuery query) {
    final todayCutoff = extractTodayCutoffDate(query);
    if (todayCutoff == null) {
      // Safety: if we cannot reliably key this stream by day, do not cache it.
      return buildAndExecuteQuery(query);
    }

    final cached = _sharedTodayStreamsByDate[todayCutoff];
    if (cached != null) return cached;

    final stream = buildAndExecuteQuery(query).map((tasks) {
      AppLog.routineThrottled(
        'task_repo.today_stream',
        const Duration(seconds: 10),
        'data.task_repository',
        'TODAY stream emitting ${tasks.length} tasks',
      );
      return tasks;
    });
    final shared = stream.shareValue();
    _sharedTodayStreamsByDate[todayCutoff] = shared;

    // Prevent unbounded growth (e.g., app stays open for weeks).
    // Keep only the most recent few days.
    if (_sharedTodayStreamsByDate.length > 4) {
      final keys = _sharedTodayStreamsByDate.keys.toList()..sort();
      final keysToRemove = keys.take(keys.length - 4);
      keysToRemove.forEach(_sharedTodayStreamsByDate.remove);
    }

    return shared;
  }

  /// Gets or creates the shared upcoming stream with tier-based caching.
  Stream<List<Task>> getOrCreateUpcomingStream(TaskQuery query) {
    if (_sharedUpcomingStream == null) {
      final stream = buildAndExecuteQuery(query).map((tasks) {
        AppLog.routineThrottled(
          'task_repo.upcoming_stream',
          const Duration(seconds: 10),
          'data.task_repository',
          'UPCOMING stream emitting ${tasks.length} tasks',
        );
        return tasks;
      });
      _sharedUpcomingStream = stream.shareValue();
    }
    return _sharedUpcomingStream!;
  }
}
