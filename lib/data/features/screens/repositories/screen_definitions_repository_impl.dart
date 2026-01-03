import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' as db;
import 'package:taskly_bloc/data/drift/features/screen_tables.drift.dart'
    as db_screens;
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/system_screen_provider.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';
import 'package:taskly_bloc/domain/models/settings/screen_preferences.dart';

/// Drift implementation of [ScreenDefinitionsRepositoryContract].
///
/// ## Architecture
///
/// This repository merges screens from two sources:
/// 1. **System screens** - From [SystemScreenProvider] (code-based)
/// 2. **Custom screens** - From database (user-created)
///
/// User preferences (sortOrder, isActive) are stored in
/// `AppSettings.screenPreferences` via [SettingsRepositoryContract].
class ScreenDefinitionsRepositoryImpl
    implements ScreenDefinitionsRepositoryContract {
  ScreenDefinitionsRepositoryImpl(
    this._db,
    this._idGenerator,
    this._systemScreenProvider,
    this._settingsRepository,
  );

  final db.AppDatabase _db;
  final IdGenerator _idGenerator;
  final SystemScreenProvider _systemScreenProvider;
  final SettingsRepositoryContract _settingsRepository;

  @override
  Stream<List<ScreenWithPreferences>> watchAllScreens() {
    // Combine system screens + custom screens + preferences
    return Rx.combineLatest3<
      List<ScreenDefinition>,
      List<ScreenDefinition>,
      Map<String, ScreenPreferences>,
      List<ScreenWithPreferences>
    >(
      Stream.value(_systemScreenProvider.getSystemScreens()),
      watchCustomScreens(),
      _settingsRepository.watch(SettingsKey.allScreenPrefs),
      (systemScreens, customScreens, allPrefs) {
        final allScreens = <ScreenWithPreferences>[];

        // Add system screens with preferences
        for (final screen in systemScreens) {
          final prefs = allPrefs[screen.screenKey] ?? const ScreenPreferences();
          if (prefs.isActive) {
            allScreens.add(
              ScreenWithPreferences(
                screen: screen,
                preferences: prefs,
              ),
            );
          }
        }

        // Add custom screens with preferences
        for (final screen in customScreens) {
          final prefs = allPrefs[screen.screenKey] ?? const ScreenPreferences();
          if (prefs.isActive) {
            allScreens.add(
              ScreenWithPreferences(
                screen: screen,
                preferences: prefs,
              ),
            );
          }
        }

        // Sort by effective sortOrder
        allScreens.sort((a, b) {
          final aOrder =
              a.preferences.sortOrder ??
              _systemScreenProvider.getDefaultSortOrder(a.screen.screenKey);
          final bOrder =
              b.preferences.sortOrder ??
              _systemScreenProvider.getDefaultSortOrder(b.screen.screenKey);
          return aOrder.compareTo(bOrder);
        });

        talker.repositoryLog(
          'Screens',
          'watchAllScreens: ${allScreens.length} active screens '
              '(${systemScreens.length} system, ${customScreens.length} custom)',
        );

        return allScreens;
      },
    );
  }

  @override
  Stream<List<ScreenWithPreferences>> watchSystemScreens() {
    return _settingsRepository.watch(SettingsKey.allScreenPrefs).map((
      allPrefs,
    ) {
      final systemScreens = _systemScreenProvider.getSystemScreens();
      final result = <ScreenWithPreferences>[];

      for (final screen in systemScreens) {
        final prefs = allPrefs[screen.screenKey] ?? const ScreenPreferences();
        result.add(
          ScreenWithPreferences(
            screen: screen,
            preferences: prefs,
          ),
        );
      }

      // Sort by effective sortOrder
      result.sort((a, b) {
        final aOrder =
            a.preferences.sortOrder ??
            _systemScreenProvider.getDefaultSortOrder(a.screen.screenKey);
        final bOrder =
            b.preferences.sortOrder ??
            _systemScreenProvider.getDefaultSortOrder(b.screen.screenKey);
        return aOrder.compareTo(bOrder);
      });

      return result;
    });
  }

  @override
  Stream<List<ScreenDefinition>> watchCustomScreens() {
    return (_db.select(_db.screenDefinitions)
          ..where((t) => t.isSystem.equals(false))
          ..orderBy([
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
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
    // Check if it's a system screen
    if (_systemScreenProvider.isSystemScreen(screenKey)) {
      return _settingsRepository.watch(SettingsKey.screenPrefs(screenKey)).map((
        prefs,
      ) {
        final screen = _systemScreenProvider.getSystemScreen(screenKey);
        if (screen == null) return null;
        return ScreenWithPreferences(screen: screen, preferences: prefs);
      });
    }

    // Look up custom screen from database
    return Rx.combineLatest2<
      ScreenDefinition?,
      ScreenPreferences,
      ScreenWithPreferences?
    >(
      (_db.select(_db.screenDefinitions)
            ..where((t) => t.screenKey.equals(screenKey)))
          .watchSingleOrNull()
          .map((e) => e == null ? null : _mapEntity(e)),
      _settingsRepository.watch(SettingsKey.screenPrefs(screenKey)),
      (screen, prefs) {
        if (screen == null) return null;
        return ScreenWithPreferences(screen: screen, preferences: prefs);
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
    if (screen.isSystem) {
      throw ArgumentError('Cannot create system screen via repository');
    }

    final now = DateTime.now();
    final id = screen.id.isNotEmpty
        ? screen.id
        : _idGenerator.screenDefinitionId(screenKey: screen.screenKey);
    final iconName = _requireIconName(screen);

    // Extract variant-specific fields
    final (
      screenType,
      sections,
      supportBlocks,
      triggerConfig,
    ) = switch (screen) {
      DataDrivenScreenDefinition(
        :final screenType,
        :final sections,
        :final supportBlocks,
        :final triggerConfig,
      ) =>
        (
          _toDbScreenType(screenType),
          sections,
          supportBlocks,
          triggerConfig,
        ),
      NavigationOnlyScreenDefinition() => (
        null,
        const <Section>[],
        const <SupportBlock>[],
        null,
      ),
    };

    await _db
        .into(_db.screenDefinitions)
        .insert(
          db.ScreenDefinitionsCompanion.insert(
            id: id,
            screenType: Value(screenType),
            screenKey: screen.screenKey,
            name: screen.name,
            iconName: Value(iconName),
            isSystem: const Value(false),
            category: Value(_toDbCategory(screen.category)),
            sectionsConfig: Value(sections),
            supportBlocksConfig: Value(supportBlocks),
            triggerConfig: Value(triggerConfig),
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
    if (screen.isSystem) {
      throw ArgumentError('Cannot update system screen via repository');
    }

    final now = DateTime.now();
    final iconName = _requireIconName(screen);

    // Extract variant-specific fields
    final (
      screenType,
      sections,
      supportBlocks,
      triggerConfig,
    ) = switch (screen) {
      DataDrivenScreenDefinition(
        :final screenType,
        :final sections,
        :final supportBlocks,
        :final triggerConfig,
      ) =>
        (
          _toDbScreenType(screenType),
          sections,
          supportBlocks,
          triggerConfig,
        ),
      NavigationOnlyScreenDefinition() => (
        null,
        const <Section>[],
        const <SupportBlock>[],
        null,
      ),
    };

    await (_db.update(
      _db.screenDefinitions,
    )..where((t) => t.screenKey.equals(screen.screenKey))).write(
      db.ScreenDefinitionsCompanion(
        screenType: Value(screenType),
        name: Value(screen.name),
        iconName: Value(iconName),
        category: Value(_toDbCategory(screen.category)),
        sectionsConfig: Value(sections),
        supportBlocksConfig: Value(supportBlocks),
        triggerConfig: Value(triggerConfig),
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
    await _settingsRepository.save(
      SettingsKey.screenPrefs(screenKey),
      preferences,
    );

    talker.repositoryLog(
      'Screens',
      'updateScreenPreferences: screenKey=$screenKey, '
          'sortOrder=${preferences.sortOrder}, isActive=${preferences.isActive}',
    );
  }

  @override
  Future<void> reorderScreens(List<String> orderedScreenKeys) async {
    // Load current preferences
    final allPrefs = await _settingsRepository.load(SettingsKey.allScreenPrefs);
    final updatedPrefs = Map<String, ScreenPreferences>.from(allPrefs);

    // Update sortOrder for each screen
    for (var index = 0; index < orderedScreenKeys.length; index++) {
      final screenKey = orderedScreenKeys[index];
      final existing = updatedPrefs[screenKey] ?? const ScreenPreferences();
      updatedPrefs[screenKey] = ScreenPreferences(
        sortOrder: index,
        isActive: existing.isActive,
      );
    }

    // Save updated preferences
    await _settingsRepository.save(SettingsKey.allScreenPrefs, updatedPrefs);

    talker.repositoryLog(
      'Screens',
      'reorderScreens: updated ${orderedScreenKeys.length} screen orders',
    );
  }

  // ============================================================================
  // Mapping Methods
  // ============================================================================

  List<ScreenDefinition> _mapEntities(
    List<db.ScreenDefinitionEntity> entities,
  ) {
    return entities.map(_mapEntity).toList(growable: false);
  }

  ScreenDefinition _mapEntity(db.ScreenDefinitionEntity e) {
    // Map category from Drift enum to domain enum
    final category = switch (e.category) {
      db_screens.ScreenCategory.workspace => ScreenCategory.workspace,
      db_screens.ScreenCategory.wellbeing => ScreenCategory.wellbeing,
      db_screens.ScreenCategory.settings => ScreenCategory.settings,
      null => ScreenCategory.workspace,
    };

    // Infer screen type from data: empty sections = navigation-only
    final sections = e.sectionsConfig ?? const <Section>[];
    final hasContent = sections.isNotEmpty;

    if (hasContent) {
      // Map screen type from Drift enum to domain enum (default to list if null)
      final screenType = switch (e.screenType) {
        db_screens.ScreenType.list => ScreenType.list,
        db_screens.ScreenType.dashboard =>
          ScreenType.list, // Legacy: treat as list
        db_screens.ScreenType.focus => ScreenType.focus,
        db_screens.ScreenType.workflow => ScreenType.workflow,
        null => ScreenType.list, // Default for corrupted/partial data
      };

      return ScreenDefinition.dataDriven(
        id: e.id,
        screenKey: e.screenKey,
        name: e.name,
        screenType: screenType,
        sections: sections,
        supportBlocks: e.supportBlocksConfig ?? const <SupportBlock>[],
        iconName: e.iconName,
        isSystem: e.isSystem,
        category: category,
        triggerConfig: e.triggerConfig,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );
    }

    // Navigation-only screen (no sections)
    return ScreenDefinition.navigationOnly(
      id: e.id,
      screenKey: e.screenKey,
      name: e.name,
      iconName: e.iconName,
      isSystem: e.isSystem,
      category: category,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
    );
  }

  // ============================================================================
  // Conversion Methods
  // ============================================================================

  /// Converts domain ScreenType to DB ScreenType.
  /// Note: NavigationOnly screens don't have a screenType, caller should handle null.
  db_screens.ScreenType _toDbScreenType(ScreenType type) {
    return switch (type) {
      ScreenType.list => db_screens.ScreenType.list,
      ScreenType.focus => db_screens.ScreenType.focus,
      ScreenType.workflow => db_screens.ScreenType.workflow,
    };
  }

  db_screens.ScreenCategory _toDbCategory(ScreenCategory category) {
    return switch (category) {
      ScreenCategory.workspace => db_screens.ScreenCategory.workspace,
      ScreenCategory.wellbeing => db_screens.ScreenCategory.wellbeing,
      ScreenCategory.settings => db_screens.ScreenCategory.settings,
    };
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  String _requireIconName(ScreenDefinition screen) {
    final iconName = screen.iconName;

    if (iconName == null || iconName.trim().isEmpty) {
      throw ArgumentError(
        'iconName is required for screen ${screen.screenKey}',
      );
    }

    return iconName.trim();
  }
}
