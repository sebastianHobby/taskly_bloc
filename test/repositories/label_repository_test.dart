import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' hide LabelType;
import 'package:taskly_bloc/data/repositories/label_repository.dart';
import 'package:taskly_bloc/domain/domain.dart';

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
    await repo.create(
      name: 'Test Label',
      color: '#000000',
      type: LabelType.label,
    );

    final listAfterCreate = await repo.watchAll().first;
    expect(listAfterCreate, hasLength(1));
    final fetched = listAfterCreate.single;
    expect(fetched.name, 'Test Label');

    await repo.update(
      id: fetched.id,
      name: 'Updated Label',
      color: '#ffffff',
      type: LabelType.label,
    );

    final listAfterUpdate = await repo.watchAll().first;
    final after = listAfterUpdate.singleWhere((l) => l.id == fetched.id);
    expect(after.name, 'Updated Label');

    await repo.delete(fetched.id);

    final listAfterDelete = await repo.watchAll().first;
    expect(listAfterDelete.where((l) => l.id == fetched.id), isEmpty);
  });

  test('create value label is returned by type filters', () async {
    await repo.create(
      name: 'V1',
      color: '#000000',
      type: LabelType.value,
    );
    await repo.create(
      name: 'L1',
      color: '#000000',
      type: LabelType.label,
    );

    final valuesFromGetAll = await repo.getAllByType(LabelType.value);
    expect(valuesFromGetAll.map((l) => l.name), <String>['V1']);

    final labelsFromGetAll = await repo.getAllByType(LabelType.label);
    expect(labelsFromGetAll.map((l) => l.name), <String>['L1']);

    final valuesFromWatch = await repo.watchByType(LabelType.value).first;
    expect(valuesFromWatch.map((l) => l.name), <String>['V1']);
  });
}
