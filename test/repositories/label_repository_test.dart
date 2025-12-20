import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/label_repository.dart';

import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late LabelRepository repo;

  setUp(() {
    db = createTestDb();
    repo = LabelRepository(driftDb: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('create/get/update/delete label flow', () async {
    await repo.create(name: 'Test Label');

    final listAfterCreate = await repo.watchAll().first;
    expect(listAfterCreate, hasLength(1));
    final fetched = listAfterCreate.single;
    expect(fetched.name, 'Test Label');

    await repo.update(id: fetched.id, name: 'Updated Label');

    final listAfterUpdate = await repo.watchAll().first;
    final after = listAfterUpdate.singleWhere((l) => l.id == fetched.id);
    expect(after.name, 'Updated Label');

    await repo.delete(fetched.id);

    final listAfterDelete = await repo.watchAll().first;
    expect(listAfterDelete.where((l) => l.id == fetched.id), isEmpty);
  });
}
