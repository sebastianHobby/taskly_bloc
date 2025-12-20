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
    await repo.create(name: 'Test Value');

    final listAfterCreate = await repo.watchAll().first;
    expect(listAfterCreate, hasLength(1));
    final fetched = listAfterCreate.single;
    expect(fetched.name, 'Test Value');

    await repo.update(id: fetched.id, name: 'Updated Value');

    final listAfterUpdate = await repo.watchAll().first;
    final after = listAfterUpdate.singleWhere((v) => v.id == fetched.id);
    expect(after.name, 'Updated Value');

    await repo.delete(fetched.id);

    final listAfterDelete = await repo.watchAll().first;
    expect(listAfterDelete.where((v) => v.id == fetched.id), isEmpty);
  });
}
