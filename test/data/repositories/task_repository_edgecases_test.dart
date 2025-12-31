import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
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

  test('watchAll stream is initially empty', () async {
    final first = await repo.watchAll().first;
    expect(first, isEmpty);
  });

  test('getById returns null when missing', () async {
    final res = await repo.getById('non-existent');
    expect(res, isNull);
  });

  test('creating twice creates two tasks', () async {
    await repo.create(name: 'A');
    await repo.create(name: 'B');

    final list = await repo.watchAll().first;
    expect(list, hasLength(2));
    expect(list.map((t) => t.name), containsAll(<String>['A', 'B']));
  });

  test('update non-existent throws', () async {
    await expectLater(
      repo.update(id: 'nope', name: 'Nope', completed: false),
      throwsA(isA<RepositoryNotFoundException>()),
    );
  });

  test('delete non-existent does not throw', () async {
    await repo.delete('nope');
    final list = await repo.watchAll().first;
    expect(list, isEmpty);
  });

  test('concurrent creates produce multiple rows', () async {
    final futures = List.generate(5, (i) {
      return repo.create(name: 'Task $i');
    });

    await Future.wait(futures);

    final list = await repo.watchAll().first;
    expect(list, hasLength(5));
    expect(
      list.map((t) => t.name),
      containsAll(<String>['Task 0', 'Task 1', 'Task 2', 'Task 3', 'Task 4']),
    );
  });
}
