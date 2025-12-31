import 'package:drift/drift.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' as db;
import 'package:taskly_bloc/data/drift/features/screen_tables.drift.dart'
    as db_screens;
import 'package:taskly_bloc/domain/models/screens/completion_criteria.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart'
    as domain_screens;
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/trigger_config.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:uuid/uuid.dart';

/// Drift implementation of [ScreenDefinitionsRepositoryContract].
class ScreenDefinitionsRepositoryImpl
    implements ScreenDefinitionsRepositoryContract {
  ScreenDefinitionsRepositoryImpl(this._db);

  final db.AppDatabase _db;
  final Uuid _uuid = const Uuid();

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
  Stream<ScreenDefinition?> watchScreenByScreenId(String screenId) {
    talker.repositoryLog(
      'Screens',
      'watchScreenByScreenId called: screenId="$screenId"',
    );
    return (_db.select(
      _db.screenDefinitions,
    )..where((t) => t.screenId.equals(screenId))).watchSingleOrNull().map((e) {
      talker.repositoryLog(
        'Screens',
        'watchScreenByScreenId stream emission: screenId="$screenId", entity=${e == null ? "null" : "exists(id=${e.id})"}',
      );
      if (e == null) return null;
      try {
        final mapped = _mapEntity(e);
        talker.repositoryLog(
          'Screens',
          'watchScreenByScreenId mapped successfully: ${mapped.screenId}',
        );
        return mapped;
      } catch (err, st) {
        talker.databaseError(
          'Screens.watchScreenByScreenId._mapEntity - Raw entity data: id=${e.id}, screenId=${e.screenId}, selectorConfig type=${e.selectorConfig.runtimeType}',
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
    final (screenType, selector, display, trigger, completionCriteria) = _split(
      screen,
    );

    final iconName = _requireIconName(screen);

    await _db
        .into(_db.screenDefinitions)
        .insert(
          db.ScreenDefinitionsCompanion.insert(
            id: Value(id),
            screenType: screenType,
            screenId: _extractScreenId(screen),
            name: _extractName(screen),
            iconName: Value(iconName),
            isSystem: Value(_extractIsSystem(screen)),
            isActive: Value(_extractIsActive(screen)),
            sortOrder: Value(_extractSortOrder(screen)),
            category: Value(_toDbCategory(_extractCategory(screen))),
            entityType: Value(_toDbEntityType(selector.entityType)),
            selectorConfig: Value(selector),
            displayConfig: Value(display),
            triggerConfig: Value(trigger),
            completionCriteria: Value(completionCriteria),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
          mode: InsertMode.insertOrAbort,
        );

    return id;
  }

  @override
  Future<void> updateScreen(ScreenDefinition screen) async {
    final now = DateTime.now();
    final (screenType, selector, display, trigger, completionCriteria) = _split(
      screen,
    );

    final iconName = _requireIconName(screen);

    await (_db.update(
      _db.screenDefinitions,
    )..where((t) => t.id.equals(_extractId(screen)))).write(
      db.ScreenDefinitionsCompanion(
        screenType: Value(screenType),
        screenId: Value(_extractScreenId(screen)),
        name: Value(_extractName(screen)),
        iconName: Value(iconName),
        isSystem: Value(_extractIsSystem(screen)),
        isActive: Value(_extractIsActive(screen)),
        sortOrder: Value(_extractSortOrder(screen)),
        category: Value(_toDbCategory(_extractCategory(screen))),
        entityType: Value(_toDbEntityType(selector.entityType)),
        selectorConfig: Value(selector),
        displayConfig: Value(display),
        triggerConfig: Value(trigger),
        completionCriteria: Value(completionCriteria),
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
    final trigger = e.triggerConfig;
    final completionCriteria = e.completionCriteria;

    // Map category from Drift enum to domain enum
    final category = switch (e.category) {
      null => ScreenCategory.workspace,
      db_screens.ScreenCategory.workspace => ScreenCategory.workspace,
      db_screens.ScreenCategory.wellbeing => ScreenCategory.wellbeing,
      db_screens.ScreenCategory.settings => ScreenCategory.settings,
    };

    final base = (
      id: e.id,
      userId: e.userId ?? '',
      screenId: e.screenId,
      name: e.name,
      selector: selector,
      display: display,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      iconName: e.iconName,
      isSystem: e.isSystem,
      isActive: e.isActive,
      sortOrder: e.sortOrder,
      category: category,
    );

    return switch (e.screenType) {
      db_screens.ScreenType.collection => ScreenDefinition.collection(
        id: base.id,
        userId: base.userId,
        screenId: base.screenId,
        name: base.name,
        selector: base.selector,
        display: base.display,
        createdAt: base.createdAt,
        updatedAt: base.updatedAt,
        iconName: base.iconName,
        isSystem: base.isSystem,
        isActive: base.isActive,
        sortOrder: base.sortOrder,
        category: base.category,
      ),
      db_screens.ScreenType.workflow => ScreenDefinition.workflow(
        id: base.id,
        userId: base.userId,
        screenId: base.screenId,
        name: base.name,
        selector: base.selector,
        display: base.display,
        createdAt: base.createdAt,
        updatedAt: base.updatedAt,
        iconName: base.iconName,
        isSystem: base.isSystem,
        isActive: base.isActive,
        sortOrder: base.sortOrder,
        category: base.category,
        trigger: trigger,
        completionCriteria: completionCriteria,
      ),
    };
  }

  db_screens.EntityType _toDbEntityType(domain_screens.EntityType type) {
    return db_screens.EntityType.values.byName(type.name);
  }

  domain_screens.EntityType _fromDbEntityType(db_screens.EntityType? type) {
    return switch (type) {
      null => domain_screens.EntityType.task,
      _ => domain_screens.EntityType.values.byName(type.name),
    };
  }

  db_screens.ScreenCategory _toDbCategory(ScreenCategory category) {
    return db_screens.ScreenCategory.values.byName(category.name);
  }

  ScreenCategory _extractCategory(ScreenDefinition screen) {
    return screen.when(
      collection:
          (
            id,
            userId,
            screenId,
            name,
            selector,
            display,
            createdAt,
            updatedAt,
            iconName,
            isSystem,
            isActive,
            sortOrder,
            category,
          ) => category,
      workflow:
          (
            id,
            userId,
            screenId,
            name,
            selector,
            display,
            createdAt,
            updatedAt,
            iconName,
            isSystem,
            isActive,
            sortOrder,
            category,
            trigger,
            completionCriteria,
          ) => category,
    );
  }

  (
    db_screens.ScreenType,
    domain_screens.EntitySelector,
    DisplayConfig,
    TriggerConfig?,
    CompletionCriteria?,
  )
  _split(ScreenDefinition screen) {
    return screen.when(
      collection:
          (
            id,
            userId,
            screenId,
            name,
            selector,
            display,
            createdAt,
            updatedAt,
            iconName,
            isSystem,
            isActive,
            sortOrder,
            category,
          ) => (
            db_screens.ScreenType.collection,
            selector,
            display,
            null,
            null,
          ),
      workflow:
          (
            id,
            userId,
            screenId,
            name,
            selector,
            display,
            createdAt,
            updatedAt,
            iconName,
            isSystem,
            isActive,
            sortOrder,
            category,
            trigger,
            completionCriteria,
          ) => (
            db_screens.ScreenType.workflow,
            selector,
            display,
            trigger,
            completionCriteria,
          ),
    );
  }

  String _extractOrGenerateId(ScreenDefinition screen) {
    final id = _extractId(screen);
    if (id.isNotEmpty) return id;
    return _uuid.v4();
  }

  String _extractId(ScreenDefinition screen) {
    return screen.when(
      collection:
          (
            id,
            userId,
            screenId,
            name,
            selector,
            display,
            createdAt,
            updatedAt,
            iconName,
            isSystem,
            isActive,
            sortOrder,
            category,
          ) => id,
      workflow:
          (
            id,
            userId,
            screenId,
            name,
            selector,
            display,
            createdAt,
            updatedAt,
            iconName,
            isSystem,
            isActive,
            sortOrder,
            category,
            trigger,
            completionCriteria,
          ) => id,
    );
  }

  String _extractScreenId(ScreenDefinition screen) {
    return screen.when(
      collection:
          (
            id,
            userId,
            screenId,
            name,
            selector,
            display,
            createdAt,
            updatedAt,
            iconName,
            isSystem,
            isActive,
            sortOrder,
            category,
          ) => screenId,
      workflow:
          (
            id,
            userId,
            screenId,
            name,
            selector,
            display,
            createdAt,
            updatedAt,
            iconName,
            isSystem,
            isActive,
            sortOrder,
            category,
            trigger,
            completionCriteria,
          ) => screenId,
    );
  }

  String _extractName(ScreenDefinition screen) {
    return screen.when(
      collection:
          (
            id,
            userId,
            screenId,
            name,
            selector,
            display,
            createdAt,
            updatedAt,
            iconName,
            isSystem,
            isActive,
            sortOrder,
            category,
          ) => name,
      workflow:
          (
            id,
            userId,
            screenId,
            name,
            selector,
            display,
            createdAt,
            updatedAt,
            iconName,
            isSystem,
            isActive,
            sortOrder,
            category,
            trigger,
            completionCriteria,
          ) => name,
    );
  }

  String _requireIconName(ScreenDefinition screen) {
    final iconName = screen.when(
      collection:
          (
            id,
            userId,
            screenId,
            name,
            selector,
            display,
            createdAt,
            updatedAt,
            iconName,
            isSystem,
            isActive,
            sortOrder,
            category,
          ) => iconName,
      workflow:
          (
            id,
            userId,
            screenId,
            name,
            selector,
            display,
            createdAt,
            updatedAt,
            iconName,
            isSystem,
            isActive,
            sortOrder,
            category,
            trigger,
            completionCriteria,
          ) => iconName,
    );

    if (iconName == null || iconName.trim().isEmpty) {
      throw ArgumentError(
        'iconName is required for screen ${_extractScreenId(screen)}',
      );
    }

    return iconName.trim();
  }

  bool _extractIsSystem(ScreenDefinition screen) {
    return screen.when(
      collection:
          (
            id,
            userId,
            screenId,
            name,
            selector,
            display,
            createdAt,
            updatedAt,
            iconName,
            isSystem,
            isActive,
            sortOrder,
            category,
          ) => isSystem,
      workflow:
          (
            id,
            userId,
            screenId,
            name,
            selector,
            display,
            createdAt,
            updatedAt,
            iconName,
            isSystem,
            isActive,
            sortOrder,
            category,
            trigger,
            completionCriteria,
          ) => isSystem,
    );
  }

  bool _extractIsActive(ScreenDefinition screen) {
    return screen.when(
      collection:
          (
            id,
            userId,
            screenId,
            name,
            selector,
            display,
            createdAt,
            updatedAt,
            iconName,
            isSystem,
            isActive,
            sortOrder,
            category,
          ) => isActive,
      workflow:
          (
            id,
            userId,
            screenId,
            name,
            selector,
            display,
            createdAt,
            updatedAt,
            iconName,
            isSystem,
            isActive,
            sortOrder,
            category,
            trigger,
            completionCriteria,
          ) => isActive,
    );
  }

  int _extractSortOrder(ScreenDefinition screen) {
    return screen.when(
      collection:
          (
            id,
            userId,
            screenId,
            name,
            selector,
            display,
            createdAt,
            updatedAt,
            iconName,
            isSystem,
            isActive,
            sortOrder,
            category,
          ) => sortOrder,
      workflow:
          (
            id,
            userId,
            screenId,
            name,
            selector,
            display,
            createdAt,
            updatedAt,
            iconName,
            isSystem,
            isActive,
            sortOrder,
            category,
            trigger,
            completionCriteria,
          ) => sortOrder,
    );
  }
}
