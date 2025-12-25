import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' hide LabelType;
import 'package:taskly_bloc/data/repositories/label_repository.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/domain/domain.dart';

import '../helpers/test_db.dart';
import '../mocks/repository_mocks.dart';

void main() {
  late AppDatabase db;
  late TaskRepository taskRepository;
  late LabelRepository labelRepository;

  setUp(() {
    db = createTestDb();
    taskRepository = TaskRepository(
      driftDb: db,
      occurrenceExpander: MockOccurrenceStreamExpander(),
      occurrenceWriteHelper: MockOccurrenceWriteHelper(),
    );
    labelRepository = LabelRepository(driftDb: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('create writes label link rows when ids provided', () async {
    await labelRepository.create(
      name: 'Label A',
      color: '#000000',
      type: LabelType.label,
    );
    final label = (await labelRepository.getAll()).single;

    await taskRepository.create(
      name: 'Task',
      labelIds: <String>[label.id],
    );

    final task = (await taskRepository.watchAll().first).single;

    final labelLinks = await (db.select(
      db.taskLabelsTable,
    )..where((t) => t.taskId.equals(task.id))).get();
    expect(labelLinks.map((l) => l.labelId), <String>[label.id]);
  });

  test('create tolerates duplicate label ids', () async {
    await labelRepository.create(
      name: 'Label A',
      color: '#000000',
      type: LabelType.label,
    );
    final label = (await labelRepository.getAll()).single;

    await taskRepository.create(
      name: 'Task',
      labelIds: <String>[label.id, label.id],
    );

    final task = (await taskRepository.watchAll().first).single;

    final labelLinks = await (db.select(
      db.taskLabelsTable,
    )..where((t) => t.taskId.equals(task.id))).get();
    expect(labelLinks.map((l) => l.labelId), <String>[label.id]);
  });

  test('update replaces label link rows when ids provided', () async {
    await labelRepository.create(
      name: 'L1',
      color: '#000000',
      type: LabelType.label,
    );
    await labelRepository.create(
      name: 'L2',
      color: '#000000',
      type: LabelType.label,
    );

    final label1Id = (await labelRepository.getAll())
        .singleWhere((l) => l.name == 'L1')
        .id;
    final label2Id = (await labelRepository.getAll())
        .singleWhere((l) => l.name == 'L2')
        .id;

    await taskRepository.create(
      name: 'T',
      labelIds: <String>[label1Id],
    );

    final taskId = (await taskRepository.watchAll().first).single.id;

    await taskRepository.update(
      id: taskId,
      name: 'T',
      completed: false,
      labelIds: <String>[label2Id],
    );

    final after = await taskRepository.getById(taskId);
    expect(after, isNotNull);
    expect(after!.labels.map((Label l) => l.id).toList(), <String>[label2Id]);

    final labelLinks = await (db.select(
      db.taskLabelsTable,
    )..where((t) => t.taskId.equals(taskId))).get();
    expect(labelLinks.map((r) => r.labelId).toList(), <String>[label2Id]);
  });

  test('update does not rewrite link rows when ids unchanged', () async {
    await labelRepository.create(
      name: 'L1',
      color: '#000000',
      type: LabelType.label,
    );
    await labelRepository.create(
      name: 'L2',
      color: '#000000',
      type: LabelType.label,
    );
    final label1Id = (await labelRepository.getAll())
        .singleWhere((l) => l.name == 'L1')
        .id;
    final label2Id = (await labelRepository.getAll())
        .singleWhere((l) => l.name == 'L2')
        .id;

    await taskRepository.create(
      name: 'T',
      labelIds: <String>[label1Id, label2Id],
    );

    final taskId = (await taskRepository.watchAll().first).single.id;

    final beforeLabelLinks = await (db.select(
      db.taskLabelsTable,
    )..where((t) => t.taskId.equals(taskId))).get();

    await taskRepository.update(
      id: taskId,
      name: 'T',
      completed: false,
      labelIds: <String>[label1Id, label2Id],
    );
    final afterLabelLinks = await (db.select(
      db.taskLabelsTable,
    )..where((t) => t.taskId.equals(taskId))).get();
    expect(
      afterLabelLinks.map((r) => r.id).toSet(),
      beforeLabelLinks.map((r) => r.id).toSet(),
    );
  });

  test('update throws when task is missing', () async {
    await expectLater(
      taskRepository.update(
        id: 'missing',
        name: 'Name',
        completed: false,
      ),
      throwsA(isA<RepositoryNotFoundException>()),
    );
  });

  test('delete removes task and does not throw twice', () async {
    await taskRepository.create(name: 'To delete');
    final taskId = (await taskRepository.watchAll().first).single.id;

    await taskRepository.delete(taskId);
    expect(await taskRepository.watchAll().first, isEmpty);

    await taskRepository.delete(taskId);
    expect(await taskRepository.watchAll().first, isEmpty);
  });
}
