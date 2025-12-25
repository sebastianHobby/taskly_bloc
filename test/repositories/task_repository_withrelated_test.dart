import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' hide LabelType;
import 'package:taskly_bloc/data/repositories/label_repository.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/domain/domain.dart';

import '../helpers/test_db.dart';
import '../mocks/repository_mocks.dart';

void main() {
  late AppDatabase db;
  late TaskRepository taskRepository;
  late ProjectRepository projectRepository;
  late LabelRepository labelRepository;

  setUp(() {
    db = createTestDb();
    taskRepository = TaskRepository(
      driftDb: db,
      occurrenceExpander: MockOccurrenceStreamExpander(),
      occurrenceWriteHelper: MockOccurrenceWriteHelper(),
    );
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
    'watchById includes project and labels',
    () async {
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

      // Get task ID from watchAll
      final tasks = await taskRepository.watchAll().first;
      expect(tasks, hasLength(1));

      // watchById always loads full related data
      final task = await taskRepository.watchById(tasks.single.id).first;
      expect(task, isNotNull);
      expect(task!.project, isNotNull);
      expect(task.project!.id, projectId);
      expect(task.labels.map((Label l) => l.name).toList(), <String>['M', 'Z']);
    },
  );

  test('watch(id, withRelated: true) emits task with related data', () async {
    await projectRepository.create(name: 'Proj2');
    await labelRepository.create(
      name: 'L1',
      color: '#000000',
      type: LabelType.label,
    );

    final projectId = (await projectRepository.getAll())
        .singleWhere((p) => p.name == 'Proj2')
        .id;
    final labelId = (await labelRepository.getAll())
        .singleWhere((l) => l.name == 'L1')
        .id;

    await taskRepository.create(
      name: 'Task2',
      projectId: projectId,
      labelIds: <String>[labelId],
    );

    final taskId = (await taskRepository.watchAll().first)
        .singleWhere((Task t) => t.name == 'Task2')
        .id;

    final watched = await taskRepository
        .watchById(taskId)
        .firstWhere((Task? t) => t != null);

    expect(watched, isNotNull);
    expect(watched!.id, taskId);
    expect(watched.project, isNotNull);
    expect(watched.labels.map((Label l) => l.id).toList(), <String>[labelId]);
  });
}
