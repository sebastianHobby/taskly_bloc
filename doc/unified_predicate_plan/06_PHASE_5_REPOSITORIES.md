# Phase 5: Repository Integration

**Duration**: 1 day  
**Risk**: 🔴 High  
**Dependencies**: Phase 4 (Query classes migrated)

---

## Objectives

1. Update repositories to use `UnifiedPredicateMapper`
2. Update repositories to use `FilterEvaluator`
3. Maintain full backward compatibility
4. Ensure all integration tests pass

---

## ⚠️ Risk Assessment

This phase modifies **production data access code**. Bugs here can cause:
- Data not loading
- Wrong query results
- Performance regressions
- App crashes

**Mitigation**:
1. Extensive test coverage before changes
2. Incremental migration (one repository at a time)
3. Parity testing at each step
4. Feature flag for rollback if needed

---

## Deliverables

| File | Description |
|------|-------------|
| `lib/data/repositories/task_repository_impl.dart` | Updated to use new mapper |
| `lib/data/repositories/project_repository_impl.dart` | Updated to use new mapper |
| `lib/data/repositories/journal_repository_impl.dart` | Updated to use new mapper |

---

## Implementation Strategy

### Approach: Dual Path with Feature Flag

```dart
class TaskRepositoryImpl implements TaskRepository {
  static const _useNewMapper = true; // Toggle for rollback
  
  final UnifiedPredicateMapper<Task> _newMapper;
  final TaskPredicateMapper _oldMapper; // Keep during migration
  
  @override
  Future<List<Task>> query(TaskQuery query) async {
    final whereClause = _useNewMapper
        ? _buildNewWhere(query)
        : _buildOldWhere(query);
    // ...
  }
}
```

---

## Implementation Details

### 1. Repository Pattern

```dart
// lib/data/repositories/task_repository_impl.dart
import 'package:taskly_bloc/data/repositories/mappers/unified_predicate_mapper.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/queries/predicates/predicates.dart';
import 'package:taskly_bloc/domain/entities/task.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl({
    required Database database,
    UnifiedPredicateMapper<Task>? predicateMapper,
  }) : _database = database,
       _predicateMapper = predicateMapper ?? const UnifiedPredicateMapper<Task>();

  final Database _database;
  final UnifiedPredicateMapper<Task> _predicateMapper;
  
  // Keep old mapper during transition
  final _oldMapper = TaskPredicateMapper();

  @override
  Future<List<Task>> query(TaskQuery query) async {
    // Build WHERE clause
    final predicate = query.effectivePredicate;
    final whereClause = predicate != null 
        ? _predicateMapper.toSql(predicate)
        : null;

    // Build ORDER BY
    final orderBy = _buildOrderBy(query.sortBy, query.sortDirection);

    // Build LIMIT/OFFSET
    final limitClause = query.limit != null ? 'LIMIT ${query.limit}' : '';
    final offsetClause = query.offset != null ? 'OFFSET ${query.offset}' : '';

    // Construct full query
    final sql = StringBuffer('SELECT * FROM tasks');
    final params = <Object?>[];

    if (whereClause != null) {
      sql.write(' WHERE ${whereClause.sql}');
      params.addAll(whereClause.parameters);
    }

    sql.write(' $orderBy $limitClause $offsetClause');

    // Execute and map results
    final rows = await _database.rawQuery(sql.toString(), params);
    return rows.map(_mapRowToTask).toList();
  }

  String _buildOrderBy(TaskSortField field, SortDirection direction) {
    final column = switch (field) {
      TaskSortField.createdAt => 'created_at',
      TaskSortField.dueDate => 'due_date',
      TaskSortField.priority => 'priority',
      TaskSortField.title => 'title',
    };
    final dir = direction == SortDirection.ascending ? 'ASC' : 'DESC';
    return 'ORDER BY $column $dir';
  }

  Task _mapRowToTask(Map<String, dynamic> row) {
    // Map database row to Task entity
    return Task(
      id: row['id'] as String,
      title: row['title'] as String,
      isCompleted: (row['is_completed'] as int) == 1,
      // ... other fields
    );
  }
}
```

### 2. Client-Side Filtering

For repositories that do client-side filtering:

```dart
class TaskRepositoryImpl implements TaskRepository {
  final FilterEvaluator<Task> _evaluator = const FilterEvaluator<Task>();

  @override
  Stream<List<Task>> watchFiltered(TaskQuery query) {
    return watchAll().map((tasks) {
      var result = tasks;
      
      // Apply predicate filter
      final predicate = query.effectivePredicate;
      if (predicate != null) {
        result = _evaluator.filter(result, predicate);
      }
      
      // Apply sorting
      result = _sortTasks(result, query.sortBy, query.sortDirection);
      
      // Apply pagination
      if (query.offset != null) {
        result = result.skip(query.offset!).toList();
      }
      if (query.limit != null) {
        result = result.take(query.limit!).toList();
      }
      
      return result;
    });
  }
}
```

### 3. Migration Test

```dart
// test/integration/repository_migration_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Repository Migration Parity', () {
    late TaskRepositoryImpl repo;
    late Database database;

    setUp(() async {
      database = await setupTestDatabase();
      repo = TaskRepositoryImpl(database: database);
      await seedTestData(database);
    });

    test('query with new predicate matches old predicate results', () async {
      // Query with NEW predicate format
      final newQuery = TaskQuery(
        filter: AndPredicate<Task>([
          BoolPredicate<Task>(
            field: TaskFields.isCompleted,
            operator: ComparisonOperator.equals,
            value: false,
          ),
          BoolPredicate<Task>(
            field: TaskFields.isTrashed,
            operator: ComparisonOperator.equals,
            value: false,
          ),
        ]),
      );
      final newResults = await repo.query(newQuery);

      // Query with OLD predicate format
      final oldQuery = TaskQuery(
        predicates: [
          TaskBoolPredicate(
            field: TaskBoolField.isCompleted,
            operator: BoolOperator.equals,
            value: false,
          ),
          TaskBoolPredicate(
            field: TaskBoolField.isTrashed,
            operator: BoolOperator.equals,
            value: false,
          ),
        ],
      );
      final oldResults = await repo.query(oldQuery);

      // Results should be identical
      expect(newResults.length, equals(oldResults.length));
      expect(
        newResults.map((t) => t.id),
        equals(oldResults.map((t) => t.id)),
      );
    });

    // Test all predicate types...
  });
}
```

---

## Step-by-Step Implementation

### Step 1: Add Mapper to TaskRepository

1. Add `UnifiedPredicateMapper<Task>` as constructor dependency
2. Update query building to use new mapper
3. Keep old mapper available for comparison

### Step 2: Run Parity Tests

```bash
flutter test test/integration/ -t "parity"
```

### Step 3: Update ProjectRepository

Apply same changes to ProjectRepository.

### Step 4: Update JournalRepository

Apply same changes to JournalRepository.

### Step 5: Run Full Integration Tests

```bash
flutter test test/integration/
```

### Step 6: Run All Tests

```bash
flutter test
```

---

## ✅ Verification Checklist

- [ ] TaskRepository uses `UnifiedPredicateMapper<Task>`
- [ ] ProjectRepository uses `UnifiedPredicateMapper<Project>`
- [ ] JournalRepository uses `UnifiedPredicateMapper<JournalEntry>`
- [ ] All parity tests pass (old vs new queries)
- [ ] All integration tests pass
- [ ] All unit tests pass
- [ ] Manual testing: app loads and displays data correctly
- [ ] Query performance unchanged (no regression)

---

## 🤖 AI Assistant Instructions

### Context Required

Attach or reference these files:
- `lib/data/repositories/task_repository_impl.dart` (existing)
- `lib/data/repositories/project_repository_impl.dart` (existing)
- `lib/data/repositories/journal_repository_impl.dart` (existing)
- `lib/data/repositories/mappers/unified_predicate_mapper.dart` (from Phase 3)
- `lib/domain/services/filter_evaluator.dart` (from Phase 3)
- `lib/domain/queries/task_query.dart` (from Phase 4)

### Implementation Checklist

1. [ ] Update TaskRepository constructor to accept `UnifiedPredicateMapper<Task>`
2. [ ] Update `query()` method to use `query.effectivePredicate`
3. [ ] Update `watchFiltered()` to use `FilterEvaluator<Task>`
4. [ ] Create integration test for parity verification
5. [ ] Repeat for ProjectRepository
6. [ ] Repeat for JournalRepository
7. [ ] Run full test suite
8. [ ] Verify app runs correctly

### Key Prompts

**Prompt 1 - Update TaskRepository:**
> Update `lib/data/repositories/task_repository_impl.dart` to:
> 1. Add `UnifiedPredicateMapper<Task>` as injectable dependency
> 2. Update `query()` method to use `query.effectivePredicate`
> 3. Use `_predicateMapper.toSql(predicate)` for WHERE clause
> 4. Keep old mapper code commented for easy rollback
>
> Reference the existing implementation to maintain query structure.

**Prompt 2 - Create Integration Test:**
> Create `test/integration/repository_migration_test.dart` that:
> 1. Tests identical results for old vs new predicate format
> 2. Covers bool, date, string predicates
> 3. Tests compound predicates (AND/OR)
> 4. Verifies sorting still works
> 5. Verifies pagination still works

### Watch Out For

| ❌ Avoid | ✅ Instead |
|---------|-----------|
| Removing old mapper immediately | Keep for rollback during migration |
| Changing SQL format | Preserve exact SQL patterns |
| Breaking existing tests | Run tests after each change |
| Missing null handling | Handle `effectivePredicate` being null |
| Changing sorting behavior | Keep sort logic unchanged |
| Modifying row mapping | Entity mapping is separate concern |

### Critical Safety Checks

Before completing this phase:

```dart
// 1. Verify old queries still work
final oldQuery = TaskQuery(predicates: [...]);  // No errors

// 2. Verify new queries work
final newQuery = TaskQuery(filter: ...);  // No errors

// 3. Verify identical results
final oldResults = await repo.query(oldQuery);
final newResults = await repo.query(newQuery);
expect(oldResults, equals(newResults));  // ✅

// 4. Verify raw SQL is similar
// Log SQL and compare manually
```

### Verification Questions

After completion, verify:
1. Does the app launch without errors?
2. Do task lists load correctly?
3. Do filtered views (Today, Upcoming) work?
4. Do all integration tests pass?
5. Is query performance similar? (no slowdown)

---

## Files to Modify

```
lib/data/repositories/
├── task_repository_impl.dart      # MODIFY
├── project_repository_impl.dart   # MODIFY
└── journal_repository_impl.dart   # MODIFY

test/integration/
└── repository_migration_test.dart # NEW
```

---

## Rollback Plan

If issues occur after deployment:

1. **Quick Rollback**: Set feature flag to false
   ```dart
   static const _useNewMapper = false;
   ```

2. **Full Rollback**: Revert Git commits
   ```bash
   git revert HEAD~N  # N = number of commits in this phase
   ```

3. **Verify**: Run full test suite after rollback

---

## Next Phase

→ [Phase 6: Test Migration](./07_PHASE_6_TESTS.md)
