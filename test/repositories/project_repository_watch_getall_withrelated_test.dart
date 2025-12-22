import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' hide LabelType;
import 'package:taskly_bloc/data/repositories/label_repository.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/domain/domain.dart';

import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late ProjectRepository projectRepository;
  late LabelRepository labelRepository;

  setUp(() {
    db = createTestDb();
    projectRepository = ProjectRepository(driftDb: db);
    labelRepository = LabelRepository(driftDb: db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> createProjectWithLinks() async {
    await projectRepository.create(name: 'Proj');
    final projectId = (await projectRepository.getAll()).single.id;
    await labelRepository.create(
      name: 'Z',
      color: '#000000',
      type: LabelType.label,
    );
    await labelRepository.create(
      name: 'M',
      color: '#000000',
      type: LabelType.label,
    );
    final labelMId = (await labelRepository.getAll())
        .singleWhere((l) => l.name == 'M')
        .id;
    final labelZId = (await labelRepository.getAll())
        .singleWhere((l) => l.name == 'Z')
        .id;

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

  test('getAll(withRelated: true) includes labels', () async {
    final projectId = await createProjectWithLinks();

    final projects = await projectRepository.getAll(withRelated: true);
    expect(projects, hasLength(1));

    final p = projects.singleWhere((p) => p.id == projectId);
    expect(p.labels.map((l) => l.name).toList(), <String>['M', 'Z']);
  });

  test('watch(id, withRelated: true) returns project with links', () async {
    final projectId = await createProjectWithLinks();

    final project = await projectRepository
        .watch(projectId, withRelated: true)
        .firstWhere((p) => p != null);

    expect(project, isNotNull);
    expect(project!.id, projectId);
    expect(project.labels.map((l) => l.name).toList(), <String>['M', 'Z']);
  });

  test('watch(id, withRelated: true) emits null when missing', () async {
    final project = await projectRepository
        .watch('missing', withRelated: true)
        .first;
    expect(project, isNull);
  });
}
