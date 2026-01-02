# Phase 4B: Data Fetching - Repository Updates

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each phase/subphase. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files - do not fix errors for compilation of tests.
- **Forms**: Prefer `flutter_form_builder` fields and extensions where applicable.
- **Reuse**: Check existing patterns in codebase before creating new ones.

---

## Goal

Add query methods to repositories that support the new query types.

**Decisions Implemented**: DR-002 (Queries embedded in DataConfig)

---

## Prerequisites

- Phase 1A complete (LabelQuery exists)
- Phase 1B complete (Query enhancements exist)
- Phase 4A complete (SectionDataService exists)

---

## Task 1: Update TaskRepository

**File**: `lib/domain/repositories/task_repository.dart`

Add or update the query method:

```dart
/// Query tasks using TaskQuery
Future<List<Task>> queryTasks(TaskQuery query);

/// Get tasks by project ID
Future<List<Task>> getTasksByProject(String projectId);

/// Get tasks by label ID
Future<List<Task>> getTasksByLabel(String labelId);

/// Get tasks by IDs
Future<List<Task>> getTasksByIds(List<String> ids);
```

---

## Task 2: Update TaskRepository Implementation

**File**: `lib/data/repositories/task_repository_impl.dart` (or similar)

Implement the query method:

```dart
@override
Future<List<Task>> queryTasks(TaskQuery query) async {
  // Build query based on filter and sort criteria
  var dbQuery = _database.select(_database.tasks);

  if (query.filter != null) {
    dbQuery = _applyTaskFilter(dbQuery, query.filter!);
  }

  // Apply sorting
  for (final criterion in query.sortCriteria) {
    dbQuery = _applyTaskSort(dbQuery, criterion);
  }

  final results = await dbQuery.get();
  return results.map(_mapToTask).toList();
}

SimpleSelectStatement<$TasksTable, TaskData> _applyTaskFilter(
  SimpleSelectStatement<$TasksTable, TaskData> query,
  QueryFilter<TaskPredicate> filter,
) {
  for (final predicate in filter.shared) {
    query = _applyTaskPredicate(query, predicate);
  }
  return query;
}

SimpleSelectStatement<$TasksTable, TaskData> _applyTaskPredicate(
  SimpleSelectStatement<$TasksTable, TaskData> query,
  TaskPredicate predicate,
) {
  return switch (predicate) {
    TaskIdPredicate(:final taskId) =>
        query..where((t) => t.id.equals(taskId)),
    TaskProjectIdPredicate(:final projectId) =>
        query..where((t) => t.projectId.equals(projectId)),
    TaskCompletedPredicate(:final isCompleted) =>
        query..where((t) => t.isCompleted.equals(isCompleted)),
    TaskDeadlineDateRangePredicate(:final start, :final end) =>
        query..where((t) => t.deadlineDate.isBetweenValues(start, end)),
    TaskDeadlineBeforePredicate(:final date) =>
        query..where((t) => t.deadlineDate.isSmallerThanValue(date)),
    TaskLabelsPredicate(:final labelIds, :final matchMode) =>
        _applyLabelFilter(query, labelIds, matchMode),
    TaskNoProjectPredicate() =>
        query..where((t) => t.projectId.isNull()),
    TaskInIdsPredicate(:final ids) =>
        query..where((t) => t.id.isIn(ids)),
    // Add more predicate handlers as needed
    _ => query,
  };
}
```

**Note**: Adapt to existing Drift/repository patterns in the codebase.

---

## Task 3: Update ProjectRepository

**File**: `lib/domain/repositories/project_repository.dart`

Add query method:

```dart
/// Query projects using ProjectQuery
Future<List<Project>> queryProjects(ProjectQuery query);

/// Get projects by IDs
Future<List<Project>> getProjectsByIds(List<String> ids);

/// Get projects by label ID
Future<List<Project>> getProjectsByLabel(String labelId);
```

---

## Task 4: Update ProjectRepository Implementation

Similar pattern to TaskRepository:

```dart
@override
Future<List<Project>> queryProjects(ProjectQuery query) async {
  var dbQuery = _database.select(_database.projects);

  if (query.filter != null) {
    dbQuery = _applyProjectFilter(dbQuery, query.filter!);
  }

  for (final criterion in query.sortCriteria) {
    dbQuery = _applyProjectSort(dbQuery, criterion);
  }

  final results = await dbQuery.get();
  return results.map(_mapToProject).toList();
}
```

---

## Task 5: Update LabelRepository

**File**: `lib/domain/repositories/label_repository.dart`

Add query method:

```dart
/// Query labels using LabelQuery
Future<List<Label>> queryLabels(LabelQuery query);

/// Get labels by IDs
Future<List<Label>> getLabelsByIds(List<String> ids);
```

---

## Task 6: Update LabelRepository Implementation

```dart
@override
Future<List<Label>> queryLabels(LabelQuery query) async {
  var dbQuery = _database.select(_database.labels);

  if (query.filter != null) {
    dbQuery = _applyLabelFilter(dbQuery, query.filter!);
  }

  for (final criterion in query.sortCriteria) {
    dbQuery = _applyLabelSort(dbQuery, criterion);
  }

  final results = await dbQuery.get();
  return results.map(_mapToLabel).toList();
}

SimpleSelectStatement<$LabelsTable, LabelData> _applyLabelPredicate(
  SimpleSelectStatement<$LabelsTable, LabelData> query,
  LabelPredicate predicate,
) {
  return switch (predicate) {
    LabelIdPredicate(:final labelId) =>
        query..where((l) => l.id.equals(labelId)),
    LabelTypePredicate(:final type) =>
        query..where((l) => l.type.equals(type.name)),
    LabelNamePredicate(:final value, :final mode) =>
        _applyNameFilter(query, value, mode),
    LabelColorPredicate(:final colorHex) =>
        query..where((l) => l.color.equals(colorHex)),
    LabelInIdsPredicate(:final ids) =>
        query..where((l) => l.id.isIn(ids)),
  };
}

SimpleSelectStatement<$LabelsTable, LabelData> _applyNameFilter(
  SimpleSelectStatement<$LabelsTable, LabelData> query,
  String value,
  StringMatchMode mode,
) {
  return switch (mode) {
    StringMatchMode.equals => query..where((l) => l.name.equals(value)),
    StringMatchMode.contains => query..where((l) => l.name.contains(value)),
    StringMatchMode.startsWith => query..where((l) => l.name.like('$value%')),
    StringMatchMode.endsWith => query..where((l) => l.name.like('%$value')),
  };
}
```

---

## Task 7: Add QueryFilter Merge Method

**File**: `lib/domain/queries/query_filter.dart`

Add merge capability:

```dart
extension QueryFilterExtension<T> on QueryFilter<T> {
  /// Merge with another filter (combines shared predicates)
  QueryFilter<T> merge(QueryFilter<T>? other) {
    if (other == null) return this;
    return QueryFilter<T>(
      shared: [...shared, ...other.shared],
      include: include != null || other.include != null
          ? [...?include, ...?other.include]
          : null,
      exclude: exclude != null || other.exclude != null
          ? [...?exclude, ...?other.exclude]
          : null,
    );
  }
}
```

---

## Validation Checklist

- [ ] `flutter analyze` returns 0 errors, 0 warnings (ignore test file errors)
- [ ] `TaskRepository.queryTasks` method exists
- [ ] `ProjectRepository.queryProjects` method exists
- [ ] `LabelRepository.queryLabels` method exists
- [ ] Query implementations handle all predicate types
- [ ] `QueryFilter.merge` works correctly

---

## Files Modified

| File | Change |
|------|--------|
| `lib/domain/repositories/task_repository.dart` | Add query methods |
| `lib/data/repositories/task_repository_impl.dart` | Implement query methods |
| `lib/domain/repositories/project_repository.dart` | Add query methods |
| `lib/data/repositories/project_repository_impl.dart` | Implement query methods |
| `lib/domain/repositories/label_repository.dart` | Add query methods |
| `lib/data/repositories/label_repository_impl.dart` | Implement query methods |
| `lib/domain/queries/query_filter.dart` | Add merge extension |

---

## Next Phase

Proceed to **Phase 5A: Unified ScreenBloc - Core** after validation passes.
