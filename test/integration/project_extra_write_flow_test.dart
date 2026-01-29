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

  testSafe('project repository setPinned persists updates', () async {
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

    await projectRepository.create(name: 'Project Alpha');
    final projectRow = await db.select(db.projectTable).getSingle();

    final context = contextFactory.create(
      feature: 'projects',
      intent: 'test',
      operation: 'projects.pin',
    );
    await projectRepository.setPinned(
      id: projectRow.id,
      isPinned: true,
      context: context,
    );

    final updatedRow = await db.select(db.projectTable).getSingle();
    expect(updatedRow.isPinned, isTrue);
    final metadata =
        jsonDecode(updatedRow.psMetadata ?? '{}') as Map<String, dynamic>;
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
