# Phase 4: Orphan Task Handling

> **Status**: Not Started  
> **Effort**: 1-2 days  
> **Dependencies**: Phase 2 (Urgency Unification)

---

## AI Implementation Instructions

### General Guidelines
1. **Follow existing patterns** - Match code style, naming conventions, and architecture patterns already in the codebase
2. **Do NOT run or update tests** - If tests break, leave them; they will be fixed separately
3. **Run `flutter analyze` at end of phase** - Fix ALL errors and warnings before marking phase complete
4. **Format code** - Use `dart format` or the dart_format tool for Dart files

### Build Runner
- **Assume `build_runner` is running in watch mode** in background
- **Do NOT run `dart run build_runner build` manually**
- After creating/modifying freezed files, wait for `.freezed.dart` / `.g.dart` files to regenerate
- If generated files don't update after ~45 seconds, there's likely a **syntax error in the source .dart file** - review and fix

### Freezed Syntax (Project Convention)
- Use **`sealed class`** for union types (multiple factory constructors / variants):
  ```dart
  @freezed
  sealed class MyEvent with _$MyEvent {
    const factory MyEvent.started() = _Started;
    const factory MyEvent.loaded(Data data) = _Loaded;
  }
  ```
- Use **`abstract class`** for single-class models with copyWith:
  ```dart
  @freezed
  abstract class MyModel with _$MyModel {
    const factory MyModel({
      required String id,
      required String name,
    }) = _MyModel;
  }
  ```

### Compatibility - IMPORTANT
- **No backwards compatibility** - Remove old fields/code completely
- **No deprecation annotations** - Just delete obsolete code
- **No migration logic** - Clean break, assume fresh state

### Presentation Layer Rules
- Use BLoC pattern for state management
- Widgets should be stateless where possible
- Use `context.l10n` for all user-facing strings
- Follow Material 3 theming conventions

---

## Objective

Show users how many tasks they have without values assigned ("orphan tasks") in the Focus screen footer:
- Add analytics method to count orphan tasks
- Create footer widget showing count
- Add navigation to filtered task list
- Respect `showOrphanTaskCount` setting

---

## Background

"Orphan tasks" are tasks that:
- Have **no value assigned** (valueId is null or empty)
- Are **not included** in value-based allocation (excluded from Focus)

These tasks can easily be forgotten. Rather than including them in Focus (which would defeat the purpose of values-based allocation), we show a subtle count in the footer to remind users they exist.

---

## Files to Create

### 1. `lib/presentation/features/next_action/widgets/orphan_task_footer.dart`

```dart
import 'package:flutter/material.dart';

/// Footer widget showing count of tasks without values.
/// 
/// Displays at the bottom of the Focus screen when there are
/// orphan tasks and the setting is enabled.
/// 
/// Example:
/// ```
/// ┌─────────────────────────────────────────┐
/// │  ⚠ 12 tasks have no value assigned      │
/// │                              [View →]   │
/// └─────────────────────────────────────────┘
/// ```
class OrphanTaskFooter extends StatelessWidget {
  const OrphanTaskFooter({
    super.key,
    required this.orphanCount,
    required this.onViewTap,
  });

  /// Number of tasks without values.
  final int orphanCount;

  /// Called when "View" button is tapped.
  final VoidCallback onViewTap;

  @override
  Widget build(BuildContext context) {
    if (orphanCount == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _buildMessage(context, orphanCount),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              onPressed: onViewTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View', // TODO: Use context.l10n.view
                    style: TextStyle(
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildMessage(BuildContext context, int count) {
    return context.l10n.orphanTaskCount(count);
  }
}
```

**Localization (ARB with ICU plural syntax):**

```json
// app_en.arb
"orphanTaskCount": "{count, plural, =1{1 task has no value assigned} other{{count} tasks have no value assigned}}",
"@orphanTaskCount": {
  "placeholders": {
    "count": { "type": "int" }
  }
}

// app_es.arb  
"orphanTaskCount": "{count, plural, =1{1 tarea no tiene valor asignado} other{{count} tareas no tienen valor asignado}}"
```
```

---

## Files to Modify

### 2. `lib/domain/services/analytics/analytics_service.dart`

**Add method to contract:**

```dart
/// Returns count of incomplete tasks without a value assigned.
/// 
/// If [excludeWithDeadline] is true, tasks with deadlines are
/// not counted (they may still appear via urgency handling).
Future<int> getOrphanTaskCount({bool excludeWithDeadline = false});
```

---

### 3. `lib/data/features/analytics/services/analytics_service_impl.dart`

**Implement the method:**

```dart
@override
Future<int> getOrphanTaskCount({bool excludeWithDeadline = false}) async {
  // Query tasks where:
  // - isCompleted == false
  // - valueId is null OR valueId is empty string
  // - (optionally) deadline is null
  
  final tasks = await _taskRepository.getIncompleteTasks();
  
  return tasks.where((task) {
    final hasNoValue = task.valueId == null || task.valueId!.isEmpty;
    if (!hasNoValue) return false;
    
    if (excludeWithDeadline && task.deadline != null) {
      return false;
    }
    
    return true;
  }).length;
}
```

**Note:** Adjust based on actual repository method names and implementation patterns.

---

### 4. `lib/presentation/features/next_action/view/next_actions_page.dart`

**Add orphan footer to the page:**

1. **Add state for orphan count** in BLoC or local state
2. **Fetch orphan count** when page loads
3. **Show footer** at bottom of page when:
   - `settings.displaySettings.showOrphanTaskCount == true`
   - `orphanCount > 0`
4. **Handle "View" tap** - navigate to task list filtered by no value

**Implementation approach:**

```dart
// In the build method, wrap content with Column or use bottomNavigationBar
Scaffold(
  body: // ... existing Focus content
  bottomSheet: state.config.displaySettings.showOrphanTaskCount && state.orphanCount > 0
    ? OrphanTaskFooter(
        orphanCount: state.orphanCount,
        onViewTap: () => _navigateToOrphanTasks(context),
      )
    : null,
);

void _navigateToOrphanTasks(BuildContext context) {
  // Navigate to task list with filter for tasks without values
  // Use go_router with query parameter
  context.push('/tasks', extra: {'filter': TaskFilter.noValue});
}
```

### Navigation Target: `/tasks` with `noValue` filter

The "View" button navigates to the existing task list page with a filter applied.

**If task list supports filtering via route parameter:**
```dart
context.push('/tasks?filter=noValue');
```

**If task list uses BLoC-based filtering:**
```dart
void _navigateToOrphanTasks(BuildContext context) {
  // Set filter in task list BLoC before navigation
  context.read<TaskListBloc>().add(
    const TaskListEvent.filterChanged(TaskFilter.noValue),
  );
  context.push('/tasks');
}
```

**Add `TaskFilter.noValue` if not exists:**
```dart
enum TaskFilter {
  all,
  today,
  upcoming,
  noValue,  // Tasks without a value assigned
  // ...
}
```

---

### 5. Update BLoC (if needed)

Depending on the existing architecture, you may need to:

**Add to state:**
```dart
final int orphanCount;
```

**Add event:**
```dart
const factory NextActionsEvent.orphanCountRequested() = _OrphanCountRequested;
```

**Handle in BLoC:**
```dart
on<_OrphanCountRequested>((event, emit) async {
  final count = await _analyticsService.getOrphanTaskCount();
  emit(state.copyWith(orphanCount: count));
});
```

---

## Navigation Target

The "View" button should navigate to a filtered task list showing only tasks without values. Options:

### Option A: Query parameter filter
```dart
context.push('/tasks?filter=noValue');
```

### Option B: Dedicated route
```dart
context.push('/tasks/unassigned');
```

### Option C: Existing filter mechanism
If the task list already supports filtering, use that mechanism:
```dart
context.read<TaskListBloc>().add(
  TaskListEvent.filterChanged(TaskFilter.noValue),
);
context.push('/tasks');
```

**Choose based on existing patterns in the codebase.**

---

## Step-by-Step Implementation

### Step 1: Add analytics method
1. Add `getOrphanTaskCount` to analytics service contract
2. Implement in analytics service impl

### Step 2: Create OrphanTaskFooter widget
Create `lib/presentation/features/next_action/widgets/orphan_task_footer.dart`.

### Step 3: Update BLoC state (if needed)
Add `orphanCount` to state and event to fetch it.

### Step 4: Integrate footer into next_actions_page
1. Import OrphanTaskFooter
2. Add to scaffold (bottomSheet or Column)
3. Connect to orphan count from state
4. Implement navigation callback

### Step 5: Implement navigation
Ensure "View" navigates to filtered task list.

### Step 6: Add localization strings
Add strings for footer message and button.

### Step 7: Run flutter analyze
```bash
flutter analyze
```
Fix all errors and warnings.

---

## Verification Checklist

- [ ] `getOrphanTaskCount` method added to analytics service contract
- [ ] `getOrphanTaskCount` implemented in analytics service impl
- [ ] Method correctly counts tasks with no value
- [ ] Method respects `excludeWithDeadline` parameter
- [ ] `OrphanTaskFooter` widget created
- [ ] Footer hides when count is 0
- [ ] Footer shows icon, message, and View button
- [ ] Message uses correct pluralization (1 task / N tasks)
- [ ] Footer integrated into next_actions_page
- [ ] Footer respects `showOrphanTaskCount` setting
- [ ] "View" button navigates to filtered task list
- [ ] Task list shows only tasks without values
- [ ] All UI strings use `context.l10n`
- [ ] `flutter analyze` passes with 0 errors and 0 warnings

---

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| 0 orphan tasks | Footer hidden completely |
| 1 orphan task | Shows "1 task has no value assigned" |
| 100 orphan tasks | Shows "100 tasks have no value assigned" |
| Setting disabled | Footer hidden regardless of count |
| All tasks have values | Footer hidden |
| Task completed | Decrements count (not shown in orphan list) |

---

## UI/UX Notes

### Visual Design
- Footer uses subtle surface color, not attention-grabbing
- Info icon (not warning) - this is informational, not an error
- "View" button is clearly actionable

### Behavior
- Footer should not cover Focus list content
- Consider using `bottomSheet` or fixed position at bottom
- Smooth appearance/disappearance animation preferred
