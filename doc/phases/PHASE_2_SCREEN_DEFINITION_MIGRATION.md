# Phase 2: Screen Definition Migration

## AI Implementation Instructions

### Environment Setup
- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each file creation. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files.
- **Forms**: Prefer `flutter_form_builder` fields and extensions where applicable.
- **Reuse**: Check existing patterns in codebase before creating new ones.

### Phase Goal
Migrate ScreenDefinition model from `view: ViewDefinition` to `sections: List<Section>`. Update database schema and migrate all 11 system screens to new format.

### Prerequisites
- Phase 0 complete (foundation types exist)
- Phase 1 complete (SectionDataService exists)

---

## Task 1: Update ScreenDefinition Model

**File**: `lib/domain/models/screens/screen_definition.dart`

**Current structure** (examine file first):
```dart
@freezed
class ScreenDefinition with _$ScreenDefinition {
  const factory ScreenDefinition({
    required String id,
    required String screenKey,
    required String name,
    // ... other fields
    required ViewDefinition view,  // OLD - to be replaced
  }) = _ScreenDefinition;
}
```

**New structure**:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';

part 'screen_definition.freezed.dart';
part 'screen_definition.g.dart';

@freezed
class ScreenDefinition with _$ScreenDefinition {
  const factory ScreenDefinition({
    /// Unique identifier (UUID)
    required String id,
    
    /// Stable key for system screens (e.g., 'inbox', 'today')
    /// User-defined screens use UUID as screenKey
    required String screenKey,
    
    /// Display name
    required String name,
    
    /// Material icon name (serialized as string)
    required String iconName,
    
    /// Screen category for organization
    required ScreenCategory category,
    
    /// Ordered list of sections composing the screen
    required List<Section> sections,
    
    /// Default layout for the screen
    @Default(ScreenLayout.list) ScreenLayout defaultLayout,
    
    /// Whether this is a system-defined screen (not user-deletable)
    @Default(false) bool isSystem,
    
    /// Show in navigation menu
    @Default(true) bool showInMenu,
    
    /// Menu order (lower = higher in list)
    @Default(100) int menuOrder,
    
    /// Creation timestamp
    DateTime? createdAt,
    
    /// Last update timestamp
    DateTime? updatedAt,
    
    // DEPRECATED - keep for migration, remove in Phase 6
    @Deprecated('Use sections instead') ViewDefinition? view,
  }) = _ScreenDefinition;

  factory ScreenDefinition.fromJson(Map<String, dynamic> json) =>
      _$ScreenDefinitionFromJson(json);
}

/// Screen layout options
enum ScreenLayout {
  list,      // Standard list view
  grid,      // Grid/card view
  kanban,    // Kanban columns
  tree,      // Hierarchical tree
  calendar,  // Calendar view
  agenda,    // Date-grouped agenda
}
```

**Migration Strategy**: Keep `view` field as nullable deprecated during transition. Remove in Phase 6.

---

## Task 2: Create Migration Helper

**File**: `lib/data/features/screens/view_to_sections_migrator.dart`

**Purpose**: Convert existing ViewDefinition to List<Section> for data migration.

```dart
import 'package:taskly_bloc/domain/models/screens/view_definition.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/related_data_config.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';

/// Migrates legacy ViewDefinition to List<Section> format.
class ViewToSectionsMigrator {
  /// Convert a ViewDefinition to sections
  List<Section> migrate(ViewDefinition view) {
    return switch (view) {
      CollectionView(
        :final selector,
        :final display,
        :final supportBlocks,
      ) =>
        _migrateCollection(selector, display, supportBlocks),
      
      AgendaView(
        :final selector,
        :final display,
        :final agendaConfig,
        :final supportBlocks,
      ) =>
        _migrateAgenda(selector, display, agendaConfig, supportBlocks),
      
      DetailView(
        :final parentType,
        :final childView,
        :final supportBlocks,
      ) =>
        _migrateDetail(parentType, childView, supportBlocks),
      
      AllocatedView(
        :final selector,
        :final display,
        :final supportBlocks,
      ) =>
        _migrateAllocated(selector, display, supportBlocks),
    };
  }

  List<Section> _migrateCollection(
    EntitySelector selector,
    DisplayConfig display,
    List<SupportBlock>? supportBlocks,
  ) {
    final sections = <Section>[];
    
    // Add support blocks first
    if (supportBlocks != null) {
      for (final block in supportBlocks) {
        sections.add(_migrateSupportBlock(block));
      }
    }
    
    // Add data section
    final dataConfig = _selectorToDataConfig(selector, display);
    sections.add(Section.data(config: dataConfig));
    
    return sections;
  }

  List<Section> _migrateAgenda(
    EntitySelector selector,
    DisplayConfig display,
    AgendaConfig agendaConfig,
    List<SupportBlock>? supportBlocks,
  ) {
    // Agenda is essentially a collection with date grouping
    // The agendaConfig becomes part of display settings (handled in Phase 5)
    return _migrateCollection(selector, display, supportBlocks);
  }

  List<Section> _migrateDetail(
    DetailParentType parentType,
    ViewDefinition? childView,
    List<SupportBlock>? supportBlocks,
  ) {
    final sections = <Section>[];
    
    if (supportBlocks != null) {
      for (final block in supportBlocks) {
        sections.add(_migrateSupportBlock(block));
      }
    }
    
    // Detail view: primary is project or label, with child tasks
    final dataConfig = switch (parentType) {
      DetailParentType.project => const DataConfig.project(
        query: ProjectQuery(), // Will be constrained by parentEntityId at runtime
      ),
      DetailParentType.label => const DataConfig.label(),
    };
    
    // Add related tasks if childView was defined
    final relatedData = <RelatedDataConfig>[];
    if (childView != null) {
      relatedData.add(const RelatedDataConfig.tasks());
    }
    
    sections.add(Section.data(
      config: dataConfig,
      relatedData: relatedData,
    ));
    
    return sections;
  }

  List<Section> _migrateAllocated(
    EntitySelector selector,
    DisplayConfig display,
    List<SupportBlock>? supportBlocks,
  ) {
    final sections = <Section>[];
    
    if (supportBlocks != null) {
      for (final block in supportBlocks) {
        sections.add(_migrateSupportBlock(block));
      }
    }
    
    // Allocated view uses AllocationSection
    sections.add(const Section.allocation(maxTasks: 10));
    
    return sections;
  }

  DataConfig _selectorToDataConfig(EntitySelector selector, DisplayConfig display) {
    return switch (selector.entityType) {
      EntityType.task => DataConfig.task(
        query: TaskQuery(
          filter: selector.taskFilter ?? const QueryFilter.matchAll(),
          sortCriteria: _mapSortCriteria(display.sorting),
        ),
      ),
      EntityType.project => DataConfig.project(
        query: ProjectQuery(
          filter: selector.projectFilter ?? const QueryFilter.matchAll(),
          sortCriteria: _mapSortCriteria(display.sorting),
        ),
      ),
      EntityType.label => const DataConfig.label(),
      EntityType.goal => const DataConfig.value(),
    };
  }

  Section _migrateSupportBlock(SupportBlock block) {
    final blockType = switch (block.type) {
      SupportBlockType.reviewReminder => SupportBlockType.reviewBanner,
      SupportBlockType.problemDetection => SupportBlockType.problemBanner,
      // Map other types as needed
      _ => SupportBlockType.reviewBanner,
    };
    
    return Section.support(
      config: SupportBlockConfig(blockType: blockType),
    );
  }

  List<SortCriterion> _mapSortCriteria(List<screen_models.SortCriterion> criteria) {
    // Map from screen_models.SortCriterion to domain SortCriterion
    // Implementation depends on existing types
    return [];
  }
}
```

---

## Task 3: Update SystemScreenFactory

**File**: `lib/data/features/screens/system_screen_factory.dart`

**Examine current file first** to understand existing screen definitions.

**Update each system screen** to use sections. Example transformations:

### Inbox Screen
```dart
ScreenDefinition _createInboxScreen() {
  return ScreenDefinition(
    id: _generateId('inbox'),
    screenKey: 'inbox',
    name: 'Inbox',
    iconName: 'inbox',
    category: ScreenCategory.tasks,
    isSystem: true,
    menuOrder: 10,
    sections: [
      Section.data(
        config: DataConfig.task(
          query: TaskQuery(
            filter: QueryFilter(
              shared: [
                const TaskStringPredicate(
                  field: TaskStringField.projectId,
                  operator: StringOperator.isNull,
                ),
                const TaskBoolPredicate(
                  field: TaskBoolField.completed,
                  operator: BoolOperator.isFalse,
                ),
              ],
            ),
          ),
        ),
      ),
    ],
    defaultLayout: ScreenLayout.list,
  );
}
```

### Today Screen
```dart
ScreenDefinition _createTodayScreen() {
  return ScreenDefinition(
    id: _generateId('today'),
    screenKey: 'today',
    name: 'Today',
    iconName: 'today',
    category: ScreenCategory.tasks,
    isSystem: true,
    menuOrder: 20,
    sections: [
      Section.data(
        config: DataConfig.task(
          query: TaskQuery(
            filter: QueryFilter(
              shared: [
                const TaskBoolPredicate(
                  field: TaskBoolField.completed,
                  operator: BoolOperator.isFalse,
                ),
                TaskDatePredicate(
                  field: TaskDateField.startDate,
                  operator: DateOperator.onOrBefore,
                  date: DateTime.now(), // Will be evaluated at runtime
                ),
              ],
              orGroups: [
                [
                  TaskDatePredicate(
                    field: TaskDateField.deadlineDate,
                    operator: DateOperator.onOrBefore,
                    date: DateTime.now(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ],
    defaultLayout: ScreenLayout.agenda,
  );
}
```

### Upcoming Screen
```dart
ScreenDefinition _createUpcomingScreen() {
  return ScreenDefinition(
    id: _generateId('upcoming'),
    screenKey: 'upcoming',
    name: 'Upcoming',
    iconName: 'event',
    category: ScreenCategory.tasks,
    isSystem: true,
    menuOrder: 30,
    sections: [
      Section.data(
        config: DataConfig.task(
          query: TaskQuery(
            filter: QueryFilter(
              shared: [
                const TaskBoolPredicate(
                  field: TaskBoolField.completed,
                  operator: BoolOperator.isFalse,
                ),
              ],
              orGroups: [
                [
                  const TaskDatePredicate(
                    field: TaskDateField.startDate,
                    operator: DateOperator.isNotNull,
                  ),
                ],
                [
                  const TaskDatePredicate(
                    field: TaskDateField.deadlineDate,
                    operator: DateOperator.isNotNull,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ],
    defaultLayout: ScreenLayout.agenda,
  );
}
```

### Projects Screen
```dart
ScreenDefinition _createProjectsScreen() {
  return ScreenDefinition(
    id: _generateId('projects'),
    screenKey: 'projects',
    name: 'Projects',
    iconName: 'folder',
    category: ScreenCategory.projects,
    isSystem: true,
    menuOrder: 40,
    sections: [
      Section.data(
        config: const DataConfig.project(
          query: ProjectQuery(),
        ),
        relatedData: [
          const RelatedDataConfig.tasks(), // Show task count per project
        ],
      ),
    ],
    defaultLayout: ScreenLayout.list,
  );
}
```

### Labels Screen
```dart
ScreenDefinition _createLabelsScreen() {
  return ScreenDefinition(
    id: _generateId('labels'),
    screenKey: 'labels',
    name: 'Labels',
    iconName: 'label',
    category: ScreenCategory.labels,
    isSystem: true,
    menuOrder: 50,
    sections: [
      Section.data(
        config: const DataConfig.label(),
        relatedData: [
          const RelatedDataConfig.tasks(),
        ],
      ),
    ],
    defaultLayout: ScreenLayout.list,
  );
}
```

### Values Screen
```dart
ScreenDefinition _createValuesScreen() {
  return ScreenDefinition(
    id: _generateId('values'),
    screenKey: 'values',
    name: 'Values',
    iconName: 'star',
    category: ScreenCategory.labels,
    isSystem: true,
    menuOrder: 60,
    sections: [
      Section.data(
        config: const DataConfig.value(),
        relatedData: [
          const RelatedDataConfig.valueHierarchy(
            includeInheritedTasks: true,
          ),
        ],
      ),
    ],
    defaultLayout: ScreenLayout.tree,
  );
}
```

### Next Actions Screen
```dart
ScreenDefinition _createNextActionsScreen() {
  return ScreenDefinition(
    id: _generateId('next_actions'),
    screenKey: 'next_actions',
    name: 'Next Actions',
    iconName: 'play_arrow',
    category: ScreenCategory.tasks,
    isSystem: true,
    menuOrder: 5, // High priority
    sections: [
      const Section.allocation(maxTasks: 10),
    ],
    defaultLayout: ScreenLayout.list,
  );
}
```

### Settings Screen
```dart
ScreenDefinition _createSettingsScreen() {
  return ScreenDefinition(
    id: _generateId('settings'),
    screenKey: 'settings',
    name: 'Settings',
    iconName: 'settings',
    category: ScreenCategory.utility,
    isSystem: true,
    showInMenu: false, // Accessed via gear icon, not menu
    sections: [
      Section.navigation(
        items: [
          const NavigationItem(
            id: 'appearance',
            title: 'Appearance',
            route: '/settings/appearance',
            iconName: 'palette',
          ),
          const NavigationItem(
            id: 'language',
            title: 'Language & Region',
            route: '/settings/language',
            iconName: 'language',
          ),
          const NavigationItem(
            id: 'customization',
            title: 'Customization',
            route: '/settings/customization',
            iconName: 'tune',
          ),
          const NavigationItem(
            id: 'advanced',
            title: 'Advanced',
            route: '/settings/advanced',
            iconName: 'build',
          ),
          const NavigationItem(
            id: 'account',
            title: 'Account',
            route: '/settings/account',
            iconName: 'person',
          ),
        ],
      ),
    ],
    defaultLayout: ScreenLayout.list,
  );
}
```

### Wellbeing Dashboard Screen
```dart
ScreenDefinition _createWellbeingScreen() {
  return ScreenDefinition(
    id: _generateId('wellbeing'),
    screenKey: 'wellbeing',
    name: 'Wellbeing',
    iconName: 'favorite',
    category: ScreenCategory.utility,
    isSystem: true,
    menuOrder: 70,
    sections: [
      Section.support(
        config: const SupportBlockConfig(
          blockType: SupportBlockType.moodTrend,
        ),
      ),
      Section.support(
        config: const SupportBlockConfig(
          blockType: SupportBlockType.correlations,
        ),
      ),
    ],
    defaultLayout: ScreenLayout.list,
  );
}
```

---

## Task 4: Update Drift Schema

**File**: `lib/data/drift/features/screen_tables.drift.dart`

**Examine current schema first**, then update to store sections as JSON.

```dart
// In the table definition, change:
// viewDefinitionJson TEXT NOT NULL
// to:
// sectionsJson TEXT NOT NULL
// 
// Keep viewDefinitionJson as nullable for migration period

CREATE TABLE screen_definitions (
  id TEXT PRIMARY KEY NOT NULL,
  screen_key TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  icon_name TEXT NOT NULL,
  category TEXT NOT NULL,
  sections_json TEXT NOT NULL,          -- NEW: List<Section> as JSON
  default_layout TEXT NOT NULL DEFAULT 'list',
  is_system INTEGER NOT NULL DEFAULT 0,
  show_in_menu INTEGER NOT NULL DEFAULT 1,
  menu_order INTEGER NOT NULL DEFAULT 100,
  created_at INTEGER,
  updated_at INTEGER,
  view_definition_json TEXT             -- DEPRECATED: Keep for migration
) AS ScreenDefinitionsTable;
```

---

## Task 5: Create Database Migration

**File**: `lib/data/drift/migrations/migration_vX_to_vY.dart` (increment version)

```dart
import 'package:drift/drift.dart';
import 'package:taskly_bloc/data/drift/database.dart';
import 'package:taskly_bloc/data/features/screens/view_to_sections_migrator.dart';

/// Migration to add sections column and migrate existing data
class MigrationVXToVY extends DatabaseMigration {
  @override
  int get fromVersion => X; // Current version
  
  @override
  int get toVersion => Y; // Next version
  
  @override
  Future<void> migrate(Migrator m, int from, int to) async {
    // 1. Add new columns
    await m.addColumn(
      screenDefinitions,
      GeneratedColumn<String>(
        'sections_json',
        aliasedName: 'sections_json',
        type: DriftSqlType.string,
        nullable: true, // Temporarily nullable during migration
      ),
    );
    
    await m.addColumn(
      screenDefinitions,
      GeneratedColumn<String>(
        'default_layout',
        aliasedName: 'default_layout',
        type: DriftSqlType.string,
        defaultValue: const Constant('list'),
      ),
    );
    
    // 2. Migrate existing data
    final migrator = ViewToSectionsMigrator();
    final existingScreens = await (select(screenDefinitions)).get();
    
    for (final screen in existingScreens) {
      if (screen.viewDefinitionJson != null) {
        // Parse old ViewDefinition
        final viewJson = jsonDecode(screen.viewDefinitionJson!);
        final view = ViewDefinition.fromJson(viewJson);
        
        // Convert to sections
        final sections = migrator.migrate(view);
        final sectionsJson = jsonEncode(sections.map((s) => s.toJson()).toList());
        
        // Update row
        await (update(screenDefinitions)
          ..where((t) => t.id.equals(screen.id)))
          .write(ScreenDefinitionsCompanion(
            sectionsJson: Value(sectionsJson),
          ));
      }
    }
    
    // 3. Make sections_json NOT NULL (after data populated)
    // Note: SQLite doesn't support ALTER COLUMN, may need table recreation
  }
}
```

---

## Task 6: Update ScreenDefinitionsRepository

**File**: `lib/data/features/screens/screen_definitions_repository.dart`

**Update mapping methods** to handle new sections field:

```dart
// In _mapToModel method:
ScreenDefinition _mapToModel(ScreenDefinitionsTableData row) {
  List<Section> sections;
  
  if (row.sectionsJson != null) {
    // New format
    final sectionsData = jsonDecode(row.sectionsJson!) as List;
    sections = sectionsData
        .map((json) => Section.fromJson(json as Map<String, dynamic>))
        .toList();
  } else if (row.viewDefinitionJson != null) {
    // Legacy format - migrate on read
    final viewJson = jsonDecode(row.viewDefinitionJson!);
    final view = ViewDefinition.fromJson(viewJson);
    sections = ViewToSectionsMigrator().migrate(view);
  } else {
    sections = [];
  }
  
  return ScreenDefinition(
    id: row.id,
    screenKey: row.screenKey,
    name: row.name,
    iconName: row.iconName,
    category: ScreenCategory.values.firstWhere(
      (c) => c.name == row.category,
      orElse: () => ScreenCategory.tasks,
    ),
    sections: sections,
    defaultLayout: ScreenLayout.values.firstWhere(
      (l) => l.name == row.defaultLayout,
      orElse: () => ScreenLayout.list,
    ),
    isSystem: row.isSystem,
    showInMenu: row.showInMenu,
    menuOrder: row.menuOrder,
    createdAt: row.createdAt != null 
        ? DateTime.fromMillisecondsSinceEpoch(row.createdAt!)
        : null,
    updatedAt: row.updatedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(row.updatedAt!)
        : null,
  );
}

// In _mapToCompanion method:
ScreenDefinitionsCompanion _mapToCompanion(ScreenDefinition screen) {
  return ScreenDefinitionsCompanion(
    id: Value(screen.id),
    screenKey: Value(screen.screenKey),
    name: Value(screen.name),
    iconName: Value(screen.iconName),
    category: Value(screen.category.name),
    sectionsJson: Value(
      jsonEncode(screen.sections.map((s) => s.toJson()).toList()),
    ),
    defaultLayout: Value(screen.defaultLayout.name),
    isSystem: Value(screen.isSystem),
    showInMenu: Value(screen.showInMenu),
    menuOrder: Value(screen.menuOrder),
    createdAt: Value(screen.createdAt?.millisecondsSinceEpoch),
    updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    // Don't write viewDefinitionJson - deprecated
  );
}
```

---

## Task 7: Update SystemScreenSeeder

**File**: `lib/data/features/screens/system_screen_seeder.dart`

**Ensure seeder uses updated SystemScreenFactory**:

```dart
class SystemScreenSeeder {
  SystemScreenSeeder({
    required ScreenDefinitionsRepositoryContract repository,
    required SystemScreenFactory factory,
  }) : _repository = repository,
       _factory = factory;

  final ScreenDefinitionsRepositoryContract _repository;
  final SystemScreenFactory _factory;

  Future<void> seedIfNeeded() async {
    final existingScreens = await _repository.getAll();
    final existingKeys = existingScreens.map((s) => s.screenKey).toSet();
    
    final systemScreens = _factory.createAllSystemScreens();
    
    for (final screen in systemScreens) {
      if (!existingKeys.contains(screen.screenKey)) {
        await _repository.create(screen);
      } else {
        // Optionally update existing system screens if schema changed
        // await _repository.update(screen);
      }
    }
  }
}
```

---

## Validation Checklist

After completing all tasks:

1. [ ] Run `flutter analyze` - expect 0 errors, 0 warnings
2. [ ] Verify ScreenDefinition model compiles with new `sections` field
3. [ ] Verify all `.freezed.dart` and `.g.dart` files regenerate
4. [ ] Verify SystemScreenFactory creates valid screen definitions
5. [ ] Verify database migration script is syntactically correct
6. [ ] Verify repository can read both old and new formats
7. [ ] App starts without database errors (manual test)

---

## Files Created This Phase

| File | Purpose |
|------|---------|
| `lib/data/features/screens/view_to_sections_migrator.dart` | Legacy migration helper |
| `lib/data/drift/migrations/migration_vX_to_vY.dart` | Database migration |

## Files Modified This Phase

| File | Change |
|------|--------|
| `lib/domain/models/screens/screen_definition.dart` | Add sections, deprecate view |
| `lib/data/features/screens/system_screen_factory.dart` | All screens use sections |
| `lib/data/drift/features/screen_tables.drift.dart` | Add sectionsJson column |
| `lib/data/features/screens/screen_definitions_repository.dart` | Handle sections mapping |
| `lib/data/features/screens/system_screen_seeder.dart` | Use updated factory |

---

## Known Considerations

1. **Database Version**: Increment schema version in `database.dart`
2. **Backward Compatibility**: Repository reads both formats during transition
3. **System Screen Updates**: Decide whether to auto-update existing system screens or only seed new ones
4. **Icon Names**: Using string names for serialization; UI converts to IconData

---

## Next Phase
Proceed to **Phase 3: BLoC & UI Layer** after all validation passes.
