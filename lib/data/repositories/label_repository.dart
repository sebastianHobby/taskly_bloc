import 'package:taskly_bloc/data/drift/drift_database.dart';

class LabelRepository {
  LabelRepository({required this.driftDb});
  final AppDatabase driftDb;

  Stream<List<LabelTableData>> get getLabels =>
      driftDb.select(driftDb.labelTable).watch();

  Future<LabelTableData?> getLabelById(String id) {
    return (driftDb.select(
      driftDb.labelTable,
    )..where((l) => l.id.equals(id))).getSingleOrNull();
  }

  Future<int> updateLabel(LabelTableCompanion updateCompanion) {
    return driftDb.update(driftDb.labelTable).write(updateCompanion);
  }

  Future<int> deleteLabel(LabelTableCompanion deleteCompanion) async {
    return driftDb.delete(driftDb.labelTable).delete(deleteCompanion);
  }

  Future<int> createLabel(LabelTableCompanion createCompanion) {
    return driftDb.into(driftDb.labelTable).insert(createCompanion);
  }
}
