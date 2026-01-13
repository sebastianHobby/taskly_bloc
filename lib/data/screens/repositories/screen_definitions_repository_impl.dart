import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/data/screens/daos/screen_preferences_dao.dart';
import 'package:taskly_bloc/data/infrastructure/drift/drift_database.dart'
    as db;
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/screens/catalog/system_screens/system_screen_specs.dart';
import 'package:taskly_bloc/presentation/shared/models/screen_preferences.dart';

/// Drift implementation of [ScreenDefinitionsRepositoryContract].
///
/// ## Architecture (Option B)
///
/// - System screen definitions come from code via [SystemScreenSpecs].
/// - Preferences (sort order + visibility) come from `screen_preferences`.
///
/// Hard cutover assumption: custom screens are removed and the app ships only
/// the typed system screens.
class ScreenDefinitionsRepositoryImpl
    implements ScreenDefinitionsRepositoryContract {
  ScreenDefinitionsRepositoryImpl(
    db.AppDatabase db,
  ) : _preferencesDao = ScreenPreferencesDao(db);

  final ScreenPreferencesDao _preferencesDao;

  @override
  Stream<List<ScreenWithPreferences>> watchAllScreens() {
    final prefsStream = _preferencesDao.watchAllByScreenKey();

    return prefsStream.map((prefsByKey) {
      final systemScreens = SystemScreenSpecs.all
          .map((s) {
            final effectivePrefs =
                prefsByKey[s.screenKey] ?? const ScreenPreferences();
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
        'watchAllScreens: ${active.length} active system screens: $screenKeys',
      );

      return active;
    });
  }

  @override
  Stream<List<ScreenWithPreferences>> watchSystemScreens() {
    return _preferencesDao.watchAllByScreenKey().map((prefsByKey) {
      final systemScreens = SystemScreenSpecs.all
          .map((s) {
            final effectivePrefs =
                prefsByKey[s.screenKey] ?? const ScreenPreferences();
            return ScreenWithPreferences(
              screen: s,
              preferences: effectivePrefs,
            );
          })
          .toList(growable: false);

      systemScreens.sort(
        (a, b) => a.effectiveSortOrder.compareTo(b.effectiveSortOrder),
      );

      talker.repositoryLog(
        'Screens',
        'watchSystemScreens: ${systemScreens.length} system screens from code',
      );
      return systemScreens;
    });
  }

  @override
  Stream<ScreenWithPreferences?> watchScreen(String screenKey) {
    final systemScreen = SystemScreenSpecs.getByKey(screenKey);
    if (systemScreen != null) {
      // System screen definition comes from code; preferences come from DB.
      return _preferencesDao
          .watchOne(systemScreen.screenKey)
          .map(
            (prefs) => ScreenWithPreferences(
              screen: systemScreen,
              preferences: prefs ?? const ScreenPreferences(),
            ),
          );
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
