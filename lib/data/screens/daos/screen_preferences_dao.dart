import 'package:drift/drift.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/data/infrastructure/drift/drift_database.dart'
    as db;
import 'package:taskly_bloc/data/infrastructure/powersync/api_connector.dart'
    show isLoggedIn;
import 'package:taskly_bloc/domain/models/settings/screen_preferences.dart';

/// Drift DAO for the `screen_preferences` table.
///
/// Important:
/// - The app does not read/filter by `user_id`.
/// - Writes are blocked before authentication (PowerSync/Supabase requirement).
class ScreenPreferencesDao {
  ScreenPreferencesDao(this._db);

  final db.AppDatabase _db;

  Stream<Map<String, ScreenPreferences>> watchAllByScreenKey() {
    return _db.select(_db.screenPreferencesTable).watch().map((rows) {
      final map = <String, ScreenPreferences>{};
      for (final row in rows) {
        map[row.screenKey] = ScreenPreferences(
          sortOrder: row.sortOrder,
          isActive: row.isActive,
        );
      }
      return map;
    });
  }

  Stream<ScreenPreferences?> watchOne(String screenKey) {
    return (_db.select(
      _db.screenPreferencesTable,
    )..where((t) => t.screenKey.equals(screenKey))).watchSingleOrNull().map(
      (row) => row == null
          ? null
          : ScreenPreferences(
              sortOrder: row.sortOrder,
              isActive: row.isActive,
            ),
    );
  }

  Future<void> upsert(
    String screenKey,
    ScreenPreferences preferences,
  ) async {
    if (!isLoggedIn()) {
      talker.debug(
        '[ScreenPreferencesDao] Skipping write (not authenticated): '
        'screenKey=$screenKey',
      );
      return;
    }

    final now = DateTime.now();

    await _db.transaction(() async {
      final existing = await (_db.select(
        _db.screenPreferencesTable,
      )..where((t) => t.screenKey.equals(screenKey))).getSingleOrNull();

      if (existing == null) {
        await _db
            .into(_db.screenPreferencesTable)
            .insert(
              db.ScreenPreferencesTableCompanion.insert(
                screenKey: screenKey,
                isActive: Value(preferences.isActive),
                sortOrder: Value(preferences.sortOrder),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
              mode: InsertMode.insertOrAbort,
            );
        return;
      }

      await (_db.update(
        _db.screenPreferencesTable,
      )..where((t) => t.id.equals(existing.id))).write(
        db.ScreenPreferencesTableCompanion(
          isActive: Value(preferences.isActive),
          sortOrder: Value(preferences.sortOrder),
          updatedAt: Value(now),
        ),
      );
    });
  }

  Future<void> upsertManyOrdered(List<String> orderedScreenKeys) async {
    if (!isLoggedIn()) {
      talker.debug(
        '[ScreenPreferencesDao] Skipping reorder write (not authenticated)',
      );
      return;
    }

    final now = DateTime.now();

    await _db.transaction(() async {
      final existingRows = await (_db.select(
        _db.screenPreferencesTable,
      )..where((t) => t.screenKey.isIn(orderedScreenKeys))).get();

      final existingByKey = <String, db.ScreenPreferenceEntity>{
        for (final row in existingRows) row.screenKey: row,
      };

      for (var index = 0; index < orderedScreenKeys.length; index++) {
        final screenKey = orderedScreenKeys[index];
        final existing = existingByKey[screenKey];

        if (existing == null) {
          await _db
              .into(_db.screenPreferencesTable)
              .insert(
                db.ScreenPreferencesTableCompanion.insert(
                  screenKey: screenKey,
                  isActive: const Value(true),
                  sortOrder: Value(index),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ),
                mode: InsertMode.insertOrAbort,
              );
          continue;
        }

        await (_db.update(
          _db.screenPreferencesTable,
        )..where((t) => t.id.equals(existing.id))).write(
          db.ScreenPreferencesTableCompanion(
            sortOrder: Value(index),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }
}
