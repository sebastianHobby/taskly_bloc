import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/label_repository.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';

import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late ProjectRepository projectRepository;
  late ValueRepository valueRepository;
  late LabelRepository labelRepository;

  setUp(() {
    db = createTestDb();
    projectRepository = ProjectRepository(driftDb: db);
    valueRepository = ValueRepository(driftDb: db);
    labelRepository = LabelRepository(driftDb: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('update does not rewrite link rows when ids unchanged', () async {
    await valueRepository.create(name: 'A');
    await valueRepository.create(name: 'B');
    await labelRepository.create(name: 'L1');
    await labelRepository.create(name: 'L2');

    final valueAId = (await valueRepository.getAll())
        .singleWhere((v) => v.name == 'A')
        .id;
    final valueBId = (await valueRepository.getAll())
        .singleWhere((v) => v.name == 'B')
        .id;
    final label1Id = (await labelRepository.getAll())
        .singleWhere((l) => l.name == 'L1')
        .id;
    final label2Id = (await labelRepository.getAll())
        .singleWhere((l) => l.name == 'L2')
        .id;

    await projectRepository.create(
      name: 'P',
      valueIds: <String>[valueAId, valueBId],
      labelIds: <String>[label1Id, label2Id],
    );

    final projectId = (await projectRepository.getAll()).single.id;

    final beforeValueLinks = await (db.select(
      db.projectValuesLinkTable,
    )..where((t) => t.projectId.equals(projectId))).get();
    final beforeLabelLinks = await (db.select(
      db.projectLabelsTable,
    )..where((t) => t.projectId.equals(projectId))).get();

    await projectRepository.update(
      id: projectId,
      name: 'P',
      completed: false,
      valueIds: <String>[valueAId, valueBId],
      labelIds: <String>[label1Id, label2Id],
    );

    final afterValueLinks = await (db.select(
      db.projectValuesLinkTable,
    )..where((t) => t.projectId.equals(projectId))).get();
    final afterLabelLinks = await (db.select(
      db.projectLabelsTable,
    )..where((t) => t.projectId.equals(projectId))).get();

    expect(
      afterValueLinks.map((r) => r.id).toSet(),
      beforeValueLinks.map((r) => r.id).toSet(),
    );
    expect(
      afterLabelLinks.map((r) => r.id).toSet(),
      beforeLabelLinks.map((r) => r.id).toSet(),
    );
  });
}
