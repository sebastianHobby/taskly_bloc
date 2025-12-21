import 'package:drift/drift.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/value_repository_contract.dart';
import 'package:taskly_bloc/data/mappers/drift_to_domain.dart';

class ValueRepository implements ValueRepositoryContract {
  ValueRepository({required this.driftDb});
  final AppDatabase driftDb;

  Stream<List<ValueTableData>> get _valueStream => (driftDb.select(
    driftDb.valueTable,
  )..orderBy([(v) => OrderingTerm(expression: v.name)])).watch();

  Future<List<ValueTableData>> get _valueList => (driftDb.select(
    driftDb.valueTable,
  )..orderBy([(v) => OrderingTerm(expression: v.name)])).get();

  Future<ValueTableData?> _getValueById(String id) {
    return (driftDb.select(
      driftDb.valueTable,
    )..where((v) => v.id.equals(id))).getSingleOrNull();
  }

  // Domain-aware read methods
  @override
  Stream<List<ValueModel>> watchAll({bool withRelated = false}) =>
      _valueStream.map((rows) => rows.map(valueFromTable).toList());

  @override
  Future<List<ValueModel>> getAll({bool withRelated = false}) async =>
      (await _valueList).map(valueFromTable).toList();

  @override
  Stream<ValueModel?> watch(String id, {bool withRelated = false}) =>
      (driftDb.select(
        driftDb.valueTable,
      )..where((v) => v.id.equals(id))).watch().map(
        (rows) => rows.isEmpty ? null : valueFromTable(rows.first),
      );

  @override
  Future<ValueModel?> get(String id, {bool withRelated = false}) async {
    final data = await _getValueById(id);
    return data == null ? null : valueFromTable(data);
  }

  Future<void> _updateValue(ValueTableCompanion updateCompanion) async {
    await driftDb.update(driftDb.valueTable).replace(updateCompanion);
  }

  Future<int> _deleteValue(ValueTableCompanion deleteCompanion) async {
    return driftDb.delete(driftDb.valueTable).delete(deleteCompanion);
  }

  Future<int> _createValue(ValueTableCompanion createCompanion) {
    return driftDb.into(driftDb.valueTable).insert(createCompanion);
  }

  @override
  Future<void> create({required String name}) async {
    final now = DateTime.now();
    await _createValue(
      ValueTableCompanion(
        name: Value(name),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> update({required String id, required String name}) async {
    final existing = await _getValueById(id);
    if (existing == null) {
      throw RepositoryNotFoundException('No value found to update');
    }

    final now = DateTime.now();
    await _updateValue(
      ValueTableCompanion(
        id: Value(id),
        name: Value(name),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    await _deleteValue(ValueTableCompanion(id: Value(id)));
  }
}
