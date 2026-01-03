# Phase 9: Cleanup Legacy Code

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each task. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files.
- **Reuse**: Check existing patterns in codebase before creating new ones.
- **Imports**: Use absolute imports (`package:taskly_bloc/...`).

---

## Goal

Remove deprecated blocs, pages, and views that are no longer needed after the unified screen model migration.

**⚠️ IMPORTANT**: Only proceed with this phase after ALL screens are confirmed working via the unified path.

---

## Prerequisites

- Phase 8 complete (feature parity confirmed)
- All screens tested and working
- No regressions reported

---

## Pre-Cleanup Verification

Before deleting anything, verify:

- [ ] All navigation paths work
- [ ] All screens render correctly
- [ ] All actions (complete, delete, etc.) work
- [ ] App has been tested on all target platforms
- [ ] No console errors related to screens

---

## Task 9.1: Delete Task List Bloc

**Files to delete**:
- `lib/presentation/features/tasks/bloc/task_list_bloc.dart`
- `lib/presentation/features/tasks/bloc/task_list_bloc.freezed.dart` (generated)

**Estimated LOC removed**: ~172

### Before deleting:
1. Search for usages: `grep -r "TaskListBloc\|TaskOverviewEvent\|TaskOverviewState" lib/`
2. Remove any remaining imports/usages
3. Delete files

---

## Task 9.2: Delete Project List Bloc

**Files to delete**:
- `lib/presentation/features/projects/bloc/project_list_bloc.dart`
- `lib/presentation/features/projects/bloc/project_list_bloc.freezed.dart` (generated)

**Estimated LOC removed**: ~237

### Before deleting:
1. Search for usages: `grep -r "ProjectListBloc\|ProjectOverviewEvent\|ProjectOverviewState" lib/`
2. Remove any remaining imports/usages
3. Delete files

---

## Task 9.3: Delete Legacy View Files

**Files to delete** (verify they are deprecated first):

| File | LOC |
|------|-----|
| `lib/presentation/features/tasks/view/inbox_view.dart` | ~200 |
| `lib/presentation/features/tasks/view/upcoming_view.dart` | ~413 |
| `lib/presentation/features/tasks/view/logbook_view.dart` | ~150 |
| `lib/presentation/features/projects/view/project_list_view.dart` | ~150 |
| `lib/presentation/features/labels/view/label_list_view.dart` | ~150 |

### Before deleting each:
1. Verify file has `@Deprecated` annotation
2. Search for usages
3. Remove imports from barrel exports
4. Delete file

---

## Task 9.4: Delete ScreenHostPage

**File to delete**:
- `lib/presentation/features/screens/view/screen_host_page.dart`

**Estimated LOC removed**: ~281

This was the bridge component that is now replaced by `UnifiedScreenPage`.

### Before deleting:
1. Verify no routes use `ScreenHostPage`
2. Remove from barrel exports
3. Delete file

---

## Task 9.5: Update Barrel Exports

**Files to update**:

### `lib/presentation/features/tasks/view/view.dart` (or similar)
Remove exports for deleted views:
```dart
// Remove these lines:
// export 'inbox_view.dart';
// export 'upcoming_view.dart';
// export 'logbook_view.dart';
```

### `lib/presentation/features/tasks/bloc/bloc.dart`
Remove exports for deleted blocs:
```dart
// Remove:
// export 'task_list_bloc.dart';
```

### `lib/presentation/features/projects/bloc/bloc.dart`
```dart
// Remove:
// export 'project_list_bloc.dart';
```

### `lib/presentation/features/screens/view/screens.dart`
```dart
// Remove:
// export 'screen_host_page.dart';
```

---

## Task 9.6: Clean Up Router Imports

**File**: `lib/core/routing/router.dart`

Remove unused imports:
```dart
// Remove imports for deleted views/pages:
// import 'package:taskly_bloc/presentation/features/tasks/view/inbox_view.dart';
// import 'package:taskly_bloc/presentation/features/screens/view/screen_host_page.dart';
```

---

## Task 9.7: Clean Up DI Registration

**File**: `lib/core/dependency_injection/dependency_injection.dart`

Remove registrations for deleted blocs:
```dart
// Remove if present:
// getIt.registerFactory<TaskListBloc>(...);
// getIt.registerFactory<ProjectListBloc>(...);
```

---

## Task 9.8: Final Analysis

Run full analysis to catch any broken imports:

```bash
flutter analyze
```

Fix all errors related to missing imports or references.

---

## Deletion Summary

| Category | Files Deleted | LOC Removed |
|----------|---------------|-------------|
| Task Blocs | 2 | ~172 |
| Project Blocs | 2 | ~237 |
| Task Views | 3 | ~763 |
| Project Views | 1 | ~150 |
| Label Views | 1 | ~150 |
| Screen Bridge | 1 | ~281 |
| **Total** | **10** | **~1,753** |

---

## Validation Checklist

- [ ] `flutter analyze` returns 0 errors, 0 warnings
- [ ] All deleted files confirmed removed
- [ ] All barrel exports updated
- [ ] All imports cleaned up
- [ ] App compiles successfully
- [ ] App runs without errors
- [ ] All screens still work

---

## Rollback Plan

If issues are discovered:

1. Git revert the deletion commits
2. Re-enable the deprecated code
3. Investigate the issue before attempting cleanup again

**Recommendation**: Make each deletion task a separate commit for easy rollback.

---

## Post-Cleanup

After successful cleanup:

1. Update documentation to reflect new architecture
2. Remove any TODO comments referencing migration
3. Consider updating tests to match new structure (separate task)

---

## Final Metrics

After cleanup, the codebase should have:

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| Screen-related LOC | ~2,200 | ~550 | **-1,650** |
| List Blocs | 5 | 1 | **-4** |
| Screen Page Files | ~8 | 2 | **-6** |
| Rendering Paths | 8+ | 1 | **-7** |

---

## Migration Complete! 🎉

The unified screen model is now fully implemented. All screens (system and user-created) render through a single path via:

1. `ScreenDefinition` → describes the screen
2. `ScreenDataInterpreter` → interprets to reactive data
3. `ScreenBloc` → thin state holder
4. `UnifiedScreenPage` → renders the UI

User-created screens are now first-class citizens with full feature parity.
