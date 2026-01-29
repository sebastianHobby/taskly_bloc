@Tags(['integration'])
library;

import 'dart:convert';

import 'package:taskly_data/db.dart';
import 'package:taskly_data/id.dart';
import 'package:taskly_data/repositories.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart';

import '../helpers/test_imports.dart';
import '../helpers/test_db.dart';
import '../mocks/fake_id_generator.dart';
import '../mocks/repository_mocks.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testSafe('task repository create/update emits stream updates', () async {
    final db = createTestDb();
    addTearDown(() => closeTestDb(db));

    final clock = _FixedClock(DateTime.utc(2025, 1, 15, 12));
    final idGenerator = FakeIdGenerator('user-1');
    final expander = MockOccurrenceStreamExpanderContract();
    final writeHelper = MockOccurrenceWriteHelperContract();

    final projectRepository = ProjectRepository(
      driftDb: db,
      occurrenceExpander: expander,
      occurrenceWriteHelper: writeHelper,
      idGenerator: idGenerator,
      clock: clock,
    );
    final taskRepository = TaskRepository(
      driftDb: db,
      occurrenceExpander: expander,
      occurrenceWriteHelper: writeHelper,
      idGenerator: idGenerator,
      clock: clock,
    );

    await projectRepository.create(name: 'Project Alpha');
    final projectRow = await db.select(db.projectTable).getSingle();

    final context = const OperationContext(
      correlationId: 'corr-1',
      feature: 'tasks',
      intent: 'test',
      operation: 'tasks.create',
    );

    await taskRepository.create(
      name: 'Task A',
      completed: false,
      projectId: projectRow.id,
      context: context,
    );

    final created = await taskRepository.watchAll().firstWhere(
      (tasks) => tasks.isNotEmpty,
    );
    expect(created, hasLength(1));
    expect(created.single.projectId, projectRow.id);

    final taskId = created.single.id;
    await taskRepository.update(
      id: taskId,
      name: 'Task A Updated',
      completed: false,
      projectId: projectRow.id,
      context: context,
    );

    final updated = await taskRepository
        .watchById(taskId)
        .firstWhere((task) => task?.name == 'Task A Updated');
    expect(updated?.name, 'Task A Updated');

    final row = await db.select(db.taskTable).getSingle();
    final metadata = jsonDecode(row.psMetadata ?? '{}') as Map<String, dynamic>;
    expect(metadata['cid'], context.correlationId);
  });

  testSafe('task repository delete removes task and emits stream updates', () async {
    final db = createTestDb();
    addTearDown(() => closeTestDb(db));

    final clock = _FixedClock(DateTime.utc(2025, 1, 15, 12));
    final idGenerator = FakeIdGenerator('user-1');
    final expander = MockOccurrenceStreamExpanderContract();
    final writeHelper = MockOccurrenceWriteHelperContract();

    final taskRepository = TaskRepository(
      driftDb: db,
      occurrenceExpander: expander,
      occurrenceWriteHelper: writeHelper,
      idGenerator: idGenerator,
      clock: clock,
    );

    await taskRepository.create(name: 'Delete Me', completed: false);
    final created = await taskRepository.watchAll().firstWhere(
      (tasks) => tasks.isNotEmpty,
    );
    final taskId = created.single.id;

    await taskRepository.delete(taskId);

    final afterDelete = await taskRepository.watchAll().firstWhere(
      (tasks) => tasks.isEmpty,
    );
    expect(afterDelete, isEmpty);

    final removed = await taskRepository.watchById(taskId).firstWhere(
      (task) => task == null,
    );
    expect(removed, isNull);
  });

  testSafe('task repository rejects empty name', () async {
    final db = createTestDb();
    addTearDown(() => closeTestDb(db));

    final clock = _FixedClock(DateTime.utc(2025, 1, 15, 12));
    final idGenerator = FakeIdGenerator('user-1');
    final expander = MockOccurrenceStreamExpanderContract();
    final writeHelper = MockOccurrenceWriteHelperContract();

    final taskRepository = TaskRepository(
      driftDb: db,
      occurrenceExpander: expander,
      occurrenceWriteHelper: writeHelper,
      idGenerator: idGenerator,
      clock: clock,
    );

    await expectLater(
      taskRepository.create(name: '', completed: false),
      throwsA(isA<Exception>()),
    );
  });
}

final class _FixedClock implements Clock {
  _FixedClock(this._nowUtc);

  final DateTime _nowUtc;

  @override
  DateTime nowLocal() => _nowUtc.toLocal();

  @override
  DateTime nowUtc() => _nowUtc;
}
