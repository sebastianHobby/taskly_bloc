# Phase 8: System Screen Seeder

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each phase/subphase. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files - do not fix errors for compilation of tests.
- **Forms**: Prefer `flutter_form_builder` fields and extensions where applicable.
- **Reuse**: Check existing patterns in codebase before creating new ones.

---

## Goal

Create seeder to populate all 11 system screens using the new unified model.

**Reference**: System screens listed in design decisions

---

## Prerequisites

- All previous phases complete
- Database schema supports new ScreenDefinition structure

---

## Task 1: Create SystemScreenSeeder

**File**: `lib/data/seeders/system_screen_seeder.dart`

```dart
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/related_data_config.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/label_query.dart';
import 'package:taskly_bloc/domain/repositories/screen_repository.dart';

/// Seeder for system-provided screens
class SystemScreenSeeder {
  final ScreenRepository _screenRepository;

  SystemScreenSeeder({required ScreenRepository screenRepository})
      : _screenRepository = screenRepository;

  /// Seed all system screens
  Future<void> seedAll() async {
    final screens = getAllSystemScreens();
    for (final screen in screens) {
      await _screenRepository.upsertScreen(screen);
    }
  }

  /// Get all system screen definitions
  List<ScreenDefinition> getAllSystemScreens() {
    return [
      inboxScreen,
      todayScreen,
      upcomingScreen,
      focusScreen,
      projectsScreen,
      labelsScreen,
      valuesScreen,
      completedScreen,
      allTasksScreen,
      searchScreen,
      settingsScreen,
    ];
  }

  // ============================================================
  // 1. INBOX SCREEN
  // ============================================================
  static final inboxScreen = ScreenDefinition(
    id: 'system-inbox',
    name: 'Inbox',
    screenType: ScreenType.list,
    icon: 'inbox',
    description: 'Tasks without a project',
    isSystem: true,
    displayOrder: 1,
    sections: [
      Section.data(
        config: DataConfig.task(
          query: TaskQuery.inbox(),
        ),
        title: 'Inbox',
      ),
    ],
    supportBlocks: [
      const SupportBlock.stats(stats: [
        StatConfig(label: 'Total', metricId: 'task_count'),
      ]),
    ],
  );

  // ============================================================
  // 2. TODAY SCREEN
  // ============================================================
  static final todayScreen = ScreenDefinition(
    id: 'system-today',
    name: 'Today',
    screenType: ScreenType.dashboard,
    icon: 'today',
    description: 'Tasks due today',
    isSystem: true,
    displayOrder: 2,
    sections: [
      Section.agenda(
        dateField: AgendaDateField.deadlineDate,
        grouping: AgendaGrouping.overdueFirst,
        additionalFilter: TaskQuery(
          filter: QueryFilter(
            shared: [const TaskPredicate.completed(isCompleted: false)],
          ),
        ),
        title: 'Today',
      ),
    ],
    supportBlocks: [
      const SupportBlock.problemSummary(
        problemTypes: ['overdue'],
        showCount: true,
        showList: false,
        title: 'Overdue',
      ),
    ],
  );

  // ============================================================
  // 3. UPCOMING SCREEN
  // ============================================================
  static final upcomingScreen = ScreenDefinition(
    id: 'system-upcoming',
    name: 'Upcoming',
    screenType: ScreenType.dashboard,
    icon: 'calendar_month',
    description: 'Tasks with upcoming deadlines',
    isSystem: true,
    displayOrder: 3,
    sections: [
      Section.agenda(
        dateField: AgendaDateField.deadlineDate,
        grouping: AgendaGrouping.standard,
        title: 'Upcoming',
      ),
    ],
  );

  // ============================================================
  // 4. FOCUS / NEXT ACTIONS SCREEN
  // ============================================================
  static final focusScreen = ScreenDefinition(
    id: 'system-focus',
    name: 'Focus',
    screenType: ScreenType.focus,
    icon: 'center_focus_strong',
    description: 'Your allocated next actions',
    isSystem: true,
    displayOrder: 4,
    sections: [
      const Section.allocation(
        maxTasks: 5,
        title: 'Next Actions',
      ),
    ],
    supportBlocks: [
      const SupportBlock.stats(stats: [
        StatConfig(label: 'Focus', metricId: 'allocation_count'),
        StatConfig(label: 'Available', metricId: 'available_count'),
      ]),
    ],
  );

  // ============================================================
  // 5. PROJECTS SCREEN
  // ============================================================
  static final projectsScreen = ScreenDefinition(
    id: 'system-projects',
    name: 'Projects',
    screenType: ScreenType.list,
    icon: 'folder',
    description: 'All projects',
    isSystem: true,
    displayOrder: 5,
    sections: [
      Section.data(
        config: DataConfig.project(
          query: ProjectQuery.active(),
        ),
        relatedData: [
          const RelatedDataConfig.tasks(
            additionalFilter: TaskQuery(
              filter: QueryFilter(
                shared: [TaskPredicate.completed(isCompleted: false)],
              ),
            ),
          ),
        ],
        title: 'Active Projects',
      ),
    ],
    supportBlocks: [
      const SupportBlock.problemSummary(
        showCount: true,
        showList: true,
        maxListItems: 3,
      ),
    ],
  );

  // ============================================================
  // 6. LABELS SCREEN
  // ============================================================
  static final labelsScreen = ScreenDefinition(
    id: 'system-labels',
    name: 'Labels',
    screenType: ScreenType.list,
    icon: 'label',
    description: 'All labels',
    isSystem: true,
    displayOrder: 6,
    sections: [
      Section.data(
        config: DataConfig.label(
          query: LabelQuery.labelsOnly(),
        ),
        title: 'Labels',
      ),
    ],
  );

  // ============================================================
  // 7. VALUES SCREEN
  // ============================================================
  static final valuesScreen = ScreenDefinition(
    id: 'system-values',
    name: 'Values',
    screenType: ScreenType.list,
    icon: 'star',
    description: 'Your values and areas of focus',
    isSystem: true,
    displayOrder: 7,
    sections: [
      Section.data(
        config: DataConfig.value(
          query: LabelQuery.values(),
        ),
        relatedData: [
          const RelatedDataConfig.valueHierarchy(),
        ],
        title: 'Values',
      ),
    ],
    supportBlocks: [
      const SupportBlock.contextSummary(
        title: 'About Values',
        showDescription: true,
      ),
    ],
  );

  // ============================================================
  // 8. COMPLETED SCREEN
  // ============================================================
  static final completedScreen = ScreenDefinition(
    id: 'system-completed',
    name: 'Completed',
    screenType: ScreenType.list,
    icon: 'check_circle',
    description: 'Completed tasks',
    isSystem: true,
    displayOrder: 8,
    sections: [
      Section.data(
        config: DataConfig.task(
          query: TaskQuery(
            filter: QueryFilter(
              shared: [const TaskPredicate.completed(isCompleted: true)],
            ),
            sortCriteria: [
              const TaskSortCriterion(
                field: TaskSortField.completedAt,
                direction: SortDirection.descending,
              ),
            ],
          ),
        ),
        title: 'Completed',
      ),
    ],
  );

  // ============================================================
  // 9. ALL TASKS SCREEN
  // ============================================================
  static final allTasksScreen = ScreenDefinition(
    id: 'system-all-tasks',
    name: 'All Tasks',
    screenType: ScreenType.list,
    icon: 'list',
    description: 'All tasks in the system',
    isSystem: true,
    displayOrder: 9,
    sections: [
      Section.data(
        config: DataConfig.task(
          query: TaskQuery(
            filter: QueryFilter(
              shared: [const TaskPredicate.completed(isCompleted: false)],
            ),
          ),
        ),
        title: 'All Tasks',
      ),
    ],
    supportBlocks: [
      const SupportBlock.stats(stats: [
        StatConfig(label: 'Total', metricId: 'task_count'),
        StatConfig(label: 'Overdue', metricId: 'overdue_count'),
      ]),
    ],
  );

  // ============================================================
  // 10. SEARCH SCREEN
  // ============================================================
  static final searchScreen = ScreenDefinition(
    id: 'system-search',
    name: 'Search',
    screenType: ScreenType.dashboard,
    icon: 'search',
    description: 'Search tasks, projects, and labels',
    isSystem: true,
    displayOrder: 10,
    sections: [
      // Search screen sections are dynamic based on search query
      // This is a placeholder - actual implementation handles search state
      Section.data(
        config: DataConfig.task(query: const TaskQuery()),
        title: 'Results',
      ),
    ],
  );

  // ============================================================
  // 11. SETTINGS SCREEN
  // ============================================================
  static final settingsScreen = ScreenDefinition(
    id: 'system-settings',
    name: 'Settings',
    screenType: ScreenType.dashboard,
    icon: 'settings',
    description: 'App settings and preferences',
    isSystem: true,
    displayOrder: 11,
    sections: const [],
    // Settings screen is handled by custom widgets, not sections
  );
}
```

---

## Task 2: Create Seeder Initialization

**File**: `lib/data/seeders/seeders.dart`

```dart
export 'system_screen_seeder.dart';
```

---

## Task 3: Add Seeder to App Initialization

Update the app initialization to run the seeder:

**File**: `lib/bootstrap.dart` (or similar initialization file)

Add seeder call after database initialization:

```dart
Future<void> bootstrap() async {
  // ... existing initialization

  // Seed system screens
  final screenRepository = getIt<ScreenRepository>();
  final seeder = SystemScreenSeeder(screenRepository: screenRepository);
  await seeder.seedAll();

  // ... continue initialization
}
```

---

## Task 4: Add Migration for Existing Users

If users have existing data, add a migration to preserve their screens:

**File**: `lib/data/migrations/screen_migration.dart`

```dart
import 'package:taskly_bloc/domain/repositories/screen_repository.dart';
import 'package:taskly_bloc/data/seeders/system_screen_seeder.dart';

/// Migration for screen architecture changes
class ScreenMigration {
  final ScreenRepository _screenRepository;

  ScreenMigration({required ScreenRepository screenRepository})
      : _screenRepository = screenRepository;

  /// Migrate screens to new architecture
  Future<void> migrate() async {
    // Delete all old screens (clean slate approach)
    await _screenRepository.deleteAllScreens();

    // Reseed with new system screens
    final seeder = SystemScreenSeeder(screenRepository: _screenRepository);
    await seeder.seedAll();
  }
}
```

---

## Task 5: Verify Screen Repository Methods

Ensure `ScreenRepository` has needed methods:

**File**: `lib/domain/repositories/screen_repository.dart`

```dart
abstract class ScreenRepository {
  /// Get a screen by ID
  Future<ScreenDefinition?> getScreenById(String id);

  /// Get all screens
  Future<List<ScreenDefinition>> getAllScreens();

  /// Get system screens
  Future<List<ScreenDefinition>> getSystemScreens();

  /// Get user screens
  Future<List<ScreenDefinition>> getUserScreens();

  /// Insert or update a screen
  Future<void> upsertScreen(ScreenDefinition screen);

  /// Delete a screen
  Future<void> deleteScreen(String id);

  /// Delete all screens
  Future<void> deleteAllScreens();

  /// Watch all screens (stream)
  Stream<List<ScreenDefinition>> watchAllScreens();
}
```

---

## Validation Checklist

- [ ] `flutter analyze` returns 0 errors, 0 warnings (ignore test file errors)
- [ ] `SystemScreenSeeder` class exists with all 11 screens
- [ ] Each screen has correct `screenType`
- [ ] Each screen has appropriate `sections`
- [ ] Seeder runs during app initialization
- [ ] `ScreenRepository` has `upsertScreen` method

---

## Files Created

| File | Purpose |
|------|---------|
| `lib/data/seeders/system_screen_seeder.dart` | System screen definitions |
| `lib/data/seeders/seeders.dart` | Barrel export |
| `lib/data/migrations/screen_migration.dart` | Migration for existing users |

## Files Modified

| File | Change |
|------|--------|
| `lib/bootstrap.dart` | Add seeder initialization |
| `lib/domain/repositories/screen_repository.dart` | Verify/add methods |

---

## System Screens Summary

| # | ID | Name | Type | Primary Section |
|---|-----|------|------|-----------------|
| 1 | system-inbox | Inbox | list | Task (no project) |
| 2 | system-today | Today | dashboard | Agenda (deadline) |
| 3 | system-upcoming | Upcoming | dashboard | Agenda (deadline) |
| 4 | system-focus | Focus | focus | Allocation |
| 5 | system-projects | Projects | list | Project (active) |
| 6 | system-labels | Labels | list | Label |
| 7 | system-values | Values | list | Value |
| 8 | system-completed | Completed | list | Task (completed) |
| 9 | system-all-tasks | All Tasks | list | Task (all) |
| 10 | system-search | Search | dashboard | Dynamic |
| 11 | system-settings | Settings | dashboard | Custom |

---

## Next Phase

Proceed to **Phase 9: Final Cleanup** after validation passes.
