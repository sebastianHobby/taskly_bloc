# Phase 7: Cleanup & Deletion

**Duration**: 0.5 days  
**Risk**: 🟢 Low  
**Dependencies**: Phase 6 (All tests migrated)

---

## Objectives

1. Remove deprecated `predicates` field from query classes
2. Delete old entity-specific predicate files
3. Delete old entity-specific mappers
4. Delete old entity-specific evaluators
5. Update all imports

---

## Prerequisites

Before starting this phase, verify:

- [ ] All production code uses new `filter` field
- [ ] All tests use new `filter` field  
- [ ] No deprecated warnings in production code
- [ ] Full test suite passes

**Run this check:**
```bash
# Search for deprecated usage
grep -r "predicates:" lib/
grep -r "@Deprecated" lib/domain/queries/

# Should find NO usages of old predicates field in production code
```

---

## Files to Delete

### Old Predicate Files

| File | Reason |
|------|--------|
| `lib/domain/predicates/task_predicate.dart` | Replaced by `predicates/` |
| `lib/domain/predicates/project_predicate.dart` | Replaced by `predicates/` |
| `lib/domain/predicates/journal_predicate.dart` | Replaced by `predicates/` |
| `lib/domain/predicates/predicates.dart` | Old barrel export |

### Old Mapper Files

| File | Reason |
|------|--------|
| `lib/data/repositories/mappers/task_predicate_mapper.dart` | Replaced by unified |
| `lib/data/repositories/mappers/project_predicate_mapper.dart` | Replaced by unified |
| `lib/data/repositories/mappers/journal_predicate_mapper.dart` | Replaced by unified |

### Old Evaluator Files

| File | Reason |
|------|--------|
| `lib/domain/services/task_filter_evaluator.dart` | Replaced by generic |
| `lib/domain/services/project_filter_evaluator.dart` | Replaced by generic |

---

## Files to Modify

### Query Classes

Remove deprecated fields:

```dart
// BEFORE: lib/domain/queries/task_query.dart
@freezed
abstract class TaskQuery with _$TaskQuery {
  const factory TaskQuery({
    @TaskPredicateConverter() Predicate<Task>? filter,
    
    @Deprecated('Use filter instead')
    @Default([]) List<TaskPredicate> predicates,  // DELETE THIS
    // ...
  }) = _TaskQuery;
}

// AFTER
@freezed
abstract class TaskQuery with _$TaskQuery {
  const factory TaskQuery({
    @TaskPredicateConverter() Predicate<Task>? filter,
    // predicates field removed
    // ...
  }) = _TaskQuery;
}
```

Also remove:
- `effectivePredicate` getter (simplify to just use `filter`)
- Legacy conversion methods (`_convertLegacyPredicates`, etc.)
- Old predicate imports

---

## Step-by-Step Implementation

### Step 1: Verify No Production Usage

```bash
# Check for any remaining usage of old predicates
grep -r "TaskBoolPredicate\|TaskDatePredicate" lib/
grep -r "ProjectBoolPredicate" lib/
grep -r "JournalDatePredicate" lib/

# Should return empty
```

### Step 2: Update Query Classes

For each query class:

1. Remove `predicates` field
2. Remove old predicate imports
3. Simplify `effectivePredicate` to just return `filter`
4. Remove legacy conversion methods

### Step 3: Delete Old Predicate Files

```bash
rm lib/domain/predicates/task_predicate.dart
rm lib/domain/predicates/project_predicate.dart
rm lib/domain/predicates/journal_predicate.dart
rm lib/domain/predicates/predicates.dart
rmdir lib/domain/predicates  # if empty
```

### Step 4: Delete Old Mapper Files

```bash
rm lib/data/repositories/mappers/task_predicate_mapper.dart
rm lib/data/repositories/mappers/project_predicate_mapper.dart
rm lib/data/repositories/mappers/journal_predicate_mapper.dart
```

### Step 5: Delete Old Evaluator Files

```bash
rm lib/domain/services/task_filter_evaluator.dart
rm lib/domain/services/project_filter_evaluator.dart
```

### Step 6: Update Imports

Fix any broken imports throughout the codebase:

```bash
# Find files with old imports
grep -r "import.*predicates/task_predicate" lib/
grep -r "import.*mappers/task_predicate_mapper" lib/
```

### Step 7: Delete Old Tests

```bash
rm test/domain/predicates/task_predicate_test.dart
rm test/domain/predicates/project_predicate_test.dart
# etc.
```

### Step 8: Run Analyzer

```bash
flutter analyze
```

### Step 9: Run Tests

```bash
flutter test
```

---

## ✅ Verification Checklist

- [ ] No references to old `TaskPredicate`, `ProjectPredicate`, etc.
- [ ] No references to old `TaskPredicateMapper`, etc.
- [ ] No references to old `TaskFilterEvaluator`, etc.
- [ ] All old files deleted
- [ ] All imports updated
- [ ] `flutter analyze` shows no errors
- [ ] `flutter test` passes
- [ ] App runs correctly

---

## 🤖 AI Assistant Instructions

### Context Required

- Run `grep` commands to verify no remaining usages
- List of files to delete (from above)
- Query class files to modify

### Implementation Checklist

1. [ ] Verify no production usage of old predicates
2. [ ] Update `TaskQuery` - remove deprecated field
3. [ ] Update `ProjectQuery` - remove deprecated field
4. [ ] Update `JournalQuery` - remove deprecated field
5. [ ] Delete old predicate files
6. [ ] Delete old mapper files
7. [ ] Delete old evaluator files
8. [ ] Fix broken imports
9. [ ] Delete old test files
10. [ ] Run analyzer and tests

### Key Prompts

**Prompt 1 - Clean TaskQuery:**
> Remove deprecated code from `lib/domain/queries/task_query.dart`:
> 1. Remove `predicates` field
> 2. Remove import of old `TaskPredicate`
> 3. Remove `_convertLegacyPredicates` method
> 4. Remove field mapping constants (`_boolFieldMap`, etc.)
> 5. Simplify `effectivePredicate` or remove if just using `filter`
>
> Keep `filter` field and `TaskPredicateConverter`.

**Prompt 2 - Delete Old Files:**
> Delete these files:
> - `lib/domain/predicates/` (entire directory)
> - `lib/data/repositories/mappers/task_predicate_mapper.dart`
> - `lib/data/repositories/mappers/project_predicate_mapper.dart`
> - `lib/data/repositories/mappers/journal_predicate_mapper.dart`
> - `lib/domain/services/task_filter_evaluator.dart`
> - `lib/domain/services/project_filter_evaluator.dart`

### Watch Out For

| ❌ Avoid | ✅ Instead |
|---------|-----------|
| Deleting files still in use | Verify with grep first |
| Breaking barrel exports | Update/remove old exports |
| Leaving orphan imports | Fix all import errors |
| Forgetting test files | Delete old tests too |

### Deletion Safety

**NEVER delete a file without first:**
1. Searching for imports: `grep -r "import.*filename" lib/ test/`
2. Searching for usages: `grep -r "ClassName" lib/ test/`
3. Running analyzer: `flutter analyze`

### Verification Questions

After completion, verify:
1. Does `flutter analyze` show 0 errors?
2. Does `flutter test` show all tests passing?
3. Does `grep -r "TaskPredicate" lib/` return empty?
4. Does the app launch and function correctly?
5. Is the codebase smaller? (check line count)

---

## Line Count Verification

After cleanup, verify code reduction:

```bash
# Count lines in new predicate system
wc -l lib/domain/queries/predicates/*.dart
wc -l lib/domain/queries/fields/*.dart
wc -l lib/data/repositories/mappers/unified_predicate_mapper.dart
wc -l lib/domain/services/filter_evaluator.dart

# Expected total: ~800-1000 lines
# Original total: ~1800+ lines
# Net reduction: ~800-1000 lines (40-50%)
```

---

## Git Commit Strategy

Make atomic commits for easy rollback:

```bash
# Commit 1: Update query classes
git add lib/domain/queries/
git commit -m "refactor(queries): remove deprecated predicates field"

# Commit 2: Delete old predicates
git add lib/domain/predicates/
git commit -m "chore: delete old entity-specific predicate files"

# Commit 3: Delete old mappers
git add lib/data/repositories/mappers/
git commit -m "chore: delete old entity-specific mapper files"

# Commit 4: Delete old evaluators
git add lib/domain/services/
git commit -m "chore: delete old entity-specific evaluator files"

# Commit 5: Delete old tests
git add test/
git commit -m "chore: delete obsolete predicate tests"
```

---

## Next Phase

→ [Phase 8: Documentation](./09_PHASE_8_DOCUMENTATION.md)
