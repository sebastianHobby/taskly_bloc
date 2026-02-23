@Tags(['integration'])
library;

import 'package:taskly_data/db.dart';
import 'package:taskly_data/repositories.dart';
import 'package:taskly_domain/analytics.dart';
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

  testSafe('journal repository create/update emits stream updates', () async {
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
      operation: 'journal.create',
    );

    final entryId = await journalRepository.createJournalEntry(
      entry,
      context: context,
    );

    final created = await journalRepository.watchJournalEntries().firstWhere(
      (entries) => entries.isNotEmpty,
    );
    expect(created.single.id, entryId);

    await journalRepository.updateJournalEntry(
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

  testSafe(
    'tracker events update watch events and day state projection',
    () async {
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
      final day = DateTime.utc(2025, 1, 15);
      final context = const OperationContext(
        correlationId: 'corr-3',
        feature: 'journal',
        intent: 'test',
        operation: 'journal.append_event',
      );

      await journalRepository.saveTrackerDefinition(
        TrackerDefinition(
          id: '',
          name: 'Water',
          scope: 'day',
          valueType: 'quantity',
          valueKind: 'number',
          opKind: 'add',
          unitKind: 'ml',
          createdAt: nowUtc,
          updatedAt: nowUtc,
          sortOrder: 0,
          isActive: true,
        ),
        context: context,
      );

      final definition = await journalRepository
          .watchTrackerDefinitions()
          .firstWhere(
            (rows) => rows.any((d) => d.name == 'Water'),
          );
      final trackerId = definition.first.id;

      await journalRepository.appendTrackerEvent(
        TrackerEvent(
          id: '',
          trackerId: trackerId,
          anchorType: 'day',
          anchorDate: day,
          op: 'add',
          value: 100,
          occurredAt: nowUtc,
          recordedAt: nowUtc,
        ),
        context: context,
      );

      await journalRepository.appendTrackerEvent(
        TrackerEvent(
          id: '',
          trackerId: trackerId,
          anchorType: 'day',
          anchorDate: day,
          op: 'add',
          value: 200,
          occurredAt: nowUtc.add(const Duration(minutes: 1)),
          recordedAt: nowUtc.add(const Duration(minutes: 1)),
        ),
        context: context,
      );

      final events = await journalRepository
          .watchTrackerEvents(anchorType: 'day', trackerId: trackerId)
          .firstWhere((rows) => rows.length >= 2);
      expect(events.length, greaterThanOrEqualTo(2));

      final dayStateRows = await journalRepository
          .watchTrackerStateDay(
            range: DateRange(start: day, end: day),
          )
          .first;
      expect(dayStateRows, isA<List<TrackerStateDay>>());
    },
  );

  testSafe('tracker definition choices emit stream updates', () async {
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
      correlationId: 'corr-4',
      feature: 'journal',
      intent: 'test',
      operation: 'journal.save_choice',
    );

    await journalRepository.saveTrackerDefinition(
      TrackerDefinition(
        id: '',
        name: 'Context',
        scope: 'entry',
        valueType: 'choice',
        valueKind: 'single_choice',
        opKind: 'set',
        createdAt: nowUtc,
        updatedAt: nowUtc,
        isActive: true,
        sortOrder: 0,
      ),
      context: context,
    );

    final tracker = await journalRepository
        .watchTrackerDefinitions()
        .firstWhere(
          (rows) => rows.any((d) => d.name == 'Context'),
        );

    await journalRepository.saveTrackerDefinitionChoice(
      TrackerDefinitionChoice(
        id: '',
        trackerId: tracker.first.id,
        choiceKey: 'home',
        label: 'Home',
        sortOrder: 0,
        isActive: true,
        createdAt: nowUtc,
        updatedAt: nowUtc,
        userId: null,
      ),
      context: context,
    );

    final choices = await journalRepository
        .watchTrackerDefinitionChoices(trackerId: tracker.first.id)
        .firstWhere((rows) => rows.isNotEmpty);
    expect(choices.first.label, 'Home');
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
