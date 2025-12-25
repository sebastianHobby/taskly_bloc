Upda# Architecture Improvements Plan

**Created:** December 25, 2025  
**Status:** Planning  
**Net Complexity Impact:** -186 lines (reduces overall codebase complexity)

---

## Executive Summary

This plan addresses architectural improvements focused on:
1. Performance optimization through transparent caching
2. Eliminating code duplication in Today/Upcoming features
3. Unifying the dual filter system (TaskFilterConfig → TaskQuery)
4. Adding count method capabilities for efficient queries

**Key Principle:** Priorities 1-3 reduce complexity while improving performance. Priority 4 adds new capability.

---

## Priority 1: Transparent Performance Improvements

**Goal:** Optimize occurrence expansion without changing any contracts or consumer code  
**Effort:** 2-3 hours  
**Net Complexity:** +25 lines  
**API Changes:** None

### 1A. Stream Sharing for Occurrences

**File:** `lib/data/repositories/task_repository.dart`

**Problem:** `watchOccurrences()` creates new streams every call. Multiple subscribers to same date range cause duplicate expansion work.

**Solution:**
- Add internal `Map<_OccurrenceRangeKey, ValueStream<List<Task>>> _occurrenceStreamCache`
- Wrap `watchOccurrences()` result in `shareValue()`
- Multiple widgets watching same date range share ONE expansion

**Impact:** ~50% CPU reduction for common patterns (e.g., Today badge + Today page)

### 1B. RRULE Parse Caching

**File:** `lib/core/streams/occurrence_stream_expander.dart`

**Problem:** RRULE parsing (~1ms per task) happens every stream emission, even though RRULE strings rarely change.

**Solution:**
- Add internal `Map<String, RecurrenceRule> _rruleCache`
- Cache parsed RRULE objects by string key

**Impact:** ~15% reduction in expansion time

### 1C. Per-Entity Expansion Caching (Phase 2 - Optional)

**File:** `lib/core/streams/occurrence_stream_expander.dart`

**Problem:** When one task changes, all tasks are re-expanded.

**Solution:**
- Cache expanded occurrences per entity + range + completions hash
- Skip re-expansion when unrelated tasks change
- Invalidate on entity update, completion change, or exception change

**Impact:** ~35% additional reduction

**Complexity:** Medium - requires change detection and cache invalidation logic

---

## Priority 2: Today/Upcoming BLoC Consolidation

**Goal:** Eliminate TodayTasksBloc duplication while keeping distinct page UIs  
**Effort:** 3 hours  
**Net Complexity:** -250 lines  
**API Changes:** None

### Problem Statement

Currently two BLoCs handle today's tasks:
- `TodayTasksBloc` (app-level) - provides badge count for navigation
- `TaskOverviewBloc` (page-level) - provides data for Today page

This duplicates 95% of stream subscription logic just to calculate `incompleteCount`.

### 2A. Create TodayBadgeService

**File:** New `lib/features/tasks/services/today_badge_service.dart`

```dart
class TodayBadgeService {
  TodayBadgeService({
    required TaskRepositoryContract taskRepository,
    DateTime Function()? nowFactory,
  });

  /// Watch stream of incomplete task count for today.
  Stream<int> watchIncompleteCount() {
    return _taskRepository
        .watchAll(TaskQuery.today(now: _nowFactory()))
        .map((tasks) => tasks.where((t) => !t.completed).length);
  }
}
```

### 2B. Update Navigation Scaffolds

**Files:**
- `lib/core/shared/views/navigation_rail_scaffold.dart`
- `lib/core/shared/views/navigation_bar_scaffold.dart`

**Change:** Replace `BlocBuilder<TodayTasksBloc>` with `StreamBuilder<int>` consuming `TodayBadgeService.watchIncompleteCount()`

### 2C. Update App Registration

**File:** `lib/features/app/view/app.dart`

**Change:** Replace `BlocProvider<TodayTasksBloc>` with `Provider<TodayBadgeService>`

### 2D. Delete TodayTasksBloc

**Files to delete:**
- `lib/features/tasks/bloc/today_tasks_bloc.dart`
- `lib/features/tasks/bloc/today_tasks_event.dart`
- `lib/features/tasks/bloc/today_tasks_state.dart`
- Generated `.freezed.dart` files

### Reasoning Impact

**Before:** "Why are there two BLoCs for today's tasks?"  
**After:** "Service provides badge count, page uses standard TaskOverviewBloc"

---

## Priority 3: TaskFilterConfig → TaskQuery Migration

**Goal:** Complete migration to unified TaskQuery API and delete legacy code  
**Effort:** 3 hours  
**Net Complexity:** -400 lines  
**API Changes:** Remove `watchWithFilter()` from contract

### Problem Statement

Two parallel filter systems exist:
- `TaskFilterConfig` - SQL rules + Dart rules, uses `watchWithFilter()`
- `TaskQuery` - Pure SQL rules, uses `watchAll()`

`TaskRepository.watchAll([TaskQuery? query])` is already implemented. Only 4 consumers still use `watchWithFilter()`.

### 3A. Migrate Remaining Consumers

| File | Current | Change To |
|------|---------|-----------|
| `lib/features/tasks/bloc/task_list_bloc.dart#L118` | `watchWithFilter(config)` | `watchAll(TaskQuery.xxx())` |
| `lib/features/next_action/bloc/next_actions_bloc.dart#L183` | `watchWithFilter(filterConfig)` | `watchAll(TaskQuery.nextActions())` |

### 3B. Delete Legacy Filter System

**Files to delete:**
- `lib/domain/filtering/task_filter_config.dart` (~280 lines)
- `lib/domain/filtering/task_filter_service.dart` (~80 lines)
- `lib/domain/filtering/filtered_stream_result.dart` (~40 lines)
- `lib/domain/filtering/filter_result_metadata.dart` (if unused)

**Contract changes:**
- Remove `watchWithFilter()` from `TaskRepositoryContract`
- Remove `watchWithFilter()` implementation from `TaskRepository`

### Reasoning Impact

**Before:** "When do I use TaskFilterConfig vs TaskQuery?"  
**After:** "Always use TaskQuery"

---

## Priority 4: Count Methods (New Functionality)

**Goal:** Add a single `count/watchCount` API that returns either base-row counts or virtual occurrence counts based on the query (no extra complexity for consumers)  
**Effort:** 7-8 hours  
**Net Complexity:** +208 lines  
**API Changes:** New methods added

**Recommendation:** Defer unless actively needed. Priorities 1-3 should be completed first.

### 4A. Add to TaskRepositoryContract

**File:** `lib/domain/contracts/task_repository_contract.dart`

```dart
/// Count tasks matching query.
Future<int> count([TaskQuery? query]);

/// Watch count of tasks matching query.
Stream<int> watchCount([TaskQuery? query]);
```

**Unified semantics (hide complexity from consumers):**
- If `query` is null, treat as `TaskQuery.all()`.
- If `query.occurrenceExpansion == null`: count base task rows in SQL (fast).
- If `query.occurrenceExpansion != null`: count *virtual expanded occurrences* within `occurrenceExpansion.rangeStart/rangeEnd`.
  - Consumers only pass the query; they do not choose a different method.
  - Example: `TaskQuery.schedule(...)` yields virtual occurrence counts.

### 4B. Implement in TaskRepository

**File:** `lib/data/repositories/task_repository.dart`

Use Drift `selectOnly` + `countAll()` for SQL-level counting:

```dart
@override
Future<int> count([TaskQuery? query]) async {
  final baseQuery = driftDb.selectOnly(driftDb.taskTable);
  
  if (query != null && query.rules.isNotEmpty) {
    final whereExpr = _buildWhereExpression(query);
    baseQuery.where(whereExpr);
  }
  
  baseQuery.addColumns([driftDb.taskTable.id.count()]);
  
  final result = await baseQuery.getSingle();
  return result.read(driftDb.taskTable.id.count()) ?? 0;
}
```

**Occurrence-aware implementation (virtual counts):**
- In `count/watchCount`, branch on `query.shouldExpandOccurrences`.
- For virtual counts, reuse the existing occurrence pipeline initially:
  - `watchOccurrences(rangeStart: q.occurrenceExpansion.rangeStart, rangeEnd: q.occurrenceExpansion.rangeEnd)`
  - then map to `.length`, apply `distinct()`, and share with `shareValue()`.
- Later optimization (no consumer/API change): add a count-only expansion path in `OccurrenceStreamExpander` to avoid building full occurrence objects.

### 4C. Create ProjectQuery

**File:** New `lib/domain/queries/project_query.dart`

Mirror TaskQuery structure with:
- `rules` - List of filter rules
- `sortCriteria` - Sort configuration
- Factory methods: `all()`, `active()`, `completed()`, `forLabel()`, `today()`, `upcoming()`

### 4D. Add Project Count Methods

**Files:**
- `lib/domain/contracts/project_repository_contract.dart`
- `lib/data/repositories/project_repository.dart`

Same pattern as task counts.

### 4E. Virtual Occurrence Counts (Included)

Virtual occurrence counts are supported through the same `count/watchCount` methods by passing a query with `occurrenceExpansion` populated.

This keeps the consumer API simple while allowing advanced (virtual) counts when needed.

---

## Priority 5: Badge Uses Count API

**Goal:** Optimize TodayBadgeService to use SQL COUNT  
**Effort:** 15 minutes  
**Net Complexity:** 0 lines  
**Dependencies:** Priority 4 must be complete

**File:** `lib/features/tasks/services/today_badge_service.dart`

```dart
// Before (Priority 2 implementation)
Stream<int> watchIncompleteCount() {
  return taskRepository.watchAll(TaskQuery.today(now: now))
      .map((tasks) => tasks.where((t) => !t.completed).length);
}

// After (Priority 5 optimization)
Stream<int> watchIncompleteCount() {
  return taskRepository.watchCount(TaskQuery.today(now: now));
}
```

Note: if a badge ever needs *virtual* occurrence counts (not base rows), it should pass a `TaskQuery` that includes `occurrenceExpansion` (for example, `TaskQuery.schedule(...)`).

---

## Complexity Summary

| Priority | Lines Added | Lines Removed | Net Change | API Impact |
|----------|-------------|---------------|------------|------------|
| 1. Caching | +25 | 0 | **+25** | None |
| 2. TodayBadgeService | +35 | -285 | **-250** | None |
| 3. TaskQuery Migration | 0 | -400 | **-400** | Remove method |
| 4. Count Methods | +208 | 0 | **+208** | New methods |
| 5. Badge optimization | 0 | 0 | **0** | None |
| **TOTAL** | **+268** | **-685** | **-417** | |

---

## Reasoning Improvements

| Area | Before | After |
|------|--------|-------|
| Filter systems | Two parallel systems (TaskFilterConfig + TaskQuery) | One unified system (TaskQuery) |
| Today data sources | Two BLoCs with overlapping responsibility | Service for badge + standard BLoC for page |
| Project filtering | No query object, Dart-side filtering only | ProjectQuery mirrors TaskQuery pattern |
| Performance | No caching for occurrence streams | Transparent caching at multiple layers |

---

## Implementation Order

```
Priority 1 (Caching)     ─┬─► Can run in parallel
Priority 2 (Badge)       ─┤
Priority 3 (Migration)   ─┘
                           │
                           ▼
Priority 4 (Counts)      ─── Defer until needed
                           │
                           ▼
Priority 5 (Optimize)    ─── Depends on Priority 4
```

**Recommended:** Complete Priorities 1-3 first. They have **negative net complexity** (-625 lines combined) and improve architectural reasoning. Priority 4 can be added when count functionality is actively needed.

---

## Risk Assessment

| Change | Risk Level | Mitigation |
|--------|------------|------------|
| Occurrence caching | Low | Purely internal, no API changes |
| TodayBadgeService | Low | Simple service, clear single purpose |
| TaskQuery migration | Low-Medium | TaskQuery already implemented, clean deletion |
| Count methods | Medium | New API surface, needs documentation |
| ProjectQuery | Medium | New file, but follows established pattern |

---

## Files Changed Summary

### Priority 1
- `lib/data/repositories/task_repository.dart` (modify)
- `lib/core/streams/occurrence_stream_expander.dart` (modify)

### Priority 2
- `lib/features/tasks/services/today_badge_service.dart` (create)
- `lib/core/shared/views/navigation_rail_scaffold.dart` (modify)
- `lib/core/shared/views/navigation_bar_scaffold.dart` (modify)
- `lib/features/app/view/app.dart` (modify)
- `lib/features/tasks/bloc/today_tasks_bloc.dart` (delete)
- `lib/features/tasks/bloc/today_tasks_event.dart` (delete)
- `lib/features/tasks/bloc/today_tasks_state.dart` (delete)

### Priority 3
- `lib/features/tasks/bloc/task_list_bloc.dart` (modify)
- `lib/features/next_action/bloc/next_actions_bloc.dart` (modify)
- `lib/domain/contracts/task_repository_contract.dart` (modify - remove watchWithFilter)
- `lib/data/repositories/task_repository.dart` (modify - remove watchWithFilter)
- `lib/domain/filtering/task_filter_config.dart` (delete)
- `lib/domain/filtering/task_filter_service.dart` (delete)
- `lib/domain/filtering/filtered_stream_result.dart` (delete)
- `lib/domain/filtering/filter_result_metadata.dart` (delete if unused)

### Priority 4
- `lib/domain/contracts/task_repository_contract.dart` (modify)
- `lib/data/repositories/task_repository.dart` (modify)
- `lib/domain/queries/project_query.dart` (create)
- `lib/domain/contracts/project_repository_contract.dart` (modify)
- `lib/data/repositories/project_repository.dart` (modify)

### Priority 5
- `lib/features/tasks/services/today_badge_service.dart` (modify)
