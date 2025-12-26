import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';

import '../../helpers/test_db.dart';
import '../../mocks/repository_mocks.dart';

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

  test('get returns the created project', () async {
    await repo.create(name: 'GBY Project');
    final created = (await repo.watchAll().first).single;

    final fetched = await repo.get(created.id);
    expect(fetched, isNotNull);
    expect(fetched!.id, created.id);
    expect(fetched.name, 'GBY Project');
  });
}
