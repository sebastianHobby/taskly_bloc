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
    testSafe('create/update journal entry and list by date', () async {
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

      final id = await repo.createJournalEntry(entry);
      final fetched = await repo.getJournalEntryById(id);
      expect(fetched, matcher.isNotNull);
      expect(fetched!.journalText, equals('Hello'));

      await repo.updateJournalEntry(
        fetched.copyWith(journalText: 'Updated'),
      );

      final byDate = await repo.getJournalEntriesByDate(date: entryDate);
      expect(byDate, isNotEmpty);
      expect(byDate.first.journalText, equals('Updated'));
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
      await repo.createJournalEntry(entry1);

      final entry2 = entry1.copyWith(id: 'e2', journalText: 'Second');
      await repo.createJournalEntry(entry2);

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
      'saveTrackerGroup create reuses existing normalized-name group id',
      () async {
        final db = createAutoClosingDb();
        final repo = JournalRepositoryImpl(
          db,
          IdGenerator.withUserId('user-1'),
        );

        final existingCreatedAt = DateTime.utc(2025, 1, 1);
        final existingUpdatedAt = DateTime.utc(2025, 1, 2);

        await db
            .into(db.trackerGroups)
            .insert(
              TrackerGroupsCompanion.insert(
                id: const drift.Value('group-existing'),
                name: 'Health',
                isActive: const drift.Value(false),
                sortOrder: const drift.Value(10),
                createdAt: drift.Value(existingCreatedAt),
                updatedAt: drift.Value(existingUpdatedAt),
              ),
            );

        final now = DateTime.utc(2025, 2, 1);
        await repo.saveTrackerGroup(
          TrackerGroup(
            id: '',
            name: '  health  ',
            createdAt: now,
            updatedAt: now,
            isActive: true,
            sortOrder: 200,
            userId: null,
          ),
        );

        final rows = await db.select(db.trackerGroups).get();
        expect(rows.length, equals(1));
        expect(rows.single.id, equals('group-existing'));
        expect(rows.single.name, equals('  health  '));
        expect(rows.single.isActive, isTrue);
        expect(rows.single.sortOrder, equals(200));
      },
    );

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

    testSafe(
      'updateJournalEntry validates id and deleteJournalEntry removes row',
      () async {
        final db = createAutoClosingDb();
        final repo = JournalRepositoryImpl(
          db,
          IdGenerator.withUserId('user-1'),
        );
        final now = DateTime.utc(2025, 1, 1);

        await expectLater(
          () => repo.updateJournalEntry(
            JournalEntry(
              id: '   ',
              entryDate: now,
              entryTime: now,
              occurredAt: now,
              localDate: now,
              journalText: 'x',
              createdAt: now,
              updatedAt: now,
              deletedAt: null,
            ),
          ),
          throwsA(isA<Exception>()),
        );

        final id = await repo.createJournalEntry(
          JournalEntry(
            id: '',
            entryDate: now,
            entryTime: now,
            occurredAt: now,
            localDate: now,
            journalText: 'x',
            createdAt: now,
            updatedAt: now,
            deletedAt: null,
          ),
        );
        await repo.deleteJournalEntry(id);
        expect(await repo.getJournalEntryById(id), isNull);
      },
    );

    testSafe(
      'updateJournalEntry allows no-op updates when row exists',
      () async {
        final db = createAutoClosingDb();
        final repo = JournalRepositoryImpl(
          db,
          IdGenerator.withUserId('user-1'),
        );
        final now = DateTime.utc(2025, 1, 1, 12);

        final id = await repo.createJournalEntry(
          JournalEntry(
            id: '',
            entryDate: now,
            entryTime: now,
            occurredAt: now,
            localDate: now,
            journalText: 'same',
            createdAt: now,
            updatedAt: now,
            deletedAt: null,
          ),
        );

        final before = await repo.getJournalEntryById(id);
        expect(before, isNotNull);

        await repo.updateJournalEntry(before!);

        final after = await repo.getJournalEntryById(id);
        expect(after, isNotNull);
        expect(after!.id, id);
      },
    );

    testSafe('updateJournalEntry throws when row does not exist', () async {
      final db = createAutoClosingDb();
      final repo = JournalRepositoryImpl(db, IdGenerator.withUserId('user-1'));
      final now = DateTime.utc(2025, 1, 1, 12);

      await expectLater(
        () => repo.updateJournalEntry(
          JournalEntry(
            id: 'missing-id',
            entryDate: now,
            entryTime: now,
            occurredAt: now,
            localDate: now,
            journalText: 'value',
            createdAt: now,
            updatedAt: now,
            deletedAt: null,
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });

    testSafe('saveTrackerPreference and choice update existing rows', () async {
      final db = createAutoClosingDb();
      final repo = JournalRepositoryImpl(db, IdGenerator.withUserId('user-1'));
      final now = DateTime.utc(2025, 1, 1);

      await repo.saveTrackerPreference(
        TrackerPreference(
          id: 'pref-1',
          trackerId: 't1',
          isActive: true,
          sortOrder: 1,
          pinned: false,
          showInQuickAdd: false,
          color: null,
          createdAt: now,
          updatedAt: now,
          userId: null,
        ),
      );
      await repo.saveTrackerPreference(
        TrackerPreference(
          id: 'pref-1',
          trackerId: 't1',
          isActive: false,
          sortOrder: 2,
          pinned: true,
          showInQuickAdd: true,
          color: '#123456',
          createdAt: now,
          updatedAt: now.add(const Duration(minutes: 1)),
          userId: null,
        ),
      );

      await repo.saveTrackerDefinitionChoice(
        TrackerDefinitionChoice(
          id: 'choice-1',
          trackerId: 't1',
          choiceKey: 'a',
          label: 'A',
          sortOrder: 1,
          isActive: true,
          createdAt: now,
          updatedAt: now,
          userId: null,
        ),
      );
      await repo.saveTrackerDefinitionChoice(
        TrackerDefinitionChoice(
          id: 'choice-1',
          trackerId: 't1',
          choiceKey: 'a',
          label: 'AA',
          sortOrder: 2,
          isActive: false,
          createdAt: now,
          updatedAt: now.add(const Duration(minutes: 1)),
          userId: null,
        ),
      );

      final pref = await db.select(db.trackerPreferences).getSingle();
      final choice = await db.select(db.trackerDefinitionChoices).getSingle();
      expect(pref.isActive, isFalse);
      expect(pref.pinned, isTrue);
      expect(choice.label, 'AA');
      expect(choice.isActive, isFalse);
    });

    testSafe(
      'deleteTrackerGroup trims input and soft-deletes matching group',
      () async {
        final db = createAutoClosingDb();
        final repo = JournalRepositoryImpl(
          db,
          IdGenerator.withUserId('user-1'),
        );
        final now = DateTime.utc(2025, 1, 1);

        await db
            .into(db.trackerGroups)
            .insert(
              TrackerGroupsCompanion.insert(
                id: const drift.Value('g1'),
                name: 'Health',
                isActive: const drift.Value(true),
                sortOrder: const drift.Value(1),
                createdAt: drift.Value(now),
                updatedAt: drift.Value(now),
              ),
            );

        await repo.deleteTrackerGroup('   ');
        expect(
          (await db.select(db.trackerGroups).getSingle()).isActive,
          isTrue,
        );

        await repo.deleteTrackerGroup(' g1 ');
        expect(
          (await db.select(db.trackerGroups).getSingle()).isActive,
          isFalse,
        );
      },
    );

    testSafe('watchTrackerEvents applies range and anchor filters', () async {
      final db = createAutoClosingDb();
      final repo = JournalRepositoryImpl(db, IdGenerator.withUserId('user-1'));

      await db
          .into(db.trackerEvents)
          .insert(
            TrackerEventsCompanion.insert(
              id: const drift.Value('e-in'),
              trackerId: 't1',
              anchorType: 'entry',
              entryId: const drift.Value('entry-1'),
              anchorDate: drift.Value(DateTime.utc(2025, 1, 2)),
              occurredAt: DateTime.utc(2025, 1, 2, 9, 0),
              recordedAt: drift.Value(DateTime.utc(2025, 1, 2, 9, 0)),
              op: 'set',
              value: const drift.Value('1'),
            ),
          );
      await db
          .into(db.trackerEvents)
          .insert(
            TrackerEventsCompanion.insert(
              id: const drift.Value('e-out'),
              trackerId: 't2',
              anchorType: 'day',
              entryId: const drift.Value('entry-2'),
              anchorDate: drift.Value(DateTime.utc(2025, 1, 5)),
              occurredAt: DateTime.utc(2025, 1, 5, 9, 0),
              recordedAt: drift.Value(DateTime.utc(2025, 1, 5, 9, 0)),
              op: 'set',
              value: const drift.Value('1'),
            ),
          );

      final results = await repo
          .watchTrackerEvents(
            range: DateRange(
              start: DateTime.utc(2025, 1, 1),
              end: DateTime.utc(2025, 1, 3),
            ),
            anchorType: 'entry',
            entryId: 'entry-1',
            anchorDate: DateTime.utc(2025, 1, 2),
            trackerId: 't1',
          )
          .first;
      expect(results.map((e) => e.id).toList(), ['e-in']);
    });

    testSafe('analytics helpers handle empty/legacy tracker values', () async {
      final db = createAutoClosingDb();
      final repo = JournalRepositoryImpl(db, IdGenerator.withUserId('user-1'));

      final noMood = await repo.getDailyMoodAverages(
        range: DateRange(
          start: DateTime.utc(2025, 1, 1),
          end: DateTime.utc(2025, 1, 2),
        ),
      );
      expect(noMood, isEmpty);

      await db
          .into(db.trackerEvents)
          .insert(
            TrackerEventsCompanion.insert(
              id: const drift.Value('bool-false'),
              trackerId: 't-bool',
              anchorType: 'entry',
              anchorDate: drift.Value(DateTime.utc(2025, 1, 1)),
              occurredAt: DateTime.utc(2025, 1, 1, 8, 0),
              recordedAt: drift.Value(DateTime.utc(2025, 1, 1, 8, 0)),
              op: 'set',
              value: const drift.Value('FALSE'),
            ),
          );
      await db
          .into(db.trackerEvents)
          .insert(
            TrackerEventsCompanion.insert(
              id: const drift.Value('num-plain'),
              trackerId: 't-num',
              anchorType: 'entry',
              anchorDate: drift.Value(DateTime.utc(2025, 1, 1)),
              occurredAt: DateTime.utc(2025, 1, 1, 9, 0),
              recordedAt: drift.Value(DateTime.utc(2025, 1, 1, 9, 0)),
              op: 'set',
              value: const drift.Value('7.5'),
            ),
          );
      await db
          .into(db.trackerEvents)
          .insert(
            TrackerEventsCompanion.insert(
              id: const drift.Value('text-ignored'),
              trackerId: 't-num',
              anchorType: 'entry',
              anchorDate: drift.Value(DateTime.utc(2025, 1, 1)),
              occurredAt: DateTime.utc(2025, 1, 1, 10, 0),
              recordedAt: drift.Value(DateTime.utc(2025, 1, 1, 10, 0)),
              op: 'set',
              value: const drift.Value('not-a-number'),
            ),
          );

      final boolValues = await repo.getTrackerValues(
        trackerId: 't-bool',
        range: DateRange(
          start: DateTime.utc(2025, 1, 1),
          end: DateTime.utc(2025, 1, 2),
        ),
      );
      final numValues = await repo.getTrackerValues(
        trackerId: 't-num',
        range: DateRange(
          start: DateTime.utc(2025, 1, 1),
          end: DateTime.utc(2025, 1, 2),
        ),
      );
      final emptyIdValues = await repo.getTrackerValues(
        trackerId: '  ',
        range: DateRange(
          start: DateTime.utc(2025, 1, 1),
          end: DateTime.utc(2025, 1, 2),
        ),
      );

      expect(boolValues.values.single, 0);
      expect(numValues.values.single, 7.5);
      expect(emptyIdValues, isEmpty);
    });
  });
}
