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

  testSafe('project anchor state records anchors and emits streams', () async {
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
    final anchorRepository = ProjectAnchorStateRepository(
      driftDb: db,
      idGenerator: idGenerator,
      clock: clock,
    );

    await projectRepository.create(name: 'Project Alpha');
    final projectRow = await db.select(db.projectTable).getSingle();

    final context = contextFactory.create(
      feature: 'projects',
      intent: 'test',
      operation: 'projects.anchor.record',
    );

    final anchoredAt = DateTime.utc(2025, 1, 14);
    await anchorRepository.recordAnchors(
      projectIds: [projectRow.id],
      anchoredAtUtc: anchoredAt,
      context: context,
    );

    final anchored = await anchorRepository.watchAll().firstWhere(
      (items) => items.isNotEmpty,
    );
    expect(anchored.single.projectId, projectRow.id);
    expect(anchored.single.lastAnchoredAtUtc, anchoredAt);

    final row = await db.select(db.projectAnchorStateTable).getSingle();
    final metadata = jsonDecode(row.psMetadata ?? '{}') as Map<String, dynamic>;
    expect(metadata['cid'], context.correlationId);
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
