import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/label_repository.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';

import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late TaskRepository taskRepository;
  late ProjectRepository projectRepository;
  late ValueRepository valueRepository;
  late LabelRepository labelRepository;

  setUp(() {
    db = createTestDb();
    taskRepository = TaskRepository(driftDb: db);
    projectRepository = ProjectRepository(driftDb: db);
    valueRepository = ValueRepository(driftDb: db);
    labelRepository = LabelRepository(driftDb: db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'watchAll(withRelated: true) includes project, values, labels',
    () async {
      await projectRepository.create(name: 'Proj');
      await valueRepository.create(name: 'B');
      await valueRepository.create(name: 'A');
      await labelRepository.create(name: 'Z');
      await labelRepository.create(name: 'M');

      final projectId = (await projectRepository.getAll())
          .singleWhere((p) => p.name == 'Proj')
          .id;
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

      await taskRepository.create(
        name: 'Task',
        projectId: projectId,
        valueIds: <String>[valueBId, valueAId],
        labelIds: <String>[labelZId, labelMId],
      );

      final tasks = await taskRepository.watchAll(withRelated: true).first;
      expect(tasks, hasLength(1));

      final task = tasks.single;
      expect(task.project, isNotNull);
      expect(task.project!.id, projectId);

      expect(task.values.map((v) => v.name).toList(), <String>['A', 'B']);
      expect(task.labels.map((l) => l.name).toList(), <String>['M', 'Z']);
    },
  );

  test('watch(id, withRelated: true) emits task with related data', () async {
    await projectRepository.create(name: 'Proj2');
    await valueRepository.create(name: 'V1');
    await labelRepository.create(name: 'L1');

    final projectId = (await projectRepository.getAll())
        .singleWhere((p) => p.name == 'Proj2')
        .id;
    final valueId = (await valueRepository.getAll())
        .singleWhere((v) => v.name == 'V1')
        .id;
    final labelId = (await labelRepository.getAll())
        .singleWhere((l) => l.name == 'L1')
        .id;

    await taskRepository.create(
      name: 'Task2',
      projectId: projectId,
      valueIds: <String>[valueId],
      labelIds: <String>[labelId],
    );

    final taskId = (await taskRepository.getAll())
        .singleWhere((t) => t.name == 'Task2')
        .id;

    final watched = await taskRepository
        .watch(taskId, withRelated: true)
        .firstWhere((t) => t != null);

    expect(watched, isNotNull);
    expect(watched!.id, taskId);
    expect(watched.project, isNotNull);
    expect(watched.values.map((v) => v.id).toList(), <String>[valueId]);
    expect(watched.labels.map((l) => l.id).toList(), <String>[labelId]);
  });
}
