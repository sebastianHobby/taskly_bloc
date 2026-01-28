@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import '../../helpers/test_db.dart';

import 'package:taskly_data/id.dart';
import 'package:taskly_data/src/repositories/project_anchor_state_repository.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('ProjectAnchorStateRepository', () {
    testSafe('recordAnchors inserts and updates anchors', () async {
      final db = createAutoClosingDb();
      final repo = ProjectAnchorStateRepository(
        driftDb: db,
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      final firstAnchor = DateTime.utc(2025, 1, 10);
      await repo.recordAnchors(
        projectIds: const ['project-1', 'project-2'],
        anchoredAtUtc: firstAnchor,
      );

      final initial = await repo.getAll();
      expect(initial, hasLength(2));

      final updatedAnchor = DateTime.utc(2025, 1, 12);
      await repo.recordAnchors(
        projectIds: const ['project-1'],
        anchoredAtUtc: updatedAnchor,
      );

      final updated = await repo.getAll();
      final project1 = updated.firstWhere((p) => p.projectId == 'project-1');
      expect(project1.lastAnchoredAtUtc, updatedAnchor);
    });
  });
}
