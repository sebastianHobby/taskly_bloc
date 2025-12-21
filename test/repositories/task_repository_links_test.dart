import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/label_repository.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';

import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late TaskRepository taskRepository;
  late ValueRepository valueRepository;
  late LabelRepository labelRepository;

  setUp(() {
    db = createTestDb();
    taskRepository = TaskRepository(driftDb: db);
    valueRepository = ValueRepository(driftDb: db);
    labelRepository = LabelRepository(driftDb: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('create writes value/label link rows when ids provided', () async {
    await valueRepository.create(name: 'Value A');
    await labelRepository.create(name: 'Label A');

    final value = (await valueRepository.getAll()).single;
    final label = (await labelRepository.getAll()).single;

    await taskRepository.create(
      name: 'Task',
      valueIds: <String>[value.id],
      labelIds: <String>[label.id],
    );

    final task = (await taskRepository.getAll()).single;

    final valueLinks = await (db.select(
      db.taskValuesTable,
    )..where((t) => t.taskId.equals(task.id))).get();
    expect(valueLinks.map((l) => l.valueId), <String>[value.id]);

    final labelLinks = await (db.select(
      db.taskLabelsTable,
    )..where((t) => t.taskId.equals(task.id))).get();
    expect(labelLinks.map((l) => l.labelId), <String>[label.id]);
  });

  test('create tolerates duplicate link ids', () async {
    await valueRepository.create(name: 'Value A');
    await labelRepository.create(name: 'Label A');

    final value = (await valueRepository.getAll()).single;
    final label = (await labelRepository.getAll()).single;

    await taskRepository.create(
      name: 'Task',
      valueIds: <String>[value.id, value.id],
      labelIds: <String>[label.id, label.id],
    );

    final task = (await taskRepository.getAll()).single;

    final valueLinks = await (db.select(
      db.taskValuesTable,
    )..where((t) => t.taskId.equals(task.id))).get();
    expect(valueLinks.map((l) => l.valueId), <String>[value.id]);

    final labelLinks = await (db.select(
      db.taskLabelsTable,
    )..where((t) => t.taskId.equals(task.id))).get();
    expect(labelLinks.map((l) => l.labelId), <String>[label.id]);
  });

  test('update replaces value/label link rows when ids provided', () async {
    await valueRepository.create(name: 'A');
    await valueRepository.create(name: 'B');
    await valueRepository.create(name: 'C');
    await labelRepository.create(name: 'L1');
    await labelRepository.create(name: 'L2');

    final valueAId = (await valueRepository.getAll())
        .singleWhere((v) => v.name == 'A')
        .id;
    final valueBId = (await valueRepository.getAll())
        .singleWhere((v) => v.name == 'B')
        .id;
    final valueCId = (await valueRepository.getAll())
        .singleWhere((v) => v.name == 'C')
        .id;
    final label1Id = (await labelRepository.getAll())
        .singleWhere((l) => l.name == 'L1')
        .id;
    final label2Id = (await labelRepository.getAll())
        .singleWhere((l) => l.name == 'L2')
        .id;

    await taskRepository.create(
      name: 'T',
      valueIds: <String>[valueAId, valueBId],
      labelIds: <String>[label1Id],
    );

    final taskId = (await taskRepository.getAll()).single.id;

    await taskRepository.update(
      id: taskId,
      name: 'T',
      completed: false,
      valueIds: <String>[valueCId],
      labelIds: <String>[label2Id],
    );

    final after = await taskRepository.get(taskId, withRelated: true);
    expect(after, isNotNull);
    expect(after!.values.map((v) => v.id).toList(), <String>[valueCId]);
    expect(after.labels.map((l) => l.id).toList(), <String>[label2Id]);

    final valueLinks = await (db.select(
      db.taskValuesTable,
    )..where((t) => t.taskId.equals(taskId))).get();
    expect(valueLinks.map((r) => r.valueId).toList(), <String>[valueCId]);

    final labelLinks = await (db.select(
      db.taskLabelsTable,
    )..where((t) => t.taskId.equals(taskId))).get();
    expect(labelLinks.map((r) => r.labelId).toList(), <String>[label2Id]);
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

    await taskRepository.create(
      name: 'T',
      valueIds: <String>[valueAId, valueBId],
      labelIds: <String>[label1Id, label2Id],
    );

    final taskId = (await taskRepository.getAll()).single.id;

    final beforeValueLinks = await (db.select(
      db.taskValuesTable,
    )..where((t) => t.taskId.equals(taskId))).get();
    final beforeLabelLinks = await (db.select(
      db.taskLabelsTable,
    )..where((t) => t.taskId.equals(taskId))).get();

    await taskRepository.update(
      id: taskId,
      name: 'T',
      completed: false,
      valueIds: <String>[valueAId, valueBId],
      labelIds: <String>[label1Id, label2Id],
    );

    final afterValueLinks = await (db.select(
      db.taskValuesTable,
    )..where((t) => t.taskId.equals(taskId))).get();
    final afterLabelLinks = await (db.select(
      db.taskLabelsTable,
    )..where((t) => t.taskId.equals(taskId))).get();

    expect(
      afterValueLinks.map((r) => r.id).toSet(),
      beforeValueLinks.map((r) => r.id).toSet(),
    );
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
    final taskId = (await taskRepository.getAll()).single.id;

    await taskRepository.delete(taskId);
    expect(await taskRepository.getAll(), isEmpty);

    await taskRepository.delete(taskId);
    expect(await taskRepository.getAll(), isEmpty);
  });
}
