import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' hide LabelType;
import 'package:taskly_bloc/data/repositories/label_repository.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/domain/domain.dart';

import '../helpers/test_db.dart';
import '../mocks/repository_mocks.dart';

void main() {
  late AppDatabase db;
  late ProjectRepository projectRepository;
  late LabelRepository labelRepository;

  setUp(() {
    db = createTestDb();
    projectRepository = ProjectRepository(
      driftDb: db,
      occurrenceExpander: MockOccurrenceStreamExpander(),
      occurrenceWriteHelper: MockOccurrenceWriteHelper(),
    );
    labelRepository = LabelRepository(driftDb: db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'get(withRelated: true) includes labels from link table',
    () async {
      await projectRepository.create(name: 'Proj');
      final projectId = (await projectRepository.getAll())
          .singleWhere((p) => p.name == 'Proj')
          .id;
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

      final project = await projectRepository.get(projectId, withRelated: true);
      expect(project, isNotNull);
      expect(project!.labels.map((l) => l.name).toList(), <String>['M', 'Z']);
    },
  );

  test('watchAll(withRelated: true) includes labels', () async {
    await projectRepository.create(name: 'Proj2');
    final projectId = (await projectRepository.getAll())
        .singleWhere((p) => p.name == 'Proj2')
        .id;
    await labelRepository.create(
      name: 'L',
      color: '#000000',
      type: LabelType.label,
    );
    final labelId = (await labelRepository.getAll())
        .singleWhere((l) => l.name == 'L')
        .id;

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
    expect(project.labels.single.id, labelId);
  });
}
