@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import '../../helpers/test_db.dart';

import 'package:taskly_data/id.dart';
import 'package:taskly_data/src/repositories/project_next_actions_repository.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/telemetry.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('ProjectNextActionsRepository', () {
    testSafe('setForProject normalizes rank ordering', () async {
      final db = createAutoClosingDb();
      final repo = ProjectNextActionsRepository(
        driftDb: db,
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.setForProject(
        projectId: 'project-1',
        actions: const [
          ProjectNextActionDraft(taskId: 'task-2', rank: 2),
          ProjectNextActionDraft(taskId: 'task-1', rank: 1),
        ],
        context: const OperationContext(
          correlationId: 'corr-1',
          feature: 'projects',
          intent: 'test',
          operation: 'project.next_actions',
        ),
      );

      final rows = await repo.getForProject('project-1');
      expect(rows.map((r) => r.rank).toList(), equals([1, 2]));
    });

    testSafe('removeForTask compacts ranks', () async {
      final db = createAutoClosingDb();
      final repo = ProjectNextActionsRepository(
        driftDb: db,
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.setForProject(
        projectId: 'project-1',
        actions: const [
          ProjectNextActionDraft(taskId: 'task-1', rank: 1),
          ProjectNextActionDraft(taskId: 'task-2', rank: 2),
          ProjectNextActionDraft(taskId: 'task-3', rank: 3),
        ],
        context: const OperationContext(
          correlationId: 'corr-2',
          feature: 'projects',
          intent: 'test',
          operation: 'project.next_actions',
        ),
      );

      await repo.removeForTask(taskId: 'task-1');

      final rows = await repo.getForProject('project-1');
      expect(rows.map((r) => r.rank).toList(), equals([1, 2]));
      expect(rows.map((r) => r.taskId), equals(['task-2', 'task-3']));
    });
  });
}
