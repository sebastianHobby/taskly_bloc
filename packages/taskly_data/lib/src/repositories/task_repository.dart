import 'package:drift/drift.dart' as drift_pkg;
import 'package:rxdart/rxdart.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/taskly_domain.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/src/infrastructure/powersync/crud_metadata.dart';
import 'package:taskly_data/src/id/id_generator.dart';
import 'package:taskly_data/src/mappers/drift_to_domain.dart';
import 'package:taskly_data/src/errors/failure_guard.dart';
import 'package:taskly_data/src/repositories/mappers/task_predicate_mapper.dart';
import 'package:taskly_data/src/repositories/query_stream_cache.dart';
import 'package:taskly_data/src/repositories/repository_exceptions.dart';
import 'package:taskly_data/src/repositories/repository_helpers.dart';

class _OccurrenceRangeKey {
  const _OccurrenceRangeKey({required this.rangeStart, required this.rangeEnd});

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

  Future<String?> _getProjectPrimaryValueId(String projectId) async {
    final row = await (driftDb.select(
      driftDb.projectTable,
    )..where((p) => p.id.equals(projectId))).getSingleOrNull();
    return row?.primaryValueId;
  }

  bool _hasNonEmptyValueIds(List<String>? valueIds) {
    return (valueIds ?? const <String>[]).any((id) => id.trim().isNotEmpty);
  }

  String _taskValueValidationMessage(List<TaskValueIssue> issues) {
    if (issues.isEmpty) {
      return 'Invalid task values.';
    }

    const priorityOrder = [
      TaskValueIssue.projectRequired,
      TaskValueIssue.projectPrimaryRequired,
      TaskValueIssue.matchesProjectPrimary,
      TaskValueIssue.maxOverrides,
      TaskValueIssue.duplicate,
    ];

    final issue = priorityOrder.firstWhere(
      issues.contains,
      orElse: () => issues.first,
    );

    return switch (issue) {
      TaskValueIssue.projectRequired =>
        'Tasks must belong to a project before assigning values.',
      TaskValueIssue.projectPrimaryRequired =>
        'Project must have a primary value before assigning task values.',
      TaskValueIssue.matchesProjectPrimary =>
        'Task values cannot match the project primary value.',
      TaskValueIssue.maxOverrides =>
        'Tasks may have at most two override values (primary + optional secondary).',
      TaskValueIssue.duplicate => 'Task values must be unique.',
    };
  }

  /// Watch tasks with optional filtering, sorting, and occurrence expansion.
  ///
  /// If [query] is null, returns all tasks with related entities.
  /// All filtering happens at the database level for optimal performance.
  @override
  Stream<List<Task>> watchAll([TaskQuery? query]) {
    final normalizedQuery = query ?? TaskQuery.all();

    if (normalizedQuery.shouldExpandOccurrences ||
        normalizedQuery.hasOccurrencePreview) {
      throw UnsupportedError(
        'TaskRepository does not support occurrenceExpansion/occurrencePreview '
        'query flags. Use OccurrenceReadService (taskly_domain) for '
        'occurrence-aware reads.',
      );
    }

    // Route to shared streams for common patterns.
    if (isInboxQuery(normalizedQuery)) {
      return getOrCreateInboxStream(normalizedQuery);
    } else if (isTodayQuery(normalizedQuery)) {
      return getOrCreateTodayStream(normalizedQuery);
    } else if (isUpcomingQuery(normalizedQuery)) {
      return getOrCreateUpcomingStream(normalizedQuery);
    }

    // Conservative policy: don't cache date-based queries by default.
    if (normalizedQuery.hasDateFilter) {
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

    if (query.shouldExpandOccurrences || query.hasOccurrencePreview) {
      throw UnsupportedError(
        'TaskRepository does not support occurrenceExpansion/occurrencePreview '
        'query flags. Use OccurrenceReadService (taskly_domain) for '
        'occurrence-aware reads.',
      );
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
    final projectPrimaryValueTable = driftDb.valueTable.createAlias(
      'project_primary_value',
    );
    final overridePrimaryValueTable = driftDb.valueTable.createAlias(
      'task_override_primary_value',
    );
    final overrideSecondaryValueTable = driftDb.valueTable.createAlias(
      'task_override_secondary_value',
    );

    final joined =
        (driftDb.select(
          driftDb.taskTable,
        )..where((t) => t.id.equals(id))).join([
          drift_pkg.leftOuterJoin(
            driftDb.projectTable,
            driftDb.taskTable.projectId.equalsExp(driftDb.projectTable.id),
          ),
          drift_pkg.leftOuterJoin(
            projectPrimaryValueTable,
            driftDb.projectTable.primaryValueId.equalsExp(
              projectPrimaryValueTable.id,
            ),
          ),
          drift_pkg.leftOuterJoin(
            overridePrimaryValueTable,
            driftDb.taskTable.overridePrimaryValueId.equalsExp(
              overridePrimaryValueTable.id,
            ),
          ),
          drift_pkg.leftOuterJoin(
            overrideSecondaryValueTable,
            driftDb.taskTable.overrideSecondaryValueId.equalsExp(
              overrideSecondaryValueTable.id,
            ),
          ),
        ]);

    final rows = await joined.get();
    return TaskAggregation.fromRows(
      rows: rows,
      driftDb: driftDb,
      projectPrimaryValueTable: projectPrimaryValueTable,
      overridePrimaryValueTable: overridePrimaryValueTable,
      overrideSecondaryValueTable: overrideSecondaryValueTable,
    ).toSingleTask();
  }

  @override
  Future<List<Task>> getByIds(Iterable<String> ids) async {
    final idsList = ids.toList(growable: false);
    if (idsList.isEmpty) return const <Task>[];

    final projectPrimaryValueTable = driftDb.valueTable.createAlias(
      'project_primary_value',
    );
    final overridePrimaryValueTable = driftDb.valueTable.createAlias(
      'task_override_primary_value',
    );
    final overrideSecondaryValueTable = driftDb.valueTable.createAlias(
      'task_override_secondary_value',
    );

    final joined =
        (driftDb.select(
          driftDb.taskTable,
        )..where((t) => t.id.isIn(idsList))).join([
          drift_pkg.leftOuterJoin(
            driftDb.projectTable,
            driftDb.taskTable.projectId.equalsExp(driftDb.projectTable.id),
          ),
          drift_pkg.leftOuterJoin(
            projectPrimaryValueTable,
            driftDb.projectTable.primaryValueId.equalsExp(
              projectPrimaryValueTable.id,
            ),
          ),
          drift_pkg.leftOuterJoin(
            overridePrimaryValueTable,
            driftDb.taskTable.overridePrimaryValueId.equalsExp(
              overridePrimaryValueTable.id,
            ),
          ),
          drift_pkg.leftOuterJoin(
            overrideSecondaryValueTable,
            driftDb.taskTable.overrideSecondaryValueId.equalsExp(
              overrideSecondaryValueTable.id,
            ),
          ),
        ]);

    final rows = await joined.get();
    final tasks = TaskAggregation.fromRows(
      rows: rows,
      driftDb: driftDb,
      projectPrimaryValueTable: projectPrimaryValueTable,
      overridePrimaryValueTable: overridePrimaryValueTable,
      overrideSecondaryValueTable: overrideSecondaryValueTable,
    ).toTasks();

    final byId = <String, Task>{for (final t in tasks) t.id: t};
    return [
      for (final id in idsList)
        if (byId[id] != null) byId[id]!,
    ];
  }

  /// Watch a single task by ID with related entities.
  @override
  Stream<Task?> watchById(String taskId) {
    final projectPrimaryValueTable = driftDb.valueTable.createAlias(
      'project_primary_value',
    );
    final overridePrimaryValueTable = driftDb.valueTable.createAlias(
      'task_override_primary_value',
    );
    final overrideSecondaryValueTable = driftDb.valueTable.createAlias(
      'task_override_secondary_value',
    );

    final joined =
        (driftDb.select(
          driftDb.taskTable,
        )..where((t) => t.id.equals(taskId))).join([
          drift_pkg.leftOuterJoin(
            driftDb.projectTable,
            driftDb.taskTable.projectId.equalsExp(driftDb.projectTable.id),
          ),
          drift_pkg.leftOuterJoin(
            projectPrimaryValueTable,
            driftDb.projectTable.primaryValueId.equalsExp(
              projectPrimaryValueTable.id,
            ),
          ),
          drift_pkg.leftOuterJoin(
            overridePrimaryValueTable,
            driftDb.taskTable.overridePrimaryValueId.equalsExp(
              overridePrimaryValueTable.id,
            ),
          ),
          drift_pkg.leftOuterJoin(
            overrideSecondaryValueTable,
            driftDb.taskTable.overrideSecondaryValueId.equalsExp(
              overrideSecondaryValueTable.id,
            ),
          ),
        ]);

    return joined.watch().map((rows) {
      return TaskAggregation.fromRows(
        rows: rows,
        driftDb: driftDb,
        projectPrimaryValueTable: projectPrimaryValueTable,
        overridePrimaryValueTable: overridePrimaryValueTable,
        overrideSecondaryValueTable: overrideSecondaryValueTable,
      ).toSingleTask();
    });
  }

  @override
  Stream<List<Task>> watchByIds(Iterable<String> ids) {
    final idsList = ids.toList(growable: false);
    if (idsList.isEmpty) return Stream.value(const <Task>[]);

    final projectPrimaryValueTable = driftDb.valueTable.createAlias(
      'project_primary_value',
    );
    final overridePrimaryValueTable = driftDb.valueTable.createAlias(
      'task_override_primary_value',
    );
    final overrideSecondaryValueTable = driftDb.valueTable.createAlias(
      'task_override_secondary_value',
    );

    final joined =
        (driftDb.select(
          driftDb.taskTable,
        )..where((t) => t.id.isIn(idsList))).join([
          drift_pkg.leftOuterJoin(
            driftDb.projectTable,
            driftDb.taskTable.projectId.equalsExp(driftDb.projectTable.id),
          ),
          drift_pkg.leftOuterJoin(
            projectPrimaryValueTable,
            driftDb.projectTable.primaryValueId.equalsExp(
              projectPrimaryValueTable.id,
            ),
          ),
          drift_pkg.leftOuterJoin(
            overridePrimaryValueTable,
            driftDb.taskTable.overridePrimaryValueId.equalsExp(
              overridePrimaryValueTable.id,
            ),
          ),
          drift_pkg.leftOuterJoin(
            overrideSecondaryValueTable,
            driftDb.taskTable.overrideSecondaryValueId.equalsExp(
              overrideSecondaryValueTable.id,
            ),
          ),
        ]);

    return joined.watch().map((rows) {
      final tasks = TaskAggregation.fromRows(
        rows: rows,
        driftDb: driftDb,
        projectPrimaryValueTable: projectPrimaryValueTable,
        overridePrimaryValueTable: overridePrimaryValueTable,
        overrideSecondaryValueTable: overrideSecondaryValueTable,
      ).toTasks();

      final byId = <String, Task>{for (final t in tasks) t.id: t};
      return [
        for (final id in idsList)
          if (byId[id] != null) byId[id]!,
      ];
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
    bool seriesEnded = false,
    List<String>? valueIds,
    OperationContext? context,
  }) async {
    await FailureGuard.run(
      () async {
        final normalizedProjectId = switch (projectId?.trim()) {
          null || '' => null,
          final v => v,
        };
        talker.debug(
          '[TaskRepository] create: name="$name", projectId=$normalizedProjectId',
        );
        final now = DateTime.now();
        final id = idGenerator.taskId();

        final normalizedStartDate = dateOnlyOrNull(startDate);
        final normalizedDeadlineDate = dateOnlyOrNull(deadlineDate);

        final projectPrimaryValueId =
            normalizedProjectId == null || !_hasNonEmptyValueIds(valueIds)
            ? null
            : await _getProjectPrimaryValueId(normalizedProjectId);
        final valueValidation = TaskValuePolicy.validate(
          valueIds: valueIds,
          projectId: normalizedProjectId,
          projectPrimaryValueId: projectPrimaryValueId,
        );
        if (!valueValidation.isValid) {
          throw RepositoryValidationException(
            _taskValueValidationMessage(valueValidation.issues),
          );
        }

        final normalizedValueIds = valueValidation.normalizedIds;
        final overridePrimaryValueId = normalizedValueIds.isEmpty
            ? null
            : normalizedValueIds.first;
        final overrideSecondaryValueId = normalizedValueIds.length > 1
            ? normalizedValueIds[1]
            : null;

        final psMetadata = encodeCrudMetadata(context);

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
                  projectId: drift_pkg.Value(normalizedProjectId),
                  priority: drift_pkg.Value(priority),
                  isPinned: const drift_pkg.Value(false),
                  repeatIcalRrule: repeatIcalRrule == null
                      ? const drift_pkg.Value<String>.absent()
                      : drift_pkg.Value(repeatIcalRrule),
                  repeatFromCompletion: drift_pkg.Value(repeatFromCompletion),
                  seriesEnded: drift_pkg.Value(seriesEnded),
                  overridePrimaryValueId: drift_pkg.Value(
                    overridePrimaryValueId,
                  ),
                  overrideSecondaryValueId: drift_pkg.Value(
                    overrideSecondaryValueId,
                  ),
                  psMetadata: psMetadata == null
                      ? const drift_pkg.Value<String?>.absent()
                      : drift_pkg.Value(psMetadata),
                  createdAt: drift_pkg.Value(now),
                  updatedAt: drift_pkg.Value(now),
                ),
              );
        });
      },
      area: 'data.task',
      opName: 'create',
      context: context,
    );
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
    bool? seriesEnded,
    List<String>? valueIds,
    bool? isPinned,
    OperationContext? context,
  }) async {
    await FailureGuard.run(
      () async {
        final normalizedProjectId = switch (projectId?.trim()) {
          null || '' => null,
          final v => v,
        };
        talker.debug('[TaskRepository] update: id=$id, name="$name"');
        final existing = await (driftDb.select(
          driftDb.taskTable,
        )..where((t) => t.id.equals(id))).getSingleOrNull();
        if (existing == null) {
          talker.warning(
            '[TaskRepository] update failed: task not found id=$id',
          );
          throw RepositoryNotFoundException('No task found to update');
        }

        final now = DateTime.now();

        final normalizedStartDate = dateOnlyOrNull(startDate);
        final normalizedDeadlineDate = dateOnlyOrNull(deadlineDate);

        final nextPinned = !completed && (isPinned ?? existing.isPinned);
        final previousProjectId = existing.projectId;
        final projectChanged = normalizedProjectId != previousProjectId;

        List<String>? normalizedValueIds;
        if (valueIds != null) {
          final projectPrimaryValueId =
              normalizedProjectId == null || !_hasNonEmptyValueIds(valueIds)
              ? null
              : await _getProjectPrimaryValueId(normalizedProjectId);
          final valueValidation = TaskValuePolicy.validate(
            valueIds: valueIds,
            projectId: normalizedProjectId,
            projectPrimaryValueId: projectPrimaryValueId,
          );
          if (!valueValidation.isValid) {
            throw RepositoryValidationException(
              _taskValueValidationMessage(valueValidation.issues),
            );
          }
          normalizedValueIds = valueValidation.normalizedIds;
        }

        final overridePrimaryValueId = normalizedValueIds == null
            ? null
            : (normalizedValueIds.isEmpty ? null : normalizedValueIds.first);
        final overrideSecondaryValueId = normalizedValueIds == null
            ? null
            : (normalizedValueIds.length > 1 ? normalizedValueIds[1] : null);
        final clearOverrides = normalizedProjectId == null;

        final psMetadata = encodeCrudMetadata(context);

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
                  projectId: drift_pkg.Value(normalizedProjectId),
                  priority: drift_pkg.Value(priority),
                  myDaySnoozedUntilUtc: drift_pkg.Value(
                    existing.myDaySnoozedUntilUtc,
                  ),
                  isPinned: drift_pkg.Value(nextPinned),
                  repeatIcalRrule: repeatIcalRrule == null
                      ? const drift_pkg.Value<String>.absent()
                      : drift_pkg.Value(repeatIcalRrule),
                  repeatFromCompletion: repeatFromCompletion == null
                      ? drift_pkg.Value(existing.repeatFromCompletion)
                      : drift_pkg.Value(repeatFromCompletion),
                  seriesEnded: seriesEnded == null
                      ? drift_pkg.Value(existing.seriesEnded)
                      : drift_pkg.Value(seriesEnded),
                  overridePrimaryValueId:
                      normalizedValueIds == null && !clearOverrides
                      ? const drift_pkg.Value<String?>.absent()
                      : drift_pkg.Value(
                          clearOverrides ? null : overridePrimaryValueId,
                        ),
                  overrideSecondaryValueId:
                      normalizedValueIds == null && !clearOverrides
                      ? const drift_pkg.Value<String?>.absent()
                      : drift_pkg.Value(
                          clearOverrides ? null : overrideSecondaryValueId,
                        ),
                  psMetadata: psMetadata == null
                      ? const drift_pkg.Value<String?>.absent()
                      : drift_pkg.Value(psMetadata),
                  createdAt: drift_pkg.Value(existing.createdAt),
                  updatedAt: drift_pkg.Value(now),
                ),
              );

          if (projectChanged) {
            await _removeNextActionForTask(
              taskId: id,
              now: now,
              psMetadata: psMetadata,
            );
          }
        });
      },
      area: 'data.task',
      opName: 'update',
      context: context,
    );
  }

  @override
  Future<int> bulkRescheduleDeadlines({
    required Iterable<String> taskIds,
    required DateTime deadlineDate,
    OperationContext? context,
  }) async {
    final ids = taskIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (ids.isEmpty) return 0;

    return FailureGuard.run(
      () async {
        final normalizedDeadline = dateOnlyOrNull(deadlineDate);
        final now = DateTime.now();
        final psMetadata = encodeCrudMetadata(context);

        return driftDb.transaction(() async {
          final existingIds =
              await (driftDb.selectOnly(driftDb.taskTable)
                    ..addColumns([driftDb.taskTable.id])
                    ..where(driftDb.taskTable.id.isIn(ids)))
                  .map((row) => row.read(driftDb.taskTable.id)!)
                  .get();

          if (existingIds.length != ids.length) {
            throw RepositoryNotFoundException(
              'Some tasks were not found for bulk deadline update',
            );
          }

          final updated =
              await (driftDb.update(
                driftDb.taskTable,
              )..where((t) => t.id.isIn(ids))).write(
                TaskTableCompanion(
                  deadlineDate: drift_pkg.Value(normalizedDeadline),
                  updatedAt: drift_pkg.Value(now),
                  psMetadata: psMetadata == null
                      ? const drift_pkg.Value<String?>.absent()
                      : drift_pkg.Value(psMetadata),
                ),
              );

          if (updated != ids.length) {
            throw RepositoryException('Bulk task deadline update failed');
          }

          return updated;
        });
      },
      area: 'data.task',
      opName: 'bulk_update_deadline',
      context: context,
    );
  }

  @override
  Future<void> setPinned({
    required String id,
    required bool isPinned,
    OperationContext? context,
  }) async {
    await FailureGuard.run(
      () async {
        talker.debug('[TaskRepository] setPinned: id=$id, isPinned=$isPinned');
        final psMetadata = encodeCrudMetadata(context);
        await (driftDb.update(
          driftDb.taskTable,
        )..where((t) => t.id.equals(id))).write(
          TaskTableCompanion(
            isPinned: drift_pkg.Value(isPinned),
            psMetadata: psMetadata == null
                ? const drift_pkg.Value<String?>.absent()
                : drift_pkg.Value(psMetadata),
            updatedAt: drift_pkg.Value(DateTime.now()),
          ),
        );
      },
      area: 'data.task',
      opName: 'setPinned',
      context: context,
    );
  }

  @override
  Future<void> setMyDaySnoozedUntil({
    required String id,
    required DateTime? untilUtc,
    OperationContext? context,
  }) async {
    await FailureGuard.run(
      () async {
        talker.debug(
          '[TaskRepository] setMyDaySnoozedUntil: id=$id, untilUtc=$untilUtc',
        );

        final normalized = untilUtc?.toUtc();
        final psMetadata = encodeCrudMetadata(context);
        final now = DateTime.now();

        await driftDb.transaction(() async {
          await (driftDb.update(
            driftDb.taskTable,
          )..where((t) => t.id.equals(id))).write(
            TaskTableCompanion(
              myDaySnoozedUntilUtc: drift_pkg.Value(normalized),
              psMetadata: psMetadata == null
                  ? const drift_pkg.Value<String?>.absent()
                  : drift_pkg.Value(psMetadata),
              updatedAt: drift_pkg.Value(now),
            ),
          );

          if (normalized != null) {
            await driftDb
                .into(driftDb.taskSnoozeEventsTable)
                .insert(
                  TaskSnoozeEventsTableCompanion(
                    id: drift_pkg.Value(idGenerator.taskSnoozeEventId()),
                    taskId: drift_pkg.Value(id),
                    snoozedAt: drift_pkg.Value(now),
                    snoozedUntil: drift_pkg.Value(normalized),
                    createdAt: drift_pkg.Value(now),
                    updatedAt: drift_pkg.Value(now),
                    psMetadata: psMetadata == null
                        ? const drift_pkg.Value<String?>.absent()
                        : drift_pkg.Value(psMetadata),
                  ),
                  mode: drift_pkg.InsertMode.insert,
                );
          }
        });
      },
      area: 'data.task',
      opName: 'setMyDaySnoozedUntil',
      context: context,
    );
  }

  @override
  Future<Map<String, TaskSnoozeStats>> getSnoozeStats({
    required DateTime sinceUtc,
    required DateTime untilUtc,
  }) async {
    final rows =
        await (driftDb.select(driftDb.taskSnoozeEventsTable)..where(
              (row) =>
                  row.snoozedAt.isBiggerOrEqualValue(sinceUtc) &
                  row.snoozedAt.isSmallerOrEqualValue(untilUtc),
            ))
            .get();

    final stats = <String, TaskSnoozeStats>{};
    for (final row in rows) {
      final taskId = row.taskId;
      final current =
          stats[taskId] ??
          const TaskSnoozeStats(snoozeCount: 0, totalSnoozeDays: 0);

      final start = row.snoozedAt;
      final end = row.snoozedUntil ?? row.snoozedAt;
      final effectiveStart = start.isBefore(sinceUtc) ? sinceUtc : start;
      final effectiveEnd = end.isAfter(untilUtc) ? untilUtc : end;
      final duration = effectiveEnd.difference(effectiveStart);
      final snoozeDays = _ceilDays(duration);

      stats[taskId] = TaskSnoozeStats(
        snoozeCount: current.snoozeCount + 1,
        totalSnoozeDays: current.totalSnoozeDays + snoozeDays,
      );
    }

    return stats;
  }

  int _ceilDays(Duration duration) {
    if (duration.inMinutes <= 0) return 0;
    return (duration.inMinutes + 1439) ~/ 1440;
  }

  @override
  Future<void> delete(String id, {OperationContext? context}) async {
    await FailureGuard.run(
      () async {
        talker.debug('[TaskRepository] delete: id=$id');
        final now = DateTime.now();
        final psMetadata = encodeCrudMetadata(context);

        await driftDb.transaction(() async {
          await _removeNextActionForTask(
            taskId: id,
            now: now,
            psMetadata: psMetadata,
          );

          await driftDb
              .delete(driftDb.taskTable)
              .delete(TaskTableCompanion(id: drift_pkg.Value(id)));
        });
      },
      area: 'data.task',
      opName: 'delete',
      context: context,
    );
  }

  // ===========================================================================
  // OCCURRENCE METHODS
  // ===========================================================================

  @override
  Stream<List<CompletionHistoryData>> watchCompletionHistory() {
    return driftDb
        .select(driftDb.taskCompletionHistoryTable)
        .watch()
        .map((rows) => rows.map(toCompletionData).toList());
  }

  @override
  Stream<List<RecurrenceExceptionData>> watchRecurrenceExceptions() {
    return driftDb
        .select(driftDb.taskRecurrenceExceptionsTable)
        .watch()
        .map((rows) => rows.map(toExceptionData).toList());
  }

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
  Future<List<Task>> getOccurrencesForTask({
    required String taskId,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    final taskRows = await (driftDb.select(
      driftDb.taskTable,
    )..where((t) => t.id.equals(taskId))).get();
    final tasks = taskRows.map(taskFromTable).toList();

    final completionRows = await (driftDb.select(
      driftDb.taskCompletionHistoryTable,
    )..where((c) => c.taskId.equals(taskId))).get();
    final exceptionRows = await (driftDb.select(
      driftDb.taskRecurrenceExceptionsTable,
    )..where((e) => e.taskId.equals(taskId))).get();

    return occurrenceExpander.expandTaskOccurrencesSync(
      tasks: tasks,
      completions: completionRows.map(toCompletionData).toList(),
      exceptions: exceptionRows.map(toExceptionData).toList(),
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
    OperationContext? context,
  }) => occurrenceWriteHelper.completeTaskOccurrence(
    taskId: taskId,
    occurrenceDate: occurrenceDate,
    originalOccurrenceDate: originalOccurrenceDate,
    notes: notes,
    context: context,
  );

  @override
  Future<void> uncompleteOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    OperationContext? context,
  }) => occurrenceWriteHelper.uncompleteTaskOccurrence(
    taskId: taskId,
    occurrenceDate: occurrenceDate,
    context: context,
  );

  @override
  Future<void> skipOccurrence({
    required String taskId,
    required DateTime originalDate,
    OperationContext? context,
  }) => occurrenceWriteHelper.skipTaskOccurrence(
    taskId: taskId,
    originalDate: originalDate,
    context: context,
  );

  @override
  Future<void> rescheduleOccurrence({
    required String taskId,
    required DateTime originalDate,
    required DateTime newDate,
    DateTime? newDeadline,
    OperationContext? context,
  }) => occurrenceWriteHelper.rescheduleTaskOccurrence(
    taskId: taskId,
    originalDate: originalDate,
    newDate: newDate,
    newDeadline: newDeadline,
    context: context,
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
    if (query.shouldExpandOccurrences || query.hasOccurrencePreview) {
      throw UnsupportedError(
        'TaskRepository does not support occurrenceExpansion/occurrencePreview '
        'query flags. Use OccurrenceReadService (taskly_domain) for '
        'occurrence-aware reads.',
      );
    }

    // Start with base query
    final select = driftDb.select(driftDb.taskTable);

    select.where((t) {
      return whereExpressionFromFilter(query.filter, t) ??
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

    final projectPrimaryValueTable = driftDb.valueTable.createAlias(
      'project_primary_value',
    );
    final overridePrimaryValueTable = driftDb.valueTable.createAlias(
      'task_override_primary_value',
    );
    final overrideSecondaryValueTable = driftDb.valueTable.createAlias(
      'task_override_secondary_value',
    );

    // Build the join query - include task override slots AND project slots.
    final joinQuery = select.join([
      drift_pkg.leftOuterJoin(
        driftDb.projectTable,
        driftDb.taskTable.projectId.equalsExp(driftDb.projectTable.id),
      ),
      drift_pkg.leftOuterJoin(
        projectPrimaryValueTable,
        driftDb.projectTable.primaryValueId.equalsExp(
          projectPrimaryValueTable.id,
        ),
      ),
      drift_pkg.leftOuterJoin(
        overridePrimaryValueTable,
        driftDb.taskTable.overridePrimaryValueId.equalsExp(
          overridePrimaryValueTable.id,
        ),
      ),
      drift_pkg.leftOuterJoin(
        overrideSecondaryValueTable,
        driftDb.taskTable.overrideSecondaryValueId.equalsExp(
          overrideSecondaryValueTable.id,
        ),
      ),
    ]);

    // Map results to Task objects
    final baseTasksStream = joinQuery.watch().map((rows) {
      return TaskAggregation.fromRows(
        rows: rows,
        driftDb: driftDb,
        projectPrimaryValueTable: projectPrimaryValueTable,
        overridePrimaryValueTable: overridePrimaryValueTable,
        overrideSecondaryValueTable: overrideSecondaryValueTable,
      ).toTasks();
    });

    return baseTasksStream;
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

  Future<void> _removeNextActionForTask({
    required String taskId,
    required DateTime now,
    required String? psMetadata,
  }) async {
    final rows = await (driftDb.select(
      driftDb.projectNextActionsTable,
    )..where((t) => t.taskId.equals(taskId))).get();

    if (rows.isEmpty) return;

    final projectIds = rows.map((row) => row.projectId).toSet();

    await (driftDb.delete(
      driftDb.projectNextActionsTable,
    )..where((t) => t.taskId.equals(taskId))).go();

    for (final projectId in projectIds) {
      await _compactProjectNextActionRanks(
        projectId: projectId,
        now: now,
        psMetadata: psMetadata,
      );
    }
  }

  Future<void> _compactProjectNextActionRanks({
    required String projectId,
    required DateTime now,
    required String? psMetadata,
  }) async {
    final rows =
        await (driftDb.select(driftDb.projectNextActionsTable)
              ..where((t) => t.projectId.equals(projectId))
              ..orderBy([(t) => drift_pkg.OrderingTerm(expression: t.rank)]))
            .get();

    var nextRank = 1;
    for (final row in rows) {
      if (row.rank == nextRank) {
        nextRank += 1;
        continue;
      }

      await (driftDb.update(
        driftDb.projectNextActionsTable,
      )..where((t) => t.id.equals(row.id))).write(
        ProjectNextActionsTableCompanion(
          rank: drift_pkg.Value(nextRank),
          updatedAt: drift_pkg.Value(now),
          psMetadata: psMetadata == null
              ? const drift_pkg.Value.absent()
              : drift_pkg.Value(psMetadata),
        ),
      );
      nextRank += 1;
    }
  }
}
