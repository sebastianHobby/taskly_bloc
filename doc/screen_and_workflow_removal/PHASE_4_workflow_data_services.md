# Phase 4: Remove Workflow Data Layer & Services

**Risk Level:** Medium  
**Estimated Time:** 25 minutes  
**Dependencies:** Phase 3 complete

---

## Objective

Remove workflow data repositories, drift tables, and unused repository methods. This completes the workflow feature removal before cleaning up overlapping components.

---

## Files to Delete (2 files)

### 1. Workflow Repository Implementation
```
lib/data/features/workflow/repositories/workflow_repository_impl.dart
```

### 2. Workflow Drift Tables
```
lib/data/infrastructure/drift/features/workflow_tables.drift.dart
```

---

## Files to Modify (5 files)

### 1. Remove Workflow Tables from Database

**File:** `lib/data/infrastructure/drift/drift_database.dart`

**Find and remove:**
```dart
import 'package:taskly_bloc/data/infrastructure/drift/features/workflow_tables.drift.dart';
```

**Find:** (around line 40-50)
```dart
@DriftDatabase(
  tables: [
    // ... other tables
    WorkflowDefinitions,
    WorkflowSteps,
    // ... other tables
  ],
  // ...
)
```

**Remove:**
- `WorkflowDefinitions,`
- `WorkflowSteps,`
- Any other workflow-related table references

### 2. Remove Workflow Repository from DI

**File:** `lib/core/di/dependency_injection.dart`

**Find and remove:** (around line 520-530)
```dart
  ..registerLazySingleton<WorkflowRepositoryContract>(
    () => WorkflowRepositoryImpl(
      db: getIt<AppDatabase>(),
    ),
  )
```

**Also remove import:**
```dart
import 'package:taskly_bloc/domain/interfaces/workflow_repository_contract.dart';
import 'package:taskly_bloc/data/features/workflow/repositories/workflow_repository_impl.dart';
```

### 3. Remove Screen Create Repository Methods

**File:** `lib/data/features/screens/repositories/screen_repository_impl.dart`

**Find and remove methods:**
```dart
  @override
  Stream<List<ScreenDefinition>> watchCustomScreens() {
    // implementation
  }

  @override
  Future<ScreenDefinition> createCustomScreen({
    required ScreenDefinition screen,
  }) async {
    // implementation
  }

  @override
  Future<ScreenDefinition> updateCustomScreen({
    required ScreenDefinition screen,
  }) async {
    // implementation
  }

  @override
  Future<void> deleteCustomScreen({
    required String screenKey,
  }) async {
    // implementation
  }
```

### 4. Remove Screen Create Methods from Contract

**File:** `lib/domain/interfaces/screen_repository_contract.dart`

**Find and remove method signatures:**
```dart
  Stream<List<ScreenDefinition>> watchCustomScreens();
  Future<ScreenDefinition> createCustomScreen({required ScreenDefinition screen});
  Future<ScreenDefinition> updateCustomScreen({required ScreenDefinition screen});
  Future<void> deleteCustomScreen({required String screenKey});
```

### 5. Remove updateLastReviewedAt Methods

**Note:** The `lastReviewedAt` field is NOT in the database schema (confirmed in Phase planning)

**File:** `lib/domain/interfaces/task_repository_contract.dart`

**Find and remove:**
```dart
  Future<void> updateLastReviewedAt({
    required String taskId,
    required DateTime reviewedAt,
  });
```

**File:** `lib/domain/interfaces/project_repository_contract.dart`

**Find and remove:**
```dart
  Future<void> updateLastReviewedAt({
    required String projectId,
    required DateTime reviewedAt,
  });
```

**File:** Implementations in data layer
- `lib/data/features/tasks/repositories/task_repository_impl.dart`
- `lib/data/features/projects/repositories/project_repository_impl.dart`

Remove the corresponding implementations of `updateLastReviewedAt()`.

---

## Test Files to Delete

```bash
rm -rf test/data/features/workflow/
rm test/mocks/*workflow*.dart
```

---

## Validation Steps

### 1. Delete data layer files
```bash
rm -rf lib/data/features/workflow/
rm lib/data/infrastructure/drift/features/workflow_tables.drift.dart
```

### 2. Make modifications to remaining files
- Edit `drift_database.dart`
- Edit `dependency_injection.dart`
- Edit `screen_repository_impl.dart`
- Edit `screen_repository_contract.dart`
- Edit `task_repository_contract.dart`
- Edit `task_repository_impl.dart`
- Edit `project_repository_contract.dart`
- Edit `project_repository_impl.dart`

### 3. Delete test files
```bash
rm -rf test/data/features/workflow/
rm test/mocks/*workflow*.dart
```

### 4. Run code generation
```bash
# Important: Regenerate drift database after removing tables
dart run build_runner build --delete-conflicting-outputs
```

### 5. Run analysis
```bash
flutter analyze
```

### 6. Fix any import errors
Common issues:
- Services still trying to inject WorkflowRepository
- Tests still mocking WorkflowRepository

### 7. Verify no references remain
```bash
grep -ri "WorkflowRepository" lib/ --exclude-dir=.dart_tool
grep -ri "workflow_tables" lib/ --exclude-dir=.dart_tool
grep -ri "WorkflowDefinitions" lib/ --exclude-dir=.dart_tool
grep -ri "updateLastReviewedAt" lib/ --exclude-dir=.dart_tool
grep -ri "watchCustomScreens" lib/ --exclude-dir=.dart_tool
```

---

## Expected Issues and Fixes

### Issue 1: Drift generation errors
**Symptom:** Build runner fails due to missing table imports
**Fix:** Ensure all workflow table imports are removed from `drift_database.dart`

### Issue 2: Test mocks still reference deleted methods
**Location:** `test/mocks/` folder
**Fix:** Remove workflow-related mock implementations

### Issue 3: Fake repositories in tests
**Location:** `test/helpers/` or `test/mocks/`
**Fix:** Remove fake workflow repository implementations

---

## Expected Analyze Output

```
Analyzing taskly_bloc...
No issues found!
```

---
---

## Next Phase

→ **Phase 5:** Remove overlapping and unused components
