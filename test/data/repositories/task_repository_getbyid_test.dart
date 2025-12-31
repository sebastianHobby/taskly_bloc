import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';

import '../../helpers/test_db.dart';
import '../../mocks/repository_mocks.dart';

void main() {
  late AppDatabase db;
  late TaskRepository repo;

  setUp(() {
    db = createTestDb();
    repo = TaskRepository(
      driftDb: db,
      occurrenceExpander: MockOccurrenceStreamExpanderContract(),
      occurrenceWriteHelper: MockOccurrenceWriteHelperContract(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('get returns the created task', () async {
    await repo.create(name: 'GBY Task');
    final created = (await repo.watchAll().first).single;

    final fetched = await repo.getById(created.id);
    expect(fetched, isNotNull);
    expect(fetched!.id, created.id);
    expect(fetched.name, 'GBY Task');
  });
}
