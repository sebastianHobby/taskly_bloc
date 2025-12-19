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

  test('create/get/update/delete task flow', () async {
    final now = DateTime.now();

    final createCompanion = TaskTableCompanion(
      id: Value('t-test-1'),
      name: Value('Test Task'),
      createdAt: Value(now),
      updatedAt: Value(now),
      completed: const Value(false),
    );

    final rowId = await repo.createTask(createCompanion);
    expect(rowId, isNonZero);

    final listAfterCreate = await repo.getTasks.first;
    final fetched = listAfterCreate.singleWhere((t) => t.id == 't-test-1');
    expect(fetched.name, 'Test Task');

    final updateCompanion = TaskTableCompanion(
      id: Value('t-test-1'),
      name: const Value('Updated Task'),
      updatedAt: Value(DateTime.now()),
      completed: const Value(true),
    );

    final updated = await repo.updateTask(updateCompanion);
    expect(updated, isTrue);

    final listAfterUpdate = await repo.getTasks.first;
    final after = listAfterUpdate.singleWhere((t) => t.id == 't-test-1');
    expect(after.name, 'Updated Task');
    expect(after.completed, isTrue);

    final deleteCompanion = TaskTableCompanion(id: Value('t-test-1'));
    final deleted = await repo.deleteTask(deleteCompanion);
    expect(deleted, greaterThanOrEqualTo(0));

    final listAfterDelete = await repo.getTasks.first;
    expect(listAfterDelete.where((t) => t.id == 't-test-1'), isEmpty);
  });
}
