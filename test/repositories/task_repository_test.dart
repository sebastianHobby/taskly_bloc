import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';

import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late TaskRepository repo;

  setUp(() {
    db = createTestDb();
    repo = TaskRepository(driftDb: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('create/get/update/delete task flow', () async {
    await repo.create(name: 'Test Task');

    final listAfterCreate = await repo.watchAll().first;
    expect(listAfterCreate, hasLength(1));

    final fetched = listAfterCreate.single;
    expect(fetched.name, 'Test Task');

    await repo.update(
      id: fetched.id,
      name: 'Updated Task',
      completed: true,
    );

    final listAfterUpdate = await repo.watchAll().first;
    final after = listAfterUpdate.singleWhere((t) => t.id == fetched.id);
    expect(after.name, 'Updated Task');
    expect(after.completed, isTrue);

    await repo.delete(fetched.id);

    final listAfterDelete = await repo.watchAll().first;
    expect(listAfterDelete.where((t) => t.id == fetched.id), isEmpty);
  });
}
