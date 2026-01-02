# Phase 6: Cleanup & Migration

## AI Implementation Instructions

### Environment Setup
- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each file creation. Fix ALL errors and warnings before proceeding.
- **Tests**: NOW update and run tests. This is the final phase.
- **Reuse**: This phase focuses on removing old code, not creating new patterns.

### Phase Goal
Remove deprecated code, finalize database migrations, update tests, and ensure the codebase is clean and consistent.

### Prerequisites
- Phase 0-5 complete and verified working

---

## Task 1: Remove Deprecated ViewDefinition

### Files to Delete

After verifying all functionality works with the new Section model:

```
lib/domain/models/screens/view_definition.dart
lib/domain/models/screens/view_definition.freezed.dart
lib/domain/models/screens/view_definition.g.dart
```

### Files to Update

Remove ViewDefinition imports and usages:

**Search pattern**: `import.*view_definition`

Update each file found to remove the import and any remaining ViewDefinition usage.

---

## Task 2: Remove Legacy ViewBloc

**File to delete** (after verifying SectionBloc handles all cases):

```
lib/presentation/features/screens/bloc/view_bloc.dart
lib/presentation/features/screens/bloc/view_bloc.freezed.dart
```

**Files to update** - remove ViewBloc references:

1. Search for `ViewBloc` imports
2. Replace with `SectionBloc` where applicable
3. Update BlocProvider usages

---

## Task 3: Remove Legacy ViewService

**File to delete** (after verifying SectionDataService handles all cases):

```
lib/domain/services/view_service.dart
```

**Files to update**:

1. Search for `ViewService` imports
2. Replace with `SectionDataService`
3. Update DI registrations

---

## Task 4: Clean Up ScreenHostPage

The ScreenHostPage was updated in Phase 3B. Verify and remove any remaining:

1. Hardcoded screen switches (the giant switch statement)
2. Direct page references that bypass section rendering
3. Legacy route handling

**Target state**: ScreenHostPage should only:
- Load ScreenDefinition by ID
- Provide SectionBloc
- Render sections

---

## Task 5: Database Migration Script

**File**: `lib/data/local/drift/migrations/migration_v_sections.dart`

Create a migration for the Drift database:

```dart
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:taskly_bloc/data/local/drift/app_database.dart';

/// Migration to convert ViewDefinition-based screens to Section-based.
class MigrationVSections {
  /// Run the migration.
  static Future<void> migrate(AppDatabase db) async {
    // 1. Add sections_json column to screen_definitions if not exists
    await _addSectionsColumn(db);

    // 2. Migrate existing data
    await _migrateScreenDefinitions(db);

    // 3. Migrate workflow steps
    await _migrateWorkflowSteps(db);

    // 4. Clean up old columns (optional, can be done in later migration)
    // await _removeOldColumns(db);
  }

  static Future<void> _addSectionsColumn(AppDatabase db) async {
    // Check if column exists
    final columns = await db.customSelect(
      "PRAGMA table_info('screen_definitions')",
    ).get();

    final hasSectionsColumn = columns.any(
      (row) => row.read<String>('name') == 'sections_json',
    );

    if (!hasSectionsColumn) {
      await db.customStatement(
        "ALTER TABLE screen_definitions ADD COLUMN sections_json TEXT NOT NULL DEFAULT '[]'",
      );
    }
  }

  static Future<void> _migrateScreenDefinitions(AppDatabase db) async {
    // Get all screen definitions with old view_definition_json
    final rows = await db.customSelect(
      "SELECT id, view_definition_json FROM screen_definitions WHERE view_definition_json IS NOT NULL AND sections_json = '[]'",
    ).get();

    for (final row in rows) {
      final id = row.read<String>('id');
      final viewDefJson = row.read<String?>('view_definition_json');

      if (viewDefJson == null || viewDefJson.isEmpty) continue;

      try {
        final viewDef = jsonDecode(viewDefJson) as Map<String, dynamic>;
        final sections = _convertViewDefinitionToSections(viewDef);
        final sectionsJson = jsonEncode(sections);

        await db.customStatement(
          "UPDATE screen_definitions SET sections_json = ? WHERE id = ?",
          variables: [Variable.withString(sectionsJson), Variable.withString(id)],
        );
      } catch (e) {
        // Log error but continue with other rows
        print('Failed to migrate screen $id: $e');
      }
    }
  }

  static Future<void> _migrateWorkflowSteps(AppDatabase db) async {
    // Similar migration for workflow_steps table
    final hasTable = await db.customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='workflow_steps'",
    ).get();

    if (hasTable.isEmpty) return;

    // Check if sections_json column exists
    final columns = await db.customSelect(
      "PRAGMA table_info('workflow_steps')",
    ).get();

    final hasSectionsColumn = columns.any(
      (row) => row.read<String>('name') == 'sections_json',
    );

    if (!hasSectionsColumn) {
      await db.customStatement(
        "ALTER TABLE workflow_steps ADD COLUMN sections_json TEXT NOT NULL DEFAULT '[]'",
      );
    }

    // Migrate data
    final rows = await db.customSelect(
      "SELECT id, view_definition_json FROM workflow_steps WHERE view_definition_json IS NOT NULL AND sections_json = '[]'",
    ).get();

    for (final row in rows) {
      final id = row.read<String>('id');
      final viewDefJson = row.read<String?>('view_definition_json');

      if (viewDefJson == null || viewDefJson.isEmpty) continue;

      try {
        final viewDef = jsonDecode(viewDefJson) as Map<String, dynamic>;
        final sections = _convertViewDefinitionToSections(viewDef);
        final sectionsJson = jsonEncode(sections);

        await db.customStatement(
          "UPDATE workflow_steps SET sections_json = ? WHERE id = ?",
          variables: [Variable.withString(sectionsJson), Variable.withString(id)],
        );
      } catch (e) {
        print('Failed to migrate workflow step $id: $e');
      }
    }
  }

  static List<Map<String, dynamic>> _convertViewDefinitionToSections(
    Map<String, dynamic> viewDef,
  ) {
    final type = viewDef['runtimeType'] as String?;

    return switch (type) {
      'collection' => [
          {
            'runtimeType': 'data',
            'id': 'migrated_collection',
            'dataConfig': _convertQueryToDataConfig(viewDef['query']),
          }
        ],
      'agenda' => [
          {
            'runtimeType': 'data',
            'id': 'migrated_agenda',
            'title': 'Agenda',
            'dataConfig': {
              'runtimeType': 'task',
              'query': viewDef['query'] ?? {},
              'dateFilter': {
                'field': 'deadline',
                'start': viewDef['dateRange']?['start'],
                'end': viewDef['dateRange']?['end'],
              },
            },
          }
        ],
      'allocated' => [
          {
            'runtimeType': 'allocation',
            'id': 'migrated_allocation',
            'maxTasks': viewDef['maxItems'] ?? 5,
          }
        ],
      _ => <Map<String, dynamic>>[],
    };
  }

  static Map<String, dynamic> _convertQueryToDataConfig(
    Map<String, dynamic>? query,
  ) {
    if (query == null) {
      return {'runtimeType': 'task', 'query': {}};
    }

    final queryType = query['runtimeType'] as String?;

    return switch (queryType) {
      'task' || 'TaskQuery' => {'runtimeType': 'task', 'query': query},
      'project' || 'ProjectQuery' => {'runtimeType': 'project', 'query': query},
      'label' || 'LabelQuery' => {'runtimeType': 'label', 'query': query},
      'value' || 'ValueQuery' => {'runtimeType': 'value', 'query': query},
      _ => {'runtimeType': 'task', 'query': query},
    };
  }
}
```

---

## Task 6: Update Drift Schema Version

**File**: `lib/data/local/drift/app_database.dart`

Increment schema version and add migration:

```dart
@DriftDatabase(
  tables: [/* ... */],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => X + 1; // Increment from current version

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        // Seed system screens
        await SystemScreenSeeder(this).seedAll();
      },
      onUpgrade: (m, from, to) async {
        // Run all migrations in sequence
        for (var version = from; version < to; version++) {
          await _runMigration(m, version + 1);
        }
      },
    );
  }

  Future<void> _runMigration(Migrator m, int version) async {
    switch (version) {
      // ... existing migrations
      case X + 1: // Replace X with actual version
        await MigrationVSections.migrate(this);
    }
  }
}
```

---

## Task 7: Update Tests

### Unit Tests to Update

**Pattern**: Search for `ViewDefinition` in test files

For each test file:
1. Replace `ViewDefinition` with appropriate Section configuration
2. Update mock setups
3. Update assertions

### Test Files Likely Needing Updates

```
test/domain/models/screens/screen_definition_test.dart
test/domain/services/view_service_test.dart → delete or rename to section_data_service_test.dart
test/presentation/features/screens/bloc/view_bloc_test.dart → delete or rename
test/presentation/features/workflow/bloc/workflow_run_bloc_test.dart
```

### New Tests to Create

```
test/domain/models/screens/section_test.dart
test/domain/models/screens/data_config_test.dart
test/domain/services/section_data_service_test.dart
test/domain/services/value_hierarchy_service_test.dart
test/presentation/features/screens/bloc/section_bloc_test.dart
test/data/repositories/section_display_settings_repository_test.dart
```

### Example Test Structure

**File**: `test/domain/models/screens/section_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';

void main() {
  group('DataSection', () {
    test('creates with task data config', () {
      final section = DataSection(
        id: 'test',
        dataConfig: const TaskDataConfig(
          query: TaskQuery(isCompleted: false),
        ),
      );

      expect(section.id, 'test');
      expect(section.dataConfig, isA<TaskDataConfig>());
    });

    test('serializes to JSON and back', () {
      final section = DataSection(
        id: 'test',
        title: 'My Tasks',
        dataConfig: const TaskDataConfig(
          query: TaskQuery(isCompleted: false),
        ),
      );

      final json = section.toJson();
      final restored = Section.fromJson(json);

      expect(restored, equals(section));
    });

    test('validates related config compatibility', () {
      // TaskDataConfig should only allow projects or valueHierarchy as related
      final validSection = DataSection(
        id: 'test',
        dataConfig: const TaskDataConfig(query: TaskQuery()),
        relatedConfig: const RelatedProjectsConfig(),
      );

      expect(validSection.relatedConfig, isA<RelatedProjectsConfig>());
    });
  });

  group('Section types', () {
    test('SupportSection creates with config', () {
      const section = SupportSection(
        id: 'review',
        config: SupportBlockConfig.reviewBanner(),
      );

      expect(section.config, isA<SupportBlockConfig>());
    });

    test('NavigationSection creates with items', () {
      final section = NavigationSection(
        id: 'nav',
        items: [
          const NavigationItem(
            title: 'Theme',
            route: '/settings/theme',
          ),
        ],
      );

      expect(section.items.length, 1);
    });

    test('AllocationSection has max tasks', () {
      const section = AllocationSection(
        id: 'next',
        maxTasks: 5,
      );

      expect(section.maxTasks, 5);
    });
  });
}
```

---

## Task 8: Remove Dead Code

Use IDE or command to find unused code:

```bash
# Find unused Dart files (manual review needed)
dart analyze --fatal-infos

# Or use DCM (Dart Code Metrics) if installed
dcm analyze lib --unused-code
```

### Common Dead Code Patterns to Look For

1. **Unused imports** - `dart fix --apply` can help
2. **Unreferenced private methods**
3. **Deprecated model classes**
4. **Old widget variants replaced by new ones**
5. **Commented-out code blocks**

---

## Task 9: Update Documentation

### Files to Update

**README.md** - Update architecture section if it references ViewDefinition

**API documentation** - Regenerate dartdoc:
```bash
dart doc .
```

### Inline Documentation

Ensure all new public APIs have dartdoc comments:

```dart
/// Fetches data for a single section.
/// 
/// The [section] determines what data to fetch and how.
/// The optional [parentEntityId] scopes the query to a parent entity
/// (e.g., tasks within a specific project).
/// 
/// Returns a [SectionData] subtype matching the section's data config.
/// 
/// Throws [SectionDataException] if fetching fails.
Future<SectionData> fetchSectionData({
  required Section section,
  String? parentEntityId,
});
```

---

## Task 10: Final Verification

### Checklist

```bash
# 1. Static analysis
flutter analyze
# Expected: 0 issues

# 2. Run all tests
flutter test
# Expected: All pass

# 3. Build for all platforms you support
flutter build windows --release
flutter build web --release
# ... etc

# 4. Run the app and manually verify:
```

**Manual Testing Checklist**:

- [ ] Home screen loads with sections
- [ ] Inbox screen shows tasks
- [ ] Today screen shows agenda
- [ ] Project detail shows project + tasks
- [ ] Settings screen shows navigation sections
- [ ] Wellbeing dashboard shows analytics
- [ ] Change display settings - verify persistence
- [ ] Restart app - verify settings persisted
- [ ] Run a workflow - verify steps render
- [ ] Complete tasks in workflow
- [ ] Value hierarchy displays correctly (3 levels)
- [ ] Group by works on task lists
- [ ] Sort works on task lists
- [ ] Related data mode toggle works

---

## Files to Delete (Summary)

| File | Reason |
|------|--------|
| `lib/domain/models/screens/view_definition.dart` | Replaced by Section |
| `lib/domain/models/screens/view_definition.freezed.dart` | Generated |
| `lib/domain/models/screens/view_definition.g.dart` | Generated |
| `lib/domain/services/view_service.dart` | Replaced by SectionDataService |
| `lib/presentation/features/screens/bloc/view_bloc.dart` | Replaced by SectionBloc |
| `lib/presentation/features/screens/bloc/view_bloc.freezed.dart` | Generated |
| `test/domain/services/view_service_test.dart` | No longer needed |
| `test/presentation/features/screens/bloc/view_bloc_test.dart` | No longer needed |

## Files to Update (Summary)

| File | Change |
|------|--------|
| `lib/data/local/drift/app_database.dart` | Add migration |
| All files importing ViewDefinition | Remove import, update usage |
| All files importing ViewBloc | Replace with SectionBloc |
| All files importing ViewService | Replace with SectionDataService |
| `pubspec.yaml` | Remove unused dependencies if any |
| DI configuration | Remove old registrations |

---

## Rollback Plan

If issues are found after migration:

1. **Database**: Keep `view_definition_json` column (don't delete in migration)
2. **Code**: Tag release before cleanup: `git tag pre-section-migration`
3. **Fallback**: ViewToSectionsMigrator can read old format at runtime

---

## Post-Migration Cleanup (Future)

In a future release (after confirming stability):

1. Remove `view_definition_json` column from database
2. Remove ViewToSectionsMigrator
3. Remove any fallback/compatibility code

---

## Success Criteria

Phase 6 is complete when:

1. ✅ No references to ViewDefinition in codebase
2. ✅ No references to ViewBloc in codebase
3. ✅ No references to ViewService in codebase
4. ✅ `flutter analyze` reports 0 issues
5. ✅ `flutter test` passes 100%
6. ✅ All manual tests pass
7. ✅ Database migration runs successfully
8. ✅ App functions identically to pre-migration (feature parity)
9. ✅ New features work (display settings, value hierarchy)

---

## Congratulations! 🎉

You have completed the Screen Architecture Redesign.

### What's New

- **Unified Section Model**: Single way to define screen content
- **Type-Safe Data Configs**: Compile-time validation of queries
- **Feature Parity**: Workflows use same model as screens
- **User Preferences**: Per-section display customization
- **Value Hierarchy**: 3-level tree for Values → Projects → Tasks
- **Clean Architecture**: Separation of data fetching, state management, and rendering

### Architecture Summary

```
┌─────────────────────────────────────────────────────────────┐
│                      ScreenDefinition                        │
│  - id, name, icon, isSystem, isHidden                       │
│  - sections: List<Section>                                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Section (sealed)                          │
│  ├─ DataSection (dataConfig, relatedConfig, title)          │
│  ├─ SupportSection (config: banner/analytics)               │
│  ├─ NavigationSection (items, groupTitle)                   │
│  └─ AllocationSection (maxTasks)                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  SectionDataService                          │
│  - fetchSectionData(section, parentEntityId)                │
│  - Returns: SectionData (task/project/label/value/etc.)     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      SectionBloc                             │
│  - Loads all sections for a screen                          │
│  - Manages display settings per section                     │
│  - Emits LoadedSection list                                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Section Renderers                          │
│  - SectionRenderer (dispatcher)                             │
│  - DataSectionRenderer → TaskListRenderer, etc.             │
│  - SupportSectionRenderer                                   │
│  - NavigationSectionRenderer                                │
│  - AllocationSectionRenderer                                │
└─────────────────────────────────────────────────────────────┘
```

### Next Steps (Beyond This Migration)

1. **User-Defined Screens**: Allow users to create custom screens with sections
2. **Drag-and-Drop Reordering**: Let users reorder sections
3. **More Section Types**: Calendar view, Kanban board, Timeline
4. **Workflow Builder**: Visual editor for creating workflows
5. **Sync**: Cloud sync for screen definitions and preferences
