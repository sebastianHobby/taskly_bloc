import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart' show uuid;
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/mappers/drift_to_domain.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
import 'package:taskly_bloc/data/repositories/repository_helpers.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/domain/contracts/occurrence_stream_expander_contract.dart';
import 'package:taskly_bloc/domain/contracts/occurrence_write_helper_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/filtering/evaluation_context.dart';
import 'package:taskly_bloc/domain/queries/project_filter_evaluator.dart';
import 'package:taskly_bloc/domain/queries/project_predicate.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart'
    show BoolOperator, DateOperator, LabelOperator, RelativeComparison;

class ProjectRepository implements ProjectRepositoryContract {
  ProjectRepository({
    required this.driftDb,
    required this.occurrenceExpander,
    required this.occurrenceWriteHelper,
  });
  final AppDatabase driftDb;
  final OccurrenceStreamExpanderContract occurrenceExpander;
  final OccurrenceWriteHelperContract occurrenceWriteHelper;

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
    final terms = filter.toDnfTerms();
    if (terms.isEmpty) return null;

    Expression<bool> andTerm(List<ProjectPredicate> predicates) {
      if (predicates.isEmpty) return const Constant(true);
      return predicates
          .map((pred) => _predicateToExpression(pred, p))
          .reduce((a, b) => a & b);
    }

    final exprs = terms.map(andTerm).toList(growable: false);
    return exprs.reduce((a, b) => a | b);
  }

  Expression<bool> _predicateToExpression(
    ProjectPredicate predicate,
    $ProjectTableTable p,
  ) {
    return switch (predicate) {
      ProjectBoolPredicate() => _boolPredicateToExpression(predicate, p),
      ProjectDatePredicate() => _datePredicateToExpression(predicate, p),
      ProjectLabelPredicate() => _labelPredicateToExpression(predicate, p),
    };
  }

  Expression<bool> _boolPredicateToExpression(
    ProjectBoolPredicate predicate,
    $ProjectTableTable p,
  ) {
    final column = switch (predicate.field) {
      ProjectBoolField.completed => p.completed,
    };

    return switch (predicate.operator) {
      BoolOperator.isTrue => column.equals(true),
      BoolOperator.isFalse => column.equals(false),
    };
  }

  Expression<bool> _datePredicateToExpression(
    ProjectDatePredicate predicate,
    $ProjectTableTable p,
  ) {
    if (predicate.field == ProjectDateField.completedAt) {
      return _completedAtDatePredicateToExpression(predicate, p);
    }

    final dynamic column = switch (predicate.field) {
      ProjectDateField.startDate => p.startDate,
      ProjectDateField.deadlineDate => p.deadlineDate,
      ProjectDateField.createdAt => p.createdAt,
      ProjectDateField.updatedAt => p.updatedAt,
      ProjectDateField.completedAt => p.updatedAt,
    };

    if (predicate.operator == DateOperator.relative) {
      final comp = predicate.relativeComparison;
      final days = predicate.relativeDays;
      if (comp == null || days == null) return const Constant(false);

      final pivot = _relativeToAbsolute(days);
      return (switch (comp) {
            RelativeComparison.on => column.equals(pivot),
            RelativeComparison.before => column.isSmallerThanValue(pivot),
            RelativeComparison.after => column.isBiggerThanValue(pivot),
            RelativeComparison.onOrAfter => column.isBiggerOrEqualValue(pivot),
            RelativeComparison.onOrBefore => column.isSmallerOrEqualValue(
              pivot,
            ),
          })
          as Expression<bool>;
    }

    final date = predicate.date;
    final start = predicate.startDate;
    final end = predicate.endDate;

    return (switch (predicate.operator) {
          DateOperator.onOrAfter => column.isBiggerOrEqualValue(date!),
          DateOperator.onOrBefore => column.isSmallerOrEqualValue(date!),
          DateOperator.before => column.isSmallerThanValue(date!),
          DateOperator.after => column.isBiggerThanValue(date!),
          DateOperator.on => column.equals(date!),
          DateOperator.between => column.isBetweenValues(start!, end!),
          DateOperator.isNull => column.isNull(),
          DateOperator.isNotNull => column.isNotNull(),
          DateOperator.relative => const Constant(false),
        })
        as Expression<bool>;
  }

  Expression<bool> _completedAtDatePredicateToExpression(
    ProjectDatePredicate predicate,
    $ProjectTableTable p,
  ) {
    final history = driftDb.projectCompletionHistoryTable;

    if (predicate.operator == DateOperator.relative) {
      final comp = predicate.relativeComparison;
      final days = predicate.relativeDays;
      if (comp == null || days == null) return const Constant(false);

      final absoluteDate = _relativeToAbsolute(days);
      return switch (comp) {
        RelativeComparison.on => existsQuery(
          driftDb.selectOnly(history)
            ..addColumns([history.projectId])
            ..where(history.projectId.equalsExp(p.id))
            ..where(history.completedAt.equals(absoluteDate)),
        ),
        RelativeComparison.before => existsQuery(
          driftDb.selectOnly(history)
            ..addColumns([history.projectId])
            ..where(history.projectId.equalsExp(p.id))
            ..where(history.completedAt.isSmallerThanValue(absoluteDate)),
        ),
        RelativeComparison.after => existsQuery(
          driftDb.selectOnly(history)
            ..addColumns([history.projectId])
            ..where(history.projectId.equalsExp(p.id))
            ..where(history.completedAt.isBiggerThanValue(absoluteDate)),
        ),
        RelativeComparison.onOrAfter => existsQuery(
          driftDb.selectOnly(history)
            ..addColumns([history.projectId])
            ..where(history.projectId.equalsExp(p.id))
            ..where(
              history.completedAt.isBiggerOrEqualValue(absoluteDate),
            ),
        ),
        RelativeComparison.onOrBefore => existsQuery(
          driftDb.selectOnly(history)
            ..addColumns([history.projectId])
            ..where(history.projectId.equalsExp(p.id))
            ..where(
              history.completedAt.isSmallerOrEqualValue(absoluteDate),
            ),
        ),
      };
    }

    final absoluteDate = predicate.date;
    final absoluteStart = predicate.startDate;
    final absoluteEnd = predicate.endDate;

    return switch (predicate.operator) {
      DateOperator.onOrAfter => existsQuery(
        driftDb.selectOnly(history)
          ..addColumns([history.projectId])
          ..where(history.projectId.equalsExp(p.id))
          ..where(history.completedAt.isBiggerOrEqualValue(absoluteDate!)),
      ),
      DateOperator.onOrBefore => existsQuery(
        driftDb.selectOnly(history)
          ..addColumns([history.projectId])
          ..where(history.projectId.equalsExp(p.id))
          ..where(history.completedAt.isSmallerOrEqualValue(absoluteDate!)),
      ),
      DateOperator.before => existsQuery(
        driftDb.selectOnly(history)
          ..addColumns([history.projectId])
          ..where(history.projectId.equalsExp(p.id))
          ..where(history.completedAt.isSmallerThanValue(absoluteDate!)),
      ),
      DateOperator.after => existsQuery(
        driftDb.selectOnly(history)
          ..addColumns([history.projectId])
          ..where(history.projectId.equalsExp(p.id))
          ..where(history.completedAt.isBiggerThanValue(absoluteDate!)),
      ),
      DateOperator.on => existsQuery(
        driftDb.selectOnly(history)
          ..addColumns([history.projectId])
          ..where(history.projectId.equalsExp(p.id))
          ..where(history.completedAt.equals(absoluteDate!)),
      ),
      DateOperator.between => existsQuery(
        driftDb.selectOnly(history)
          ..addColumns([history.projectId])
          ..where(history.projectId.equalsExp(p.id))
          ..where(
            history.completedAt.isBetweenValues(absoluteStart!, absoluteEnd!),
          ),
      ),
      DateOperator.isNull => notExistsQuery(
        driftDb.selectOnly(history)
          ..addColumns([history.projectId])
          ..where(history.projectId.equalsExp(p.id)),
      ),
      DateOperator.isNotNull => existsQuery(
        driftDb.selectOnly(history)
          ..addColumns([history.projectId])
          ..where(history.projectId.equalsExp(p.id)),
      ),
      DateOperator.relative => const Constant(false),
    };
  }

  Expression<bool> _labelPredicateToExpression(
    ProjectLabelPredicate predicate,
    $ProjectTableTable p,
  ) {
    return switch (predicate.operator) {
      LabelOperator.hasAny => existsQuery(
        driftDb.selectOnly(driftDb.projectLabelsTable)
          ..addColumns([driftDb.projectLabelsTable.projectId])
          ..where(driftDb.projectLabelsTable.projectId.equalsExp(p.id))
          ..where(
            driftDb.projectLabelsTable.labelId.isIn(predicate.labelIds),
          ),
      ),
      LabelOperator.hasAll => existsQuery(
        driftDb.selectOnly(driftDb.projectLabelsTable)
          ..addColumns([driftDb.projectLabelsTable.projectId])
          ..where(driftDb.projectLabelsTable.projectId.equalsExp(p.id))
          ..where(
            driftDb.projectLabelsTable.labelId.isIn(predicate.labelIds),
          )
          ..groupBy([driftDb.projectLabelsTable.projectId]),
      ),
      LabelOperator.isNull => notExistsQuery(
        driftDb.selectOnly(driftDb.projectLabelsTable)
          ..addColumns([driftDb.projectLabelsTable.projectId])
          ..where(driftDb.projectLabelsTable.projectId.equalsExp(p.id)),
      ),
      LabelOperator.isNotNull => existsQuery(
        driftDb.selectOnly(driftDb.projectLabelsTable)
          ..addColumns([driftDb.projectLabelsTable.projectId])
          ..where(driftDb.projectLabelsTable.projectId.equalsExp(p.id)),
      ),
    };
  }

  DateTime _relativeToAbsolute(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: days));
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
  Stream<Project?> watch(String id, {bool withRelated = false}) {
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
  Future<Project?> get(String id, {bool withRelated = false}) async {
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
  }) async {
    final now = DateTime.now();
    final id = uuid.v4();

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
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      if (uniqueLabelIds != null) {
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
  }) async {
    final existing = await _getProjectById(id);
    if (existing == null) {
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
    await _deleteProject(ProjectTableCompanion(id: Value(id)));
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

  @override
  Future<void> removeException({
    required String projectId,
    required DateTime originalDate,
  }) {
    return occurrenceWriteHelper.removeProjectException(
      projectId: projectId,
      originalDate: originalDate,
    );
  }

  @override
  Future<void> stopSeries(String projectId) {
    return occurrenceWriteHelper.stopProjectSeries(projectId);
  }

  @override
  Future<void> completeSeries(String projectId) {
    return occurrenceWriteHelper.completeProjectSeries(projectId);
  }

  @override
  Future<void> convertToOneTime(String projectId) {
    return occurrenceWriteHelper.convertProjectToOneTime(projectId);
  }
}
