import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/mappers/drift_to_domain.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
import 'package:taskly_bloc/data/repositories/repository_helpers.dart';
import 'package:taskly_bloc/domain/contracts/occurrence_stream_expander_contract.dart';
import 'package:taskly_bloc/domain/contracts/occurrence_write_helper_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';
import 'package:taskly_bloc/domain/project_task_counts.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
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

  // Tier-based shared streams for common query patterns
  // Reduces concurrent queries from 6-7 down to 2-3
  ValueStream<List<Task>>? _sharedInboxStream;
  ValueStream<List<Task>>? _sharedTodayStream;
  ValueStream<List<Task>>? _sharedUpcomingStream;

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
    // Separate date rules for two-phase filtering when expansion is needed
    final List<TaskRule> sqlRules;
    final List<DateRule> dateRulesForPostExpansion;

    if (query.shouldExpandOccurrences) {
      // Two-phase: non-date rules to SQL, date rules applied after expansion
      sqlRules = query.rules.where((r) => r is! DateRule).toList();
      dateRulesForPostExpansion = query.rules.whereType<DateRule>().toList();
    } else {
      // Single-phase: all rules go to SQL
      sqlRules = query.rules;
      dateRulesForPostExpansion = [];
    }

    // Start with base query
    final select = driftDb.select(driftDb.taskTable);

    // Build WHERE clause from SQL rules
    if (sqlRules.isNotEmpty) {
      select.where((t) {
        final expressions = sqlRules
            .map((rule) => _ruleToExpression(rule, t))
            .cast<Expression<bool>>()
            .toList();

        return expressions.reduce((a, b) => a & b);
      });
    }

    // Apply ordering
    if (query.sortCriteria.isNotEmpty) {
      final orderingFuncs = query.sortCriteria.map((criterion) {
        return ($TaskTableTable t) {
          final expression = switch (criterion.field) {
            SortField.name => t.name,
            SortField.startDate => t.startDate,
            SortField.deadlineDate => t.deadlineDate,
            SortField.createdDate => t.createdAt,
            SortField.updatedDate => t.updatedAt,
          };

          return OrderingTerm(
            expression: expression,
            mode: criterion.direction == SortDirection.ascending
                ? OrderingMode.asc
                : OrderingMode.desc,
          );
        };
      }).toList();
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

      // Build post-expansion filter from date rules
      final postExpansionFilter = _buildPostExpansionFilter(
        dateRulesForPostExpansion,
      );

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

  /// Builds a post-expansion filter function from date rules.
  ///
  /// Used for two-phase filtering: date rules are applied to expanded
  /// occurrences (virtual dates) rather than base task dates.
  bool Function(Task)? _buildPostExpansionFilter(List<DateRule> dateRules) {
    if (dateRules.isEmpty) return null;

    return (Task task) {
      for (final rule in dateRules) {
        if (!_evaluateDateRuleOnTask(rule, task)) {
          return false;
        }
      }
      return true;
    };
  }

  /// Evaluates a date rule against a task's current dates.
  ///
  /// When called on an expanded occurrence, task.startDate and task.deadlineDate
  /// are the virtual occurrence dates, enabling filtering on occurrence dates.
  bool _evaluateDateRuleOnTask(DateRule rule, Task task) {
    final DateTime? fieldValue = switch (rule.field) {
      DateRuleField.startDate => task.startDate,
      DateRuleField.deadlineDate => task.deadlineDate,
      DateRuleField.createdAt => task.createdAt,
      DateRuleField.updatedAt => task.updatedAt,
    };

    // Convert relative dates to absolute
    DateTime? absoluteDate;
    DateTime? absoluteEndDate;
    if (rule.operator == DateRuleOperator.relative &&
        rule.relativeDays != null) {
      absoluteDate = _relativeToAbsolute(rule.relativeDays!);
    } else {
      absoluteDate = rule.date;
      absoluteEndDate = rule.endDate;
    }

    return switch (rule.operator) {
      DateRuleOperator.onOrAfter =>
        fieldValue != null && !fieldValue.isBefore(absoluteDate!),
      DateRuleOperator.onOrBefore =>
        fieldValue != null && !fieldValue.isAfter(absoluteDate!),
      DateRuleOperator.before =>
        fieldValue != null && fieldValue.isBefore(absoluteDate!),
      DateRuleOperator.after =>
        fieldValue != null && fieldValue.isAfter(absoluteDate!),
      DateRuleOperator.on =>
        fieldValue != null && dateOnly(fieldValue) == dateOnly(absoluteDate!),
      DateRuleOperator.between =>
        fieldValue != null &&
            !fieldValue.isBefore(absoluteDate!) &&
            !fieldValue.isAfter(absoluteEndDate!),
      DateRuleOperator.isNull => fieldValue == null,
      DateRuleOperator.isNotNull => fieldValue != null,
      DateRuleOperator.relative =>
        fieldValue != null && !fieldValue.isBefore(absoluteDate!),
    };
  }

  /// Converts a TaskRule to a Drift expression with 100% SQL coverage.
  Expression<bool> _ruleToExpression(TaskRule rule, $TaskTableTable t) {
    return switch (rule) {
      DateRule() => _dateRuleToExpression(rule, t),
      BooleanRule() => _booleanRuleToExpression(rule, t),
      ProjectRule() => _projectRuleToExpression(rule, t),
      LabelRule() => _labelRuleToExpression(rule, t),
      _ => const Constant(true), // Should not happen
    };
  }

  /// Converts a DateRule to a Drift expression with relative date support.
  Expression<bool> _dateRuleToExpression(DateRule rule, $TaskTableTable t) {
    final column = switch (rule.field) {
      DateRuleField.startDate => t.startDate,
      DateRuleField.deadlineDate => t.deadlineDate,
      DateRuleField.createdAt => t.createdAt,
      DateRuleField.updatedAt => t.updatedAt,
    };

    // Convert relative dates to absolute at query build time
    DateTime? absoluteDate;
    DateTime? absoluteEndDate;
    if (rule.operator == DateRuleOperator.relative &&
        rule.relativeDays != null) {
      absoluteDate = _relativeToAbsolute(rule.relativeDays!);
    } else {
      absoluteDate = rule.date;
      absoluteEndDate = rule.endDate;
    }

    return switch (rule.operator) {
      DateRuleOperator.onOrAfter => column.isBiggerOrEqualValue(absoluteDate!),
      DateRuleOperator.onOrBefore => column.isSmallerOrEqualValue(
        absoluteDate!,
      ),
      DateRuleOperator.before => column.isSmallerThanValue(absoluteDate!),
      DateRuleOperator.after => column.isBiggerThanValue(absoluteDate!),
      DateRuleOperator.on => column.equals(absoluteDate!),
      DateRuleOperator.between => column.isBetweenValues(
        absoluteDate!,
        absoluteEndDate!,
      ),
      DateRuleOperator.isNull => column.isNull(),
      DateRuleOperator.isNotNull => column.isNotNull(),
      DateRuleOperator.relative => column.isBiggerOrEqualValue(absoluteDate!),
    };
  }

  /// Converts relative days to an absolute DateTime.
  DateTime _relativeToAbsolute(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: days));
  }

  /// Converts a BooleanRule to a Drift expression.
  Expression<bool> _booleanRuleToExpression(
    BooleanRule rule,
    $TaskTableTable t,
  ) {
    final column = switch (rule.field) {
      BooleanRuleField.completed => t.completed,
    };

    return switch (rule.operator) {
      BooleanRuleOperator.isTrue => column.equals(true),
      BooleanRuleOperator.isFalse => column.equals(false),
    };
  }

  /// Converts a ProjectRule to a Drift expression.
  Expression<bool> _projectRuleToExpression(
    ProjectRule rule,
    $TaskTableTable t,
  ) {
    return switch (rule.operator) {
      ProjectRuleOperator.matches => t.projectId.equals(rule.projectId!),
      ProjectRuleOperator.isNull => t.projectId.isNull(),
      ProjectRuleOperator.isNotNull => t.projectId.isNotNull(),
    };
  }

  /// Converts a LabelRule to a Drift expression using EXISTS subquery.
  ///
  /// Supports:
  /// - matchesAny: Tasks with at least one of the specified labels
  /// - matchesAll: Tasks with all specified labels (uses GROUP BY + HAVING)
  /// - hasNoLabels: Tasks with no labels at all
  Expression<bool> _labelRuleToExpression(LabelRule rule, $TaskTableTable t) {
    return switch (rule.operator) {
      LabelRuleOperator.hasAny => existsQuery(
        driftDb.selectOnly(driftDb.taskLabelsTable)
          ..addColumns([driftDb.taskLabelsTable.taskId])
          ..where(driftDb.taskLabelsTable.taskId.equalsExp(t.id))
          ..where(driftDb.taskLabelsTable.labelId.isIn(rule.labelIds)),
      ),
      LabelRuleOperator.hasAll => existsQuery(
        driftDb.selectOnly(driftDb.taskLabelsTable)
          ..addColumns([driftDb.taskLabelsTable.taskId])
          ..where(driftDb.taskLabelsTable.taskId.equalsExp(t.id))
          ..where(driftDb.taskLabelsTable.labelId.isIn(rule.labelIds))
          ..groupBy([driftDb.taskLabelsTable.taskId]),
      ),
      LabelRuleOperator.isNull => notExistsQuery(
        driftDb.selectOnly(driftDb.taskLabelsTable)
          ..addColumns([driftDb.taskLabelsTable.taskId])
          ..where(driftDb.taskLabelsTable.taskId.equalsExp(t.id)),
      ),
      LabelRuleOperator.isNotNull => existsQuery(
        driftDb.selectOnly(driftDb.taskLabelsTable)
          ..addColumns([driftDb.taskLabelsTable.taskId])
          ..where(driftDb.taskLabelsTable.taskId.equalsExp(t.id)),
      ),
    };
  }

  /// Checks if a query matches the inbox tier.
  bool _isInboxQuery(TaskQuery query) {
    if (query.rules.length != 2) return false;

    final hasNotCompleted = query.rules.any(
      (r) =>
          r is BooleanRule &&
          r.field == BooleanRuleField.completed &&
          r.operator == BooleanRuleOperator.isFalse,
    );

    final hasNoProject = query.rules.any(
      (r) => r is ProjectRule && r.operator == ProjectRuleOperator.isNull,
    );

    return hasNotCompleted && hasNoProject;
  }

  /// Checks if a query matches the today tier.
  bool _isTodayQuery(TaskQuery query) {
    if (query.rules.length != 2) return false;

    final hasNotCompleted = query.rules.any(
      (r) =>
          r is BooleanRule &&
          r.field == BooleanRuleField.completed &&
          r.operator == BooleanRuleOperator.isFalse,
    );

    final hasStartDateToday = query.rules.any((r) {
      if (r is! DateRule) return false;
      if (r.field != DateRuleField.startDate) return false;
      if (r.operator != DateRuleOperator.onOrBefore) return false;

      final today = DateTime.now();
      final targetDate = DateTime(today.year, today.month, today.day);
      return r.date?.isAtSameMomentAs(targetDate) ?? false;
    });

    return hasNotCompleted && hasStartDateToday;
  }

  /// Checks if a query matches the upcoming tier.
  bool _isUpcomingQuery(TaskQuery query) {
    if (query.rules.length != 2) return false;

    final hasNotCompleted = query.rules.any(
      (r) =>
          r is BooleanRule &&
          r.field == BooleanRuleField.completed &&
          r.operator == BooleanRuleOperator.isFalse,
    );

    final hasProjectNotNull = query.rules.any(
      (r) => r is ProjectRule && r.operator == ProjectRuleOperator.isNotNull,
    );

    return hasNotCompleted && hasProjectNotNull;
  }

  /// Gets or creates the shared inbox stream with tier-based caching.
  Stream<List<Task>> _getOrCreateInboxStream(TaskQuery query) {
    if (_sharedInboxStream == null) {
      final stream = _buildAndExecuteQuery(query);
      _sharedInboxStream = stream.shareValue();
    }
    return _sharedInboxStream!;
  }

  /// Gets or creates the shared today stream with tier-based caching.
  Stream<List<Task>> _getOrCreateTodayStream(TaskQuery query) {
    if (_sharedTodayStream == null) {
      final stream = _buildAndExecuteQuery(query);
      _sharedTodayStream = stream.shareValue();
    }
    return _sharedTodayStream!;
  }

  /// Gets or creates the shared upcoming stream with tier-based caching.
  Stream<List<Task>> _getOrCreateUpcomingStream(TaskQuery query) {
    if (_sharedUpcomingStream == null) {
      final stream = _buildAndExecuteQuery(query);
      _sharedUpcomingStream = stream.shareValue();
    }
    return _sharedUpcomingStream!;
  }
}
