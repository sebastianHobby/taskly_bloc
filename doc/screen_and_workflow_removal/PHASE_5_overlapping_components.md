# Phase 5: Remove Overlapping & Unused Components

**Risk Level:** Low  
**Estimated Time:** 20 minutes  
**Dependencies:** Phase 4 complete

---

## Objective

Remove components that overlap with the attention system or are no longer used:
- `orphan_tasks` system screen
- `Task.lastReviewedAt` and `Project.lastReviewedAt` fields (not in DB)
- Any remaining workflow-related enums or utilities

---

## Files to Modify (7 files)

### 1. Remove orphan_tasks System Screen

**File:** `lib/domain/screens/catalog/system_screens/system_screen_definitions.dart`

**Find and remove:** (around line 252-268)
```dart
  /// Orphan Tasks screen
  static const orphanTasks = ScreenDefinition(
    id: 'orphan_tasks',
    screenKey: 'orphan_tasks',
    // ... rest of definition
  );
```

**Also remove from:**
- `getByKey()` switch statement: `'orphan_tasks' => orphanTasks,`
- `defaultSortOrders` map: `'orphan_tasks': 7,`

### 2. Remove orphan_tasks Navigation

**File:** `lib/presentation/screens/templates/renderers/issues_summary_section_renderer.dart`

**Find:** (around line 68)
```dart
Routing.toScreenKey(context, 'orphan_tasks');
```

**Replace with:** Remove the navigation link, or comment explaining orphan detection is now via analytics only

### 3. Remove orphan_tasks Icon Mapping

**File:** `lib/presentation/features/navigation/services/navigation_icon_resolver.dart`

**Find and remove:** (around line 66)
```dart
      'orphan_tasks' || 'orphan-tasks' => (
        name: 'Orphan Tasks',
        icon: Icons.help_outline,
      ),
```

### 4. Remove getOrphanTaskCount from Section Data Service

**File:** `lib/domain/screens/runtime/section_data_service.dart`

**Find:** (around line 900)
```dart
_analyticsService.getOrphanTaskCount(),
```

**Remove:** The orphan count Future from the values dashboard Future.wait() call

**Also:** Remove any variables/fields that use this count

### 5. Remove Task.lastReviewedAt Field

**File:** `lib/domain/core/model/task.dart`

**Find and remove:** (around line 62)
```dart
  /// Timestamp of when this task was last reviewed in a workflow.
  final DateTime? lastReviewedAt;
```

**Also remove from:**
- Constructor parameter (line ~29)
- `copyWith()` method parameter and assignment (line ~115-136)
- `==` operator comparison (line ~162)
- `hashCode` calculation (line ~185)

### 6. Remove Project.lastReviewedAt Field

**File:** `lib/domain/core/model/project.dart`

**Find and remove:** Similar to Task, the `lastReviewedAt` field and all references

**Search for:**
```dart
lastReviewedAt
```

**Remove:**
- Field declaration
- Constructor parameter
- copyWith parameter
- Equality comparison
- Hash code inclusion

### 7. Remove getOrphanTaskCount Method

**File:** `lib/domain/services/analytics/analytics_service.dart`

**Find and remove:** (around line 90)
```dart
  /// Returns count of incomplete tasks without a value assigned.
  ///
  /// Counts tasks where:
  /// - `completed == false`
  /// - Has no labels of type `LabelType.value`
  ///
  /// If [excludeWithDeadline] is true, tasks with deadlines are
  /// not counted (they may still appear via urgency handling).
  Future<int> getOrphanTaskCount({bool excludeWithDeadline = false});
```

**File:** `lib/data/features/analytics/services/analytics_service_impl.dart`

**Find and remove:** (around line 335)
```dart
  @override
  Future<int> getOrphanTaskCount({bool excludeWithDeadline = false}) async {
    // ... implementation
  }
```

---

## Test Files to Update

### Remove lastReviewedAt from Test Helpers

**File:** `test/mocks/fake_repositories.dart`

**Find and remove:**
- `updateLastReviewedAt()` method implementations for tasks
- `updateLastReviewedAt()` method implementations for projects
- `lastReviewedAt` field references in fake entities

**Files to check:**
- `test/helpers/`
- `test/mocks/`
- `test/fixtures/`

---

## Validation Steps

### 1. Make modifications to all files
- Edit `system_screen_definitions.dart`
- Edit `issues_summary_section_renderer.dart`
- Edit `navigation_icon_resolver.dart`
- Edit `section_data_service.dart`
- Edit `task.dart`
- Edit `project.dart`
- Edit `analytics_service.dart`
- Edit `analytics_service_impl.dart`

### 2. Update test helpers
- Edit `test/mocks/fake_repositories.dart`
- Remove `lastReviewedAt` from test fixtures

### 3. Run code generation
```bash
# Regenerate freezed models
dart run build_runner build --delete-conflicting-outputs
```

### 4. Run analysis
```bash
flutter analyze
```

### 5. Fix any import errors
Common issues:
- Tests still using `lastReviewedAt`
- UI still referencing orphan_tasks screen
- Analytics still computing orphan counts

### 6. Verify no references remain
```bash
grep -ri "orphan_tasks" lib/ --exclude-dir=.dart_tool
grep -ri "lastReviewedAt" lib/ --exclude-dir=.dart_tool
grep -ri "getOrphanTaskCount" lib/ --exclude-dir=.dart_tool
```

---

## Expected Issues and Fixes

### Issue 1: Task/Project copyWith tests failing
**Symptom:** Tests expect `lastReviewedAt` parameter
**Fix:** Update task/project tests to remove `lastReviewedAt` assertions

### Issue 2: Fake repositories missing method
**Symptom:** Test compile error on `updateLastReviewedAt`
**Fix:** Remove the method from fake implementations

### Issue 3: Values dashboard loading orphan count
**Symptom:** Future.wait() has mismatched futures count
**Fix:** Remove orphan count from the futures list

---

## Expected Analyze Output

```
Analyzing taskly_bloc...
No issues found!
```

---
---

## Next Phase

→ **Phase 6:** Database cleanup
