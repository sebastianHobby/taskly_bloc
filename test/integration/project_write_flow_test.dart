@Tags(['integration'])
library;

import 'dart:convert';

import 'package:taskly_data/db.dart';
import 'package:taskly_data/repositories.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart';

import '../helpers/test_imports.dart';
import '../helpers/test_db.dart';
import '../mocks/fake_id_generator.dart';
import '../mocks/repository_mocks.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testSafe('project repository create/update emits stream updates', () async {
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

    final context = const OperationContext(
      correlationId: 'corr-1',
      feature: 'projects',
      intent: 'test',
      operation: 'projects.create',
    );

    await projectRepository.create(
      name: 'Project A',
      context: context,
    );

    final created = await projectRepository.watchAll().firstWhere(
      (projects) => projects.isNotEmpty,
    );
    expect(created, hasLength(1));
    final projectId = created.single.id;

    await projectRepository.update(
      id: projectId,
      name: 'Project A Updated',
      completed: false,
      context: context,
    );

    final updated = await projectRepository
        .watchById(projectId)
        .firstWhere((project) => project?.name == 'Project A Updated');
    expect(updated?.name, 'Project A Updated');

    final row = await db.select(db.projectTable).getSingle();
    final metadata = jsonDecode(row.psMetadata ?? '{}') as Map<String, dynamic>;
    expect(metadata['cid'], context.correlationId);
  });

  testSafe(
    'project repository delete removes project and emits stream updates',
    () async {
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

      await projectRepository.create(name: 'Delete Project');
      final created = await projectRepository.watchAll().firstWhere(
        (projects) => projects.isNotEmpty,
      );
      final projectId = created.single.id;

      await projectRepository.delete(projectId);

      final afterDelete = await projectRepository.watchAll().firstWhere(
        (projects) => projects.isEmpty,
      );
      expect(afterDelete, isEmpty);

      final removed = await projectRepository
          .watchById(projectId)
          .firstWhere(
            (project) => project == null,
          );
      expect(removed, isNull);
    },
  );

  testSafe('project repository rejects empty name', () async {
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

    await expectLater(
      projectRepository.create(name: ''),
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
