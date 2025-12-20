import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
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

  test('watchAll stream is initially empty', () async {
    final first = await repo.watchAll().first;
    expect(first, isEmpty);
  });

  test('get returns null when missing', () async {
    final res = await repo.get('nope');
    expect(res, isNull);
  });

  test('creating twice creates two values', () async {
    await repo.create(name: 'A');
    await repo.create(name: 'B');

    final list = await repo.watchAll().first;
    expect(list, hasLength(2));
    expect(list.map((v) => v.name), containsAll(<String>['A', 'B']));
  });

  test('update non-existent throws', () async {
    await expectLater(
      repo.update(id: 'nope-v', name: 'Nope'),
      throwsA(isA<RepositoryNotFoundException>()),
    );
  });

  test('delete non-existent does not throw', () async {
    await repo.delete('nope-v');
    final list = await repo.watchAll().first;
    expect(list, isEmpty);
  });
}
