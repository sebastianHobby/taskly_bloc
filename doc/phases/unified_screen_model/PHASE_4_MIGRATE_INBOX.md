# Phase 4: Migrate Inbox Screen

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each task. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files.
- **Reuse**: Check existing patterns in codebase before creating new ones.
- **Imports**: Use absolute imports (`package:taskly_bloc/...`).

---

## Goal

Migrate the Inbox screen to use `UnifiedScreenPage`. This is the simplest system screen and serves as the first migration test.

---

## Prerequisites

- Phase 3 complete (router integration done, `SystemScreenDefinitions` exists)
- Existing Inbox route in `router.dart`

---

## Task 4.1: Update Inbox Route

**File**: `lib/core/routing/router.dart`

Find the existing inbox redirect and update the screen route to use `UnifiedScreenPage`:

**Before** (existing redirect):
```dart
GoRoute(
  name: AppRouteName.inbox,
  path: '/inbox',
  redirect: (_, __) => '${AppRoutePath.screenBase}/inbox',
),
```

**After** (keep redirect, but update the target route):

Find where `/screen/inbox` or `screenBase/inbox` is handled (likely in a dynamic screen route) and ensure it uses `UnifiedScreenPage` with the inbox definition.

If the current pattern is `ScreenHostPage`, update it to:

```dart
// In the screen route builder, check for system screens:
builder: (context, state) {
  final screenId = state.pathParameters['screenId']!;
  
  // Check if it's a system screen
  final systemScreen = SystemScreenDefinitions.getById(screenId);
  if (systemScreen != null) {
    return UnifiedScreenPage(definition: systemScreen);
  }
  
  // Otherwise load from repository
  return UnifiedScreenPageById(screenId: screenId);
},
```

---

## Task 4.2: Verify Inbox Definition

**File**: `lib/domain/models/screens/system_screen_definitions.dart`

Verify the inbox definition matches the existing Inbox functionality:

```dart
static final inbox = ScreenDefinition(
  id: 'inbox',
  screenKey: 'inbox',
  name: 'Inbox',
  screenType: ScreenType.list,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  isSystem: true,
  iconName: 'inbox',
  category: ScreenCategory.workspace,
  sections: [
    Section.data(
      config: DataConfig(
        entityType: EntityType.task,
        filter: TaskQuery(
          predicates: [
            const TaskPredicate.hasProject(false),
            const TaskPredicate.isCompleted(false),
          ],
        ),
      ),
    ),
  ],
);
```

Check the existing `InboxView` or related bloc to ensure the filter matches:
- Tasks without a project (`hasProject: false`)
- Incomplete tasks (`isCompleted: false`)

---

## Task 4.3: Mark Legacy InboxView as Deprecated

**File**: `lib/presentation/features/tasks/view/inbox_view.dart` (or similar)

Add deprecation annotation to the legacy view:

```dart
@Deprecated('Use UnifiedScreenPage with SystemScreenDefinitions.inbox instead')
class InboxView extends StatelessWidget {
  // ... existing code
}
```

Do NOT delete yet - keep for rollback capability.

---

## Task 4.4: Functional Testing

Manual testing checklist:

- [ ] Navigate to Inbox via sidebar/navigation
- [ ] Tasks without projects appear
- [ ] Completed tasks do NOT appear
- [ ] Tapping a task navigates to task detail
- [ ] Completing a task works (checkbox)
- [ ] Pull-to-refresh works
- [ ] Empty state shows when no tasks

---

## Validation Checklist

- [ ] `flutter analyze` returns 0 errors, 0 warnings (ignore test file errors)
- [ ] Inbox route uses `UnifiedScreenPage`
- [ ] Inbox definition filter is correct
- [ ] Legacy view marked `@Deprecated`
- [ ] App compiles and runs

---

## Files Modified

| File | Change |
|------|--------|
| `lib/core/routing/router.dart` | Update inbox route to use UnifiedScreenPage |
| `lib/presentation/features/tasks/view/inbox_view.dart` | Add @Deprecated annotation |

---

## Rollback Plan

If issues are found:
1. Revert the router change to use the old `InboxView`
2. The deprecated view is still available

---

## Next Phase

Proceed to **Phase 5: Migrate Simple List Screens** after functional testing passes.
