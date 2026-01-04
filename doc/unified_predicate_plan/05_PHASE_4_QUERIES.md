# Phase 4: Query Class Migration

**Duration**: 1 day  
**Risk**: 🟡 Medium  
**Dependencies**: Phase 3 (Mapper and Evaluator exist)

---

## Objectives

1. Migrate `TaskQuery` to use new `Predicate<Task>`
2. Migrate `ProjectQuery` to use new `Predicate<Project>`
3. Migrate `JournalQuery` to use new `Predicate<JournalEntry>`
4. Maintain backward compatibility for existing usages

---

## Deliverables

| File | Description |
|------|-------------|
| `lib/domain/queries/task_query.dart` | Updated to use Predicate<Task> |
| `lib/domain/queries/project_query.dart` | Updated to use Predicate<Project> |
| `lib/domain/queries/journal_query.dart` | Updated to use Predicate<JournalEntry> |

---

## Migration Strategy

### Approach: Parallel Fields with Deprecation

1. Add new `predicate` field alongside existing `predicates` list
2. Mark old field as `@Deprecated`
3. Update internal logic to use new predicate
4. Gradually migrate callers in subsequent phases

```dart
// Before
@freezed
abstract class TaskQuery with _$TaskQuery {
  const factory TaskQuery({
    @Default([]) List<TaskPredicate> predicates,
    // ...
  }) = _TaskQuery;
}

// After
@freezed
abstract class TaskQuery with _$TaskQuery {
  const factory TaskQuery({
    /// New unified predicate. Use this instead of [predicates].
    Predicate<Task>? filter,
    
    /// @Deprecated: Use [filter] instead.
    @Deprecated('Use filter instead')
    @Default([]) List<TaskPredicate> predicates,
    // ...
  }) = _TaskQuery;
}
```

---

## Implementation Details

### 1. TaskQuery Migration

```dart
// lib/domain/queries/task_query.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../entities/task.dart';
import 'predicates/predicates.dart';
import 'fields/task_fields.dart';
// Keep old import during migration
import '../predicates/task_predicate.dart';

part 'task_query.freezed.dart';
part 'task_query.g.dart';

@freezed
abstract class TaskQuery with _$TaskQuery {
  const factory TaskQuery({
    /// Unique identifier for this query (for caching/comparison).
    String? id,
    
    /// New unified predicate filter.
    /// 
    /// Example:
    /// ```dart
    /// TaskQuery(
    ///   filter: AndPredicate([
    ///     BoolPredicate(field: TaskFields.isCompleted, operator: ComparisonOperator.equals, value: false),
    ///     BoolPredicate(field: TaskFields.isTrashed, operator: ComparisonOperator.equals, value: false),
    ///   ]),
    /// )
    /// ```
    Predicate<Task>? filter,
    
    /// @Deprecated: Use [filter] instead.
    /// Will be removed in a future version.
    @Deprecated('Use filter instead. Will be removed in v2.0')
    @Default([]) List<TaskPredicate> predicates,
    
    /// Field to sort results by.
    @Default(TaskSortField.createdAt) TaskSortField sortBy,
    
    /// Sort direction.
    @Default(SortDirection.descending) SortDirection sortDirection,
    
    /// Maximum number of results to return.
    int? limit,
    
    /// Number of results to skip (for pagination).
    int? offset,
  }) = _TaskQuery;

  const TaskQuery._();

  factory TaskQuery.fromJson(Map<String, dynamic> json) =>
      _$TaskQueryFromJson(json);

  /// Get the effective predicate for this query.
  /// 
  /// Returns [filter] if set, otherwise converts [predicates] to new format.
  Predicate<Task>? get effectivePredicate {
    if (filter != null) return filter;
    if (predicates.isEmpty) return null;
    
    // Convert legacy predicates to new format
    // ignore: deprecated_member_use_from_same_package
    return _convertLegacyPredicates(predicates);
  }

  /// Convert old TaskPredicate list to new Predicate<Task>.
  static Predicate<Task>? _convertLegacyPredicates(List<TaskPredicate> legacy) {
    if (legacy.isEmpty) return null;
    if (legacy.length == 1) return _convertSingle(legacy.first);
    
    return AndPredicate<Task>(
      legacy.map(_convertSingle).toList(),
    );
  }

  static Predicate<Task> _convertSingle(TaskPredicate old) {
    // Map old predicates to new format
    return switch (old) {
      TaskBoolPredicate p => BoolPredicate<Task>(
        field: _boolFieldMap[p.field]!,
        operator: _operatorMap[p.operator]!,
        value: p.value,
      ),
      TaskDatePredicate p => DatePredicate<Task>(
        field: _dateFieldMap[p.field]!,
        operator: _operatorMap[p.operator]!,
        value: p.value,
        relativeDate: p.relativeDate != null 
            ? RelativeDate.values.byName(p.relativeDate!.name)
            : null,
      ),
      // Add other predicate types...
      _ => throw UnimplementedError('Unknown predicate type: $old'),
    };
  }

  // Field mapping tables
  static const _boolFieldMap = {
    TaskBoolField.isCompleted: TaskFields.isCompleted,
    TaskBoolField.isTrashed: TaskFields.isTrashed,
    TaskBoolField.isRecurring: TaskFields.isRecurring,
    TaskBoolField.isPinned: TaskFields.isPinned,
  };

  static const _dateFieldMap = {
    TaskDateField.startDate: TaskFields.startDate,
    TaskDateField.dueDate: TaskFields.dueDate,
    TaskDateField.completedAt: TaskFields.completedAt,
    TaskDateField.createdAt: TaskFields.createdAt,
  };

  static const _operatorMap = {
    BoolOperator.equals: ComparisonOperator.equals,
    BoolOperator.notEquals: ComparisonOperator.notEquals,
    // Add date operators...
  };
}
```

### 2. JSON Serialization for Predicate<Task>

Add custom JSON converter:

```dart
// lib/domain/queries/predicate_json_converter.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../entities/task.dart';
import 'predicates/predicates.dart';
import 'fields/task_fields.dart';

/// JSON converter for Predicate<Task>.
class TaskPredicateConverter 
    implements JsonConverter<Predicate<Task>?, Map<String, dynamic>?> {
  const TaskPredicateConverter();

  @override
  Predicate<Task>? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return Predicate.fromJson<Task>(json, TaskFields.byName);
  }

  @override
  Map<String, dynamic>? toJson(Predicate<Task>? object) {
    return object?.toJson();
  }
}
```

Then use it in TaskQuery:

```dart
@freezed
abstract class TaskQuery with _$TaskQuery {
  const factory TaskQuery({
    @TaskPredicateConverter() Predicate<Task>? filter,
    // ...
  }) = _TaskQuery;
}
```

---

## Step-by-Step Implementation

### Step 1: Create Predicate JSON Converters

Create converters for each entity type:
- `TaskPredicateConverter`
- `ProjectPredicateConverter`  
- `JournalPredicateConverter`

### Step 2: Update TaskQuery

1. Add `filter` field with converter annotation
2. Mark `predicates` as `@Deprecated`
3. Add `effectivePredicate` getter
4. Add legacy conversion methods

### Step 3: Update ProjectQuery

Apply same pattern as TaskQuery.

### Step 4: Update JournalQuery

Apply same pattern as TaskQuery.

### Step 5: Update Tests

Update query tests to use new `filter` field.

---

## ✅ Verification Checklist

- [ ] TaskQuery has `filter` field with JSON converter
- [ ] TaskQuery.effectivePredicate returns correct predicate
- [ ] Legacy `predicates` still work (backward compat)
- [ ] JSON round-trip works for new predicate format
- [ ] `@Deprecated` warnings appear when using old field
- [ ] All existing query tests pass
- [ ] `flutter analyze` shows no errors

---

## 🤖 AI Assistant Instructions

### Context Required

Attach or reference these files:
- `lib/domain/queries/task_query.dart` (existing)
- `lib/domain/queries/project_query.dart` (existing)
- `lib/domain/queries/journal_query.dart` (existing)
- `lib/domain/queries/predicates/predicates.dart` (from Phase 2)
- `lib/domain/queries/fields/task_fields.dart` (from Phase 1)

### Implementation Checklist

1. [ ] Create `predicate_json_converter.dart` with entity-specific converters
2. [ ] Update `TaskQuery`:
   - Add `filter` field with `@TaskPredicateConverter()`
   - Add `@Deprecated` to `predicates` field
   - Add `effectivePredicate` getter
   - Add legacy conversion methods
3. [ ] Update `ProjectQuery` with same pattern
4. [ ] Update `JournalQuery` with same pattern
5. [ ] Verify build_runner generates new code (watch mode)
6. [ ] Update tests to use new `filter` field
7. [ ] Verify backward compatibility

### Key Prompts

**Prompt 1 - Create JSON Converters:**
> Create `lib/domain/queries/predicate_json_converter.dart` with:
> - `TaskPredicateConverter` implementing `JsonConverter<Predicate<Task>?, Map<String, dynamic>?>`
> - `fromJson` uses `Predicate.fromJson<Task>(json, TaskFields.byName)`
> - `toJson` calls `object?.toJson()`
> - Create similar converters for Project and JournalEntry

**Prompt 2 - Update TaskQuery:**
> Update `lib/domain/queries/task_query.dart` to add:
> 1. Import new predicate types
> 2. Add `@TaskPredicateConverter() Predicate<Task>? filter` field
> 3. Add `@Deprecated('Use filter instead')` to `predicates` field
> 4. Add `effectivePredicate` getter that prefers `filter` over `predicates`
> 5. Add private `_convertLegacyPredicates` method for backward compat
>
> Keep existing fields and behavior during migration.

### Watch Out For

| ❌ Avoid | ✅ Instead |
|---------|-----------|
| Removing old `predicates` field | Keep with @Deprecated |
| Breaking JSON format | Add new field alongside old |
| Missing JSON converter | Add @TaskPredicateConverter |
| Forgetting build_runner | Assume watch mode running |
| Non-exhaustive legacy conversion | Handle ALL old predicate types |

### Backward Compatibility

**CRITICAL**: Existing code MUST continue working:

```dart
// OLD CODE - must still compile and work
final query = TaskQuery(
  predicates: [
    TaskBoolPredicate(
      field: TaskBoolField.isCompleted,
      operator: BoolOperator.equals,
      value: false,
    ),
  ],
);

// NEW CODE - preferred approach
final query = TaskQuery(
  filter: BoolPredicate<Task>(
    field: TaskFields.isCompleted,
    operator: ComparisonOperator.equals,
    value: false,
  ),
);

// BOTH should produce same repository results
```

### Verification Questions

After completion, verify:
1. Does `TaskQuery(filter: ...)` compile?
2. Does `TaskQuery(predicates: [...])` show deprecation warning?
3. Does `query.effectivePredicate` return correct predicate?
4. Does JSON serialization include new `filter` field?
5. Can old JSON (with `predicates`) still be deserialized?

---

## Files to Modify

```
lib/domain/queries/
├── predicate_json_converter.dart  # NEW
├── task_query.dart                # MODIFY
├── project_query.dart             # MODIFY
└── journal_query.dart             # MODIFY
```

---

## Migration Pattern Summary

```dart
// 1. Add new field with converter
@TaskPredicateConverter() Predicate<Task>? filter,

// 2. Deprecate old field
@Deprecated('Use filter instead')
@Default([]) List<TaskPredicate> predicates,

// 3. Add compatibility getter
Predicate<Task>? get effectivePredicate {
  if (filter != null) return filter;
  return _convertLegacyPredicates(predicates);
}

// 4. Add conversion method
static Predicate<Task>? _convertLegacyPredicates(List<TaskPredicate> legacy) {
  // Convert each old predicate to new format
}
```

---

## Next Phase

→ [Phase 5: Repository Integration](./06_PHASE_5_REPOSITORIES.md)
