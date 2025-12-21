import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart' show uuid;
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/data/mappers/drift_to_domain.dart';

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
            driftDb.projectValuesLinkTable,
            driftDb.projectValuesLinkTable.projectId.equalsExp(
              driftDb.projectTable.id,
            ),
          ),
          leftOuterJoin(
            driftDb.valueTable,
            driftDb.projectValuesLinkTable.valueId.equalsExp(
              driftDb.valueTable.id,
            ),
          ),
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
      final Map<String, Map<String, ValueTableData>> valuesByProject = {};
      final Map<String, Map<String, LabelTableData>> labelsByProject = {};

      for (final row in rows) {
        final project = row.readTable(driftDb.projectTable);
        final id = project.id;

        projectsById.putIfAbsent(id, () => project);

        final value = row.readTableOrNull(driftDb.valueTable);
        if (value != null) {
          valuesByProject
              .putIfAbsent(id, () => <String, ValueTableData>{})
              .putIfAbsent(value.id, () => value);
        }

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
        final valueTableList =
            (valuesByProject[id]?.values.toList() ?? <ValueTableData>[])
              ..sort((a, b) => a.name.compareTo(b.name));
        final labelTableList =
            (labelsByProject[id]?.values.toList() ?? <LabelTableData>[])
              ..sort((a, b) => a.name.compareTo(b.name));

        final values = valueTableList.map(valueFromTable).toList();
        final labels = labelTableList.map(labelFromTable).toList();

        results.add(
          projectFromTable(entry.value, values: values, labels: labels),
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
            driftDb.projectValuesLinkTable,
            driftDb.projectValuesLinkTable.projectId.equalsExp(
              driftDb.projectTable.id,
            ),
          ),
          leftOuterJoin(
            driftDb.valueTable,
            driftDb.projectValuesLinkTable.valueId.equalsExp(
              driftDb.valueTable.id,
            ),
          ),
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
    final Map<String, Map<String, ValueTableData>> valuesByProject = {};
    final Map<String, Map<String, LabelTableData>> labelsByProject = {};

    for (final row in rows) {
      final project = row.readTable(driftDb.projectTable);
      final id = project.id;

      projectsById.putIfAbsent(id, () => project);

      final value = row.readTableOrNull(driftDb.valueTable);
      if (value != null) {
        valuesByProject
            .putIfAbsent(id, () => <String, ValueTableData>{})
            .putIfAbsent(value.id, () => value);
      }

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
      final valueTableList =
          (valuesByProject[id]?.values.toList() ?? <ValueTableData>[])
            ..sort((a, b) => a.name.compareTo(b.name));
      final labelTableList =
          (labelsByProject[id]?.values.toList() ?? <LabelTableData>[])
            ..sort((a, b) => a.name.compareTo(b.name));

      final values = valueTableList.map(valueFromTable).toList();
      final labels = labelTableList.map(labelFromTable).toList();

      results.add(
        projectFromTable(entry.value, values: values, labels: labels),
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
            driftDb.projectValuesLinkTable,
            driftDb.projectValuesLinkTable.projectId.equalsExp(
              driftDb.projectTable.id,
            ),
          ),
          leftOuterJoin(
            driftDb.valueTable,
            driftDb.projectValuesLinkTable.valueId.equalsExp(
              driftDb.valueTable.id,
            ),
          ),
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
      final Map<String, ValueTableData> valueMap = {};

      for (final row in rows) {
        project ??= row.readTable(driftDb.projectTable);

        final valLink = row.readTableOrNull(driftDb.projectValuesLinkTable);
        final value = row.readTableOrNull(driftDb.valueTable);
        if (value != null && valLink != null) {
          valueMap.putIfAbsent(value.id, () => value);
        }

        final labLink = row.readTableOrNull(driftDb.projectLabelsTable);
        final label = row.readTableOrNull(driftDb.labelTable);
        if (label != null && labLink != null) {
          labelMap.putIfAbsent(label.id, () => label);
        }
      }

      final labelTableList = labelMap.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      final valueTableList = valueMap.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      final labels = labelTableList.map(labelFromTable).toList();
      final values = valueTableList.map(valueFromTable).toList();

      return projectFromTable(project!, values: values, labels: labels);
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
            driftDb.projectValuesLinkTable,
            driftDb.projectValuesLinkTable.projectId.equalsExp(
              driftDb.projectTable.id,
            ),
          ),
          leftOuterJoin(
            driftDb.valueTable,
            driftDb.projectValuesLinkTable.valueId.equalsExp(
              driftDb.valueTable.id,
            ),
          ),
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
    final Map<String, ValueTableData> valueMap = {};

    for (final row in rows) {
      project ??= row.readTable(driftDb.projectTable);

      final valLink = row.readTableOrNull(driftDb.projectValuesLinkTable);
      final value = row.readTableOrNull(driftDb.valueTable);
      if (value != null && valLink != null) {
        valueMap.putIfAbsent(value.id, () => value);
      }

      final labLink = row.readTableOrNull(driftDb.projectLabelsTable);
      final label = row.readTableOrNull(driftDb.labelTable);
      if (label != null && labLink != null) {
        labelMap.putIfAbsent(label.id, () => label);
      }
    }

    final labelTableList = labelMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final valueTableList = valueMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final labels = labelTableList.map(labelFromTable).toList();
    final values = valueTableList.map(valueFromTable).toList();

    return projectFromTable(project!, values: values, labels: labels);
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
    bool completed = false,
    List<String>? valueIds,
    List<String>? labelIds,
  }) async {
    final now = DateTime.now();
    final id = uuid.v4();

    final uniqueValueIds = valueIds?.toSet().toList(growable: false);
    final uniqueLabelIds = labelIds?.toSet().toList(growable: false);

    await driftDb.transaction(() async {
      await _createProject(
        ProjectTableCompanion(
          id: Value(id),
          name: Value(name),
          completed: Value(completed),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      if (uniqueValueIds != null) {
        for (final valueId in uniqueValueIds) {
          await driftDb
              .into(driftDb.projectValuesLinkTable)
              .insert(
                ProjectValuesLinkTableCompanion(
                  projectId: Value(id),
                  valueId: Value(valueId),
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }
      }

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
    List<String>? valueIds,
    List<String>? labelIds,
  }) async {
    final existing = await _getProjectById(id);
    if (existing == null) {
      throw RepositoryNotFoundException('No project found to update');
    }

    final now = DateTime.now();

    final uniqueValueIds = valueIds?.toSet().toList(growable: false);
    final uniqueLabelIds = labelIds?.toSet().toList(growable: false);

    await driftDb.transaction(() async {
      await _updateProject(
        ProjectTableCompanion(
          id: Value(id),
          name: Value(name),
          completed: Value(completed),
          updatedAt: Value(now),
        ),
      );

      if (uniqueValueIds != null) {
        final requested = uniqueValueIds.toSet();
        final existing =
            (await (driftDb.select(
                  driftDb.projectValuesLinkTable,
                )..where((t) => t.projectId.equals(id))).get())
                .map((r) => r.valueId)
                .toSet();

        if (requested.length != existing.length ||
            !existing.containsAll(requested)) {
          await (driftDb.delete(
            driftDb.projectValuesLinkTable,
          )..where((t) => t.projectId.equals(id))).go();

          for (final valueId in uniqueValueIds) {
            await driftDb
                .into(driftDb.projectValuesLinkTable)
                .insert(
                  ProjectValuesLinkTableCompanion(
                    projectId: Value(id),
                    valueId: Value(valueId),
                  ),
                  mode: InsertMode.insertOrIgnore,
                );
          }
        }
      }

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
