import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/label_repository.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';

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

  test('getLabels stream is initially empty', () async {
    final first = await repo.watchAll().first;
    expect(first, isEmpty);
  });

  test('getLabelById returns null when missing', () async {
    final res = await repo.get('nope');
    expect(res, isNull);
  });

  test('creating twice creates two labels', () async {
    await repo.create(name: 'A');
    await repo.create(name: 'B');

    final list = await repo.watchAll().first;
    expect(list, hasLength(2));
    expect(list.map((l) => l.name), containsAll(<String>['A', 'B']));
  });

  test('update non-existent throws', () async {
    await expectLater(
      repo.update(id: 'nope-l', name: 'Nope'),
      throwsA(isA<RepositoryNotFoundException>()),
    );
  });

  test('delete non-existent does not throw', () async {
    await repo.delete('nope-l');
    final list = await repo.watchAll().first;
    expect(list, isEmpty);
  });
}
