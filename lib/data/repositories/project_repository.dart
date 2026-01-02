import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/data/mappers/drift_to_domain.dart';
import 'package:taskly_bloc/data/repositories/mappers/project_predicate_mapper.dart';
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
  ValueStream<List<Project>>? _sharedProjectsSimple;

  Stream<List<ProjectTableData>> get _projectStream => (driftDb.select(
    driftDb.projectTable,
  )..orderBy([(p) => OrderingTerm(expression: p.name)])).watch();

  Future<List<ProjectTableData>> get _projectList => (driftDb.select(
    driftDb.projectTable,
  )..orderBy([(p) => OrderingTerm(expression: p.name)])).get();

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
  @override
  Stream<List<Project>> watchAll({bool withRelated = false}) {
    if (!withRelated) {
      _sharedProjectsSimple ??= _projectStream
          .map((rows) => rows.map(projectFromTable).toList())
          .shareValue();
      return _sharedProjectsSimple!;
    }

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

  @override
  Stream<List<Project>> watchAllByQuery(
    ProjectQuery query, {
    bool withRelated = false,
  }) {
    if (query.shouldExpandOccurrences) {
      return _buildAndExecuteQuery(query, withRelated: withRelated);
    }

    if (!withRelated) {
      return _buildProjectSelectForQuery(query).watch().map(
        (rows) => rows.map(projectFromTable).toList(),
      );
    }

    return _projectWithRelatedJoin(filter: query.filter).watch().map((rows) {
      return ProjectAggregation.fromRows(
        rows: rows,
        driftDb: driftDb,
      ).toProjects();
    });
  }

  @override
  Future<List<Project>> getAllByQuery(
    ProjectQuery query, {
    bool withRelated = false,
  }) async {
    if (query.shouldExpandOccurrences) {
      return _buildAndExecuteQuery(query, withRelated: withRelated).first;
    }

    if (!withRelated) {
      final rows = await _buildProjectSelectForQuery(query).get();
      return rows.map(projectFromTable).toList();
    }

    final rows = await _projectWithRelatedJoin(filter: query.filter).get();
    return ProjectAggregation.fromRows(
      rows: rows,
      driftDb: driftDb,
    ).toProjects();
  }

  @override
  Future<int> count([ProjectQuery? query]) async {
    query ??= ProjectQuery.all();

    if (query.shouldExpandOccurrences) {
      return (await _buildAndExecuteQuery(
        query,
        withRelated: false,
      ).first).length;
    }

    final countExp = driftDb.projectTable.id.count();
    final statement = driftDb.selectOnly(driftDb.projectTable)
      ..addColumns([countExp]);

    final where = _whereExpressionFromFilter(
      query.filter,
      driftDb.projectTable,
    );
    if (where != null) statement.where(where);

    final row = await statement.getSingle();
    return row.read(countExp) ?? 0;
  }

  @override
  Stream<int> watchCount([ProjectQuery? query]) {
    query ??= ProjectQuery.all();

    if (query.shouldExpandOccurrences) {
      return _buildAndExecuteQuery(
        query,
        withRelated: false,
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

  Stream<List<Project>> _buildAndExecuteQuery(
    ProjectQuery query, {
    required bool withRelated,
  }) {
    final sqlFilter = query.shouldExpandOccurrences
        ? _removeDatePredicates(query.filter)
        : query.filter;

    Stream<List<Project>> baseStream;
    if (!withRelated) {
      baseStream = _buildProjectSelectForFilter(sqlFilter).watch().map(
        (rows) => rows.map(projectFromTable).toList(),
      );
    } else {
      baseStream = _projectWithRelatedJoin(filter: sqlFilter).watch().map(
        (rows) => ProjectAggregation.fromRows(
          rows: rows,
          driftDb: driftDb,
        ).toProjects(),
      );
    }

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

  SimpleSelectStatement<$ProjectTableTable, ProjectTableData>
  _buildProjectSelectForQuery(ProjectQuery query) {
    final sqlFilter = query.shouldExpandOccurrences
        ? _removeDatePredicates(query.filter)
        : query.filter;
    return _buildProjectSelectForFilter(sqlFilter);
  }

  SimpleSelectStatement<$ProjectTableTable, ProjectTableData>
  _buildProjectSelectForFilter(QueryFilter<ProjectPredicate> filter) {
    final select = driftDb.select(driftDb.projectTable);
    final where = _whereExpressionFromFilter(filter, driftDb.projectTable);
    if (where != null) select.where((_) => where);
    return select;
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

  Expression<bool>? _whereExpressionFromFilter(
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
  JoinedSelectStatement<HasResultSet, dynamic> _projectWithRelatedJoin({
    QueryFilter<ProjectPredicate>? filter,
  }) {
    final query = driftDb.select(driftDb.projectTable)
      ..orderBy([(p) => OrderingTerm(expression: p.name)]);

    if (filter != null) {
      query.where((p) {
        final where = _whereExpressionFromFilter(filter, p);
        return where ?? const Constant(true);
      });
    }

    return query.join([
      leftOuterJoin(
        driftDb.projectLabelsTable,
        driftDb.projectLabelsTable.projectId.equalsExp(driftDb.projectTable.id),
      ),
      leftOuterJoin(
        driftDb.labelTable,
        driftDb.projectLabelsTable.labelId.equalsExp(driftDb.labelTable.id),
      ),
    ]);
  }

  @override
  Future<List<Project>> getAll({bool withRelated = false}) async {
    if (!withRelated) {
      return (await _projectList).map(projectFromTable).toList();
    }

    final rows = await _projectWithRelatedJoin().get();
    return ProjectAggregation.fromRows(
      rows: rows,
      driftDb: driftDb,
    ).toProjects();
  }

  @override
  Stream<Project?> watchById(String id, {bool withRelated = false}) {
    if (!withRelated) {
      return (driftDb.select(driftDb.projectTable)
            ..where((p) => p.id.equals(id)))
          .watch()
          .map((rows) => rows.isEmpty ? null : projectFromTable(rows.first));
    }

    final joined =
        (driftDb.select(
          driftDb.projectTable,
        )..where((p) => p.id.equals(id))).join([
          leftOuterJoin(
            driftDb.projectLabelsTable,
            driftDb.projectLabelsTable.projectId.equalsExp(
              driftDb.projectTable.id,
            ),
          ),
          leftOuterJoin(
            driftDb.labelTable,
            driftDb.projectLabelsTable.labelId.equalsExp(driftDb.labelTable.id),
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
  Future<Project?> getById(String id, {bool withRelated = false}) async {
    if (!withRelated) {
      final data = await _getProjectById(id);
      return data == null ? null : projectFromTable(data);
    }

    final joined =
        (driftDb.select(
          driftDb.projectTable,
        )..where((p) => p.id.equals(id))).join([
          leftOuterJoin(
            driftDb.projectLabelsTable,
            driftDb.projectLabelsTable.projectId.equalsExp(
              driftDb.projectTable.id,
            ),
          ),
          leftOuterJoin(
            driftDb.labelTable,
            driftDb.projectLabelsTable.labelId.equalsExp(driftDb.labelTable.id),
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
    List<String>? labelIds,
    int? priority,
  }) async {
    talker.debug('[ProjectRepository] create: name="$name"');
    final now = DateTime.now();
    final id = idGenerator.projectId();

    final normalizedStartDate = dateOnlyOrNull(startDate);
    final normalizedDeadlineDate = dateOnlyOrNull(deadlineDate);

    final uniqueLabelIds = labelIds?.toSet().toList(growable: false);

    await driftDb.transaction(() async {
      await _createProject(
        ProjectTableCompanion(
          id: Value(id),
          name: Value(name),
          description: Value(description),
          completed: Value(completed),
          startDate: Value(normalizedStartDate),
          deadlineDate: Value(normalizedDeadlineDate),
          repeatIcalRrule: Value(repeatIcalRrule ?? ''),
          repeatFromCompletion: Value(repeatFromCompletion),
          priority: Value(priority),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      if (uniqueLabelIds != null) {
        for (final labelId in uniqueLabelIds) {
          // Generate deterministic v5 ID for junction
          final junctionId = idGenerator.projectLabelId(
            projectId: id,
            labelId: labelId,
          );
          await driftDb
              .into(driftDb.projectLabelsTable)
              .insert(
                ProjectLabelsTableCompanion(
                  id: Value(junctionId),
                  projectId: Value(id),
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
    String? repeatIcalRrule,
    bool? repeatFromCompletion,
    List<String>? labelIds,
    int? priority,
  }) async {
    talker.debug('[ProjectRepository] update: id=$id, name="$name"');
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

    final uniqueLabelIds = labelIds?.toSet().toList(growable: false);

    await driftDb.transaction(() async {
      await _updateProject(
        ProjectTableCompanion(
          id: Value(id),
          name: Value(name),
          description: Value(description),
          completed: Value(completed),
          startDate: Value(normalizedStartDate),
          deadlineDate: Value(normalizedDeadlineDate),
          repeatIcalRrule: repeatIcalRrule == null
              ? Value.absent()
              : Value(repeatIcalRrule),
          repeatFromCompletion: repeatFromCompletion == null
              ? Value.absent()
              : Value(repeatFromCompletion),
          priority: Value(priority),
          // Preserve seriesEnded - only modified via dedicated methods
          seriesEnded: Value.absent(),
          updatedAt: Value(now),
        ),
      );

      if (uniqueLabelIds != null) {
        final requested = uniqueLabelIds.toSet();
        final existing =
            (await (driftDb.select(
                  driftDb.projectLabelsTable,
                )..where((t) => t.projectId.equals(id))).get())
                .map((r) => r.labelId)
                .toSet();

        if (requested.length != existing.length ||
            !existing.containsAll(requested)) {
          await (driftDb.delete(
            driftDb.projectLabelsTable,
          )..where((t) => t.projectId.equals(id))).go();

          for (final labelId in uniqueLabelIds) {
            await driftDb
                .into(driftDb.projectLabelsTable)
                .insert(
                  ProjectLabelsTableCompanion(
                    projectId: Value(id),
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
    talker.debug('[ProjectRepository] delete: id=$id');
    await _deleteProject(ProjectTableCompanion(id: Value(id)));
  }

  @override
  Future<void> updateLastReviewedAt({
    required String id,
    required DateTime reviewedAt,
  }) async {
    talker.debug('[ProjectRepository] updateLastReviewedAt: id=$id');
    final existing = await _getProjectById(id);
    if (existing == null) {
      talker.warning(
        '[ProjectRepository] updateLastReviewedAt failed: project not found id=$id',
      );
      throw RepositoryNotFoundException('No project found to update');
    }

    await (driftDb.update(
      driftDb.projectTable,
    )..where((p) => p.id.equals(id))).write(
      ProjectTableCompanion(
        lastReviewedAt: Value(reviewedAt),
        updatedAt: Value(DateTime.now()),
      ),
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
