import '../../../helpers/test_imports.dart';
import '../../../helpers/test_db.dart';

import 'package:taskly_bloc/data/features/journal/repositories/journal_repository_impl.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/data/infrastructure/drift/drift_database.dart';
import 'package:taskly_bloc/domain/analytics/model/date_range.dart';
import 'package:taskly_bloc/domain/journal/model/journal_entry.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition_choice.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_event.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_preference.dart';
import 'package:taskly_bloc/domain/queries/journal_query.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  late AppDatabase db;
  late JournalRepositoryImpl repo;

  setUp(() {
    db = createTestDb();
    repo = JournalRepositoryImpl(db, IdGenerator.withUserId('user-1'));
  });

  tearDown(() async {
    await closeTestDb(db);
  });

  group('JournalRepositoryImpl (entries)', () {
    testSafe(
      'upsertJournalEntry inserts and getJournalEntryById returns it',
      () async {
        final entry = JournalEntry(
          id: '',
          entryDate: DateTime.utc(2026, 1, 1),
          entryTime: DateTime.utc(2026, 1, 1, 9, 0),
          occurredAt: DateTime.utc(2026, 1, 1, 9, 0),
          localDate: DateTime.utc(2026, 1, 1),
          journalText: 'hello',
          createdAt: DateTime.utc(2026, 1, 1, 9, 0),
          updatedAt: DateTime.utc(2026, 1, 1, 9, 0),
          deletedAt: null,
        );

        final id = await repo.upsertJournalEntry(entry);
        final loaded = await repo.getJournalEntryById(id);

        expect(loaded, isNotNull);
        expect(loaded!.journalText, 'hello');
      },
    );

    testSafe(
      'getJournalEntriesByDate returns ordered by entryTime desc',
      () async {
        final date = DateTime.utc(2026, 1, 2);

        await repo.upsertJournalEntry(
          JournalEntry(
            id: '',
            entryDate: date,
            entryTime: DateTime.utc(2026, 1, 2, 9, 0),
            occurredAt: DateTime.utc(2026, 1, 2, 9, 0),
            localDate: date,
            journalText: 'morning',
            createdAt: DateTime.utc(2026, 1, 2, 9, 0),
            updatedAt: DateTime.utc(2026, 1, 2, 9, 0),
            deletedAt: null,
          ),
        );

        await repo.upsertJournalEntry(
          JournalEntry(
            id: '',
            entryDate: date,
            entryTime: DateTime.utc(2026, 1, 2, 18, 0),
            occurredAt: DateTime.utc(2026, 1, 2, 18, 0),
            localDate: date,
            journalText: 'evening',
            createdAt: DateTime.utc(2026, 1, 2, 18, 0),
            updatedAt: DateTime.utc(2026, 1, 2, 18, 0),
            deletedAt: null,
          ),
        );

        final results = await repo.getJournalEntriesByDate(date: date);
        expect(results, hasLength(2));
        expect(results.first.journalText, 'evening');
        expect(results.last.journalText, 'morning');
      },
    );

    testSafe('watchJournalEntries filters by date range', () async {
      await repo.upsertJournalEntry(
        JournalEntry(
          id: '',
          entryDate: DateTime.utc(2026, 1, 1),
          entryTime: DateTime.utc(2026, 1, 1, 9, 0),
          occurredAt: DateTime.utc(2026, 1, 1, 9, 0),
          localDate: DateTime.utc(2026, 1, 1),
          journalText: 'in',
          createdAt: DateTime.utc(2026, 1, 1, 9, 0),
          updatedAt: DateTime.utc(2026, 1, 1, 9, 0),
          deletedAt: null,
        ),
      );
      await repo.upsertJournalEntry(
        JournalEntry(
          id: '',
          entryDate: DateTime.utc(2026, 2, 1),
          entryTime: DateTime.utc(2026, 2, 1, 9, 0),
          occurredAt: DateTime.utc(2026, 2, 1, 9, 0),
          localDate: DateTime.utc(2026, 2, 1),
          journalText: 'out',
          createdAt: DateTime.utc(2026, 2, 1, 9, 0),
          updatedAt: DateTime.utc(2026, 2, 1, 9, 0),
          deletedAt: null,
        ),
      );

      final stream = repo.watchJournalEntries(
        range: DateRange(
          start: DateTime.utc(2026, 1, 1),
          end: DateTime.utc(2026, 1, 31),
        ),
      );

      final first = await stream.first;
      expect(first.map((e) => e.journalText), ['in']);
    });

    testSafe('watchJournalEntriesByQuery returns stream (smoke)', () async {
      await repo.upsertJournalEntry(
        JournalEntry(
          id: '',
          entryDate: DateTime.utc(2026, 1, 5),
          entryTime: DateTime.utc(2026, 1, 5, 9, 0),
          occurredAt: DateTime.utc(2026, 1, 5, 9, 0),
          localDate: DateTime.utc(2026, 1, 5),
          journalText: 'hello query',
          createdAt: DateTime.utc(2026, 1, 5, 9, 0),
          updatedAt: DateTime.utc(2026, 1, 5, 9, 0),
          deletedAt: null,
        ),
      );

      final stream = repo.watchJournalEntriesByQuery(JournalQuery.all());
      final first = await stream.first;
      expect(first, isNotEmpty);
    });

    testSafe('deleteJournalEntry removes row', () async {
      final id = await repo.upsertJournalEntry(
        JournalEntry(
          id: '',
          entryDate: DateTime.utc(2026, 1, 6),
          entryTime: DateTime.utc(2026, 1, 6, 9, 0),
          occurredAt: DateTime.utc(2026, 1, 6, 9, 0),
          localDate: DateTime.utc(2026, 1, 6),
          journalText: 'bye',
          createdAt: DateTime.utc(2026, 1, 6, 9, 0),
          updatedAt: DateTime.utc(2026, 1, 6, 9, 0),
          deletedAt: null,
        ),
      );

      await repo.deleteJournalEntry(id);
      final loaded = await repo.getJournalEntryById(id);
      expect(loaded, isNull);
    });
  });

  group('JournalRepositoryImpl (trackers)', () {
    testSafe(
      'saveTrackerDefinition inserts and watchTrackerDefinitions emits',
      () async {
        final def = TrackerDefinition(
          id: '',
          name: 'Mood',
          description: 'How was it',
          scope: 'day',
          roles: const [],
          valueType: 'int',
          config: const <String, dynamic>{},
          goal: const <String, dynamic>{},
          isActive: true,
          sortOrder: 0,
          updatedAt: DateTime.utc(2026, 1, 1),
          createdAt: DateTime.utc(2026, 1, 1),
          source: 'user',
          systemKey: null,
          opKind: 'set',
          valueKind: null,
          unitKind: null,
          minInt: 1,
          maxInt: 5,
          stepInt: 1,
          linkedValueId: null,
          isOutcome: false,
          isInsightEnabled: false,
          higherIsBetter: true,
        );

        await repo.saveTrackerDefinition(def);

        final first = await repo.watchTrackerDefinitions().first;
        expect(first, hasLength(1));
        expect(first.single.name, 'Mood');
      },
    );

    testSafe('saveTrackerDefinition updates existing row', () async {
      final generator = IdGenerator.withUserId('user-1');
      final id = generator.trackerDefinitionId(name: 'Mood');

      await repo.saveTrackerDefinition(
        TrackerDefinition(
          id: '',
          name: 'Mood',
          description: 'How was it',
          scope: 'day',
          roles: const [],
          valueType: 'int',
          config: const <String, dynamic>{},
          goal: const <String, dynamic>{},
          isActive: true,
          sortOrder: 0,
          updatedAt: DateTime.utc(2026, 1, 1),
          createdAt: DateTime.utc(2026, 1, 1),
          source: 'user',
          systemKey: null,
          opKind: 'set',
          valueKind: null,
          unitKind: null,
          minInt: 1,
          maxInt: 5,
          stepInt: 1,
          linkedValueId: null,
          isOutcome: false,
          isInsightEnabled: false,
          higherIsBetter: true,
        ),
      );

      await repo.saveTrackerDefinition(
        TrackerDefinition(
          id: id,
          name: 'Mood v2',
          description: 'Updated',
          scope: 'day',
          roles: const ['x'],
          valueType: 'int',
          config: const <String, dynamic>{'k': 'v'},
          goal: const <String, dynamic>{},
          isActive: true,
          sortOrder: 1,
          updatedAt: DateTime.utc(2026, 1, 2),
          createdAt: DateTime.utc(2026, 1, 1),
          source: 'user',
          systemKey: null,
          opKind: 'set',
          valueKind: null,
          unitKind: null,
          minInt: 1,
          maxInt: 5,
          stepInt: 1,
          linkedValueId: null,
          isOutcome: false,
          isInsightEnabled: false,
          higherIsBetter: true,
        ),
      );

      final first = await repo.watchTrackerDefinitions().first;
      expect(first, hasLength(1));
      expect(first.single.id, id);
      expect(first.single.name, 'Mood v2');
      expect(first.single.sortOrder, 1);
    });

    testSafe(
      'saveTrackerPreference inserts and watchTrackerPreferences emits',
      () async {
        final pref = TrackerPreference(
          id: '',
          trackerId: 'tracker-1',
          isActive: true,
          sortOrder: 0,
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        );

        await repo.saveTrackerPreference(pref);

        final first = await repo.watchTrackerPreferences().first;
        expect(first, hasLength(1));
        expect(first.single.trackerId, 'tracker-1');
      },
    );

    testSafe('saveTrackerPreference updates existing row', () async {
      final generator = IdGenerator.withUserId('user-1');
      final id = generator.trackerPreferenceId(trackerId: 'tracker-1');

      await repo.saveTrackerPreference(
        TrackerPreference(
          id: '',
          trackerId: 'tracker-1',
          isActive: true,
          sortOrder: 0,
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
      );

      await repo.saveTrackerPreference(
        TrackerPreference(
          id: id,
          trackerId: 'tracker-1',
          isActive: false,
          sortOrder: 2,
          pinned: true,
          showInQuickAdd: true,
          color: '123456',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 2),
        ),
      );

      final prefs = await repo.watchTrackerPreferences().first;
      expect(prefs, hasLength(1));
      expect(prefs.single.id, id);
      expect(prefs.single.isActive, isFalse);
      expect(prefs.single.pinned, isTrue);
      expect(prefs.single.showInQuickAdd, isTrue);
      expect(prefs.single.color, '123456');
    });

    testSafe(
      'saveTrackerDefinitionChoice inserts and watch emits sorted',
      () async {
        await repo.saveTrackerDefinitionChoice(
          TrackerDefinitionChoice(
            id: '',
            trackerId: 'tracker-choices',
            choiceKey: 'b',
            label: 'B',
            sortOrder: 1,
            isActive: true,
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        );
        await repo.saveTrackerDefinitionChoice(
          TrackerDefinitionChoice(
            id: '',
            trackerId: 'tracker-choices',
            choiceKey: 'a',
            label: 'A',
            sortOrder: 0,
            isActive: true,
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 1, 1),
          ),
        );

        final choices = await repo
            .watchTrackerDefinitionChoices(trackerId: 'tracker-choices')
            .first;
        expect(choices.map((c) => c.choiceKey), ['a', 'b']);
      },
    );

    testSafe(
      'appendTrackerEvent encodes/decodes JSON values and filters',
      () async {
        final day = DateTime.utc(2026, 1, 1);

        await repo.appendTrackerEvent(
          TrackerEvent(
            id: '',
            trackerId: 'tracker-ev',
            anchorType: 'day',
            entryId: null,
            anchorDate: day,
            op: 'set',
            value: const <String, dynamic>{'x': 1},
            occurredAt: DateTime.utc(2026, 1, 1, 10, 0),
            recordedAt: DateTime.utc(2026, 1, 1, 10, 0),
          ),
        );
        await repo.appendTrackerEvent(
          TrackerEvent(
            id: '',
            trackerId: 'tracker-ev',
            anchorType: 'day',
            entryId: null,
            anchorDate: day,
            op: 'set',
            value: 'plain',
            occurredAt: DateTime.utc(2026, 1, 1, 9, 0),
            recordedAt: DateTime.utc(2026, 1, 1, 9, 0),
          ),
        );

        final events = await repo
            .watchTrackerEvents(
              range: DateRange(
                start: DateTime.utc(2026, 1, 1),
                end: DateTime.utc(2026, 1, 2),
              ),
              trackerId: 'tracker-ev',
              anchorType: 'day',
              anchorDate: day,
            )
            .first;

        expect(events, hasLength(2));
        expect(events.first.occurredAt, DateTime.utc(2026, 1, 1, 10, 0));
        expect(events.first.value, {'x': 1});
        expect(events.last.value, 'plain');
      },
    );

    testSafe(
      'mapping: invalid JSON in tracker definition falls back',
      () async {
        // Use raw SQL so we can persist invalid JSON in TEXT columns.
        await db.customStatement(
          'INSERT OR ABORT INTO tracker_definitions '
          '(id, name, description, scope, roles, value_type, config, goal, '
          'is_active, sort_order, created_at, updated_at, source, op_kind, '
          'is_insight_enabled, higher_is_better) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            'tracker-bad',
            'Bad',
            'x',
            'day',
            'not-json',
            'int',
            'not-json',
            'not-json',
            true,
            0,
            DateTime.utc(2026, 1, 1),
            DateTime.utc(2026, 1, 1),
            'user',
            'set',
            false,
            true,
          ],
        );

        final defs = await repo.watchTrackerDefinitions().first;
        expect(defs, hasLength(1));
        expect(defs.single.roles, isEmpty);
        expect(defs.single.config, isEmpty);
        expect(defs.single.goal, isEmpty);
      },
    );

    testSafe(
      'getDailyMoodAverages and getTrackerValues return empty',
      () async {
        final range = DateRange(
          start: DateTime.utc(2026, 1, 1),
          end: DateTime.utc(2026, 1, 31),
        );

        final mood = await repo.getDailyMoodAverages(range: range);
        final values = await repo.getTrackerValues(
          trackerId: 'x',
          range: range,
        );

        expect(mood, isEmpty);
        expect(values, isEmpty);
      },
    );
  });
}
