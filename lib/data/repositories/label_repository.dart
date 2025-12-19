import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';

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
}
