import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/data/screens/daos/screen_preferences_dao.dart';
import 'package:taskly_bloc/data/infrastructure/drift/drift_database.dart'
    as db;
import 'package:taskly_bloc/data/infrastructure/drift/features/shared_enums.dart'
    as shared_enums;
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/screens/catalog/system_screens/system_screen_definitions.dart';
import 'package:taskly_bloc/presentation/shared/models/screen_preferences.dart';

/// Drift implementation of [ScreenDefinitionsRepositoryContract].
///
/// ## Architecture (Option B)
///
/// - System screen definitions come from code via [SystemScreenDefinitions].
/// - Preferences (sort order + visibility) come from `screen_preferences`.
/// - Legacy fallback: older `screen_definitions` rows with
///   `source='system_template'` may exist and only contribute preference-like
///   fields (`isActive/sortOrder`) when a dedicated preference row is missing.
class ScreenDefinitionsRepositoryImpl
    implements ScreenDefinitionsRepositoryContract {
  ScreenDefinitionsRepositoryImpl(
    this._db,
  ) : _preferencesDao = ScreenPreferencesDao(_db);

  final db.AppDatabase _db;
  final ScreenPreferencesDao _preferencesDao;

  @override
  Stream<List<ScreenWithPreferences>> watchAllScreens() {
    // Option B:
    // - System screens come from code templates (always available)
    // - Preferences (isActive/sortOrder) come from screen_preferences
    // - Legacy fallback: if no preference row exists, reuse legacy values
    //   from screen_definitions where available (no writes required).

    final legacySystemPrefsStream =
        (_db.select(_db.screenDefinitions)..where(
              (t) => t.source.equals(
                shared_enums.EntitySource.system_template.name,
              ),
            ))
            .watch()
            .map((entities) {
              return <String, ScreenPreferences>{
                for (final e in entities)
                  e.screenKey: ScreenPreferences(
                    sortOrder: e.sortOrder,
                    isActive: e.isActive,
                  ),
              };
            });

    final prefsStream = _preferencesDao.watchAllByScreenKey();

    return Rx.combineLatest2<
      Map<String, ScreenPreferences>,
      Map<String, ScreenPreferences>,
      List<ScreenWithPreferences>
    >(
      prefsStream,
      legacySystemPrefsStream,
      (prefsByKey, legacySystemPrefsByKey) {
        final systemScreens = SystemScreenDefinitions.all
            .map((s) {
              final effectivePrefs =
                  prefsByKey[s.screenKey] ??
                  legacySystemPrefsByKey[s.screenKey] ??
                  const ScreenPreferences();
              return ScreenWithPreferences(
                screen: s,
                preferences: effectivePrefs,
              );
            })
            .toList(growable: false);

        final active = systemScreens.where((s) => s.isActive).toList();
        active.sort(
          (a, b) => a.effectiveSortOrder.compareTo(b.effectiveSortOrder),
        );

        final screenKeys = active.map((s) => s.screen.screenKey).toList();
        talker.repositoryLog(
          'Screens',
          'watchAllScreens: ${active.length} active system screens: '
              '$screenKeys',
        );

        return active;
      },
    );
  }

  @override
  Stream<List<ScreenWithPreferences>> watchSystemScreens() {
    final legacySystemPrefsStream =
        (_db.select(_db.screenDefinitions)..where(
              (t) => t.source.equals(
                shared_enums.EntitySource.system_template.name,
              ),
            ))
            .watch()
            .map((entities) {
              return <String, ScreenPreferences>{
                for (final e in entities)
                  e.screenKey: ScreenPreferences(
                    sortOrder: e.sortOrder,
                    isActive: e.isActive,
                  ),
              };
            });

    return Rx.combineLatest2<
      Map<String, ScreenPreferences>,
      Map<String, ScreenPreferences>,
      List<ScreenWithPreferences>
    >(
      _preferencesDao.watchAllByScreenKey(),
      legacySystemPrefsStream,
      (prefsByKey, legacySystemPrefsByKey) {
        final systemScreens = SystemScreenDefinitions.all.map((s) {
          final effectivePrefs =
              prefsByKey[s.screenKey] ??
              legacySystemPrefsByKey[s.screenKey] ??
              const ScreenPreferences();
          return ScreenWithPreferences(screen: s, preferences: effectivePrefs);
        }).toList();

        systemScreens.sort(
          (a, b) => a.effectiveSortOrder.compareTo(b.effectiveSortOrder),
        );

        talker.repositoryLog(
          'Screens',
          'watchSystemScreens: ${systemScreens.length} system screens from code',
        );
        return systemScreens;
      },
    );
  }

  @override
  Stream<ScreenWithPreferences?> watchScreen(String screenKey) {
    final systemScreen = SystemScreenDefinitions.getByKey(screenKey);
    if (systemScreen != null) {
      // System screen definition comes from code; preferences come from DB.
      return Rx.combineLatest2<
            ScreenPreferences?,
            List<db.ScreenDefinitionEntity>,
            ScreenWithPreferences
          >(
            _preferencesDao.watchOne(screenKey),
            (_db.select(_db.screenDefinitions)..where(
                  (t) =>
                      t.source.equals(
                        shared_enums.EntitySource.system_template.name,
                      ) &
                      t.screenKey.equals(screenKey),
                ))
                .watch(),
            (prefs, legacyEntities) {
              final legacy = legacyEntities.isEmpty
                  ? null
                  : ScreenPreferences(
                      sortOrder: legacyEntities.first.sortOrder,
                      isActive: legacyEntities.first.isActive,
                    );
              return ScreenWithPreferences(
                screen: systemScreen,
                preferences: prefs ?? legacy ?? const ScreenPreferences(),
              );
            },
          )
          .map((v) => v);
    }

    // Custom screens removed: unknown keys are not resolvable.
    return Stream<ScreenWithPreferences?>.value(null);
  }

  @override
  Future<void> updateScreenPreferences(
    String screenKey,
    ScreenPreferences preferences,
  ) async {
    // Option B: persist preferences in screen_preferences.
    await _preferencesDao.upsert(screenKey, preferences);
    talker.repositoryLog(
      'Screens',
      'updateScreenPreferences: screenKey=$screenKey, '
          'sortOrder=${preferences.sortOrder}, isActive=${preferences.isActive}',
    );
  }

  @override
  Future<void> reorderScreens(List<String> orderedScreenKeys) async {
    // Option B: persist ordering in screen_preferences.
    await _preferencesDao.upsertManyOrdered(orderedScreenKeys);

    talker.repositoryLog(
      'Screens',
      'reorderScreens: updated ${orderedScreenKeys.length} screen orders',
    );
  }
}
