import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';

import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late ValueRepository repo;

  setUp(() {
    db = createTestDb();
    repo = ValueRepository(driftDb: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('create/get/update/delete value flow', () async {
    final now = DateTime.now();

    final createCompanion = ValueTableCompanion(
      id: Value('v-test-1'),
      name: Value('Test Value'),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    final rowId = await repo.createValue(createCompanion);
    expect(rowId, isNonZero);

    final listAfterCreate = await repo.getValues.first;
    final fetched = listAfterCreate.singleWhere((v) => v.id == 'v-test-1');
    expect(fetched.name, 'Test Value');

    final updateCompanion = ValueTableCompanion(
      id: Value('v-test-1'),
      name: const Value('Updated Value'),
      updatedAt: Value(DateTime.now()),
    );

    final updated = await repo.updateValue(updateCompanion);
    expect(updated, greaterThanOrEqualTo(0));

    final listAfterUpdate = await repo.getValues.first;
    final after = listAfterUpdate.singleWhere((v) => v.id == 'v-test-1');
    expect(after.name, 'Updated Value');

    final deleteCompanion = ValueTableCompanion(id: Value('v-test-1'));
    final deleted = await repo.deleteValue(deleteCompanion);
    expect(deleted, greaterThanOrEqualTo(0));

    final listAfterDelete = await repo.getValues.first;
    expect(listAfterDelete.where((v) => v.id == 'v-test-1'), isEmpty);
  });
}
