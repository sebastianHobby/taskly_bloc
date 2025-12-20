import 'package:drift/drift.dart' show Value;
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

  test(
    'get(withRelated: true) includes values/labels from link tables',
    () async {
      await projectRepository.create(name: 'Proj');
      final projectId = (await projectRepository.getAll())
          .singleWhere((p) => p.name == 'Proj')
          .id;

      await valueRepository.create(name: 'B');
      await valueRepository.create(name: 'A');
      await labelRepository.create(name: 'Z');
      await labelRepository.create(name: 'M');

      final valueAId = (await valueRepository.getAll())
          .singleWhere((v) => v.name == 'A')
          .id;
      final valueBId = (await valueRepository.getAll())
          .singleWhere((v) => v.name == 'B')
          .id;
      final labelMId = (await labelRepository.getAll())
          .singleWhere((l) => l.name == 'M')
          .id;
      final labelZId = (await labelRepository.getAll())
          .singleWhere((l) => l.name == 'Z')
          .id;

      await db
          .into(db.projectValuesLinkTable)
          .insert(
            ProjectValuesLinkTableCompanion(
              projectId: Value(projectId),
              valueId: Value(valueBId),
            ),
          );
      await db
          .into(db.projectValuesLinkTable)
          .insert(
            ProjectValuesLinkTableCompanion(
              projectId: Value(projectId),
              valueId: Value(valueAId),
            ),
          );

      final now = DateTime.now();
      await db
          .into(db.projectLabelsTable)
          .insert(
            ProjectLabelsTableCompanion(
              projectId: Value(projectId),
              labelId: Value(labelZId),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      await db
          .into(db.projectLabelsTable)
          .insert(
            ProjectLabelsTableCompanion(
              projectId: Value(projectId),
              labelId: Value(labelMId),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      final project = await projectRepository.get(projectId, withRelated: true);
      expect(project, isNotNull);
      expect(project!.values.map((v) => v.name).toList(), <String>['A', 'B']);
      expect(project.labels.map((l) => l.name).toList(), <String>['M', 'Z']);
    },
  );

  test('watchAll(withRelated: true) includes values/labels', () async {
    await projectRepository.create(name: 'Proj2');
    final projectId = (await projectRepository.getAll())
        .singleWhere((p) => p.name == 'Proj2')
        .id;

    await valueRepository.create(name: 'V');
    await labelRepository.create(name: 'L');

    final valueId = (await valueRepository.getAll())
        .singleWhere((v) => v.name == 'V')
        .id;
    final labelId = (await labelRepository.getAll())
        .singleWhere((l) => l.name == 'L')
        .id;

    await db
        .into(db.projectValuesLinkTable)
        .insert(
          ProjectValuesLinkTableCompanion(
            projectId: Value(projectId),
            valueId: Value(valueId),
          ),
        );

    final now = DateTime.now();
    await db
        .into(db.projectLabelsTable)
        .insert(
          ProjectLabelsTableCompanion(
            projectId: Value(projectId),
            labelId: Value(labelId),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    final projects = await projectRepository.watchAll(withRelated: true).first;
    final project = projects.singleWhere((p) => p.id == projectId);

    expect(project.values.single.id, valueId);
    expect(project.labels.single.id, labelId);
  });
}
