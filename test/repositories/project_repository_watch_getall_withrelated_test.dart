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

  Future<String> createProjectWithLinks() async {
    await projectRepository.create(name: 'Proj');
    final projectId = (await projectRepository.getAll()).single.id;

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

    return projectId;
  }

  test('getAll(withRelated: true) includes values/labels', () async {
    final projectId = await createProjectWithLinks();

    final projects = await projectRepository.getAll(withRelated: true);
    expect(projects, hasLength(1));

    final p = projects.singleWhere((p) => p.id == projectId);
    expect(p.values.map((v) => v.name).toList(), <String>['A', 'B']);
    expect(p.labels.map((l) => l.name).toList(), <String>['M', 'Z']);
  });

  test('watch(id, withRelated: true) returns project with links', () async {
    final projectId = await createProjectWithLinks();

    final project = await projectRepository
        .watch(projectId, withRelated: true)
        .firstWhere((p) => p != null);

    expect(project, isNotNull);
    expect(project!.id, projectId);
    expect(project.values.map((v) => v.name).toList(), <String>['A', 'B']);
    expect(project.labels.map((l) => l.name).toList(), <String>['M', 'Z']);
  });

  test('watch(id, withRelated: true) emits null when missing', () async {
    final project = await projectRepository
        .watch('missing', withRelated: true)
        .first;
    expect(project, isNull);
  });
}
