import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/features/screens/daos/screen_preferences_dao.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' as db;
import 'package:taskly_bloc/data/drift/features/shared_enums.dart'
    as shared_enums;
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/system_screen_provider.dart';
import 'package:taskly_bloc/domain/models/screens/actions_config.dart';
import 'package:taskly_bloc/domain/models/screens/content_config.dart';
import 'package:taskly_bloc/domain/models/screens/screen_chrome.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/screen_source.dart';
import 'package:taskly_bloc/domain/models/screens/system_screen_definitions.dart';
import 'package:taskly_bloc/domain/models/settings/screen_preferences.dart';

/// Drift implementation of [ScreenDefinitionsRepositoryContract].
///
/// ## Architecture (Option B)
///
/// - System screen definitions come from code via [SystemScreenDefinitions].
/// - Custom screen definitions come from the database (`screen_definitions`).
/// - Preferences (sort order + visibility) come from `screen_preferences`.
/// - Legacy fallback: older `screen_definitions` rows with
///   `source='system_template'` may exist and only contribute preference-like
///   fields (`isActive/sortOrder`) when a dedicated preference row is missing.
class ScreenDefinitionsRepositoryImpl
    implements ScreenDefinitionsRepositoryContract {
  ScreenDefinitionsRepositoryImpl(
    this._db,
    this._idGenerator,
    this._systemScreenProvider,
  ) : _preferencesDao = ScreenPreferencesDao(_db);

  final db.AppDatabase _db;
  final IdGenerator _idGenerator;
  final SystemScreenProvider _systemScreenProvider;
  final ScreenPreferencesDao _preferencesDao;

  @override
  Stream<List<ScreenWithPreferences>> watchAllScreens() {
    // Option B:
    // - System screens come from code templates (always available)
    // - Custom screens come from DB
    // - Preferences (isActive/sortOrder) come from screen_preferences
    // - Legacy fallback: if no preference row exists, reuse legacy values
    //   from screen_definitions where available (no writes required).

    final customScreensStream =
        (_db.select(_db.screenDefinitions)..where(
              (t) =>
                  t.source.equals(shared_enums.EntitySource.user_created.name),
            ))
            .watch();

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

    return Rx.combineLatest3<
      List<db.ScreenDefinitionEntity>,
      Map<String, ScreenPreferences>,
      Map<String, ScreenPreferences>,
      List<ScreenWithPreferences>
    >(
      customScreensStream,
      prefsStream,
      legacySystemPrefsStream,
      (customEntities, prefsByKey, legacySystemPrefsByKey) {
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

        final customScreens = customEntities
            .map((entity) {
              final screen = _mapEntityToScreen(entity);
              final legacyPrefs = ScreenPreferences(
                sortOrder: entity.sortOrder,
                isActive: entity.isActive,
              );
              final effectivePrefs =
                  prefsByKey[screen.screenKey] ?? legacyPrefs;
              return ScreenWithPreferences(
                screen: screen,
                preferences: effectivePrefs,
              );
            })
            .toList(growable: false);

        final merged = <ScreenWithPreferences>[
          ...systemScreens,
          ...customScreens,
        ].where((s) => s.isActive).toList();
        merged.sort(
          (a, b) => a.effectiveSortOrder.compareTo(b.effectiveSortOrder),
        );

        final screenKeys = merged.map((s) => s.screen.screenKey).toList();
        talker.repositoryLog(
          'Screens',
          'watchAllScreens: ${merged.length} active screens (system+custom): '
              '$screenKeys',
        );

        return merged;
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
  Stream<List<ScreenDefinition>> watchCustomScreens() {
    // Filter for user-created screens only
    return (_db.select(_db.screenDefinitions)..where(
          (t) => t.source.equals(shared_enums.EntitySource.user_created.name),
        ))
        .watch()
        .map((entities) {
          talker.repositoryLog(
            'Screens',
            'watchCustomScreens: ${entities.length} custom screens from DB',
          );
          return _mapEntities(entities);
        });
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

    // Custom screen definition comes from DB; preferences come from DB.
    final entityStream = (_db.select(
      _db.screenDefinitions,
    )..where((t) => t.screenKey.equals(screenKey))).watchSingleOrNull();

    return Rx.combineLatest2<
      db.ScreenDefinitionEntity?,
      ScreenPreferences?,
      ScreenWithPreferences?
    >(
      entityStream,
      _preferencesDao.watchOne(screenKey),
      (entity, prefs) {
        if (entity == null) return null;
        final screen = _mapEntityToScreen(entity);
        final legacyPrefs = ScreenPreferences(
          sortOrder: entity.sortOrder,
          isActive: entity.isActive,
        );
        return ScreenWithPreferences(
          screen: screen,
          preferences: prefs ?? legacyPrefs,
        );
      },
    );
  }

  @override
  Future<bool> screenKeyExists(String screenKey) async {
    // Check system screens first
    if (_systemScreenProvider.isSystemScreen(screenKey)) {
      return true;
    }

    // Check custom screens in database
    final existing = await (_db.select(
      _db.screenDefinitions,
    )..where((t) => t.screenKey.equals(screenKey))).getSingleOrNull();

    return existing != null;
  }

  @override
  Future<String> createCustomScreen(ScreenDefinition screen) async {
    if (screen.isSystemScreen) {
      throw ArgumentError('Cannot create system screen via repository');
    }

    final now = DateTime.now();
    final id = screen.id.isNotEmpty
        ? screen.id
        : _idGenerator.screenDefinitionId(screenKey: screen.screenKey);
    final iconName = _requireIconName(screen);

    final contentConfig = ContentConfig(sections: screen.sections);
    final actionsConfig = ActionsConfig(
      fabOperations: screen.chrome.fabOperations,
      appBarActions: screen.chrome.appBarActions,
      settingsRoute: screen.chrome.settingsRoute,
    );

    await _db
        .into(_db.screenDefinitions)
        .insert(
          db.ScreenDefinitionsCompanion.insert(
            id: id,
            screenKey: screen.screenKey,
            name: screen.name,
            iconName: Value(iconName),
            source: Value(shared_enums.EntitySource.user_created),
            contentConfig: Value(contentConfig),
            actionsConfig: Value(actionsConfig),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
          mode: InsertMode.insertOrAbort,
        );

    talker.repositoryLog(
      'Screens',
      'createCustomScreen: created screenKey=${screen.screenKey}, id=$id',
    );

    return id;
  }

  @override
  Future<void> updateCustomScreen(ScreenDefinition screen) async {
    if (screen.isSystemScreen) {
      throw ArgumentError('Cannot update system screen via repository');
    }

    final now = DateTime.now();
    final iconName = _requireIconName(screen);

    final contentConfig = ContentConfig(sections: screen.sections);
    final actionsConfig = ActionsConfig(
      fabOperations: screen.chrome.fabOperations,
      appBarActions: screen.chrome.appBarActions,
      settingsRoute: screen.chrome.settingsRoute,
    );

    await (_db.update(
      _db.screenDefinitions,
    )..where((t) => t.screenKey.equals(screen.screenKey))).write(
      db.ScreenDefinitionsCompanion(
        name: Value(screen.name),
        iconName: Value(iconName),
        contentConfig: Value(contentConfig),
        actionsConfig: Value(actionsConfig),
        updatedAt: Value(now),
      ),
    );

    talker.repositoryLog(
      'Screens',
      'updateCustomScreen: updated screenKey=${screen.screenKey}',
    );
  }

  @override
  Future<void> deleteCustomScreen(String screenKey) async {
    if (_systemScreenProvider.isSystemScreen(screenKey)) {
      throw StateError('Cannot delete system screen: $screenKey');
    }

    await (_db.delete(
      _db.screenDefinitions,
    )..where((t) => t.screenKey.equals(screenKey))).go();

    talker.repositoryLog(
      'Screens',
      'deleteCustomScreen: deleted screenKey=$screenKey',
    );
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

  ScreenDefinition _mapEntityToScreen(db.ScreenDefinitionEntity entity) {
    final contentConfig = entity.contentConfig;
    final actionsConfig = entity.actionsConfig;

    final chrome = ScreenChrome(
      iconName: entity.iconName,
      fabOperations: actionsConfig?.fabOperations ?? const [],
      appBarActions: actionsConfig?.appBarActions ?? const [],
      settingsRoute: actionsConfig?.settingsRoute,
    );

    return ScreenDefinition(
      id: entity.id,
      screenKey: entity.screenKey,
      name: entity.name,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      sections: contentConfig?.sections ?? const [],
      screenSource: entity.source == shared_enums.EntitySource.system_template
          ? ScreenSource.systemTemplate
          : ScreenSource.userDefined,
      chrome: chrome,
    );
  }

  // ============================================================================
  // Mapping Methods
  // ============================================================================

  List<ScreenDefinition> _mapEntities(
    List<db.ScreenDefinitionEntity> entities,
  ) {
    return entities.map(_mapEntityToScreen).toList(growable: false);
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  String _requireIconName(ScreenDefinition screen) {
    final iconName = screen.chrome.iconName;

    if (iconName == null || iconName.trim().isEmpty) {
      throw ArgumentError(
        'iconName is required for screen ${screen.screenKey}',
      );
    }

    return iconName.trim();
  }
}
