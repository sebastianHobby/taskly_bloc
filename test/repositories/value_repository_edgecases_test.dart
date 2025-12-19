import 'package:drift/drift.dart' show Value;
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

  test('getValues stream is initially empty', () async {
    final first = await repo.getValues.first;
    expect(first, isEmpty);
  });

  test('getValueById returns null when missing', () async {
    final res = await repo.getValueById('nope');
    expect(res, isNull);
  });

  test('create duplicate id throws', () async {
    final now = DateTime.now();
    final companion = ValueTableCompanion(
      id: Value('vdup-1'),
      name: Value('Vdup'),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    final first = await repo.createValue(companion);
    expect(first, isNonZero);

    await expectLater(repo.createValue(companion), throwsA(isA<Object>()));
  });

  test('update non-existent throws', () async {
    final update = ValueTableCompanion(
      id: Value('nope-v'),
      name: const Value('Nope'),
      updatedAt: Value(DateTime.now()),
    );

    await expectLater(
      repo.updateValue(update),
      throwsA(isA<RepositoryNotFoundException>()),
    );
  });

  test('delete non-existent returns 0', () async {
    final del = ValueTableCompanion(id: Value('nope-v'));
    final res = await repo.deleteValue(del);
    expect(res, equals(0));
  });
}
