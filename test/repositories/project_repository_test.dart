import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';

import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late ProjectRepository repo;

  setUp(() {
    db = createTestDb();
    repo = ProjectRepository(driftDb: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('create/get/update/delete project flow', () async {
    final now = DateTime.now();

    final createCompanion = ProjectTableCompanion(
      id: Value('p-test-1'),
      name: Value('Test Project'),
      createdAt: Value(now),
      updatedAt: Value(now),
      completed: const Value(false),
    );

    final rowId = await repo.createProject(createCompanion);
    expect(rowId, isNonZero);

    final listAfterCreate = await repo.getProjects.first;
    final fetched = listAfterCreate.singleWhere((p) => p.id == 'p-test-1');
    expect(fetched.name, 'Test Project');

    final updateCompanion = ProjectTableCompanion(
      id: Value('p-test-1'),
      name: const Value('Updated Project'),
      updatedAt: Value(DateTime.now()),
      completed: const Value(true),
    );

    final updated = await repo.updateProject(updateCompanion);
    expect(updated, greaterThan(0));

    final listAfterUpdate = await repo.getProjects.first;
    final after = listAfterUpdate.singleWhere((p) => p.id == 'p-test-1');
    expect(after.name, 'Updated Project');
    expect(after.completed, isTrue);

    final deleteCompanion = ProjectTableCompanion(id: Value('p-test-1'));
    final deleted = await repo.deleteProject(deleteCompanion);
    expect(deleted, greaterThanOrEqualTo(0));

    final listAfterDelete = await repo.getProjects.first;
    expect(listAfterDelete.where((p) => p.id == 'p-test-1'), isEmpty);
  });
}
