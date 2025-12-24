import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart' show uuid;
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/mappers/drift_to_domain.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/domain/contracts/occurrence_stream_expander_contract.dart';
import 'package:taskly_bloc/domain/contracts/occurrence_write_helper_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/domain.dart';

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

  /// Creates the standard join query for projects with labels.
  JoinedSelectStatement<HasResultSet, dynamic> _projectWithRelatedJoin({
    Expression<bool>? where,
  }) {
    final query = driftDb.select(driftDb.projectTable)
      ..orderBy([(p) => OrderingTerm(expression: p.name)]);

    if (where != null) {
      query.where((p) => where);
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
