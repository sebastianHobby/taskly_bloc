import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';

import '../helpers/test_db.dart';
import '../mocks/repository_mocks.dart';

void main() {
  late AppDatabase db;
  late ProjectRepository repo;

  setUp(() {
    db = createTestDb();
    repo = ProjectRepository(
      driftDb: db,
      occurrenceExpander: MockOccurrenceStreamExpander(),
      occurrenceWriteHelper: MockOccurrenceWriteHelper(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('create/get/update/delete project flow', () async {
    await repo.create(name: 'Test Project');

    final listAfterCreate = await repo.watchAll().first;
    expect(listAfterCreate, hasLength(1));
    final fetched = listAfterCreate.single;
    expect(fetched.name, 'Test Project');

    await repo.update(id: fetched.id, name: 'Updated Project', completed: true);

    final listAfterUpdate = await repo.watchAll().first;
    final after = listAfterUpdate.singleWhere((p) => p.id == fetched.id);
    expect(after.name, 'Updated Project');
    expect(after.completed, isTrue);

    await repo.delete(fetched.id);

    final listAfterDelete = await repo.watchAll().first;
    expect(listAfterDelete.where((p) => p.id == fetched.id), isEmpty);
  });
}
