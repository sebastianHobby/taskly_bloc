# Phase 5: Project Enhancements

> **Status**: Not Started  
> **Effort**: 3-4 days  
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

Enhance project views with deadline warnings and "Next Task" recommendations:
- Generate `projectDeadlineApproaching` warnings in allocation
- Create `ProjectNextTaskResolver` to determine recommended task
- Show "→ Next: [task]" in project list tiles
- Show highlighted recommendation card in project detail
- Add "Start" button to pin task to Focus

---

## Background

Projects are containers for tasks but are NOT first-class citizens in allocation (tasks are allocated, not projects). However, projects need visibility features:

1. **Deadline Warnings**: When a project's deadline approaches (within threshold), warn the user even if individual tasks don't have deadlines
2. **Next Task Recommendation**: Help users know which task to work on next within a project

---

## Files to Create

### 1. `lib/domain/services/allocation/project_next_task_resolver.dart`

```dart
import 'package:taskly/domain/models/project/project.dart';
import 'package:taskly/domain/models/task/task.dart';
import 'package:taskly/domain/models/settings/allocation_settings.dart';

/// Determines the recommended next task for a project.
/// 
/// Resolution priority:
/// 1. Tasks already in Focus (user explicitly prioritized)
/// 2. Urgent tasks (deadline within threshold)
/// 3. Tasks with values (value-aligned)
/// 4. Oldest incomplete task (FIFO fallback)
class ProjectNextTaskResolver {
  const ProjectNextTaskResolver();

  /// Returns the recommended next task for [project], or null if no tasks.
  /// 
  /// [projectTasks] should be incomplete tasks belonging to [project].
  /// [focusTaskIds] are IDs of tasks currently in the Focus list.
  /// [settings] provides urgency thresholds.
  Task? getNextTask({
    required Project project,
    required List<Task> projectTasks,
    required Set<String> focusTaskIds,
    required AllocationSettings settings,
  }) {
    if (projectTasks.isEmpty) return null;

    // Priority 1: Task already in Focus
    final inFocus = projectTasks.where(
      (t) => focusTaskIds.contains(t.id),
    );
    if (inFocus.isNotEmpty) {
      return _selectBest(inFocus.toList(), settings);
    }

    // Priority 2: Urgent tasks (deadline within threshold)
    final urgent = projectTasks.where((t) {
      if (t.deadline == null) return false;
      final daysUntil = t.deadline!.difference(DateTime.now()).inDays;
      return daysUntil <= settings.taskUrgencyThresholdDays;
    });
    if (urgent.isNotEmpty) {
      return _selectMostUrgent(urgent.toList());
    }

    // Priority 3: Tasks with values
    final withValues = projectTasks.where(
      (t) => t.valueId != null && t.valueId!.isNotEmpty,
    );
    if (withValues.isNotEmpty) {
      return _selectBest(withValues.toList(), settings);
    }

    // Priority 4: Oldest task (FIFO)
    return _selectOldest(projectTasks);
  }

  /// Select the "best" task from a list (by deadline, then creation date).
  Task _selectBest(List<Task> tasks, AllocationSettings settings) {
    tasks.sort((a, b) {
      // Tasks with deadlines come first
      if (a.deadline != null && b.deadline == null) return -1;
      if (a.deadline == null && b.deadline != null) return 1;
      if (a.deadline != null && b.deadline != null) {
        return a.deadline!.compareTo(b.deadline!);
      }
      // Fall back to creation date
      return a.createdAt.compareTo(b.createdAt);
    });
    return tasks.first;
  }

  /// Select the task with the nearest deadline.
  Task _selectMostUrgent(List<Task> tasks) {
    tasks.sort((a, b) => a.deadline!.compareTo(b.deadline!));
    return tasks.first;
  }

  /// Select the oldest task by creation date.
  Task _selectOldest(List<Task> tasks) {
    tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return tasks.first;
  }
}
```

---

### 2. `lib/presentation/features/projects/widgets/project_next_task_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:taskly/domain/models/task/task.dart';

/// Card highlighting the recommended next task for a project.
/// 
/// Shown at the top of project detail view when a recommendation exists.
/// Includes a "Start" button to pin the task to Focus.
class ProjectNextTaskCard extends StatelessWidget {
  const ProjectNextTaskCard({
    super.key,
    required this.task,
    required this.onStartTap,
    required this.onTaskTap,
  });

  /// The recommended task.
  final Task task;

  /// Called when "Start" is tapped - should pin task to Focus.
  final VoidCallback onStartTap;

  /// Called when task name is tapped - navigate to task detail.
  final VoidCallback onTaskTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recommended Next Action', // TODO: context.l10n
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: onTaskTap,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (task.deadline != null) ...[
                          const SizedBox(height: 4),
                          _DeadlineChip(
                            deadline: task.deadline!,
                            colorScheme: colorScheme,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: onStartTap,
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Start'), // TODO: context.l10n
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeadlineChip extends StatelessWidget {
  const _DeadlineChip({
    required this.deadline,
    required this.colorScheme,
  });

  final DateTime deadline;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final daysUntil = deadline.difference(DateTime.now()).inDays;
    final isUrgent = daysUntil <= 3;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.schedule,
          size: 14,
          color: isUrgent
              ? colorScheme.error
              : colorScheme.onPrimaryContainer.withOpacity(0.7),
        ),
        const SizedBox(width: 4),
        Text(
          _formatDeadline(daysUntil),
          style: TextStyle(
            fontSize: 12,
            color: isUrgent
                ? colorScheme.error
                : colorScheme.onPrimaryContainer.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  String _formatDeadline(int daysUntil) {
    // TODO: Use context.l10n with pluralization
    if (daysUntil < 0) return 'Overdue';
    if (daysUntil == 0) return 'Due today';
    if (daysUntil == 1) return 'Due tomorrow';
    return 'Due in $daysUntil days';
  }
}
```

---

## Files to Modify

### 3. `lib/domain/services/allocation/allocation_orchestrator.dart`

**Add project deadline warnings:**

The orchestrator should already be generating warnings from Phase 2. Ensure:

```dart
// Generate project deadline warnings
final detector = UrgencyDetector.fromSettings(settings);
final urgentProjects = detector.findUrgentProjects(projects);

for (final project in urgentProjects) {
  final daysUntil = project.deadline!.difference(DateTime.now()).inDays;
  warnings.add(AllocationWarning(
    type: WarningType.projectDeadlineApproaching,
    projectId: project.id,
    message: 'Project "${project.name}" due in $daysUntil days',
  ));
}
```

---

### 4. `lib/presentation/features/projects/view/project_list_view.dart`

**Add "Next Task" subtitle to list tiles:**

```
┌─────────────────────────────────────────┐
│  📁 Website Redesign                    │
│  → Next: Create wireframes              │
│                              Due: Jan 15│
├─────────────────────────────────────────┤
│  📁 Q1 Planning                         │
│  → Next: Review budget proposal         │
│                                         │
└─────────────────────────────────────────┘
```

**Implementation:**

1. For each project, resolve next task using `ProjectNextTaskResolver`
2. Add subtitle to ListTile: "→ Next: [task title]"
3. Only show if `settings.showProjectNextTask == true`
4. Truncate long task titles with ellipsis

```dart
// In list tile builder
ListTile(
  leading: const Icon(Icons.folder),
  title: Text(project.name),
  subtitle: nextTask != null && settings.showProjectNextTask
    ? Text(
        '→ Next: ${nextTask.title}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      )
    : null,
  trailing: project.deadline != null
    ? Text(_formatDate(project.deadline!))
    : null,
  onTap: () => _navigateToProject(project),
);
```

---

### 5. `lib/presentation/features/projects/view/project_detail_view.dart`

**Add recommendation card at top:**

```
┌─────────────────────────────────────────┐
│  💡 Recommended Next Action             │
│  ┌─────────────────────────────────────┐│
│  │ Create wireframes                   ││
│  │ ⏰ Due in 2 days        [▶ Start]   ││
│  └─────────────────────────────────────┘│
├─────────────────────────────────────────┤
│  Tasks (5)                              │
│  ☐ Create wireframes                    │
│  ☐ Design mockups                       │
│  ☐ Review with team                     │
│  ...                                    │
└─────────────────────────────────────────┘
```

**Implementation:**

1. Import `ProjectNextTaskCard` and `ProjectNextTaskResolver`
2. Resolve next task when project loads
3. Show card above task list if:
   - `settings.showProjectNextTask == true`
   - A recommended task exists
4. Handle "Start" button - pin task to Focus

```dart
// In build method
Column(
  children: [
    if (settings.showProjectNextTask && nextTask != null)
      Padding(
        padding: const EdgeInsets.all(16),
        child: ProjectNextTaskCard(
          task: nextTask,
          onStartTap: () => _pinToFocus(nextTask),
          onTaskTap: () => _navigateToTask(nextTask),
        ),
      ),
    Expanded(
      child: TaskListView(
        tasks: projectTasks,
        // ...
      ),
    ),
  ],
);
```

---

### 6. Implement "Pin to Focus" Action

The "Start" button uses the **existing `pinTask()` mechanism** in `AllocationOrchestrator`.

**Implementation:**
```dart
void _pinToFocus(BuildContext context, Task task) async {
  // Use existing EntityActionService or AllocationOrchestrator
  await context.read<EntityActionService>().pinTask(task.id);
  
  // Show confirmation snackbar
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.taskPinnedToFocus(task.title))),
    );
  }
}
```

**Pinned Task Behavior:**
- Pinned tasks are added via `SystemLabelType.pinned` label
- Pinned tasks **count against `dailyLimit`** (appear at top of Focus)
- Pinned tasks have visual distinction (already implemented via pinned label)
- Unpinning is available via existing `unpinTask()` method

---

## Step-by-Step Implementation

### Step 1: Create ProjectNextTaskResolver
Create `lib/domain/services/allocation/project_next_task_resolver.dart`.

### Step 2: Create ProjectNextTaskCard widget
Create `lib/presentation/features/projects/widgets/project_next_task_card.dart`.

### Step 3: Verify project deadline warnings
Ensure orchestrator generates `projectDeadlineApproaching` warnings (from Phase 2).

### Step 4: Update project list view
1. Inject or create resolver
2. For each project, get next task
3. Add subtitle to list tiles

### Step 5: Update project detail view
1. Import card widget and resolver
2. Get next task when project loads
3. Add card above task list
4. Implement "Start" handler

### Step 6: Implement pin-to-focus action
Connect "Start" button to existing Focus/pinning mechanism.

### Step 7: Add localization strings
Add strings for:
- "Recommended Next Action"
- "Start"
- "→ Next: %s"
- Deadline format strings

### Step 8: Run flutter analyze
```bash
flutter analyze
```
Fix all errors and warnings.

---

## Verification Checklist

- [ ] `ProjectNextTaskResolver` created
- [ ] Resolver returns task in Focus first
- [ ] Resolver returns urgent task second
- [ ] Resolver returns value-assigned task third
- [ ] Resolver returns oldest task as fallback
- [ ] Resolver returns null for empty project
- [ ] `ProjectNextTaskCard` widget created
- [ ] Card shows task title and deadline
- [ ] Card shows "Start" button
- [ ] "Start" button pins task to Focus
- [ ] Task name is tappable (navigates to detail)
- [ ] Project list shows "→ Next: [task]" subtitle
- [ ] Subtitle respects `showProjectNextTask` setting
- [ ] Subtitle truncates long task names
- [ ] Project detail shows recommendation card
- [ ] Card only shows when setting enabled
- [ ] Project deadline warnings generated (from Phase 2)
- [ ] All UI strings use `context.l10n`
- [ ] `flutter analyze` passes with 0 errors and 0 warnings

---

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Project with 0 tasks | No "Next" shown, no card |
| All tasks completed | No "Next" shown, no card |
| Task already in Focus | That task is recommended |
| Multiple tasks in Focus | Best one (deadline, then oldest) |
| No deadlines, no values | Oldest task recommended |
| Setting disabled | No subtitle, no card |

---

## UI/UX Notes

### Visual Hierarchy
- Recommendation card uses `primaryContainer` color to stand out
- "Start" button is prominent but not overwhelming
- List subtitle is subtle (smaller, muted color)

### Interaction
- Entire card tappable to view task
- "Start" button clearly actionable
- Snackbar confirms when task pinned

### Performance
- Resolver is synchronous, fast
- Cache resolved task if project view rebuilds frequently
- Don't re-resolve on every frame
