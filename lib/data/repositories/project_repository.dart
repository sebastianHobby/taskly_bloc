import 'package:drift/drift.dart' as drift_pkg;
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/data/mappers/drift_to_domain.dart';
import 'package:taskly_bloc/data/repositories/mappers/project_predicate_mapper.dart';
import 'package:taskly_bloc/data/repositories/query_stream_cache.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
import 'package:taskly_bloc/data/repositories/repository_helpers.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/domain/interfaces/occurrence_stream_expander_contract.dart';
import 'package:taskly_bloc/domain/interfaces/occurrence_write_helper_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/filtering/evaluation_context.dart';
import 'package:taskly_bloc/domain/queries/project_filter_evaluator.dart';
import 'package:taskly_bloc/domain/queries/project_predicate.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';

class ProjectRepository implements ProjectRepositoryContract {
  ProjectRepository({
    required this.driftDb,
    required this.occurrenceExpander,
    required this.occurrenceWriteHelper,
    required this.idGenerator,
  }) : _predicateMapper = ProjectPredicateMapper(driftDb: driftDb);

  final AppDatabase driftDb;
  final OccurrenceStreamExpanderContract occurrenceExpander;
  final OccurrenceWriteHelperContract occurrenceWriteHelper;
  final IdGenerator idGenerator;
  final ProjectPredicateMapper _predicateMapper;

  // Shared streams using RxDart for efficient multi-subscriber support
  ValueStream<List<Project>>? _sharedProjectsWithRelated;

  final QueryStreamCache<ProjectQuery, List<Project>> _sharedWatchAllCache =
      QueryStreamCache(maxEntries: 16);

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
      _sharedProjectsWithRelated ??= _projectWithRelatedJoin().watch().map((
        rows,
      ) {
        return ProjectAggregation.fromRows(
          rows: rows,
          driftDb: driftDb,
        ).toProjects();
      }).shareValue();
      return _sharedProjectsWithRelated!;
    }

    // With query = use query-specific logic
    if (query.shouldExpandOccurrences) {
      return _buildAndExecuteQuery(query);
    }

    // Conservative policy: don't cache date-based queries by default.
    if (query.hasDateFilter) {
      return _projectWithRelatedJoin(filter: query.filter).watch().map((rows) {
        return ProjectAggregation.fromRows(
          rows: rows,
          driftDb: driftDb,
        ).toProjects();
      });
    }

    return _sharedWatchAllCache.getOrCreate(query, () {
      return _projectWithRelatedJoin(filter: query.filter).watch().map((rows) {
        return ProjectAggregation.fromRows(
          rows: rows,
          driftDb: driftDb,
        ).toProjects();
      });
    });
  }

  @override
  Future<List<Project>> getAll([ProjectQuery? query]) async {
    // No query = return all projects
    if (query == null) {
      final rows = await _projectWithRelatedJoin().get();
      return ProjectAggregation.fromRows(
        rows: rows,
        driftDb: driftDb,
      ).toProjects();
    }

    // With query = use query-specific logic
    if (query.shouldExpandOccurrences) {
      return _buildAndExecuteQuery(query).first;
    }

    final rows = await _projectWithRelatedJoin(filter: query.filter).get();
    return ProjectAggregation.fromRows(
      rows: rows,
      driftDb: driftDb,
    ).toProjects();
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
    final Stream<List<Project>> baseStream =
        _projectWithRelatedJoin(filter: sqlFilter).watch().map(
          (rows) => ProjectAggregation.fromRows(
            rows: rows,
            driftDb: driftDb,
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
  drift_pkg.JoinedSelectStatement<drift_pkg.HasResultSet, dynamic>
  _projectWithRelatedJoin({
    QueryFilter<ProjectPredicate>? filter,
  }) {
    final query = driftDb.select(driftDb.projectTable)
      ..orderBy([(p) => drift_pkg.OrderingTerm(expression: p.name)]);

    if (filter != null) {
      query.where((p) {
        final where = _whereExpressionFromFilter(filter, p);
        return where ?? const drift_pkg.Constant(true);
      });
    }

    return query.join([
      drift_pkg.leftOuterJoin(
        driftDb.projectValuesTable,
        driftDb.projectValuesTable.projectId.equalsExp(driftDb.projectTable.id),
      ),
      drift_pkg.leftOuterJoin(
        driftDb.valueTable,
        driftDb.projectValuesTable.valueId.equalsExp(driftDb.valueTable.id),
      ),
    ]);
  }

  @override
  Stream<Project?> watchById(String id) {
    final joined =
        (driftDb.select(
          driftDb.projectTable,
        )..where((p) => p.id.equals(id))).join([
          drift_pkg.leftOuterJoin(
            driftDb.projectValuesTable,
            driftDb.projectValuesTable.projectId.equalsExp(
              driftDb.projectTable.id,
            ),
          ),
          drift_pkg.leftOuterJoin(
            driftDb.valueTable,
            driftDb.projectValuesTable.valueId.equalsExp(driftDb.valueTable.id),
          ),
        ]);

    return joined.watch().map((rows) {
      return ProjectAggregation.fromRows(
        rows: rows,
        driftDb: driftDb,
      ).toSingleProject();
    });
  }

  @override
  Future<Project?> getById(String id) async {
    final joined =
        (driftDb.select(
          driftDb.projectTable,
        )..where((p) => p.id.equals(id))).join([
          drift_pkg.leftOuterJoin(
            driftDb.projectValuesTable,
            driftDb.projectValuesTable.projectId.equalsExp(
              driftDb.projectTable.id,
            ),
          ),
          drift_pkg.leftOuterJoin(
            driftDb.valueTable,
            driftDb.projectValuesTable.valueId.equalsExp(driftDb.valueTable.id),
          ),
        ]);

    final rows = await joined.get();
    return ProjectAggregation.fromRows(
      rows: rows,
      driftDb: driftDb,
    ).toSingleProject();
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
    List<String>? valueIds,
    int? priority,
  }) async {
    talker.debug('[ProjectRepository] create: name="$name"');

    if (valueIds == null || valueIds.isEmpty) {
      throw RepositoryValidationException(
        'Projects must have at least one value.',
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
          priority: drift_pkg.Value(priority),
          createdAt: drift_pkg.Value(now),
          updatedAt: drift_pkg.Value(now),
        ),
      );

      final primaryValueId = valueIds.first;
      for (final valueId in valueIds) {
        final projectValueId = idGenerator.projectValueId(
          projectId: id,
          valueId: valueId,
        );
        await driftDb
            .into(driftDb.projectValuesTable)
            .insert(
              ProjectValuesTableCompanion(
                id: drift_pkg.Value(projectValueId),
                projectId: drift_pkg.Value(id),
                valueId: drift_pkg.Value(valueId),
                isPrimary: drift_pkg.Value(valueId == primaryValueId),
              ),
            );
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
    String? repeatIcalRrule,
    bool? repeatFromCompletion,
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
          // Preserve seriesEnded - only modified via dedicated methods
          seriesEnded: const drift_pkg.Value<bool>.absent(),
          updatedAt: drift_pkg.Value(now),
        ),
      );

      if (valueIds != null) {
        await (driftDb.delete(
          driftDb.projectValuesTable,
        )..where((t) => t.projectId.equals(id))).go();

        final primaryValueId = valueIds.isEmpty ? null : valueIds.first;
        for (final valueId in valueIds) {
          final projectValueId = idGenerator.projectValueId(
            projectId: id,
            valueId: valueId,
          );
          await driftDb
              .into(driftDb.projectValuesTable)
              .insert(
                ProjectValuesTableCompanion(
                  id: drift_pkg.Value(projectValueId),
                  projectId: drift_pkg.Value(id),
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

  @override
  Future<void> updateLastReviewedAt({
    required String id,
    required DateTime reviewedAt,
  }) async {
    // TODO(attention-migration): This is now handled by AttentionResolutions table
    // The method is kept for interface compatibility but is a no-op
    talker.debug(
      '[ProjectRepository] updateLastReviewedAt: id=$id (no-op - migrated to AttentionResolutions)',
    );
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
