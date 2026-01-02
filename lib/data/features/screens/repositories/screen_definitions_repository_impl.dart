import 'package:drift/drift.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' as db;
import 'package:taskly_bloc/data/drift/features/screen_tables.drift.dart'
    as db_screens;
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart'
    as domain_screens;
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/view_definition.dart';
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
          'Screens.watchScreenByScreenKey._mapEntity - Raw entity data: id=${e.id}, screenKey=${e.screenKey}, selectorConfig type=${e.selectorConfig.runtimeType}',
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
    final (screenType, selector, display) = _split(screen);

    final iconName = _requireIconName(screen);

    await _db
        .into(_db.screenDefinitions)
        .insert(
          db.ScreenDefinitionsCompanion.insert(
            id: id,
            screenType: screenType,
            screenKey: _extractScreenKey(screen),
            name: _extractName(screen),
            iconName: Value(iconName),
            isSystem: Value(_extractIsSystem(screen)),
            isActive: Value(_extractIsActive(screen)),
            sortOrder: Value(_extractSortOrder(screen)),
            category: Value(_extractCategory(screen)),
            entityType: Value(_toDbEntityType(selector.entityType)),
            selectorConfig: Value(selector),
            displayConfig: Value(display),
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
        final (screenType, selector, display) = _split(screen);

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
            screenType: screenType,
            screenKey: _extractScreenKey(screen),
            name: _extractName(screen),
            iconName: Value(iconName),
            isSystem: Value(true),
            isActive: Value(_extractIsActive(screen)),
            sortOrder: Value(_extractSortOrder(screen)),
            category: Value(_extractCategory(screen)),
            entityType: Value(_toDbEntityType(selector.entityType)),
            selectorConfig: Value(selector),
            displayConfig: Value(display),
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
    final (screenType, selector, display) = _split(screen);

    final iconName = _requireIconName(screen);

    await (_db.update(
      _db.screenDefinitions,
    )..where((t) => t.id.equals(_extractId(screen)))).write(
      db.ScreenDefinitionsCompanion(
        screenType: Value(screenType),
        screenKey: Value(_extractScreenKey(screen)),
        name: Value(_extractName(screen)),
        iconName: Value(iconName),
        isSystem: Value(_extractIsSystem(screen)),
        isActive: Value(_extractIsActive(screen)),
        sortOrder: Value(_extractSortOrder(screen)),
        entityType: Value(_toDbEntityType(selector.entityType)),
        selectorConfig: Value(selector),
        displayConfig: Value(display),
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

  List<ScreenDefinition> _mapEntities(
    List<db.ScreenDefinitionEntity> e,
  ) {
    return e.map(_mapEntity).toList(growable: false);
  }

  ScreenDefinition _mapEntity(db.ScreenDefinitionEntity e) {
    // TypeConverters handle all JSON deserialization automatically
    final selector =
        e.selectorConfig ??
        domain_screens.EntitySelector(
          entityType: _fromDbEntityType(e.entityType),
        );
    final display = e.displayConfig ?? const DisplayConfig();

    // Map category from Drift enum to domain enum
    final category = switch (e.category) {
      db_screens.ScreenCategory.workspace => ScreenCategory.workspace,
      db_screens.ScreenCategory.wellbeing => ScreenCategory.wellbeing,
      db_screens.ScreenCategory.settings => ScreenCategory.settings,
      null => ScreenCategory.workspace,
    };

    // Create ViewDefinition based on screen type
    // For now, all screens use collection view (will expand in later phases)
    final view = ViewDefinition.collection(
      selector: selector,
      display: display,
    );

    return ScreenDefinition(
      id: e.id,
      screenKey: e.screenKey,
      name: e.name,
      view: view,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      iconName: e.iconName,
      isSystem: e.isSystem,
      isActive: e.isActive,
      sortOrder: e.sortOrder,
      category: category,
    );
  }

  db_screens.EntityType _toDbEntityType(domain_screens.EntityType type) {
    return db_screens.EntityType.values.byName(type.name);
  }

  domain_screens.EntityType _fromDbEntityType(db_screens.EntityType? type) {
    if (type == null) return domain_screens.EntityType.task;
    return domain_screens.EntityType.values.byName(type.name);
  }

  (
    db_screens.ScreenType,
    domain_screens.EntitySelector,
    DisplayConfig,
  )
  _split(ScreenDefinition screen) {
    // Extract selector and display from ViewDefinition
    return screen.view.when(
      collection: (selector, display, supportBlocks) => (
        db_screens.ScreenType.collection,
        selector,
        display,
      ),
      agenda: (selector, display, config, supportBlocks) => (
        // For agenda views, we'll use collection type with default selector
        db_screens.ScreenType.collection,
        selector,
        display,
      ),
      detail: (parentType, childView, supportBlocks) => (
        // For detail views, we'll use collection type with default selector
        db_screens.ScreenType.collection,
        const domain_screens.EntitySelector(
          entityType: domain_screens.EntityType.task,
        ),
        const DisplayConfig(),
      ),
      allocated: (selector, display, supportBlocks) => (
        // For allocated views, we'll use collection type with default selector
        db_screens.ScreenType.collection,
        selector,
        display,
      ),
    );
  }

  String _extractOrGenerateId(ScreenDefinition screen) {
    final id = _extractId(screen);
    if (id.isNotEmpty) return id;
    // Use v5 deterministic ID based on screenKey
    return _idGenerator.screenDefinitionId(screenKey: screen.screenKey);
  }

  String _extractId(ScreenDefinition screen) {
    return screen.id;
  }

  String _extractScreenKey(ScreenDefinition screen) {
    return screen.screenKey;
  }

  String _extractName(ScreenDefinition screen) {
    return screen.name;
  }

  String _requireIconName(ScreenDefinition screen) {
    final iconName = screen.iconName;

    if (iconName == null || iconName.trim().isEmpty) {
      throw ArgumentError(
        'iconName is required for screen ${_extractScreenKey(screen)}',
      );
    }

    return iconName.trim();
  }

  bool _extractIsSystem(ScreenDefinition screen) {
    return screen.isSystem;
  }

  bool _extractIsActive(ScreenDefinition screen) {
    return screen.isActive;
  }

  int _extractSortOrder(ScreenDefinition screen) {
    return screen.sortOrder;
  }

  db_screens.ScreenCategory _extractCategory(ScreenDefinition screen) {
    final category = screen.category;

    return switch (category) {
      ScreenCategory.workspace => db_screens.ScreenCategory.workspace,
      ScreenCategory.wellbeing => db_screens.ScreenCategory.wellbeing,
      ScreenCategory.settings => db_screens.ScreenCategory.settings,
    };
  }
}
