import 'package:drift/drift.dart' show Value;
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
    final first = await repo.getLabels.first;
    expect(first, isEmpty);
  });

  test('getLabelById returns null when missing', () async {
    final res = await repo.getLabelById('nope');
    expect(res, isNull);
  });

  test('create duplicate id throws', () async {
    final now = DateTime.now();
    final companion = LabelTableCompanion(
      id: Value('ldup-1'),
      name: Value('Ldup'),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    final first = await repo.createLabel(companion);
    expect(first, isNonZero);

    await expectLater(repo.createLabel(companion), throwsA(isA<Object>()));
  });

  test('update non-existent throws', () async {
    final update = LabelTableCompanion(
      id: Value('nope-l'),
      name: const Value('Nope'),
      updatedAt: Value(DateTime.now()),
    );

    await expectLater(
      repo.updateLabel(update),
      throwsA(isA<RepositoryNotFoundException>()),
    );
  });

  test('delete non-existent returns 0', () async {
    final del = LabelTableCompanion(id: Value('nope-l'));
    final res = await repo.deleteLabel(del);
    expect(res, equals(0));
  });
}
