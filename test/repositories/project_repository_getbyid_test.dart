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

  test('getProjectById returns the inserted project', () async {
    final now = DateTime.now();
    final companion = ProjectTableCompanion(
      id: Value('pg1'),
      name: Value('GBY Project'),
      createdAt: Value(now),
      updatedAt: Value(now),
      completed: const Value(false),
    );

    final rowId = await repo.createProject(companion);
    expect(rowId, isNonZero);

    final fetched = await repo.getProjectById('pg1');
    expect(fetched, isNotNull);
    expect(fetched!.id, 'pg1');
    expect(fetched.name, 'GBY Project');
  });
}
