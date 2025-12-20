import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/label_repository.dart';
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
}
