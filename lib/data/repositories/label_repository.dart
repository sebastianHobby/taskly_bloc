import 'package:drift/drift.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
import 'package:taskly_bloc/core/domain/domain.dart';
import 'package:taskly_bloc/data/repositories/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/data/mappers/drift_to_domain.dart';

class LabelRepository implements LabelRepositoryContract {
  LabelRepository({required this.driftDb});
  final AppDatabase driftDb;

  Stream<List<LabelTableData>> get _labelStream =>
      driftDb.select(driftDb.labelTable).watch();

  Future<List<LabelTableData>> get _labelList =>
      driftDb.select(driftDb.labelTable).get();

  Future<LabelTableData?> _getLabelById(String id) {
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
  Stream<Label?> watch(String id, {bool withRelated = false}) =>
      (driftDb.select(driftDb.labelTable)..where((l) => l.id.equals(id)))
          .watch()
          .map((rows) => rows.isEmpty ? null : labelFromTable(rows.first));

  @override
  Future<Label?> get(String id, {bool withRelated = false}) async {
    final data = await _getLabelById(id);
    return data == null ? null : labelFromTable(data);
  }

  Future<bool> updateLabel(LabelTableCompanion updateCompanion) async {
    final bool success = await driftDb
        .update(driftDb.labelTable)
        .replace(updateCompanion);
    if (!success) {
      throw RepositoryNotFoundException('No label found to update');
    }
    return success;
  }

  Future<int> deleteLabel(LabelTableCompanion deleteCompanion) async {
    return driftDb.delete(driftDb.labelTable).delete(deleteCompanion);
  }

  Future<int> createLabel(LabelTableCompanion createCompanion) {
    return driftDb.into(driftDb.labelTable).insert(createCompanion);
  }

  @override
  Future<void> create({required String name}) async {
    final now = DateTime.now();
    await createLabel(
      LabelTableCompanion(
        name: Value(name),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> update({required String id, required String name}) async {
    final now = DateTime.now();
    await updateLabel(
      LabelTableCompanion(
        id: Value(id),
        name: Value(name),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    await deleteLabel(LabelTableCompanion(id: Value(id)));
  }
}
