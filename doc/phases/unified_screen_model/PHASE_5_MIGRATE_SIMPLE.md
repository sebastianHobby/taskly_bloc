# Phase 5: Migrate Simple List Screens

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each task. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files.
- **Reuse**: Check existing patterns in codebase before creating new ones.
- **Imports**: Use absolute imports (`package:taskly_bloc/...`).

---

## Goal

Migrate simple list screens (Logbook, Projects list, Labels list) to use `UnifiedScreenPage`.

---

## Prerequisites

- Phase 4 complete (Inbox migrated and tested)

---

## Task 5.1: Migrate Logbook Screen

### 5.1.1: Verify Logbook Definition

The definition in `SystemScreenDefinitions.logbook` should match:

```dart
static final logbook = ScreenDefinition(
  id: 'logbook',
  screenKey: 'logbook',
  name: 'Logbook',
  screenType: ScreenType.list,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  isSystem: true,
  iconName: 'done_all',
  category: ScreenCategory.workspace,
  sections: [
    Section.data(
      config: DataConfig(
        entityType: EntityType.task,
        filter: TaskQuery(
          predicates: [
            const TaskPredicate.isCompleted(true),
          ],
        ),
      ),
      title: 'Completed',
    ),
  ],
);
```

### 5.1.2: Update Route

Ensure the logbook route uses `UnifiedScreenPage`. The route should already be handled by the dynamic screen route from Phase 4.

### 5.1.3: Mark Legacy View Deprecated

Find and mark any legacy Logbook view:

```dart
@Deprecated('Use UnifiedScreenPage with SystemScreenDefinitions.logbook instead')
```

---

## Task 5.2: Migrate Projects List Screen

### 5.2.1: Verify Projects Definition

```dart
static final projects = ScreenDefinition(
  id: 'projects',
  screenKey: 'projects',
  name: 'Projects',
  screenType: ScreenType.list,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  isSystem: true,
  iconName: 'folder',
  category: ScreenCategory.workspace,
  sections: [
    Section.data(
      config: DataConfig(
        entityType: EntityType.project,
      ),
    ),
  ],
);
```

### 5.2.2: Update Route

Ensure the projects list route uses `UnifiedScreenPage`.

### 5.2.3: Mark Legacy View Deprecated

```dart
@Deprecated('Use UnifiedScreenPage with SystemScreenDefinitions.projects instead')
class ProjectListView extends StatelessWidget { ... }
```

---

## Task 5.3: Migrate Labels List Screen

### 5.3.1: Verify Labels Definition

```dart
static final labels = ScreenDefinition(
  id: 'labels',
  screenKey: 'labels',
  name: 'Labels',
  screenType: ScreenType.list,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  isSystem: true,
  iconName: 'label',
  category: ScreenCategory.workspace,
  sections: [
    Section.data(
      config: DataConfig(
        entityType: EntityType.label,
      ),
    ),
  ],
);
```

### 5.3.2: Update Route

Ensure the labels list route uses `UnifiedScreenPage`.

### 5.3.3: Mark Legacy View Deprecated

```dart
@Deprecated('Use UnifiedScreenPage with SystemScreenDefinitions.labels instead')
class LabelListView extends StatelessWidget { ... }
```

---

## Task 5.4: Functional Testing

For each migrated screen:

### Logbook
- [ ] Shows completed tasks
- [ ] Tapping a task navigates to detail
- [ ] Uncompleting a task works

### Projects List
- [ ] Shows all projects
- [ ] Tapping a project navigates to project detail
- [ ] Project colors display correctly

### Labels List
- [ ] Shows all labels
- [ ] Tapping a label navigates to label detail
- [ ] Label colors display correctly

---

## Validation Checklist

- [ ] `flutter analyze` returns 0 errors, 0 warnings (ignore test file errors)
- [ ] All three screens use `UnifiedScreenPage`
- [ ] Legacy views marked `@Deprecated`
- [ ] App compiles and runs
- [ ] All screens function correctly

---

## Files Modified

| File | Change |
|------|--------|
| `lib/presentation/features/tasks/view/logbook_view.dart` | Add @Deprecated (if exists) |
| `lib/presentation/features/projects/view/project_list_view.dart` | Add @Deprecated (if exists) |
| `lib/presentation/features/labels/view/label_list_view.dart` | Add @Deprecated (if exists) |

---

## Next Phase

Proceed to **Phase 6: Migrate Project Screens** after functional testing passes.
