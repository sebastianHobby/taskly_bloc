import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
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

  test('getTasks stream is initially empty', () async {
    final first = await repo.getTasks.first;
    expect(first, isEmpty);
  });

  test('getTaskById throws when missing', () async {
    expect(
      () async => repo.getTaskById('non-existent'),
      throwsA(isA<Object>()),
    );
  });

  test('create duplicate id throws', () async {
    final now = DateTime.now();
    final companion = TaskTableCompanion(
      id: Value('dup-1'),
      name: Value('Dup'),
      createdAt: Value(now),
      updatedAt: Value(now),
      completed: const Value(false),
    );

    final first = await repo.createTask(companion);
    expect(first, isNonZero);

    // second insert with same PK should throw
    await expectLater(repo.createTask(companion), throwsA(isA<Object>()));
  });

  test('update non-existent throws', () async {
    final update = TaskTableCompanion(
      id: Value('nope'),
      name: const Value('Nope'),
      updatedAt: Value(DateTime.now()),
      completed: const Value(false),
    );

    await expectLater(
      repo.updateTask(update),
      throwsA(isA<RepositoryNotFoundException>()),
    );
  });

  test('delete non-existent returns 0', () async {
    final del = TaskTableCompanion(id: Value('nope'));
    final res = await repo.deleteTask(del);
    expect(res, equals(0));
  });

  test('concurrent creates produce multiple rows', () async {
    final now = DateTime.now();
    final futures = List.generate(5, (i) {
      final c = TaskTableCompanion(
        id: Value('c-$i'),
        name: Value('Task $i'),
        createdAt: Value(now),
        updatedAt: Value(now),
        completed: const Value(false),
      );
      return repo.createTask(c);
    });

    final results = await Future.wait(futures);
    expect(results.where((r) => r > 0), hasLength(5));

    final list = await repo.getTasks.first;
    expect(
      list.map((t) => t.id),
      containsAll(<String>['c-0', 'c-1', 'c-2', 'c-3', 'c-4']),
    );
  });
}
