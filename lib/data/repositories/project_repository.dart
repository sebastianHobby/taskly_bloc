import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart' show uuid;
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/data/mappers/drift_to_domain.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';

class ProjectRepository implements ProjectRepositoryContract {
  ProjectRepository({required this.driftDb});
  final AppDatabase driftDb;

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
  @override
  Stream<List<Project>> watchAll({bool withRelated = false}) {
    if (!withRelated) {
      return _projectStream.map((rows) => rows.map(projectFromTable).toList());
    }

    final joined =
        (driftDb.select(
          driftDb.projectTable,
        )..orderBy([(p) => OrderingTerm(expression: p.name)])).join([
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
      final Map<String, ProjectTableData> projectsById = {};
      final Map<String, Map<String, LabelTableData>> labelsByProject = {};

      for (final row in rows) {
        final project = row.readTable(driftDb.projectTable);
        final id = project.id;

        projectsById.putIfAbsent(id, () => project);

        final label = row.readTableOrNull(driftDb.labelTable);
        if (label != null) {
          labelsByProject
              .putIfAbsent(id, () => <String, LabelTableData>{})
              .putIfAbsent(label.id, () => label);
        }
      }

      final results = <Project>[];
      for (final entry in projectsById.entries) {
        final id = entry.key;
        final labelTableList =
            (labelsByProject[id]?.values.toList() ?? <LabelTableData>[])
              ..sort((a, b) => a.name.compareTo(b.name));

        final labels = labelTableList.map(labelFromTable).toList();

        results.add(
          projectFromTable(entry.value, labels: labels),
        );
      }

      return results;
    });
  }

  @override
  Future<List<Project>> getAll({bool withRelated = false}) async {
    if (!withRelated) {
      return (await _projectList).map(projectFromTable).toList();
    }

    // For snapshot queries we perform a join similar to the watch path.
    final joined =
        (driftDb.select(
          driftDb.projectTable,
        )..orderBy([(p) => OrderingTerm(expression: p.name)])).join([
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

    final Map<String, ProjectTableData> projectsById = {};
    final Map<String, Map<String, LabelTableData>> labelsByProject = {};

    for (final row in rows) {
      final project = row.readTable(driftDb.projectTable);
      final id = project.id;

      projectsById.putIfAbsent(id, () => project);

      final label = row.readTableOrNull(driftDb.labelTable);
      if (label != null) {
        labelsByProject
            .putIfAbsent(id, () => <String, LabelTableData>{})
            .putIfAbsent(label.id, () => label);
      }
    }

    final results = <Project>[];
    for (final entry in projectsById.entries) {
      final id = entry.key;
      final labelTableList =
          (labelsByProject[id]?.values.toList() ?? <LabelTableData>[])
            ..sort((a, b) => a.name.compareTo(b.name));

      final labels = labelTableList.map(labelFromTable).toList();

      results.add(
        projectFromTable(entry.value, labels: labels),
      );
    }

    return results;
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
      if (rows.isEmpty) return null;

      ProjectTableData? project;
      final Map<String, LabelTableData> labelMap = {};

      for (final row in rows) {
        project ??= row.readTable(driftDb.projectTable);

        final labLink = row.readTableOrNull(driftDb.projectLabelsTable);
        final label = row.readTableOrNull(driftDb.labelTable);
        if (label != null && labLink != null) {
          labelMap.putIfAbsent(label.id, () => label);
        }
      }

      final labelTableList = labelMap.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      final labels = labelTableList.map(labelFromTable).toList();

      return projectFromTable(project!, labels: labels);
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
    if (rows.isEmpty) return null;

    ProjectTableData? project;
    final Map<String, LabelTableData> labelMap = {};

    for (final row in rows) {
      project ??= row.readTable(driftDb.projectTable);

      final labLink = row.readTableOrNull(driftDb.projectLabelsTable);
      final label = row.readTableOrNull(driftDb.labelTable);
      if (label != null && labLink != null) {
        labelMap.putIfAbsent(label.id, () => label);
      }
    }

    final labelTableList = labelMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final labels = labelTableList.map(labelFromTable).toList();

    return projectFromTable(project!, labels: labels);
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
}
