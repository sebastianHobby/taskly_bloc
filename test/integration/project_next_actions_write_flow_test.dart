@Tags(['integration'])
library;

import 'dart:convert';

import 'package:taskly_data/db.dart';
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

  testSafe(
    'project next actions repository setForProject updates streams',
    () async {
      final db = createTestDb();
      addTearDown(() => closeTestDb(db));

      final clock = _FixedClock(DateTime.utc(2025, 1, 15, 12));
      final idGenerator = FakeIdGenerator('user-1');
      final expander = MockOccurrenceStreamExpanderContract();
      final writeHelper = MockOccurrenceWriteHelperContract();
      final contextFactory = TestOperationContextFactory();

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
      final nextActionsRepository = ProjectNextActionsRepository(
        driftDb: db,
        idGenerator: idGenerator,
        clock: clock,
      );

      await projectRepository.create(name: 'Project Alpha');
      final projectRow = await db.select(db.projectTable).getSingle();

      await taskRepository.create(
        name: 'Task A',
        completed: false,
        projectId: projectRow.id,
      );
      await taskRepository.create(
        name: 'Task B',
        completed: false,
        projectId: projectRow.id,
      );

      final tasks = await db.select(db.taskTable).get();
      final taskA = tasks.firstWhere((row) => row.name == 'Task A').id;
      final taskB = tasks.firstWhere((row) => row.name == 'Task B').id;

      final context = contextFactory.create(
        feature: 'projects',
        intent: 'test',
        operation: 'projects.next_actions.set',
      );

      await nextActionsRepository.setForProject(
        projectId: projectRow.id,
        actions: [
          ProjectNextActionDraft(taskId: taskA, rank: 1),
          ProjectNextActionDraft(taskId: taskB, rank: 2),
        ],
        context: context,
      );

      final created = await nextActionsRepository
          .watchForProject(projectRow.id)
          .firstWhere((items) => items.isNotEmpty);
      expect(created, hasLength(2));

      await nextActionsRepository.setForProject(
        projectId: projectRow.id,
        actions: [
          ProjectNextActionDraft(taskId: taskB, rank: 1),
        ],
        context: context,
      );

      final updated = await nextActionsRepository
          .watchForProject(projectRow.id)
          .firstWhere((items) => items.length == 1 && items.first.rank == 1);
      expect(updated.first.taskId, taskB);

      final row = await db.select(db.projectNextActionsTable).getSingle();
      final metadata =
          jsonDecode(row.psMetadata ?? '{}') as Map<String, dynamic>;
      expect(metadata['cid'], context.correlationId);
    },
  );
}

final class _FixedClock implements Clock {
  _FixedClock(this._nowUtc);

  final DateTime _nowUtc;

  @override
  DateTime nowLocal() => _nowUtc.toLocal();

  @override
  DateTime nowUtc() => _nowUtc;
}
