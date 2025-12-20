import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
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

  test('getProjects stream is initially empty', () async {
    final first = await repo.watchAll().first;
    expect(first, isEmpty);
  });

  test('getProjectById returns null when missing', () async {
    final res = await repo.get('non-existent');
    expect(res, isNull);
  });

  test('creating twice creates two projects', () async {
    await repo.create(name: 'A');
    await repo.create(name: 'B');

    final list = await repo.watchAll().first;
    expect(list, hasLength(2));
    expect(list.map((p) => p.name), containsAll(<String>['A', 'B']));
  });

  test('update non-existent throws', () async {
    await expectLater(
      repo.update(id: 'nope-p', name: 'Nope', completed: false),
      throwsA(isA<RepositoryNotFoundException>()),
    );
  });

  test('delete non-existent does not throw', () async {
    await repo.delete('nope-p');
    final list = await repo.watchAll().first;
    expect(list, isEmpty);
  });

  test('concurrent creates produce multiple projects', () async {
    final futures = List.generate(4, (i) {
      return repo.create(name: 'Project $i');
    });

    await Future.wait(futures);

    final list = await repo.watchAll().first;
    expect(list, hasLength(4));
    expect(
      list.map((p) => p.name),
      containsAll(<String>['Project 0', 'Project 1', 'Project 2', 'Project 3']),
    );
  });
}
