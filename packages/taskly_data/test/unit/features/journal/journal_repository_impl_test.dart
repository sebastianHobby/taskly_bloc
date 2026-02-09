@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';
import '../../../helpers/test_db.dart';

import 'package:drift/drift.dart' as drift;
import 'package:matcher/matcher.dart' as matcher;
import 'package:taskly_data/db.dart';
import 'package:taskly_data/id.dart';
import 'package:taskly_data/src/features/journal/repositories/journal_repository_impl.dart';
import 'package:taskly_domain/taskly_domain.dart' hide Value;

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('JournalRepositoryImpl', () {
    testSafe('upsertJournalEntry saves and queries by id/date', () async {
      final db = createAutoClosingDb();
      final repo = JournalRepositoryImpl(db, IdGenerator.withUserId('user-1'));
      final entryDate = DateTime(2025, 1, 1);
      final entryTime = DateTime(2025, 1, 1, 10, 0);

      final entry = JournalEntry(
        id: '',
        entryDate: entryDate,
        entryTime: entryTime,
        occurredAt: entryTime,
        localDate: entryDate,
        journalText: 'Hello',
        createdAt: entryDate,
        updatedAt: entryDate,
        deletedAt: null,
      );

      final id = await repo.upsertJournalEntry(entry);
      final fetched = await repo.getJournalEntryById(id);
      expect(fetched, matcher.isNotNull);
      expect(fetched!.journalText, equals('Hello'));

      final byDate = await repo.getJournalEntryByDate(date: entryDate);
      expect(byDate, matcher.isNotNull);
    });

    testSafe('watchJournalEntriesByQuery filters by id', () async {
      final db = createAutoClosingDb();
      final repo = JournalRepositoryImpl(db, IdGenerator.withUserId('user-1'));

      final entry1 = JournalEntry(
        id: 'e1',
        entryDate: DateTime.utc(2025, 1, 1),
        entryTime: DateTime.utc(2025, 1, 1, 9, 0),
        occurredAt: DateTime.utc(2025, 1, 1, 9, 0),
        localDate: DateTime.utc(2025, 1, 1),
        journalText: 'First',
        createdAt: DateTime.utc(2025, 1, 1),
        updatedAt: DateTime.utc(2025, 1, 1),
        deletedAt: null,
      );
      await repo.upsertJournalEntry(entry1);

      final entry2 = entry1.copyWith(id: 'e2', journalText: 'Second');
      await repo.upsertJournalEntry(entry2);

      final results = await repo
          .watchJournalEntriesByQuery(
            const JournalQuery().addPredicate(JournalIdPredicate(id: 'e2')),
          )
          .first;
      expect(results.length, equals(1));
      expect(results.single.id, equals('e2'));
    });

    testSafe('saveTrackerDefinition and watchTrackerDefinitions', () async {
      final db = createAutoClosingDb();
      final repo = JournalRepositoryImpl(db, IdGenerator.withUserId('user-1'));

      final def = TrackerDefinition(
        id: '',
        name: 'Mood',
        scope: 'entry',
        valueType: 'number',
        roles: const ['mood'],
        config: const {'min': 1},
        goal: const {'target': 5},
        createdAt: DateTime.utc(2025, 1, 1),
        updatedAt: DateTime.utc(2025, 1, 1),
        systemKey: 'mood',
      );

      await repo.saveTrackerDefinition(def);

      final defs = await repo.watchTrackerDefinitions().first;
      expect(defs.length, equals(1));
      expect(defs.single.roles, contains('mood'));
      expect(defs.single.config['min'], equals(1));
    });

    testSafe(
      'appendTrackerEvent and watchTrackerEvents decodes JSON',
      () async {
        final db = createAutoClosingDb();
        final repo = JournalRepositoryImpl(
          db,
          IdGenerator.withUserId('user-1'),
        );

        final event = TrackerEvent(
          id: '',
          trackerId: 't1',
          anchorType: 'entry',
          entryId: 'e1',
          anchorDate: DateTime.utc(2025, 1, 1),
          op: 'set',
          value: const {'a': 1},
          occurredAt: DateTime.utc(2025, 1, 1, 10, 0),
          recordedAt: DateTime.utc(2025, 1, 1, 10, 0),
          userId: null,
        );

        await repo.appendTrackerEvent(event);

        final events = await repo.watchTrackerEvents(trackerId: 't1').first;
        expect(events.length, equals(1));
        expect(events.single.value, equals(const {'a': 1}));
      },
    );

    testSafe('getDailyMoodAverages returns per-day averages', () async {
      final db = createAutoClosingDb();
      final repo = JournalRepositoryImpl(db, IdGenerator.withUserId('user-1'));

      await db
          .into(db.trackerDefinitions)
          .insert(
            TrackerDefinitionsCompanion.insert(
              id: const drift.Value('mood'),
              name: 'Mood',
              scope: 'entry',
              roles: const drift.Value('["mood"]'),
              valueType: 'number',
              config: const drift.Value('{}'),
              goal: const drift.Value('{}'),
              createdAt: drift.Value(DateTime.utc(2025, 1, 1)),
              updatedAt: drift.Value(DateTime.utc(2025, 1, 1)),
              systemKey: const drift.Value('mood'),
            ),
          );

      await db
          .into(db.trackerEvents)
          .insert(
            TrackerEventsCompanion.insert(
              id: const drift.Value('e1'),
              trackerId: 'mood',
              anchorType: 'entry',
              anchorDate: drift.Value(DateTime.utc(2025, 1, 1)),
              occurredAt: DateTime.utc(2025, 1, 1, 9, 0),
              recordedAt: drift.Value(DateTime.utc(2025, 1, 1, 9, 0)),
              op: 'set',
              value: const drift.Value('5'),
            ),
          );

      final averages = await repo.getDailyMoodAverages(
        range: DateRange(
          start: DateTime.utc(2025, 1, 1),
          end: DateTime.utc(2025, 1, 2),
        ),
      );

      expect(averages.values.single, equals(5));
    });

    testSafe('getTrackerValues aggregates bools and numbers', () async {
      final db = createAutoClosingDb();
      final repo = JournalRepositoryImpl(db, IdGenerator.withUserId('user-1'));

      await db
          .into(db.trackerEvents)
          .insert(
            TrackerEventsCompanion.insert(
              id: const drift.Value('b1'),
              trackerId: 'bool',
              anchorType: 'entry',
              anchorDate: drift.Value(DateTime.utc(2025, 1, 1)),
              occurredAt: DateTime.utc(2025, 1, 1, 9, 0),
              recordedAt: drift.Value(DateTime.utc(2025, 1, 1, 9, 0)),
              op: 'set',
              value: const drift.Value('true'),
            ),
          );
      await db
          .into(db.trackerEvents)
          .insert(
            TrackerEventsCompanion.insert(
              id: const drift.Value('n1'),
              trackerId: 'num',
              anchorType: 'entry',
              anchorDate: drift.Value(DateTime.utc(2025, 1, 1)),
              occurredAt: DateTime.utc(2025, 1, 1, 9, 0),
              recordedAt: drift.Value(DateTime.utc(2025, 1, 1, 9, 0)),
              op: 'set',
              value: const drift.Value('4'),
            ),
          );
      await db
          .into(db.trackerEvents)
          .insert(
            TrackerEventsCompanion.insert(
              id: const drift.Value('n2'),
              trackerId: 'num',
              anchorType: 'entry',
              anchorDate: drift.Value(DateTime.utc(2025, 1, 1)),
              occurredAt: DateTime.utc(2025, 1, 1, 10, 0),
              recordedAt: drift.Value(DateTime.utc(2025, 1, 1, 10, 0)),
              op: 'set',
              value: const drift.Value('6'),
            ),
          );

      final bools = await repo.getTrackerValues(
        trackerId: 'bool',
        range: DateRange(
          start: DateTime.utc(2025, 1, 1),
          end: DateTime.utc(2025, 1, 2),
        ),
      );
      final nums = await repo.getTrackerValues(
        trackerId: 'num',
        range: DateRange(
          start: DateTime.utc(2025, 1, 1),
          end: DateTime.utc(2025, 1, 2),
        ),
      );

      expect(bools.values.single, equals(1));
      expect(nums.values.single, equals(5));
    });

    testSafe('deleteTrackerAndData removes related rows', () async {
      final db = createAutoClosingDb();
      final repo = JournalRepositoryImpl(db, IdGenerator.withUserId('user-1'));

      await db
          .into(db.trackerDefinitions)
          .insert(
            TrackerDefinitionsCompanion.insert(
              id: const drift.Value('t1'),
              name: 'Tracker',
              scope: 'entry',
              roles: const drift.Value('[]'),
              valueType: 'number',
              config: const drift.Value('{}'),
              goal: const drift.Value('{}'),
              createdAt: drift.Value(DateTime.utc(2025, 1, 1)),
              updatedAt: drift.Value(DateTime.utc(2025, 1, 1)),
            ),
          );
      await db
          .into(db.trackerPreferences)
          .insert(
            TrackerPreferencesCompanion.insert(
              id: const drift.Value('pref'),
              trackerId: 't1',
              isActive: const drift.Value(true),
              sortOrder: const drift.Value(0),
              pinned: const drift.Value(false),
              showInQuickAdd: const drift.Value(false),
              createdAt: drift.Value(DateTime.utc(2025, 1, 1)),
              updatedAt: drift.Value(DateTime.utc(2025, 1, 1)),
            ),
          );
      await db
          .into(db.trackerDefinitionChoices)
          .insert(
            TrackerDefinitionChoicesCompanion.insert(
              id: const drift.Value('choice'),
              trackerId: 't1',
              choiceKey: 'a',
              label: 'A',
              sortOrder: const drift.Value(0),
              createdAt: drift.Value(DateTime.utc(2025, 1, 1)),
              updatedAt: drift.Value(DateTime.utc(2025, 1, 1)),
            ),
          );
      await db
          .into(db.trackerEvents)
          .insert(
            TrackerEventsCompanion.insert(
              id: const drift.Value('event'),
              trackerId: 't1',
              anchorType: 'entry',
              anchorDate: drift.Value(DateTime.utc(2025, 1, 1)),
              occurredAt: DateTime.utc(2025, 1, 1, 9, 0),
              recordedAt: drift.Value(DateTime.utc(2025, 1, 1, 9, 0)),
              op: 'set',
              value: const drift.Value('1'),
            ),
          );

      await repo.deleteTrackerAndData('t1');

      final def = await db.select(db.trackerDefinitions).getSingle();
      expect(def.isActive, isFalse);

      expect(await db.select(db.trackerPreferences).get(), isEmpty);
      expect(await db.select(db.trackerDefinitionChoices).get(), isEmpty);
      expect(await db.select(db.trackerEvents).get(), isEmpty);
    });
  });
}
