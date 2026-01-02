# Phase 6A: Entity Navigation

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each phase/subphase. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files - do not fix errors for compilation of tests.
- **Forms**: Prefer `flutter_form_builder` fields and extensions where applicable.
- **Reuse**: Check existing patterns in codebase before creating new ones.

---

## Goal

Create `EntityNavigator` that provides consistent navigation to entity screens.

**Decisions Implemented**: DR-007 (Default onTap navigation), DR-010 (Dynamic screen routing)

---

## Prerequisites

- Phase 5B complete (ScreenBloc implemented)
- GoRouter setup exists in the codebase

---

## Task 1: Create EntityNavigator

**File**: `lib/presentation/navigation/entity_navigator.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/label.dart';

/// Centralized navigation for entities (DR-007, DR-010).
/// Provides consistent navigation behavior across all entity widgets.
class EntityNavigator {
  /// Navigate to task detail/edit screen
  static void toTask(BuildContext context, String taskId) {
    context.push('/tasks/$taskId');
  }

  /// Navigate to task with entity object
  static void toTaskEntity(BuildContext context, Task task) {
    toTask(context, task.id);
  }

  /// Navigate to project detail screen
  static void toProject(BuildContext context, String projectId) {
    context.push('/projects/$projectId');
  }

  /// Navigate to project with entity object
  static void toProjectEntity(BuildContext context, Project project) {
    toProject(context, project.id);
  }

  /// Navigate to label detail screen
  static void toLabel(BuildContext context, String labelId) {
    context.push('/labels/$labelId');
  }

  /// Navigate to label with entity object
  static void toLabelEntity(BuildContext context, Label label) {
    toLabel(context, label.id);
  }

  /// Navigate to value (label with type=value) detail screen
  static void toValue(BuildContext context, String valueId) {
    context.push('/values/$valueId');
  }

  /// Navigate to any entity by type and ID
  static void toEntity(
    BuildContext context, {
    required String entityId,
    required String entityType,
  }) {
    switch (entityType) {
      case 'task':
        toTask(context, entityId);
      case 'project':
        toProject(context, entityId);
      case 'label':
        toLabel(context, entityId);
      case 'value':
        toValue(context, entityId);
      default:
        debugPrint('Unknown entity type: $entityType');
    }
  }

  /// Navigate to a screen by screen ID
  static void toScreen(BuildContext context, String screenId) {
    context.push('/screens/$screenId');
  }

  /// Navigate to a system screen by name
  static void toSystemScreen(BuildContext context, String screenName) {
    switch (screenName.toLowerCase()) {
      case 'inbox':
        context.push('/inbox');
      case 'today':
        context.push('/today');
      case 'upcoming':
        context.push('/upcoming');
      case 'focus':
      case 'next_actions':
        context.push('/focus');
      case 'projects':
        context.push('/projects');
      case 'labels':
        context.push('/labels');
      case 'values':
        context.push('/values');
      case 'completed':
        context.push('/completed');
      case 'all_tasks':
        context.push('/all-tasks');
      default:
        context.push('/screens/$screenName');
    }
  }

  /// Get the default onTap handler for an entity
  static VoidCallback? getDefaultOnTap(
    BuildContext context, {
    required String entityId,
    required String entityType,
  }) {
    return () => toEntity(
          context,
          entityId: entityId,
          entityType: entityType,
        );
  }
}
```

---

## Task 2: Create EntityTapHandler Mixin

**File**: `lib/presentation/widgets/entity_tap_handler.dart`

A mixin for widgets that display entities and need tap handling:

```dart
import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/navigation/entity_navigator.dart';

/// Mixin providing consistent entity tap handling for widgets.
/// Use this when building entity list items or cards.
mixin EntityTapHandler {
  /// Build tap callback with optional override
  VoidCallback? buildTapCallback(
    BuildContext context, {
    required String entityId,
    required String entityType,
    VoidCallback? customOnTap,
  }) {
    return customOnTap ??
        EntityNavigator.getDefaultOnTap(
          context,
          entityId: entityId,
          entityType: entityType,
        );
  }
}
```

---

## Task 3: Create NavigationExtensions

**File**: `lib/presentation/navigation/navigation_extensions.dart`

```dart
import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/presentation/navigation/entity_navigator.dart';

/// Extension methods for navigation on entity models
extension TaskNavigation on Task {
  /// Navigate to this task's detail screen
  void navigateTo(BuildContext context) {
    EntityNavigator.toTaskEntity(context, this);
  }

  /// Get onTap callback for this task
  VoidCallback onTap(BuildContext context) {
    return () => navigateTo(context);
  }
}

extension ProjectNavigation on Project {
  /// Navigate to this project's detail screen
  void navigateTo(BuildContext context) {
    EntityNavigator.toProjectEntity(context, this);
  }

  /// Get onTap callback for this project
  VoidCallback onTap(BuildContext context) {
    return () => navigateTo(context);
  }
}

extension LabelNavigation on Label {
  /// Navigate to this label's detail screen
  void navigateTo(BuildContext context) {
    EntityNavigator.toLabelEntity(context, this);
  }

  /// Get onTap callback for this label
  VoidCallback onTap(BuildContext context) {
    return () => navigateTo(context);
  }
}
```

---

## Task 4: Create Navigation Barrel Export

**File**: `lib/presentation/navigation/navigation.dart`

```dart
export 'entity_navigator.dart';
export 'navigation_extensions.dart';
```

---

## Task 5: Update Presentation Barrel Export

**File**: `lib/presentation/presentation.dart`

Add navigation export:

```dart
export 'navigation/navigation.dart';
// ... existing exports
```

---

## Task 6: Verify Route Configuration

Ensure the router has routes for entities. Check existing router configuration:

**File**: `lib/presentation/router/app_router.dart` (or similar)

Verify these routes exist or add them:

```dart
GoRoute(
  path: '/tasks/:id',
  builder: (context, state) {
    final taskId = state.pathParameters['id']!;
    return TaskDetailScreen(taskId: taskId);
  },
),
GoRoute(
  path: '/projects/:id',
  builder: (context, state) {
    final projectId = state.pathParameters['id']!;
    return ProjectDetailScreen(projectId: projectId);
  },
),
GoRoute(
  path: '/labels/:id',
  builder: (context, state) {
    final labelId = state.pathParameters['id']!;
    return LabelDetailScreen(labelId: labelId);
  },
),
GoRoute(
  path: '/values/:id',
  builder: (context, state) {
    final valueId = state.pathParameters['id']!;
    return ValueDetailScreen(valueId: valueId);
  },
),
GoRoute(
  path: '/screens/:id',
  builder: (context, state) {
    final screenId = state.pathParameters['id']!;
    return DynamicScreenPage(screenId: screenId);
  },
),
```

---

## Validation Checklist

- [ ] `flutter analyze` returns 0 errors, 0 warnings (ignore test file errors)
- [ ] `EntityNavigator` class exists with all navigation methods
- [ ] `EntityTapHandler` mixin exists
- [ ] Navigation extensions work on entity models
- [ ] Routes are configured in app router

---

## Files Created

| File | Purpose |
|------|---------|
| `lib/presentation/navigation/entity_navigator.dart` | Centralized entity navigation |
| `lib/presentation/widgets/entity_tap_handler.dart` | Mixin for tap handling |
| `lib/presentation/navigation/navigation_extensions.dart` | Extension methods |
| `lib/presentation/navigation/navigation.dart` | Barrel export |

## Files Modified

| File | Change |
|------|--------|
| `lib/presentation/presentation.dart` | Add navigation export |
| `lib/presentation/router/app_router.dart` | Verify/add routes |

---

## Next Phase

Proceed to **Phase 6B: Widget Updates** after validation passes.
