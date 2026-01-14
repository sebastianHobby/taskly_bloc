import 'package:drift/drift.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/data/infrastructure/drift/drift_database.dart';
import 'package:taskly_bloc/domain/journal/system_trackers.dart';

/// Seeds system tracker definitions and default preferences.
///
/// Uses deterministic v5 IDs to make seeding safe to re-run.
/// Preferences are created with insert-or-ignore so user customization is
/// preserved.
class JournalTrackerSeeder {
  JournalTrackerSeeder({
    required AppDatabase db,
    required IdGenerator idGenerator,
  }) : _db = db,
       _idGenerator = idGenerator;

  final AppDatabase _db;
  final IdGenerator _idGenerator;

  Future<void> ensureSeeded() async {
    talker.info('[JournalTrackerSeeder] Seeding system trackers');

    try {
      await _db.transaction(() async {
        for (final template in SystemTrackers.all) {
          await _seedTracker(template);
        }
      });

      talker.info(
        '[JournalTrackerSeeder] Successfully seeded '
        '${SystemTrackers.all.length} tracker(s)',
      );
    } catch (e, st) {
      talker.operationFailed(
        '[JournalTrackerSeeder] Failed to seed system trackers',
        e,
        st,
      );
      rethrow;
    }
  }

  Future<void> _seedTracker(SystemTrackerTemplate template) async {
    final trackerId = _idGenerator.trackerDefinitionId(name: template.name);

    final now = DateTime.now().toUtc();

    // Definitions are system-owned; keep them updated so the app can evolve.
    // PowerSync applies the schema using SQLite views; SQLite does not support
    // UPSERT (ON CONFLICT) on views.
    //
    // Important: Drift's update row-count can be 0 even when the row exists
    // (depending on how SQLite reports changes for view-backed tables).
    // So we avoid using the update count to decide whether to insert.
    await _db
        .into(_db.trackerDefinitions)
        .insert(
          TrackerDefinitionsCompanion(
            id: Value(trackerId),
            name: Value(template.name),
            description: Value(template.description),
            scope: Value(template.scope),
            valueType: Value(template.valueType),
            source: const Value('system'),
            systemKey: Value(template.systemKey),
            opKind: Value(template.opKind),
            valueKind: Value(template.valueKind),
            minInt: Value(template.minInt),
            maxInt: Value(template.maxInt),
            stepInt: Value(template.stepInt),
            sortOrder: Value(template.defaultSortOrder),
            isActive: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
          mode: InsertMode.insertOrIgnore,
        );

    await (_db.update(
      _db.trackerDefinitions,
    )..where((t) => t.id.equals(trackerId))).write(
      TrackerDefinitionsCompanion(
        name: Value(template.name),
        description: Value(template.description),
        scope: Value(template.scope),
        valueType: Value(template.valueType),
        source: const Value('system'),
        systemKey: Value(template.systemKey),
        opKind: Value(template.opKind),
        valueKind: Value(template.valueKind),
        minInt: Value(template.minInt),
        maxInt: Value(template.maxInt),
        stepInt: Value(template.stepInt),
        sortOrder: Value(template.defaultSortOrder),
        isActive: const Value(true),
        updatedAt: Value(now),
        createdAt: const Value.absent(),
      ),
    );

    // Preferences are user-owned; seed only when missing.
    final prefId = _idGenerator.trackerPreferenceId(trackerId: trackerId);
    await _db
        .into(_db.trackerPreferences)
        .insert(
          TrackerPreferencesCompanion.insert(
            id: Value(prefId),
            trackerId: trackerId,
            isActive: const Value(true),
            sortOrder: Value(template.defaultSortOrder),
            pinned: Value(template.defaultPinned),
            showInQuickAdd: Value(template.defaultQuickAdd),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
          mode: InsertMode.insertOrIgnore,
        );

    for (final choice in template.choices) {
      final choiceId = _idGenerator.trackerDefinitionChoiceId(
        trackerId: trackerId,
        choiceKey: choice.choiceKey,
      );

      await _db
          .into(_db.trackerDefinitionChoices)
          .insert(
            TrackerDefinitionChoicesCompanion.insert(
              id: Value(choiceId),
              trackerId: trackerId,
              choiceKey: choice.choiceKey,
              label: choice.label,
              sortOrder: Value(choice.sortOrder),
              isActive: const Value(true),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }
}
