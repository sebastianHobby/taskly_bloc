import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';

class ValueRepository {
  ValueRepository({required this.driftDb});
  final AppDatabase driftDb;

  Stream<List<ValueTableData>> get getValues =>
      driftDb.select(driftDb.valueTable).watch();

  Future<ValueTableData?> getValueById(String id) {
    return (driftDb.select(
      driftDb.valueTable,
    )..where((v) => v.id.equals(id))).getSingleOrNull();
  }

  Future<bool> updateValue(ValueTableCompanion updateCompanion) async {
    final bool success = await driftDb
        .update(driftDb.valueTable)
        .replace(updateCompanion);
    if (!success) {
      throw RepositoryNotFoundException('No value found to update');
    }
    return success;
  }

  Future<int> deleteValue(ValueTableCompanion deleteCompanion) async {
    return driftDb.delete(driftDb.valueTable).delete(deleteCompanion);
  }

  Future<int> createValue(ValueTableCompanion createCompanion) {
    return driftDb.into(driftDb.valueTable).insert(createCompanion);
  }
}
