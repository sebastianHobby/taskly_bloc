# Phase 1B: Query Foundation - Enhancements

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each phase/subphase. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files - do not fix errors for compilation of tests.
- **Forms**: Prefer `flutter_form_builder` fields and extensions where applicable.
- **Reuse**: Check existing patterns in codebase before creating new ones.

---

## Goal

Add `LabelMatchMode` enum and convenience factory methods to all query types.

**Decisions Implemented**: DR-004 (LabelMatchMode enum), DR-006 (Query convenience factories)

---

## Prerequisites

- Phase 1A complete (LabelQuery exists)

---

## Task 1: Create LabelMatchMode

**File**: `lib/domain/queries/label_match_mode.dart`

```dart
import 'package:json_annotation/json_annotation.dart';

/// How multiple labels should be matched when filtering
enum LabelMatchMode {
  /// Entity must have ANY of the specified labels
  @JsonValue('any')
  any,

  /// Entity must have ALL of the specified labels
  @JsonValue('all')
  all,

  /// Entity must have NONE of the specified labels
  @JsonValue('none')
  none,
}
```

---

## Task 2: Add Convenience Factories to TaskQuery

**File**: `lib/domain/queries/task_query.dart`

Add these factory methods to the existing `TaskQuery` class:

```dart
// Add to TaskQuery class body:

/// Tasks due today
factory TaskQuery.dueToday() {
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  return TaskQuery(
    filter: QueryFilter(
      shared: [
        TaskPredicate.deadlineDateRange(
          start: startOfDay,
          end: endOfDay,
        ),
        const TaskPredicate.completed(isCompleted: false),
      ],
    ),
  );
}

/// Tasks due this week
factory TaskQuery.dueThisWeek() {
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
  final end = start.add(const Duration(days: 7));
  return TaskQuery(
    filter: QueryFilter(
      shared: [
        TaskPredicate.deadlineDateRange(start: start, end: end),
        const TaskPredicate.completed(isCompleted: false),
      ],
    ),
  );
}

/// Overdue tasks
factory TaskQuery.overdue() {
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  return TaskQuery(
    filter: QueryFilter(
      shared: [
        TaskPredicate.deadlineBefore(date: startOfDay),
        const TaskPredicate.completed(isCompleted: false),
      ],
    ),
  );
}

/// Tasks in a specific project
factory TaskQuery.byProject(String projectId) => TaskQuery(
      filter: QueryFilter(
        shared: [TaskPredicate.projectId(projectId: projectId)],
      ),
    );

/// Tasks with specific labels
factory TaskQuery.byLabels(
  List<String> labelIds, {
  LabelMatchMode mode = LabelMatchMode.any,
}) =>
    TaskQuery(
      filter: QueryFilter(
        shared: [
          TaskPredicate.labels(labelIds: labelIds, matchMode: mode),
        ],
      ),
    );

/// Inbox tasks (no project)
factory TaskQuery.inbox() => TaskQuery(
      filter: QueryFilter(
        shared: [
          const TaskPredicate.noProject(),
          const TaskPredicate.completed(isCompleted: false),
        ],
      ),
    );
```

**Note**: Check existing `TaskPredicate` variants and use what exists. Create any missing predicates if needed.

---

## Task 3: Add Convenience Factories to ProjectQuery

**File**: `lib/domain/queries/project_query.dart`

Add these factory methods:

```dart
// Add to ProjectQuery class body:

/// Active projects (not completed)
factory ProjectQuery.active() => ProjectQuery(
      filter: QueryFilter(
        shared: [const ProjectPredicate.completed(isCompleted: false)],
      ),
    );

/// Completed projects
factory ProjectQuery.completed() => ProjectQuery(
      filter: QueryFilter(
        shared: [const ProjectPredicate.completed(isCompleted: true)],
      ),
    );

/// Projects with specific labels/values
factory ProjectQuery.byLabels(
  List<String> labelIds, {
  LabelMatchMode mode = LabelMatchMode.any,
}) =>
    ProjectQuery(
      filter: QueryFilter(
        shared: [
          ProjectPredicate.labels(labelIds: labelIds, matchMode: mode),
        ],
      ),
    );
```

---

## Task 4: Add More Factories to LabelQuery

**File**: `lib/domain/queries/label_query.dart`

Enhance with additional factories:

```dart
// Add to LabelQuery class body:

/// Create a query for labels by name search
factory LabelQuery.search(String searchTerm) => LabelQuery(
      filter: QueryFilter(
        shared: [
          LabelPredicate.name(
            value: searchTerm,
            mode: StringMatchMode.contains,
          ),
        ],
      ),
    );

/// Create a query for labels by color
factory LabelQuery.byColor(String colorHex) => LabelQuery(
      filter: QueryFilter(
        shared: [LabelPredicate.color(colorHex: colorHex)],
      ),
    );
```

---

## Task 5: Update Barrel Export

**File**: `lib/domain/queries/queries.dart`

Add export for LabelMatchMode:

```dart
export 'label_match_mode.dart';
// ... other exports
```

---

## Validation Checklist

- [ ] `flutter analyze` returns 0 errors, 0 warnings (ignore test file errors)
- [ ] `LabelMatchMode` enum created and exported
- [ ] `TaskQuery.dueToday()` compiles without errors
- [ ] `TaskQuery.byProject()` compiles without errors
- [ ] `ProjectQuery.active()` compiles without errors
- [ ] `LabelQuery.search()` compiles without errors

---

## Files Created

| File | Purpose |
|------|---------|
| `lib/domain/queries/label_match_mode.dart` | Enum for label matching logic |

## Files Modified

| File | Change |
|------|--------|
| `lib/domain/queries/task_query.dart` | Add convenience factory methods |
| `lib/domain/queries/project_query.dart` | Add convenience factory methods |
| `lib/domain/queries/label_query.dart` | Add convenience factory methods |
| `lib/domain/queries/queries.dart` | Add LabelMatchMode export |

---

## Next Phase

Proceed to **Phase 2A: Section Model** after validation passes.
