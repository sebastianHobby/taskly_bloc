import 'package:drift/drift.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' as drift;
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/data/mappers/drift_to_domain.dart';

class LabelRepository implements LabelRepositoryContract {
  LabelRepository({required this.driftDb});
  final drift.AppDatabase driftDb;

  Stream<List<drift.LabelTableData>> get _labelStream =>
      (driftDb.select(
            driftDb.labelTable,
          )..orderBy([
            (l) => OrderingTerm(expression: l.type, mode: OrderingMode.desc),
            (l) => OrderingTerm(expression: l.name),
          ]))
          .watch();

  Stream<List<drift.LabelTableData>> _labelStreamByType(LabelType type) {
    return (driftDb.select(driftDb.labelTable)
          ..where((l) => l.type.equals(type.name))
          ..orderBy([
            (l) => OrderingTerm(expression: l.type, mode: OrderingMode.desc),
            (l) => OrderingTerm(expression: l.name),
          ]))
        .watch();
  }

  Future<List<drift.LabelTableData>> get _labelList =>
      (driftDb.select(
            driftDb.labelTable,
          )..orderBy([
            (l) => OrderingTerm(expression: l.type, mode: OrderingMode.desc),
            (l) => OrderingTerm(expression: l.name),
          ]))
          .get();

  Future<List<drift.LabelTableData>> _labelListByType(LabelType type) {
    return (driftDb.select(driftDb.labelTable)
          ..where((l) => l.type.equals(type.name))
          ..orderBy([
            (l) => OrderingTerm(expression: l.type, mode: OrderingMode.desc),
            (l) => OrderingTerm(expression: l.name),
          ]))
        .get();
  }

  Future<drift.LabelTableData?> _getLabelById(String id) {
    return (driftDb.select(
      driftDb.labelTable,
    )..where((l) => l.id.equals(id))).getSingleOrNull();
  }

  // Domain-aware read methods
  @override
  Stream<List<Label>> watchAll({bool withRelated = false}) =>
      _labelStream.map((rows) => rows.map(labelFromTable).toList());

  @override
  Future<List<Label>> getAll({bool withRelated = false}) async =>
      (await _labelList).map(labelFromTable).toList();

  @override
  Stream<List<Label>> watchByType(LabelType type, {bool withRelated = false}) =>
      _labelStreamByType(type).map((rows) => rows.map(labelFromTable).toList());

  @override
  Future<List<Label>> getAllByType(
    LabelType type, {
    bool withRelated = false,
  }) async => (await _labelListByType(type)).map(labelFromTable).toList();

  @override
  Stream<Label?> watch(String id, {bool withRelated = false}) =>
      (driftDb.select(driftDb.labelTable)..where((l) => l.id.equals(id)))
          .watch()
          .map((rows) => rows.isEmpty ? null : labelFromTable(rows.first));

  @override
  Future<Label?> get(String id, {bool withRelated = false}) async {
    final data = await _getLabelById(id);
    return data == null ? null : labelFromTable(data);
  }

  Future<void> _updateLabel(drift.LabelTableCompanion updateCompanion) async {
    await driftDb.update(driftDb.labelTable).replace(updateCompanion);
  }

  Future<int> _deleteLabel(drift.LabelTableCompanion deleteCompanion) async {
    return driftDb.delete(driftDb.labelTable).delete(deleteCompanion);
  }

  Future<int> _createLabel(drift.LabelTableCompanion createCompanion) {
    return driftDb.into(driftDb.labelTable).insert(createCompanion);
  }

  @override
  Future<void> create({
    required String name,
    required String color,
    required LabelType type,
  }) async {
    final now = DateTime.now();
    final driftLabel = switch (type) {
      LabelType.label => drift.LabelType.label,
      LabelType.value => drift.LabelType.value,
    };

    await _createLabel(
      drift.LabelTableCompanion(
        name: Value(name),
        color: Value(color),
        type: Value(driftLabel),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    required String color,
    required LabelType type,
  }) async {
    final existing = await _getLabelById(id);
    if (existing == null) {
      throw RepositoryNotFoundException('No label found to update');
    }

    final now = DateTime.now();
    await _updateLabel(
      drift.LabelTableCompanion(
        id: Value(id),
        name: Value(name),
        color: Value(color),
        type: Value(drift.LabelType.values.byName(type.name)),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    await _deleteLabel(drift.LabelTableCompanion(id: Value(id)));
  }
}
