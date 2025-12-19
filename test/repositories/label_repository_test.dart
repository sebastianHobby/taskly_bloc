import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/label_repository.dart';

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

  test('create/get/update/delete label flow', () async {
    final now = DateTime.now();

    final createCompanion = LabelTableCompanion(
      id: Value('l-test-1'),
      name: Value('Test Label'),
      createdAt: Value(now),
      updatedAt: Value(now),
    );

    final rowId = await repo.createLabel(createCompanion);
    expect(rowId, isNonZero);

    final listAfterCreate = await repo.getLabels.first;
    final fetched = listAfterCreate.singleWhere((l) => l.id == 'l-test-1');
    expect(fetched.name, 'Test Label');

    final updateCompanion = LabelTableCompanion(
      id: Value('l-test-1'),
      name: const Value('Updated Label'),
      updatedAt: Value(DateTime.now()),
    );

    final updated = await repo.updateLabel(updateCompanion);
    expect(updated, greaterThanOrEqualTo(0));

    final listAfterUpdate = await repo.getLabels.first;
    final after = listAfterUpdate.singleWhere((l) => l.id == 'l-test-1');
    expect(after.name, 'Updated Label');

    final deleteCompanion = LabelTableCompanion(id: Value('l-test-1'));
    final deleted = await repo.deleteLabel(deleteCompanion);
    expect(deleted, greaterThanOrEqualTo(0));

    final listAfterDelete = await repo.getLabels.first;
    expect(listAfterDelete.where((l) => l.id == 'l-test-1'), isEmpty);
  });
}
