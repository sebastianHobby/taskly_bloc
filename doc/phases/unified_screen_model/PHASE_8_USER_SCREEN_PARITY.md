# Phase 8: User-Created Screen Parity

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each task. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files.
- **Reuse**: Check existing patterns in codebase before creating new ones.
- **Imports**: Use absolute imports (`package:taskly_bloc/...`).

---

## Goal

Ensure user-created screens (via ScreenBuilder) have full feature parity with system screens. This is the core objective of the unified screen model.

---

## Prerequisites

- Phase 7 complete (all system screens migrated)
- ScreenBuilder/ScreenCreator exists for creating custom screens

---

## Task 8.1: Audit System Screen Features

Create a checklist of all features available in system screens:

### Data Display
- [ ] Task lists with completion checkbox
- [ ] Project lists with color
- [ ] Label lists with color
- [ ] Empty state messages

### Actions
- [ ] Complete/uncomplete task
- [ ] Complete/uncomplete project
- [ ] Delete entity
- [ ] Navigate to detail page
- [ ] Pin/unpin (allocation only)

### Filtering
- [ ] Filter by project
- [ ] Filter by completion status
- [ ] Filter by date range
- [ ] Filter by label
- [ ] Filter by priority

### Grouping
- [ ] Group by date (agenda)
- [ ] Group by project
- [ ] Group by priority
- [ ] Group by value (allocation)

### Sorting
- [ ] Sort by name
- [ ] Sort by date
- [ ] Sort by priority
- [ ] Sort by creation date

### UI Features
- [ ] Pull-to-refresh
- [ ] Section titles
- [ ] Loading states
- [ ] Error states

---

## Task 8.2: Verify ScreenBuilder Can Express All Features

**File**: Review `lib/presentation/features/screens/view/screen_creator_page.dart`

Ensure the ScreenBuilder UI allows users to configure:

### Section Types
- [ ] Data section (task, project, label lists)
- [ ] Allocation section (next actions)
- [ ] Agenda section (date-grouped tasks)

### Filter Options
- [ ] Project filter
- [ ] Completion status filter
- [ ] Date range filter
- [ ] Label filter
- [ ] Priority filter

### Display Options
- [ ] Section title
- [ ] Grouping mode
- [ ] Sort order

---

## Task 8.3: Update SectionConfig If Needed

**File**: `lib/domain/models/screens/data_config.dart` or similar

If any features are missing from `DataConfig`, `Section`, or related models, add them:

```dart
/// Example: If grouping is missing from DataConfig
@freezed
abstract class DataConfig with _$DataConfig {
  const factory DataConfig({
    required EntityType entityType,
    TaskQuery? filter,
    
    // Add if missing:
    GroupingMode? grouping,
    SortConfig? sort,
    @Default(true) bool showCompleted,
  }) = _DataConfig;
}
```

---

## Task 8.4: Update ScreenBuilder UI If Needed

**File**: `lib/presentation/features/screens/view/screen_creator_page.dart`

Add UI controls for any missing configuration options.

Example for adding grouping selection:

```dart
// In the section configuration form:
DropdownButtonFormField<GroupingMode>(
  decoration: const InputDecoration(labelText: 'Group By'),
  value: section.display?.grouping,
  items: GroupingMode.values.map((mode) {
    return DropdownMenuItem(
      value: mode,
      child: Text(mode.displayName),
    );
  }).toList(),
  onChanged: (value) {
    // Update section configuration
  },
),
```

---

## Task 8.5: Test User-Created Screens

Create test screens via ScreenBuilder and verify:

### Test Screen 1: Simple Task List
- Create screen with one Data section
- Filter: incomplete tasks
- Verify: Tasks display, completion works

### Test Screen 2: Project Tasks
- Create screen filtered to specific project
- Verify: Only project tasks appear

### Test Screen 3: Priority Focus
- Create screen filtered to high priority tasks
- Group by project
- Verify: Grouping works

### Test Screen 4: Multi-Section
- Create screen with multiple sections
- Section 1: Today's tasks
- Section 2: Overdue tasks
- Verify: Both sections render correctly

---

## Task 8.6: Ensure Unified Rendering Path

Verify that user-created screens go through exactly the same code path as system screens:

1. User screen stored in database (via ScreenRepository)
2. Loaded by `ScreenBloc` via `loadById`
3. Interpreted by `ScreenDataInterpreter`
4. Rendered by `UnifiedScreenPage`

This should already be the case if Phase 3-7 are complete.

---

## Validation Checklist

- [ ] All system screen features documented
- [ ] ScreenBuilder can configure all features
- [ ] User-created screens render correctly
- [ ] No feature differences between system and user screens
- [ ] All test screens work as expected

---

## Files Modified

| File | Change |
|------|--------|
| `lib/domain/models/screens/data_config.dart` | Add missing config options (if any) |
| `lib/presentation/features/screens/view/screen_creator_page.dart` | Add UI for missing options (if any) |
| `lib/domain/models/screens/display_config.dart` | Add display options (if any) |

---

## Feature Parity Matrix

| Feature | System Screens | User Screens | Status |
|---------|---------------|--------------|--------|
| Task list | ✅ | | |
| Project list | ✅ | | |
| Label list | ✅ | | |
| Complete action | ✅ | | |
| Delete action | ✅ | | |
| Navigate action | ✅ | | |
| Filter by project | ✅ | | |
| Filter by completion | ✅ | | |
| Filter by date | ✅ | | |
| Group by date | ✅ | | |
| Group by project | ✅ | | |
| Allocation section | ✅ | | |
| Pin/unpin | ✅ | | |
| Pull-to-refresh | ✅ | | |
| Section titles | ✅ | | |

Fill in the User Screens column during testing.

---

## Next Phase

Proceed to **Phase 9: Cleanup Legacy Code** after feature parity is confirmed.
