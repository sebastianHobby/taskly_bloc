import 'package:drift/drift.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' as db;
import 'package:taskly_bloc/data/drift/features/screen_tables.drift.dart'
    as db_screens;
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';

/// Drift implementation of [ScreenDefinitionsRepositoryContract].
class ScreenDefinitionsRepositoryImpl
    implements ScreenDefinitionsRepositoryContract {
  ScreenDefinitionsRepositoryImpl(this._db, this._idGenerator);

  final db.AppDatabase _db;
  final IdGenerator _idGenerator;

  @override
  Stream<List<ScreenDefinition>> watchAllScreens() {
    return (_db.select(_db.screenDefinitions)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .watch()
        .map(_mapEntities);
  }

  @override
  Stream<List<ScreenDefinition>> watchSystemScreens() {
    return (_db.select(_db.screenDefinitions)
          ..where((t) => t.isActive.equals(true) & t.isSystem.equals(true))
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .watch()
        .map(_mapEntities);
  }

  @override
  Stream<List<ScreenDefinition>> watchUserScreens() {
    return (_db.select(_db.screenDefinitions)
          ..where((t) => t.isActive.equals(true) & t.isSystem.equals(false))
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .watch()
        .map(_mapEntities);
  }

  @override
  Stream<ScreenDefinition?> watchScreen(String id) {
    return (_db.select(_db.screenDefinitions)..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((e) => e == null ? null : _mapEntity(e));
  }

  @override
  Stream<ScreenDefinition?> watchScreenByScreenKey(String screenKey) {
    talker.repositoryLog(
      'Screens',
      'watchScreenByScreenKey called: screenKey="$screenKey"',
    );
    return (_db.select(
      _db.screenDefinitions,
    )..where((t) => t.screenKey.equals(screenKey))).watchSingleOrNull().map((
      e,
    ) {
      talker.repositoryLog(
        'Screens',
        'watchScreenByScreenKey stream emission: screenKey="$screenKey", entity=${e == null ? "null" : "exists(id=${e.id})"}',
      );
      if (e == null) return null;
      try {
        final mapped = _mapEntity(e);
        talker.repositoryLog(
          'Screens',
          'watchScreenByScreenKey mapped successfully: ${mapped.screenKey}',
        );
        return mapped;
      } catch (err, st) {
        talker.databaseError(
          'Screens.watchScreenByScreenKey._mapEntity - Raw entity data: id=${e.id}, screenKey=${e.screenKey}',
          err,
          st,
        );
        rethrow;
      }
    });
  }

  @override
  Future<String> createScreen(ScreenDefinition screen) async {
    final now = DateTime.now();

    final id = _extractOrGenerateId(screen);
    final screenType = _toDbScreenType(screen.screenType);

    final iconName = _requireIconName(screen);

    await _db
        .into(_db.screenDefinitions)
        .insert(
          db.ScreenDefinitionsCompanion.insert(
            id: id,
            screenType: Value(screenType),
            screenKey: screen.screenKey,
            name: screen.name,
            iconName: Value(iconName),
            isSystem: Value(screen.isSystem),
            isActive: Value(screen.isActive),
            sortOrder: Value(screen.sortOrder),
            category: Value(_toDbCategory(screen.category)),
            sectionsConfig: Value(screen.sections),
            supportBlocksConfig: Value(screen.supportBlocks),
            triggerConfig: Value(screen.triggerConfig),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
          mode: InsertMode.insertOrAbort,
        );

    return id;
  }

  @override
  Future<void> seedSystemScreens(List<ScreenDefinition> screens) async {
    final now = DateTime.now();

    await _db.batch((batch) {
      for (final screen in screens) {
        final screenType = _toDbScreenType(screen.screenType);
        final iconName = _requireIconName(screen);

        // Generate v5 ID if empty (system screens from factory)
        final id = screen.id.isEmpty
            ? _idGenerator.screenDefinitionId(screenKey: screen.screenKey)
            : screen.id;

        batch.insert(
          _db.screenDefinitions,
          db.ScreenDefinitionsCompanion.insert(
            id: id,
            // userId is set by Supabase trigger/RLS, we don't set it locally
            screenType: Value(screenType),
            screenKey: screen.screenKey,
            name: screen.name,
            iconName: Value(iconName),
            isSystem: Value(true),
            isActive: Value(screen.isActive),
            sortOrder: Value(screen.sortOrder),
            category: Value(_toDbCategory(screen.category)),
            sectionsConfig: Value(screen.sections),
            supportBlocksConfig: Value(screen.supportBlocks),
            triggerConfig: Value(screen.triggerConfig),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });

    talker.repositoryLog(
      'Screens',
      'seedSystemScreens: seeded ${screens.length} system screens',
    );
  }

  @override
  Future<void> updateScreen(ScreenDefinition screen) async {
    final now = DateTime.now();
    final screenType = _toDbScreenType(screen.screenType);
    final iconName = _requireIconName(screen);

    await (_db.update(
      _db.screenDefinitions,
    )..where((t) => t.id.equals(screen.id))).write(
      db.ScreenDefinitionsCompanion(
        screenType: Value(screenType),
        screenKey: Value(screen.screenKey),
        name: Value(screen.name),
        iconName: Value(iconName),
        isSystem: Value(screen.isSystem),
        isActive: Value(screen.isActive),
        sortOrder: Value(screen.sortOrder),
        category: Value(_toDbCategory(screen.category)),
        sectionsConfig: Value(screen.sections),
        supportBlocksConfig: Value(screen.supportBlocks),
        triggerConfig: Value(screen.triggerConfig),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> deleteScreen(String id) async {
    final existing = await (_db.select(
      _db.screenDefinitions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (existing == null) return;
    if (existing.isSystem) {
      throw StateError('Cannot delete system screen $id');
    }

    await (_db.delete(
      _db.screenDefinitions,
    )..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> setScreenActive(String id, bool isActive) async {
    await (_db.update(
      _db.screenDefinitions,
    )..where((t) => t.id.equals(id))).write(
      db.ScreenDefinitionsCompanion(
        isActive: Value(isActive),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> reorderScreens(List<String> orderedIds) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      for (var index = 0; index < orderedIds.length; index++) {
        await (_db.update(
          _db.screenDefinitions,
        )..where((t) => t.id.equals(orderedIds[index]))).write(
          db.ScreenDefinitionsCompanion(
            sortOrder: Value(index),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  // ============================================================================
  // Mapping Methods
  // ============================================================================

  List<ScreenDefinition> _mapEntities(
    List<db.ScreenDefinitionEntity> e,
  ) {
    return e.map(_mapEntity).toList(growable: false);
  }

  ScreenDefinition _mapEntity(db.ScreenDefinitionEntity e) {
    // Map category from Drift enum to domain enum
    final category = switch (e.category) {
      db_screens.ScreenCategory.workspace => ScreenCategory.workspace,
      db_screens.ScreenCategory.wellbeing => ScreenCategory.wellbeing,
      db_screens.ScreenCategory.settings => ScreenCategory.settings,
      null => ScreenCategory.workspace,
    };

    // Map screen type from Drift enum to domain enum (default to list if null)
    final screenType = switch (e.screenType) {
      db_screens.ScreenType.list => ScreenType.list,
      db_screens.ScreenType.dashboard => ScreenType.dashboard,
      db_screens.ScreenType.focus => ScreenType.focus,
      db_screens.ScreenType.workflow => ScreenType.workflow,
      null => ScreenType.list, // Default for corrupted/partial data
    };

    return ScreenDefinition(
      id: e.id,
      screenKey: e.screenKey,
      name: e.name,
      screenType: screenType,
      sections: e.sectionsConfig ?? const <Section>[],
      supportBlocks: e.supportBlocksConfig ?? const <SupportBlock>[],
      iconName: e.iconName,
      isSystem: e.isSystem,
      isActive: e.isActive,
      sortOrder: e.sortOrder,
      category: category,
      triggerConfig: e.triggerConfig,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
    );
  }

  // ============================================================================
  // Conversion Methods
  // ============================================================================

  db_screens.ScreenType _toDbScreenType(ScreenType type) {
    return switch (type) {
      ScreenType.list => db_screens.ScreenType.list,
      ScreenType.dashboard => db_screens.ScreenType.dashboard,
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

  String _extractOrGenerateId(ScreenDefinition screen) {
    if (screen.id.isNotEmpty) return screen.id;
    // Use v5 deterministic ID based on screenKey
    return _idGenerator.screenDefinitionId(screenKey: screen.screenKey);
  }

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
