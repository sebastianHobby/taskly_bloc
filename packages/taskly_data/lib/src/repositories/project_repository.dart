import 'package:drift/drift.dart' as drift_pkg;
import 'package:rxdart/rxdart.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/src/id/id_generator.dart';
import 'package:taskly_data/src/mappers/drift_to_domain.dart';
import 'package:taskly_data/src/repositories/mappers/project_predicate_mapper.dart';
import 'package:taskly_data/src/repositories/query_stream_cache.dart';
import 'package:taskly_data/src/repositories/repository_exceptions.dart';
import 'package:taskly_data/src/repositories/repository_helpers.dart';
import 'package:taskly_domain/taskly_domain.dart';

class ProjectRepository implements ProjectRepositoryContract {
  ProjectRepository({
    required this.driftDb,
    required this.occurrenceExpander,
    required this.occurrenceWriteHelper,
    required this.idGenerator,
  }) : _predicateMapper = ProjectPredicateMapper(driftDb: driftDb);

  // Task counts are merged into Project domain objects. We intentionally keep
  // the project+values join separate from task counting to avoid join row
  // multiplication (projects with multiple values would otherwise distort
  // counts).

  final AppDatabase driftDb;
  final OccurrenceStreamExpanderContract occurrenceExpander;
  final OccurrenceWriteHelperContract occurrenceWriteHelper;
  final IdGenerator idGenerator;
  final ProjectPredicateMapper _predicateMapper;

  // Shared streams using RxDart for efficient multi-subscriber support
  ValueStream<List<Project>>? _sharedProjectsWithRelated;

  final QueryStreamCache<ProjectQuery, List<Project>> _sharedWatchAllCache =
      QueryStreamCache(maxEntries: 16);

  Stream<List<Project>> _attachTaskCounts(
    Stream<List<Project>> projectsStream,
  ) {
    return projectsStream.switchMap((projects) {
      if (projects.isEmpty) return Stream.value(const <Project>[]);
      final ids = projects.map((p) => p.id).toSet();
      return _watchTaskCountsForProjectIds(ids).map((countsById) {
        return projects
            .map((p) {
              final counts = countsById[p.id];
              return p.copyWith(
                taskCount: counts?.taskCount ?? 0,
                completedTaskCount: counts?.completedTaskCount ?? 0,
              );
            })
            .toList(growable: false);
      });
    });
  }

  Future<List<Project>> _mergeTaskCountsOnce(List<Project> projects) async {
    if (projects.isEmpty) return const <Project>[];
    final ids = projects.map((p) => p.id).toSet();
    final countsById = await _getTaskCountsForProjectIds(ids);
    return projects
        .map((p) {
          final counts = countsById[p.id];
          return p.copyWith(
            taskCount: counts?.taskCount ?? 0,
            completedTaskCount: counts?.completedTaskCount ?? 0,
          );
        })
        .toList(growable: false);
  }

  /// Task counts grouped by project ID.
  ///
  /// Used to hydrate [Project.taskCount] and [Project.completedTaskCount] for
  /// all project reads.
  Future<Map<String, _ProjectTaskCounts>> _getTaskCountsForProjectIds(
    Set<String> projectIds,
  ) async {
    if (projectIds.isEmpty) return const <String, _ProjectTaskCounts>{};
    final ids = projectIds.toList(growable: false);

    final totalCountExp = driftDb.taskTable.id.count();
    final totalStmt = driftDb.selectOnly(driftDb.taskTable)
      ..addColumns([driftDb.taskTable.projectId, totalCountExp])
      ..where(driftDb.taskTable.projectId.isIn(ids))
      ..groupBy([driftDb.taskTable.projectId]);

    final completedCountExp = driftDb.taskTable.id.count();
    final completedStmt = driftDb.selectOnly(driftDb.taskTable)
      ..addColumns([driftDb.taskTable.projectId, completedCountExp])
      ..where(driftDb.taskTable.projectId.isIn(ids))
      ..where(driftDb.taskTable.completed.equals(true))
      ..groupBy([driftDb.taskTable.projectId]);

    final totalRows = await totalStmt.get();
    final completedRows = await completedStmt.get();

    final totalById = <String, int>{};
    for (final row in totalRows) {
      final projectId = row.read(driftDb.taskTable.projectId);
      if (projectId == null) continue;
      totalById[projectId] = row.read(totalCountExp) ?? 0;
    }

    final completedById = <String, int>{};
    for (final row in completedRows) {
      final projectId = row.read(driftDb.taskTable.projectId);
      if (projectId == null) continue;
      completedById[projectId] = row.read(completedCountExp) ?? 0;
    }

    final result = <String, _ProjectTaskCounts>{};
    for (final id in ids) {
      result[id] = _ProjectTaskCounts(
        taskCount: totalById[id] ?? 0,
        completedTaskCount: completedById[id] ?? 0,
      );
    }

    return result;
  }

  Stream<Map<String, _ProjectTaskCounts>> _watchTaskCountsForProjectIds(
    Set<String> projectIds,
  ) {
    if (projectIds.isEmpty) {
      return Stream.value(const <String, _ProjectTaskCounts>{});
    }
    final ids = projectIds.toList(growable: false);

    final totalCountExp = driftDb.taskTable.id.count();
    final totalStmt = driftDb.selectOnly(driftDb.taskTable)
      ..addColumns([driftDb.taskTable.projectId, totalCountExp])
      ..where(driftDb.taskTable.projectId.isIn(ids))
      ..groupBy([driftDb.taskTable.projectId]);

    final completedCountExp = driftDb.taskTable.id.count();
    final completedStmt = driftDb.selectOnly(driftDb.taskTable)
      ..addColumns([driftDb.taskTable.projectId, completedCountExp])
      ..where(driftDb.taskTable.projectId.isIn(ids))
      ..where(driftDb.taskTable.completed.equals(true))
      ..groupBy([driftDb.taskTable.projectId]);

    final totalStream = totalStmt.watch().map((rows) {
      final totalById = <String, int>{};
      for (final row in rows) {
        final projectId = row.read(driftDb.taskTable.projectId);
        if (projectId == null) continue;
        totalById[projectId] = row.read(totalCountExp) ?? 0;
      }
      return totalById;
    });

    final completedStream = completedStmt.watch().map((rows) {
      final completedById = <String, int>{};
      for (final row in rows) {
        final projectId = row.read(driftDb.taskTable.projectId);
        if (projectId == null) continue;
        completedById[projectId] = row.read(completedCountExp) ?? 0;
      }
      return completedById;
    });

    return Rx.combineLatest2(
      totalStream,
      completedStream,
      (Map<String, int> totalById, Map<String, int> completedById) {
        final result = <String, _ProjectTaskCounts>{};
        for (final id in ids) {
          result[id] = _ProjectTaskCounts(
            taskCount: totalById[id] ?? 0,
            completedTaskCount: completedById[id] ?? 0,
          );
        }
        return result;
      },
    );
  }

  Future<ProjectTableData?> _getProjectById(String id) async {
    return driftDb.managers.projectTable
        .filter((f) => f.id.equals(id))
        .getSingleOrNull();
  }

  // Domain-aware read methods
  //
  // Uses RxDart shareValue() to share a single database query across
  // multiple subscribers. This eliminates duplicate queries and ensures
  // all blocs see consistent data.
  //
  // All methods always load related labels - domain model is always complete.
  @override
  Stream<List<Project>> watchAll([ProjectQuery? query]) {
    // No query = return shared stream for all projects
    if (query == null) {
      final join = _projectWithRelatedJoin();
      _sharedProjectsWithRelated ??= join.joined.watch().map((rows) {
        return ProjectAggregation.fromRows(
          rows: rows,
          driftDb: driftDb,
          primaryValueTable: join.primaryValueTable,
          secondaryValueTable: join.secondaryValueTable,
        ).toProjects();
      }).shareValue();
      return _attachTaskCounts(_sharedProjectsWithRelated!);
    }

    // With query = use query-specific logic
    if (query.shouldExpandOccurrences) {
      return _buildAndExecuteQuery(query);
    }

    // Conservative policy: don't cache date-based queries by default.
    if (query.hasDateFilter) {
      final join = _projectWithRelatedJoin(filter: query.filter);
      final base = join.joined.watch().map((rows) {
        return ProjectAggregation.fromRows(
          rows: rows,
          driftDb: driftDb,
          primaryValueTable: join.primaryValueTable,
          secondaryValueTable: join.secondaryValueTable,
        ).toProjects();
      });
      return _attachTaskCounts(base);
    }

    final base = _sharedWatchAllCache.getOrCreate(query, () {
      final join = _projectWithRelatedJoin(filter: query.filter);
      return join.joined.watch().map((rows) {
        return ProjectAggregation.fromRows(
          rows: rows,
          driftDb: driftDb,
          primaryValueTable: join.primaryValueTable,
          secondaryValueTable: join.secondaryValueTable,
        ).toProjects();
      });
    });

    return _attachTaskCounts(base);
  }

  @override
  Future<List<Project>> getAll([ProjectQuery? query]) async {
    // No query = return all projects
    if (query == null) {
      final join = _projectWithRelatedJoin();
      final rows = await join.joined.get();
      final projects = ProjectAggregation.fromRows(
        rows: rows,
        driftDb: driftDb,
        primaryValueTable: join.primaryValueTable,
        secondaryValueTable: join.secondaryValueTable,
      ).toProjects();

      return _mergeTaskCountsOnce(projects);
    }

    // With query = use query-specific logic
    if (query.shouldExpandOccurrences) {
      return _buildAndExecuteQuery(query).first;
    }

    final join = _projectWithRelatedJoin(filter: query.filter);
    final rows = await join.joined.get();
    final projects = ProjectAggregation.fromRows(
      rows: rows,
      driftDb: driftDb,
      primaryValueTable: join.primaryValueTable,
      secondaryValueTable: join.secondaryValueTable,
    ).toProjects();

    return _mergeTaskCountsOnce(projects);
  }

  @override
  Stream<int> watchAllCount([ProjectQuery? query]) {
    query ??= ProjectQuery.all();

    if (query.shouldExpandOccurrences) {
      return _buildAndExecuteQuery(
        query,
      ).map((items) => items.length).distinct();
    }

    final countExp = driftDb.projectTable.id.count();
    final statement = driftDb.selectOnly(driftDb.projectTable)
      ..addColumns([countExp]);

    final where = _whereExpressionFromFilter(
      query.filter,
      driftDb.projectTable,
    );
    if (where != null) statement.where(where);

    return statement
        .watchSingle()
        .map((row) => row.read(countExp) ?? 0)
        .distinct();
  }

  Stream<List<Project>> _buildAndExecuteQuery(ProjectQuery query) {
    final sqlFilter = query.shouldExpandOccurrences
        ? _removeDatePredicates(query.filter)
        : query.filter;

    // Always load with related labels - domain model is always complete
    final join = _projectWithRelatedJoin(filter: sqlFilter);
    final Stream<List<Project>> baseStream = join.joined.watch().map(
      (rows) => ProjectAggregation.fromRows(
        rows: rows,
        driftDb: driftDb,
        primaryValueTable: join.primaryValueTable,
        secondaryValueTable: join.secondaryValueTable,
      ).toProjects(),
    );

    if (!query.shouldExpandOccurrences) return baseStream;

    final expansion = query.occurrenceExpansion!;
    final completionsStream = driftDb
        .select(driftDb.projectCompletionHistoryTable)
        .watch()
        .map((rows) => rows.map(_toCompletionData).toList());
    final exceptionsStream = driftDb
        .select(driftDb.projectRecurrenceExceptionsTable)
        .watch()
        .map((rows) => rows.map(_toExceptionData).toList());

    final evaluator = ProjectFilterEvaluator();
    final ctx = EvaluationContext();

    return occurrenceExpander.expandProjectOccurrences(
      projectsStream: baseStream,
      completionsStream: completionsStream,
      exceptionsStream: exceptionsStream,
      rangeStart: expansion.rangeStart,
      rangeEnd: expansion.rangeEnd,
      postExpansionFilter: (p) => evaluator.matches(p, query.filter, ctx),
    );
  }

  QueryFilter<ProjectPredicate> _removeDatePredicates(
    QueryFilter<ProjectPredicate> filter,
  ) {
    return QueryFilter<ProjectPredicate>(
      shared: filter.shared
          .where((p) => p is! ProjectDatePredicate)
          .toList(
            growable: false,
          ),
      orGroups: filter.orGroups
          .map(
            (g) => g
                .where((p) => p is! ProjectDatePredicate)
                .toList(
                  growable: false,
                ),
          )
          .toList(growable: false),
    );
  }

  drift_pkg.Expression<bool>? _whereExpressionFromFilter(
    QueryFilter<ProjectPredicate> filter,
    $ProjectTableTable p,
  ) {
    return _predicateMapper.whereExpressionFromFilter(
      filter: filter,
      predicateToExpression: (pred) =>
          _predicateMapper.predicateToExpression(pred, p),
    );
  }

  /// Creates the standard join query for projects with labels.
  ({
    drift_pkg.JoinedSelectStatement<drift_pkg.HasResultSet, dynamic> joined,
    $ValueTableTable primaryValueTable,
    $ValueTableTable secondaryValueTable,
  })
  _projectWithRelatedJoin({
    QueryFilter<ProjectPredicate>? filter,
  }) {
    final query = driftDb.select(driftDb.projectTable)
      ..orderBy([(p) => drift_pkg.OrderingTerm(expression: p.name)]);

    final primaryValueTable = driftDb.valueTable.createAlias(
      'project_primary_value',
    );
    final secondaryValueTable = driftDb.valueTable.createAlias(
      'project_secondary_value',
    );

    if (filter != null) {
      query.where((p) {
        final where = _whereExpressionFromFilter(filter, p);
        return where ?? const drift_pkg.Constant(true);
      });
    }

    final joined = query.join([
      drift_pkg.leftOuterJoin(
        primaryValueTable,
        driftDb.projectTable.primaryValueId.equalsExp(primaryValueTable.id),
      ),
      drift_pkg.leftOuterJoin(
        secondaryValueTable,
        driftDb.projectTable.secondaryValueId.equalsExp(secondaryValueTable.id),
      ),
    ]);

    return (
      joined: joined,
      primaryValueTable: primaryValueTable,
      secondaryValueTable: secondaryValueTable,
    );
  }

  @override
  Stream<Project?> watchById(String id) {
    final primaryValueTable = driftDb.valueTable.createAlias(
      'project_primary_value',
    );
    final secondaryValueTable = driftDb.valueTable.createAlias(
      'project_secondary_value',
    );

    final joined =
        (driftDb.select(
          driftDb.projectTable,
        )..where((p) => p.id.equals(id))).join([
          drift_pkg.leftOuterJoin(
            primaryValueTable,
            driftDb.projectTable.primaryValueId.equalsExp(primaryValueTable.id),
          ),
          drift_pkg.leftOuterJoin(
            secondaryValueTable,
            driftDb.projectTable.secondaryValueId.equalsExp(
              secondaryValueTable.id,
            ),
          ),
        ]);

    final base = joined.watch().map((rows) {
      return ProjectAggregation.fromRows(
        rows: rows,
        driftDb: driftDb,
        primaryValueTable: primaryValueTable,
        secondaryValueTable: secondaryValueTable,
      ).toSingleProject();
    });

    return base.switchMap((project) {
      if (project == null) return Stream.value(null);
      return _watchTaskCountsForProjectIds({project.id}).map((countsById) {
        final counts = countsById[project.id];
        return project.copyWith(
          taskCount: counts?.taskCount ?? 0,
          completedTaskCount: counts?.completedTaskCount ?? 0,
        );
      });
    });
  }

  @override
  Future<Project?> getById(String id) async {
    final primaryValueTable = driftDb.valueTable.createAlias(
      'project_primary_value',
    );
    final secondaryValueTable = driftDb.valueTable.createAlias(
      'project_secondary_value',
    );

    final joined =
        (driftDb.select(
          driftDb.projectTable,
        )..where((p) => p.id.equals(id))).join([
          drift_pkg.leftOuterJoin(
            primaryValueTable,
            driftDb.projectTable.primaryValueId.equalsExp(primaryValueTable.id),
          ),
          drift_pkg.leftOuterJoin(
            secondaryValueTable,
            driftDb.projectTable.secondaryValueId.equalsExp(
              secondaryValueTable.id,
            ),
          ),
        ]);

    final rows = await joined.get();
    final project = ProjectAggregation.fromRows(
      rows: rows,
      driftDb: driftDb,
      primaryValueTable: primaryValueTable,
      secondaryValueTable: secondaryValueTable,
    ).toSingleProject();

    if (project == null) return null;
    final countsById = await _getTaskCountsForProjectIds({project.id});
    final counts = countsById[project.id];
    return project.copyWith(
      taskCount: counts?.taskCount ?? 0,
      completedTaskCount: counts?.completedTaskCount ?? 0,
    );
  }

  Future<void> _updateProject(ProjectTableCompanion updateCompanion) async {
    await driftDb.update(driftDb.projectTable).replace(updateCompanion);
  }

  Future<int> _deleteProject(ProjectTableCompanion deleteCompanion) async {
    return driftDb.delete(driftDb.projectTable).delete(deleteCompanion);
  }

  Future<int> _createProject(
    ProjectTableCompanion createCompanion,
  ) {
    return driftDb.into(driftDb.projectTable).insert(createCompanion);
  }

  @override
  Future<void> create({
    required String name,
    String? description,
    bool completed = false,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? repeatIcalRrule,
    bool repeatFromCompletion = false,
    bool seriesEnded = false,
    List<String>? valueIds,
    int? priority,
  }) async {
    talker.debug('[ProjectRepository] create: name="$name"');

    if (valueIds == null || valueIds.isEmpty) {
      throw RepositoryValidationException(
        'Projects must have at least one value.',
      );
    }

    final normalizedValueIds = valueIds.where((v) => v.isNotEmpty).toList();
    if (normalizedValueIds.isEmpty) {
      throw RepositoryValidationException(
        'Projects must have at least one value.',
      );
    }
    if (normalizedValueIds.length > 2) {
      throw RepositoryValidationException(
        'Projects may have at most two values (primary + optional secondary).',
      );
    }
    final primaryValueId = normalizedValueIds.first;
    final secondaryValueId = normalizedValueIds.length > 1
        ? normalizedValueIds[1]
        : null;

    if (secondaryValueId != null && secondaryValueId == primaryValueId) {
      throw RepositoryValidationException(
        'Secondary value must be different from primary value.',
      );
    }
    final now = DateTime.now();
    final id = idGenerator.projectId();

    final normalizedStartDate = dateOnlyOrNull(startDate);
    final normalizedDeadlineDate = dateOnlyOrNull(deadlineDate);

    await driftDb.transaction(() async {
      await _createProject(
        ProjectTableCompanion(
          id: drift_pkg.Value(id),
          name: drift_pkg.Value(name),
          description: drift_pkg.Value(description),
          completed: drift_pkg.Value(completed),
          startDate: drift_pkg.Value(normalizedStartDate),
          deadlineDate: drift_pkg.Value(normalizedDeadlineDate),
          repeatIcalRrule: drift_pkg.Value(repeatIcalRrule ?? ''),
          repeatFromCompletion: drift_pkg.Value(repeatFromCompletion),
          seriesEnded: drift_pkg.Value(seriesEnded),
          priority: drift_pkg.Value(priority),
          primaryValueId: drift_pkg.Value(primaryValueId),
          secondaryValueId: drift_pkg.Value(secondaryValueId),
          createdAt: drift_pkg.Value(now),
          updatedAt: drift_pkg.Value(now),
        ),
      );
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
    String? repeatIcalRrule,
    bool? repeatFromCompletion,
    bool? seriesEnded,
    List<String>? valueIds,
    int? priority,
    bool? isPinned,
  }) async {
    talker.debug('[ProjectRepository] update: id=$id, name="$name"');

    if (valueIds != null && valueIds.isEmpty) {
      throw RepositoryValidationException(
        'Projects must have at least one value.',
      );
    }

    List<String>? normalizedValueIds;
    if (valueIds != null) {
      normalizedValueIds = valueIds.where((v) => v.isNotEmpty).toList();
      if (normalizedValueIds.isEmpty) {
        throw RepositoryValidationException(
          'Projects must have at least one value.',
        );
      }
      if (normalizedValueIds.length > 2) {
        throw RepositoryValidationException(
          'Projects may have at most two values (primary + optional secondary).',
        );
      }
      if (normalizedValueIds.length == 2 &&
          normalizedValueIds[0] == normalizedValueIds[1]) {
        throw RepositoryValidationException(
          'Secondary value must be different from primary value.',
        );
      }
    }

    final existing = await _getProjectById(id);
    if (existing == null) {
      talker.warning(
        '[ProjectRepository] update failed: project not found id=$id',
      );
      throw RepositoryNotFoundException('No project found to update');
    }

    final now = DateTime.now();

    final normalizedStartDate = dateOnlyOrNull(startDate);
    final normalizedDeadlineDate = dateOnlyOrNull(deadlineDate);

    await driftDb.transaction(() async {
      await _updateProject(
        ProjectTableCompanion(
          id: drift_pkg.Value(id),
          name: drift_pkg.Value(name),
          description: drift_pkg.Value(description),
          completed: drift_pkg.Value(completed),
          startDate: drift_pkg.Value(normalizedStartDate),
          deadlineDate: drift_pkg.Value(normalizedDeadlineDate),
          repeatIcalRrule: repeatIcalRrule == null
              ? const drift_pkg.Value<String>.absent()
              : drift_pkg.Value(repeatIcalRrule),
          repeatFromCompletion: repeatFromCompletion == null
              ? const drift_pkg.Value<bool>.absent()
              : drift_pkg.Value(repeatFromCompletion),
          priority: drift_pkg.Value(priority),
          isPinned: isPinned == null
              ? drift_pkg.Value(existing.isPinned)
              : drift_pkg.Value(isPinned),
          seriesEnded: seriesEnded == null
              ? const drift_pkg.Value<bool>.absent()
              : drift_pkg.Value(seriesEnded),
          primaryValueId: normalizedValueIds == null
              ? const drift_pkg.Value<String?>.absent()
              : drift_pkg.Value(normalizedValueIds.first),
          secondaryValueId: normalizedValueIds == null
              ? const drift_pkg.Value<String?>.absent()
              : drift_pkg.Value(
                  normalizedValueIds.length > 1 ? normalizedValueIds[1] : null,
                ),
          updatedAt: drift_pkg.Value(now),
        ),
      );
    });
  }

  @override
  Future<void> setPinned({
    required String id,
    required bool isPinned,
  }) async {
    talker.debug('[ProjectRepository] setPinned: id=$id, isPinned=$isPinned');
    await (driftDb.update(
      driftDb.projectTable,
    )..where((t) => t.id.equals(id))).write(
      ProjectTableCompanion(
        isPinned: drift_pkg.Value(isPinned),
        updatedAt: drift_pkg.Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    talker.debug('[ProjectRepository] delete: id=$id');
    await _deleteProject(ProjectTableCompanion(id: drift_pkg.Value(id)));
  }

  // ===========================================================================
  // OCCURRENCE METHODS
  // ===========================================================================

  /// Converts [ProjectCompletionHistoryTableData] to [CompletionHistoryData].
  CompletionHistoryData _toCompletionData(
    ProjectCompletionHistoryTableData c,
  ) {
    return CompletionHistoryData(
      id: c.id,
      entityId: c.projectId,
      occurrenceDate: c.occurrenceDate,
      originalOccurrenceDate: c.originalOccurrenceDate,
      completedAt: c.completedAt,
      notes: c.notes,
    );
  }

  /// Converts [ProjectRecurrenceExceptionsTableData] to [RecurrenceExceptionData].
  RecurrenceExceptionData _toExceptionData(
    ProjectRecurrenceExceptionsTableData e,
  ) {
    return RecurrenceExceptionData(
      id: e.id,
      entityId: e.projectId,
      originalDate: e.originalDate,
      exceptionType: e.exceptionType == ExceptionType.skip
          ? RecurrenceExceptionType.skip
          : RecurrenceExceptionType.reschedule,
      newDate: e.newDate,
      newDeadline: e.newDeadline,
    );
  }

  @override
  Future<List<Project>> getOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    final projects = await driftDb.select(driftDb.projectTable).get();
    final completions = await driftDb
        .select(driftDb.projectCompletionHistoryTable)
        .get();
    final exceptions = await driftDb
        .select(driftDb.projectRecurrenceExceptionsTable)
        .get();

    return occurrenceExpander.expandProjectOccurrencesSync(
      projects: projects.map(projectFromTable).toList(),
      completions: completions.map(_toCompletionData).toList(),
      exceptions: exceptions.map(_toExceptionData).toList(),
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  }

  @override
  Stream<List<Project>> watchOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    return occurrenceExpander.expandProjectOccurrences(
      projectsStream: driftDb
          .select(driftDb.projectTable)
          .watch()
          .map((rows) => rows.map(projectFromTable).toList()),
      completionsStream: driftDb
          .select(driftDb.projectCompletionHistoryTable)
          .watch()
          .map((rows) => rows.map(_toCompletionData).toList()),
      exceptionsStream: driftDb
          .select(driftDb.projectRecurrenceExceptionsTable)
          .watch()
          .map((rows) => rows.map(_toExceptionData).toList()),
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  }

  @override
  Future<void> completeOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
  }) {
    return occurrenceWriteHelper.completeProjectOccurrence(
      projectId: projectId,
      occurrenceDate: occurrenceDate,
      originalOccurrenceDate: originalOccurrenceDate,
      notes: notes,
    );
  }

  @override
  Future<void> uncompleteOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
  }) {
    return occurrenceWriteHelper.uncompleteProjectOccurrence(
      projectId: projectId,
      occurrenceDate: occurrenceDate,
    );
  }

  @override
  Future<void> skipOccurrence({
    required String projectId,
    required DateTime originalDate,
  }) {
    return occurrenceWriteHelper.skipProjectOccurrence(
      projectId: projectId,
      originalDate: originalDate,
    );
  }

  @override
  Future<void> rescheduleOccurrence({
    required String projectId,
    required DateTime originalDate,
    required DateTime newDate,
    DateTime? newDeadline,
  }) {
    return occurrenceWriteHelper.rescheduleProjectOccurrence(
      projectId: projectId,
      originalDate: originalDate,
      newDate: newDate,
      newDeadline: newDeadline,
    );
  }

  Future<void> removeException({
    required String projectId,
    required DateTime originalDate,
  }) {
    return occurrenceWriteHelper.removeProjectException(
      projectId: projectId,
      originalDate: originalDate,
    );
  }

  Future<void> stopSeries(String projectId) {
    return occurrenceWriteHelper.stopProjectSeries(projectId);
  }

  Future<void> completeSeries(String projectId) {
    return occurrenceWriteHelper.completeProjectSeries(projectId);
  }

  Future<void> convertToOneTime(String projectId) {
    return occurrenceWriteHelper.convertProjectToOneTime(projectId);
  }
}

class _ProjectTaskCounts {
  const _ProjectTaskCounts({
    required this.taskCount,
    required this.completedTaskCount,
  });

  final int taskCount;
  final int completedTaskCount;
}
