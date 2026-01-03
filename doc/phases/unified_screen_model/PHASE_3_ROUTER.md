# Phase 3: Router Integration

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each task. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files.
- **Reuse**: Check existing patterns in codebase before creating new ones.
- **Imports**: Use absolute imports (`package:taskly_bloc/...`).

---

## Goal

Connect `UnifiedScreenPage` to the app routing system so screens can be navigated to.

---

## Prerequisites

- Phase 2 complete (`UnifiedScreenPage` exists)
- Existing router at `lib/core/routing/router.dart`
- Existing routes at `lib/core/routing/routes.dart`

---

## Task 3.1: Add Unified Screen Route

**File**: `lib/core/routing/router.dart`

Add a route that loads screens via `UnifiedScreenPage`. This route should coexist with existing routes during migration.

Find the screen-related routes section and add:

```dart
// Add inside the routes list, near other screen routes:

/// Unified screen route - renders any screen by definition ID
GoRoute(
  name: AppRouteName.unifiedScreen,
  path: '${AppRoutePath.unifiedScreen}/:screenId',
  builder: (context, state) {
    final screenId = state.pathParameters['screenId']!;
    return UnifiedScreenPageById(screenId: screenId);
  },
),
```

---

## Task 3.2: Add Route Constants

**File**: `lib/core/routing/routes.dart`

Add route constants for the unified screen:

```dart
// In AppRouteName class:
static const unifiedScreen = 'unified-screen';

// In AppRoutePath class:
static const unifiedScreen = '/unified';
```

---

## Task 3.3: Add Import to Router

**File**: `lib/core/routing/router.dart`

Ensure the import is added at the top:

```dart
import 'package:taskly_bloc/presentation/features/screens/view/unified_screen_page.dart';
```

---

## Task 3.4: Create SystemScreenDefinitions

**File**: `lib/domain/models/screens/system_screen_definitions.dart`

Create constant definitions for system screens. These will be used during migration.

```dart
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';

/// System screen definitions for built-in screens.
///
/// These definitions describe how system screens render using the
/// unified screen model. They are equivalent to the hardcoded
/// logic in legacy screen views.
abstract class SystemScreenDefinitions {
  SystemScreenDefinitions._();

  /// Inbox screen - tasks without a project
  static final inbox = ScreenDefinition(
    id: 'inbox',
    screenKey: 'inbox',
    name: 'Inbox',
    screenType: ScreenType.list,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    isSystem: true,
    iconName: 'inbox',
    category: ScreenCategory.workspace,
    sections: [
      Section.data(
        config: DataConfig(
          entityType: EntityType.task,
          filter: TaskQuery(
            predicates: [
              const TaskPredicate.hasProject(false),
              const TaskPredicate.isCompleted(false),
            ],
          ),
        ),
      ),
    ],
  );

  /// Today screen - tasks due/starting today
  static final today = ScreenDefinition(
    id: 'today',
    screenKey: 'today',
    name: 'Today',
    screenType: ScreenType.list,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    isSystem: true,
    iconName: 'today',
    category: ScreenCategory.workspace,
    sections: [
      Section.agenda(
        dateField: AgendaDateField.deadlineDate,
        grouping: AgendaGrouping.overdueFirst,
        title: 'Due',
      ),
    ],
  );

  /// Upcoming screen - future tasks
  static final upcoming = ScreenDefinition(
    id: 'upcoming',
    screenKey: 'upcoming',
    name: 'Upcoming',
    screenType: ScreenType.list,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    isSystem: true,
    iconName: 'upcoming',
    category: ScreenCategory.workspace,
    sections: [
      Section.agenda(
        dateField: AgendaDateField.deadlineDate,
        grouping: AgendaGrouping.byDate,
      ),
    ],
  );

  /// Logbook screen - completed tasks
  static final logbook = ScreenDefinition(
    id: 'logbook',
    screenKey: 'logbook',
    name: 'Logbook',
    screenType: ScreenType.list,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    isSystem: true,
    iconName: 'done_all',
    category: ScreenCategory.workspace,
    sections: [
      Section.data(
        config: DataConfig(
          entityType: EntityType.task,
          filter: TaskQuery(
            predicates: [
              const TaskPredicate.isCompleted(true),
            ],
          ),
        ),
        title: 'Completed',
      ),
    ],
  );

  /// Projects screen - list of projects
  static final projects = ScreenDefinition(
    id: 'projects',
    screenKey: 'projects',
    name: 'Projects',
    screenType: ScreenType.list,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    isSystem: true,
    iconName: 'folder',
    category: ScreenCategory.workspace,
    sections: [
      Section.data(
        config: DataConfig(
          entityType: EntityType.project,
        ),
      ),
    ],
  );

  /// Labels screen - list of labels
  static final labels = ScreenDefinition(
    id: 'labels',
    screenKey: 'labels',
    name: 'Labels',
    screenType: ScreenType.list,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    isSystem: true,
    iconName: 'label',
    category: ScreenCategory.workspace,
    sections: [
      Section.data(
        config: DataConfig(
          entityType: EntityType.label,
        ),
      ),
    ],
  );

  /// Next Actions / Focus screen - allocated tasks
  static final nextActions = ScreenDefinition(
    id: 'next_actions',
    screenKey: 'next_actions',
    name: 'Next Actions',
    screenType: ScreenType.focus,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    isSystem: true,
    iconName: 'bolt',
    category: ScreenCategory.focus,
    sections: [
      const Section.allocation(),
    ],
  );

  /// Get all system screens
  static List<ScreenDefinition> get all => [
    inbox,
    today,
    upcoming,
    logbook,
    projects,
    labels,
    nextActions,
  ];

  /// Get system screen by ID
  static ScreenDefinition? getById(String id) {
    return all.cast<ScreenDefinition?>().firstWhere(
      (s) => s?.id == id,
      orElse: () => null,
    );
  }
}
```

---

## Task 3.5: Update Models Barrel Export

**File**: `lib/domain/models/screens/screens.dart`

Add the new export:

```dart
export 'system_screen_definitions.dart';
// ... existing exports
```

---

## Validation Checklist

- [ ] `flutter analyze` returns 0 errors, 0 warnings (ignore test file errors)
- [ ] Route constants added to `routes.dart`
- [ ] `UnifiedScreenPageById` route added to router
- [ ] `SystemScreenDefinitions` compiles without errors
- [ ] Can navigate to `/unified/inbox` (after app runs)

---

## Files Created

| File | Purpose | LOC |
|------|---------|-----|
| `lib/domain/models/screens/system_screen_definitions.dart` | System screen constants | ~150 |

## Files Modified

| File | Change |
|------|--------|
| `lib/core/routing/routes.dart` | Add unified screen route constants |
| `lib/core/routing/router.dart` | Add unified screen route |
| `lib/domain/models/screens/screens.dart` | Add export |

---

## Testing the Route

After validation, you can manually test by:

1. Running the app
2. Navigating to `/unified/inbox` in the browser (web) or via deep link
3. Verifying the Inbox screen renders

---

## Next Phase

Proceed to **Phase 4: Migrate Inbox Screen** after validation passes.
