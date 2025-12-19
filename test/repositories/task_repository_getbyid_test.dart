import 'package:drift/drift.dart' show Value;
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

  test('getTaskById returns the inserted task', () async {
    final now = DateTime.now();
    final companion = TaskTableCompanion(
      id: Value('g1'),
      name: Value('GBY Task'),
      createdAt: Value(now),
      updatedAt: Value(now),
      completed: const Value(false),
    );

    final rowId = await repo.createTask(companion);
    expect(rowId, isNonZero);

    final fetched = await repo.getTaskById('g1');
    expect(fetched, isNotNull);
    expect(fetched!.id, 'g1');
    expect(fetched.name, 'GBY Task');
  });
}
