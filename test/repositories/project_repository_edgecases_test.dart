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

  test('getProjects stream is initially empty', () async {
    final first = await repo.getProjects.first;
    expect(first, isEmpty);
  });

  test('getProjectById returns null when missing', () async {
    final res = await repo.getProjectById('non-existent');
    expect(res, isNull);
  });

  test('create duplicate id throws', () async {
    final now = DateTime.now();
    final companion = ProjectTableCompanion(
      id: Value('dup-p1'),
      name: Value('DupProject'),
      createdAt: Value(now),
      updatedAt: Value(now),
      completed: const Value(false),
    );

    final first = await repo.createProject(companion);
    expect(first, isNonZero);

    await expectLater(repo.createProject(companion), throwsA(isA<Object>()));
  });

  test('update non-existent throws', () async {
    final update = ProjectTableCompanion(
      id: Value('nope-p'),
      name: const Value('Nope'),
      updatedAt: Value(DateTime.now()),
      completed: const Value(false),
    );

    await expectLater(repo.updateProject(update), throwsA(isA<Object>()));
  });

  test('delete non-existent returns 0', () async {
    final del = ProjectTableCompanion(id: Value('nope-p'));
    final res = await repo.deleteProject(del);
    expect(res, equals(0));
  });

  test('concurrent creates produce multiple projects', () async {
    final now = DateTime.now();
    final futures = List.generate(4, (i) {
      final c = ProjectTableCompanion(
        id: Value('pc-$i'),
        name: Value('Project $i'),
        createdAt: Value(now),
        updatedAt: Value(now),
        completed: const Value(false),
      );
      return repo.createProject(c);
    });

    final results = await Future.wait(futures);
    expect(results.where((r) => r > 0), hasLength(4));

    final list = await repo.getProjects.first;
    expect(
      list.map((p) => p.id),
      containsAll(<String>['pc-0', 'pc-1', 'pc-2', 'pc-3']),
    );
  });
}
