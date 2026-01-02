# Phase 9: Final Cleanup

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each phase/subphase. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files - do not fix errors for compilation of tests.
- **Forms**: Prefer `flutter_form_builder` fields and extensions where applicable.
- **Reuse**: Check existing patterns in codebase before creating new ones.

---

## Goal

Final cleanup of legacy code, update exports, and comprehensive validation.

**This is the final phase - ensure everything works together.**

---

## Prerequisites

- All previous phases complete (1A through 8)

---

## Task 1: Delete Legacy Files

Delete files that are no longer needed:

### Files to Delete

| File | Reason |
|------|--------|
| `lib/domain/models/screens/view_definition.dart` | Replaced by Section |
| `lib/domain/models/screens/entity_selector.dart` | Replaced by DataConfig |
| `lib/presentation/features/screens/bloc/view_bloc.dart` | Replaced by ScreenBloc |
| `lib/presentation/features/screens/bloc/view_event.dart` | Replaced by screen_event.dart |
| `lib/presentation/features/screens/bloc/view_state.dart` | Replaced by screen_state.dart |

**Command reference:**
```bash
# List files to delete (run these manually)
rm lib/domain/models/screens/view_definition.dart
rm lib/domain/models/screens/entity_selector.dart
rm lib/presentation/features/screens/bloc/view_bloc.dart
rm lib/presentation/features/screens/bloc/view_event.dart
rm lib/presentation/features/screens/bloc/view_state.dart
```

---

## Task 2: Remove ScreenType.collection

Once all migrations are complete, remove the legacy `collection` value:

**File**: `lib/domain/models/screens/screen_definition.dart`

```dart
/// Type of screen
enum ScreenType {
  @JsonValue('list')
  list,
  @JsonValue('dashboard')
  dashboard,
  @JsonValue('focus')
  focus,
  @JsonValue('workflow')
  workflow,
  // REMOVED: collection (was for backward compatibility)
}
```

**File**: `lib/data/drift/features/screen_tables.drift.dart`

Remove `collection` from the enum there as well.

---

## Task 3: Remove Temporary EntityType References

If `EntityType` was kept for backward compatibility in screens, remove those references.

Search for and clean up:
```bash
grep -r "EntityType" lib/
```

Remove from:
- `screen_tables.drift.dart` (if used in screen_definitions table)
- Any mappers that reference it for screens
- Keep only if used elsewhere (tasks, projects)

---

## Task 4: Update Barrel Exports

### Update Screens Model Export

**File**: `lib/domain/models/screens/screens.dart`

Final exports:
```dart
export 'data_config.dart';
export 'display_config.dart';
export 'related_data_config.dart';
export 'screen_category.dart';
export 'screen_definition.dart';
export 'section.dart';
export 'support_block.dart';
export 'trigger_config.dart';
// REMOVED: view_definition.dart
// REMOVED: entity_selector.dart
```

### Update Screens Bloc Export

**File**: `lib/presentation/features/screens/bloc/bloc.dart`

```dart
export 'screen_bloc.dart';
export 'screen_event.dart';
export 'screen_state.dart';
// REMOVED: view_bloc.dart
// REMOVED: view_event.dart
// REMOVED: view_state.dart
```

### Update Queries Export

**File**: `lib/domain/queries/queries.dart`

```dart
export 'label_match_mode.dart';
export 'label_predicate.dart';
export 'label_query.dart';
export 'project_predicate.dart';
export 'project_query.dart';
export 'query_filter.dart';
export 'task_predicate.dart';
export 'task_query.dart';
```

### Update Services Export

**File**: `lib/domain/services/services.dart`

```dart
export 'allocation_orchestrator.dart';
export 'problem_detection_service.dart';
export 'section_data_result.dart';
export 'section_data_service.dart';
export 'support_block_computer.dart';
export 'support_block_result.dart';
// ... other services
```

---

## Task 5: Verify All Imports

Run analysis to find any broken imports:

```bash
flutter analyze
```

Fix any import errors that appear.

Common issues to look for:
- Imports of deleted files
- Imports of renamed classes
- Missing exports in barrel files

---

## Task 6: Update Dependency Injection

**File**: `lib/core/di/injection.dart` (or similar)

Ensure all new services are registered:

```dart
// Register SectionDataService
getIt.registerLazySingleton<SectionDataService>(
  () => SectionDataService(
    taskRepository: getIt(),
    projectRepository: getIt(),
    labelRepository: getIt(),
    allocationOrchestrator: getIt(),
  ),
);

// Register SupportBlockComputer
getIt.registerLazySingleton<SupportBlockComputer>(
  () => SupportBlockComputer(
    problemDetectionService: getIt(),
  ),
);

// Register ScreenBloc factory
getIt.registerFactory<ScreenBloc>(
  () => ScreenBloc(
    screenRepository: getIt(),
    sectionDataService: getIt(),
    supportBlockComputer: getIt(),
    taskRepository: getIt(),
    projectRepository: getIt(),
    labelRepository: getIt(),
  ),
);
```

---

## Task 7: Run Comprehensive Validation

### Step 1: Static Analysis
```bash
flutter analyze
```

Expected: 0 errors, 0 warnings (excluding test files)

### Step 2: Format Check
```bash
dart format --set-exit-if-changed lib/
```

### Step 3: Build Check
```bash
flutter build windows --debug
# or appropriate platform
```

### Step 4: App Launch Test
Launch the app and verify:
- [ ] App starts without crashes
- [ ] System screens load correctly
- [ ] Navigation works
- [ ] Entities display properly

---

## Task 8: Update Documentation

### Update README if needed

Add section about the unified screen architecture.

### Update ARCHITECTURE_DECISIONS.md

Verify all 19 decisions are recorded.

### Clean up Phase Documentation

After successful implementation, consider:
- Moving phase files to an archive folder
- Creating a summary document

---

## Validation Checklist

### Code Cleanup
- [ ] All legacy files deleted
- [ ] `ScreenType.collection` removed
- [ ] `EntityType` removed from screens (if applicable)
- [ ] All barrel exports updated
- [ ] All imports working

### Dependency Injection
- [ ] `SectionDataService` registered
- [ ] `SupportBlockComputer` registered  
- [ ] `ScreenBloc` factory registered
- [ ] All dependencies resolve correctly

### Build & Run
- [ ] `flutter analyze` returns 0 errors, 0 warnings
- [ ] `dart format` passes
- [ ] Build succeeds
- [ ] App launches and runs

### Functional Testing
- [ ] Inbox screen loads
- [ ] Today screen loads
- [ ] Focus screen loads with allocation
- [ ] Projects screen shows projects
- [ ] Navigation between screens works
- [ ] Entity tap navigates to detail

---

## Files Deleted (Summary)

| File | Status |
|------|--------|
| `lib/domain/models/screens/view_definition.dart` | DELETE |
| `lib/domain/models/screens/entity_selector.dart` | DELETE |
| `lib/presentation/features/screens/bloc/view_bloc.dart` | DELETE |
| `lib/presentation/features/screens/bloc/view_event.dart` | DELETE |
| `lib/presentation/features/screens/bloc/view_state.dart` | DELETE |

## Files Modified (Summary)

| File | Change |
|------|--------|
| `lib/domain/models/screens/screens.dart` | Remove deleted exports |
| `lib/domain/models/screens/screen_definition.dart` | Remove collection enum value |
| `lib/presentation/features/screens/bloc/bloc.dart` | Remove deleted exports |
| `lib/core/di/injection.dart` | Add new service registrations |

---

## Implementation Complete! 🎉

After completing this phase, the unified screen architecture is fully implemented:

### Summary of Changes

1. **Query Foundation**: `LabelQuery`, `LabelPredicate`, `LabelMatchMode`
2. **Section Model**: `Section`, `DataConfig`, `RelatedDataConfig`
3. **Screen Definition**: Updated with `sections` and `supportBlocks`
4. **SupportBlock**: Enhanced with `ProblemSummaryBlock`, `EmptyStateBlock`
5. **Data Fetching**: `SectionDataService` for all section types
6. **Unified Bloc**: `ScreenBloc` replaces `ViewBloc`
7. **Entity Navigation**: `EntityNavigator` with default onTap
8. **Widget Updates**: Default navigation in all entity widgets
9. **Workflow Integration**: `WorkflowStep` uses `Section`
10. **System Screens**: 11 screens seeded with new architecture

### Design Decisions Implemented

DR-001 through DR-019 as documented in `ARCHITECTURE_DECISIONS.md`

---

## Post-Implementation Notes

### Test Updates (Future Work)

Tests were ignored during implementation. When updating tests:
1. Update test fixtures with new model structures
2. Update bloc tests for ScreenBloc
3. Add tests for SectionDataService
4. Add integration tests for screen loading

### Performance Considerations

1. Section data is fetched sequentially - consider parallel fetching
2. Support blocks are recomputed on each refresh
3. Large screens may benefit from lazy loading

### Future Enhancements

1. Screen builder UI for user-created screens
2. Section templates library
3. Advanced query builder UI
4. Screen sharing/export functionality
