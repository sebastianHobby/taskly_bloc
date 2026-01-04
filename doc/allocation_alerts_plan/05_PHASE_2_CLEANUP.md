# Phase 2: Cleanup

> **Status:** Ready for implementation  
> **Depends on:** All Phase 1 complete and tested  
> **Outputs:** Removed legacy code, updated tests, cleaner codebase

## Overview

Remove legacy code that is no longer needed after My Day migration:
1. Remove `ProblemType.taskUrgentExcluded` and bridge code
2. Delete unused widgets
3. Update all affected tests
4. Clean up orphaned references

## 2a: Remove ProblemType.taskUrgentExcluded

### File: `lib/domain/models/workflow/problem_type.dart`

Remove:
```dart
/// Task is urgent but excluded from Focus allocation
@JsonValue('task_urgent_excluded')
taskUrgentExcluded,
```

After removal, enum becomes:
```dart
enum ProblemType {
  /// Task is past its deadline
  @JsonValue('task_overdue')
  taskOverdue,

  /// Task hasn't been updated recently
  @JsonValue('task_stale')
  taskStale,

  /// Task has no value assigned
  @JsonValue('task_orphan')
  taskOrphan,

  /// Project has no actionable tasks
  @JsonValue('project_idle')
  projectIdle,

  /// Allocation is weighted unevenly across values
  @JsonValue('allocation_unbalanced')
  allocationUnbalanced,

  /// No journal entry for configurable number of days
  @JsonValue('journal_overdue')
  journalOverdue,

  /// Daily tracker not filled for today
  @JsonValue('tracker_missing')
  trackerMissing,
}
```

### File: `lib/domain/services/workflow/problem_detector_service.dart`

Remove the case handling:
```dart
// DELETE this entire case block:
case ProblemType.taskUrgentExcluded:
  // This problem type is handled by the allocation layer,
  // not by deadline-based detection here. The allocation
  // orchestrator determines which tasks are urgent AND excluded,
  // and passes that info through AllocationSectionResult.
  // SupportBlockComputer creates DetectedProblem from that data.
  break;
```

### File: `lib/domain/services/screens/support_block_computer.dart`

Remove the bridge code in `_computeProblemSummary`:

```dart
// DELETE this entire block (lines ~217-232):

// Add excluded urgent tasks as problems (from allocation layer)
// These are determined by the allocation layer, not re-detected here
if (displayConfig.problemsToDetect.contains(
  ProblemType.taskUrgentExcluded,
)) {
  for (final excluded in excludedUrgentTasks) {
    allProblems.add(
      DetectedProblem(
        type: ProblemType.taskUrgentExcluded,
        entityId: excluded.task.id,
        entityType: EntityType.task,
        title: 'Urgent task excluded',
        description:
            '"${excluded.task.name}" is urgent but excluded from Focus',
        suggestedAction: 'Review allocation settings or add value to task',
      ),
    );
  }
}
```

Also update the method signature to remove `excludedUrgentTasks` parameter if no longer needed:

```dart
// Before:
Future<SupportBlockResult> _computeProblemSummary(
  ProblemSummaryBlock block,
  List<Task> tasks,
  List<Project> projects,
  DisplayConfig displayConfig,
  List<ExcludedTask> excludedUrgentTasks,  // REMOVE
) async {

// After:
Future<SupportBlockResult> _computeProblemSummary(
  ProblemSummaryBlock block,
  List<Task> tasks,
  List<Project> projects,
  DisplayConfig displayConfig,
) async {
```

Update all call sites accordingly.

### File: `lib/domain/services/screens/section_data_result.dart`

The `excludedUrgentTasks` field can be removed from `AllocationSectionResult` since we now have `excludedTasks` and `alertEvaluationResult`:

```dart
// REMOVE this field:
/// Urgent tasks that were excluded from allocation (for problem detection).
@Default([]) List<ExcludedTask> excludedUrgentTasks,
```

Update any code that references this field.

## 2b: Delete Unused Widgets

### Check usage before deleting

Run these searches to verify widgets are unused:

```bash
# Check ValuesRequiredGateway usage
grep -r "ValuesRequiredGateway" lib/ --include="*.dart"
grep -r "values_required_gateway" lib/ --include="*.dart"

# Check ReflectorInfoBanner usage
grep -r "ReflectorInfoBanner" lib/ --include="*.dart"
grep -r "reflector_info_banner" lib/ --include="*.dart"

# Check PinnedSection usage (may still be used)
grep -r "PinnedSection" lib/ --include="*.dart"
grep -r "pinned_section" lib/ --include="*.dart"
```

### Files to potentially delete

| File | Condition |
|------|-----------|
| `lib/presentation/features/next_action/widgets/values_required_gateway.dart` | If only used by old Next Actions page |
| `lib/presentation/features/next_action/widgets/reflector_info_banner.dart` | If unused |

**Note:** `SectionWidget` has its own inline `_buildValuesGateway`, so the standalone widget may be unused.

### Folder cleanup

After deleting widgets, check if `next_action/widgets/` folder can be removed or renamed:

```
lib/presentation/features/next_action/
├── next_action.dart           # Barrel export - UPDATE
├── view/
│   └── allocation_settings_page.dart  # KEEP - still used
└── widgets/
    ├── persona_selection_card.dart    # KEEP - used by settings
    └── (deleted files)
```

If only `persona_selection_card.dart` remains in widgets, consider:
1. Moving it to `view/widgets/` subfolder
2. Or keeping structure as-is for future widgets

### Update barrel export

File: `lib/presentation/features/next_action/next_action.dart`

Remove exports of deleted files:
```dart
// Remove if deleted:
export 'widgets/values_required_gateway.dart';
export 'widgets/reflector_info_banner.dart';
```

## 2c: Update Tests

### Search for affected tests

```bash
# Find tests referencing removed items
grep -rn "taskUrgentExcluded" test/ --include="*.dart"
grep -rn "excludedUrgentTasks" test/ --include="*.dart"
grep -rn "'today'" test/ --include="*.dart"
grep -rn "'next_actions'" test/ --include="*.dart"
grep -rn "nextActions" test/ --include="*.dart"
grep -rn "ValuesRequiredGateway" test/ --include="*.dart"
```

### Expected test files to update

| Test File | Changes Needed |
|-----------|----------------|
| `test/domain/models/workflow/problem_type_test.dart` | Remove taskUrgentExcluded cases |
| `test/domain/services/workflow/problem_detector_service_test.dart` | Remove taskUrgentExcluded tests |
| `test/domain/services/screens/support_block_computer_test.dart` | Remove bridge code tests |
| `test/domain/models/screens/system_screen_definitions_test.dart` | Update for my_day |
| `test/presentation/features/navigation/*_test.dart` | Update screen key references |
| `test/fixtures/test_data.dart` | Update any fixtures using old screens |

### Example test updates

#### problem_detector_service_test.dart

```dart
// DELETE test group:
group('taskUrgentExcluded', () {
  // All tests in this group should be removed
});
```

#### system_screen_definitions_test.dart

```dart
// UPDATE:
test('all screens are accessible by key', () {
  for (final screen in SystemScreenDefinitions.all) {
    expect(
      SystemScreenDefinitions.getByKey(screen.screenKey),
      isNotNull,
    );
  }
  
  // Verify removed screens return null
  expect(SystemScreenDefinitions.getByKey('today'), isNull);
  expect(SystemScreenDefinitions.getByKey('next_actions'), isNull);
});

// ADD:
test('myDay replaces today and next_actions', () {
  expect(SystemScreenDefinitions.getByKey('my_day'), isNotNull);
  expect(
    SystemScreenDefinitions.myDay.screenType,
    ScreenType.focus,
  );
});
```

## 2d: Clean Up Orphaned References

### Search for any remaining references

```bash
# Comprehensive search
grep -rn "today" lib/ test/ --include="*.dart" | grep -v "calendar_today" | grep -v "DateTime"
grep -rn "next_action" lib/ test/ --include="*.dart"
grep -rn "nextAction" lib/ test/ --include="*.dart"
grep -rn "taskUrgentExcluded" lib/ test/ --include="*.dart"
```

### Localization cleanup

File: `lib/core/l10n/arb/app_en.arb`

Remove if present:
```json
{
  "todayScreenTitle": "Today",
  "nextActionsTitle": "Next Actions",
  // ... any other removed screen strings
}
```

Keep or repurpose:
```json
{
  "nextActionsTitle": "Next Actions",  // May be used elsewhere, check first
}
```

### Icon resolver cleanup

File: `lib/presentation/features/navigation/services/navigation_icon_resolver.dart`

Check if there are hardcoded icons for removed screens:
```dart
// Remove if present:
'today' => Icons.today,
'next_actions' => Icons.bolt,
```

### Badge service cleanup

File: `lib/presentation/features/navigation/services/navigation_badge_service.dart`

Check for screen-specific badge logic:
```dart
// Remove if present:
case 'today':
case 'next_actions':
```

## Verification

### Run full test suite

```bash
flutter test
```

### Run coverage

```bash
flutter test --coverage
```

### Check for compile errors

```bash
flutter analyze
```

### Manual verification

1. Launch app
2. Navigate to My Day
3. Verify allocation displays correctly
4. Verify alerts appear when expected
5. Verify Outside Focus section works
6. Verify no references to "Today" or "Next Actions" in UI

## AI Implementation Instructions

1. **Order matters:**
   - Remove ProblemType.taskUrgentExcluded first
   - Then update support_block_computer
   - Then delete widgets
   - Then update tests

2. **Search before deleting** - Verify no remaining usages

3. **Run tests after each major change** - Catch cascading failures

4. **Check imports** - Removing files may break imports elsewhere

5. **Update barrel exports** - Don't leave dangling exports

## Checklist

### 2a: ProblemType cleanup
- [ ] Remove `taskUrgentExcluded` from ProblemType enum
- [ ] Remove case in problem_detector_service.dart
- [ ] Remove bridge code in support_block_computer.dart
- [ ] Remove `excludedUrgentTasks` from AllocationSectionResult
- [ ] Update all call sites
- [ ] Run build_runner

### 2b: Widget cleanup
- [ ] Verify ValuesRequiredGateway is unused
- [ ] Delete unused widget files
- [ ] Update barrel exports
- [ ] Consider folder reorganization

### 2c: Test updates
- [ ] Update problem_type_test.dart
- [ ] Update problem_detector_service_test.dart
- [ ] Update support_block_computer_test.dart
- [ ] Update system_screen_definitions_test.dart
- [ ] Update navigation tests
- [ ] Update fixtures

### 2d: Orphan cleanup
- [ ] Search for remaining references
- [ ] Clean up localization
- [ ] Clean up icon resolver
- [ ] Clean up badge service
- [ ] Run full test suite
- [ ] Run flutter analyze
- [ ] Manual verification
