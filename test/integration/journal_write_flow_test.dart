@Tags(['integration'])
library;

import 'package:taskly_data/db.dart';
import 'package:taskly_data/repositories.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart';

import '../helpers/test_imports.dart';
import '../helpers/test_db.dart';
import '../mocks/fake_id_generator.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testSafe('journal repository upsert/update emits stream updates', () async {
    final db = createTestDb();
    addTearDown(() => closeTestDb(db));

    final clock = _FixedClock(DateTime.utc(2025, 1, 15, 12));
    final idGenerator = FakeIdGenerator('user-1');

    final journalRepository = JournalRepositoryImpl(
      db,
      idGenerator,
      clock: clock,
    );

    final nowUtc = clock.nowUtc();
    final entry = JournalEntry(
      id: '',
      entryDate: dateOnly(nowUtc),
      entryTime: nowUtc,
      occurredAt: nowUtc,
      localDate: dateOnly(nowUtc),
      createdAt: nowUtc,
      updatedAt: nowUtc,
      journalText: 'Hello',
      deletedAt: null,
    );

    final context = const OperationContext(
      correlationId: 'corr-1',
      feature: 'journal',
      intent: 'test',
      operation: 'journal.upsert',
    );

    final entryId = await journalRepository.upsertJournalEntry(
      entry,
      context: context,
    );

    final created = await journalRepository.watchJournalEntries().firstWhere(
      (entries) => entries.isNotEmpty,
    );
    expect(created.single.id, entryId);

    await journalRepository.upsertJournalEntry(
      entry.copyWith(id: entryId, journalText: 'Updated'),
      context: context,
    );

    final updated = await journalRepository.watchJournalEntries().firstWhere(
      (entries) => entries.first.journalText == 'Updated',
    );
    expect(updated.first.journalText, 'Updated');
  });

  testSafe('tracker group/definition updates emit stream updates', () async {
    final db = createTestDb();
    addTearDown(() => closeTestDb(db));

    final clock = _FixedClock(DateTime.utc(2025, 1, 15, 12));
    final idGenerator = FakeIdGenerator('user-1');

    final journalRepository = JournalRepositoryImpl(
      db,
      idGenerator,
      clock: clock,
    );

    final nowUtc = clock.nowUtc();
    final context = const OperationContext(
      correlationId: 'corr-2',
      feature: 'journal',
      intent: 'test',
      operation: 'journal.save_tracker',
    );

    await journalRepository.saveTrackerGroup(
      TrackerGroup(
        id: '',
        name: 'Group',
        createdAt: nowUtc,
        updatedAt: nowUtc,
        isActive: true,
        sortOrder: 1,
        userId: null,
      ),
      context: context,
    );

    final groups = await journalRepository.watchTrackerGroups().firstWhere(
      (rows) => rows.isNotEmpty,
    );
    expect(groups.first.name, 'Group');

    await journalRepository.saveTrackerDefinition(
      TrackerDefinition(
        id: '',
        name: 'Mood',
        scope: 'entry',
        valueType: 'int',
        createdAt: nowUtc,
        updatedAt: nowUtc,
        groupId: groups.first.id,
        isActive: true,
        sortOrder: 1,
      ),
      context: context,
    );

    final defs = await journalRepository.watchTrackerDefinitions().firstWhere(
      (rows) => rows.isNotEmpty,
    );
    expect(defs.first.name, 'Mood');
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
