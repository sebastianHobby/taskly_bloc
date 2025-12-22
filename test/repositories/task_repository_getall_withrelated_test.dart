import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' hide LabelType;
import 'package:taskly_bloc/data/repositories/label_repository.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/domain/domain.dart';

import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late TaskRepository taskRepository;
  late ProjectRepository projectRepository;
  late LabelRepository labelRepository;

  setUp(() {
    db = createTestDb();
    taskRepository = TaskRepository(driftDb: db);
    projectRepository = ProjectRepository(driftDb: db);
    labelRepository = LabelRepository(driftDb: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('getAll(withRelated: true) includes related entities', () async {
    await projectRepository.create(name: 'Proj');
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

    final projectId = (await projectRepository.getAll())
        .singleWhere((p) => p.name == 'Proj')
        .id;
    final labelMId = (await labelRepository.getAll())
        .singleWhere((l) => l.name == 'M')
        .id;
    final labelZId = (await labelRepository.getAll())
        .singleWhere((l) => l.name == 'Z')
        .id;

    await taskRepository.create(
      name: 'Task',
      projectId: projectId,
      labelIds: <String>[labelZId, labelMId],
    );

    final tasks = await taskRepository.getAll(withRelated: true);
    expect(tasks, hasLength(1));

    final task = tasks.single;
    expect(task.project, isNotNull);
    expect(task.project!.id, projectId);
    expect(task.labels.map((l) => l.name).toList(), <String>['M', 'Z']);
  });

  test('getAll(withRelated: true) returns empty when no tasks exist', () async {
    final tasks = await taskRepository.getAll(withRelated: true);
    expect(tasks, isEmpty);
  });
}
