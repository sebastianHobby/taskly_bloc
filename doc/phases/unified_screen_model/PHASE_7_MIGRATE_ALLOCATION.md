# Phase 7: Migrate Allocation Screens

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each task. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files.
- **Reuse**: Check existing patterns in codebase before creating new ones.
- **Imports**: Use absolute imports (`package:taskly_bloc/...`).

---

## Goal

Migrate Today, Upcoming, and Next Actions (allocation) screens to use `UnifiedScreenPage`. These are the most complex screens with date grouping and allocation logic.

---

## Prerequisites

- Phase 6 complete (project screens migrated)
- Understanding of allocation system and agenda grouping

---

## Task 7.1: Migrate Today Screen

### 7.1.1: Verify Today Definition

```dart
static final today = ScreenDefinition(
  id: 'today',
  screenKey: 'today',
  name: 'Today',
  screenType: ScreenType.list,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  isSystem: true,
  iconName: 'today',
  category: ScreenCategory.workspace,
  sections: [
    Section.agenda(
      dateField: AgendaDateField.deadlineDate,
      grouping: AgendaGrouping.overdueFirst,
      additionalFilter: TaskQuery(
        predicates: [
          // Filter to today and overdue
          TaskPredicate.deadlineBefore(DateTime.now().add(const Duration(days: 1))),
        ],
      ),
      title: 'Due Today',
    ),
  ],
);
```

### 7.1.2: Ensure AgendaSectionContent Handles Grouping

The `_AgendaSectionContent` in `SectionListWidget` should properly render grouped tasks with headers for:
- Overdue
- Today
- Tomorrow (if applicable)

---

## Task 7.2: Migrate Upcoming Screen

### 7.2.1: Verify Upcoming Definition

```dart
static final upcoming = ScreenDefinition(
  id: 'upcoming',
  screenKey: 'upcoming',
  name: 'Upcoming',
  screenType: ScreenType.list,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  isSystem: true,
  iconName: 'upcoming',
  category: ScreenCategory.workspace,
  sections: [
    Section.agenda(
      dateField: AgendaDateField.deadlineDate,
      grouping: AgendaGrouping.byDate,
      additionalFilter: TaskQuery(
        predicates: [
          // Filter to future tasks
          TaskPredicate.deadlineAfter(DateTime.now()),
        ],
      ),
    ),
  ],
);
```

---

## Task 7.3: Migrate Next Actions Screen

### 7.3.1: Verify Next Actions Definition

```dart
static final nextActions = ScreenDefinition(
  id: 'next_actions',
  screenKey: 'next_actions',
  name: 'Next Actions',
  screenType: ScreenType.focus,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  isSystem: true,
  iconName: 'bolt',
  category: ScreenCategory.focus,
  sections: [
    const Section.allocation(
      displayMode: AllocationDisplayMode.pinnedFirst,
      showExcludedWarnings: true,
    ),
  ],
);
```

### 7.3.2: Enhance AllocationSectionContent

The `_AllocationSectionContent` in `SectionListWidget` should handle:
- Pinned tasks (shown first)
- Value groups (if `groupedByValue` mode)
- Allocation reasoning (optional)

```dart
class _AllocationSectionContent extends StatelessWidget {
  const _AllocationSectionContent({
    required this.result,
    required this.onEntityTap,
    required this.onEntityAction,
  });

  final AllocationSectionResult result;
  final EntityTapCallback onEntityTap;
  final EntityActionCallback onEntityAction;

  @override
  Widget build(BuildContext context) {
    final allTasks = [
      ...result.pinnedTasks.map((at) => at.task),
      ...result.allocatedTasks,
    ];

    if (allTasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, size: 48),
            SizedBox(height: 8),
            Text('No tasks allocated'),
            Text('All caught up!'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pinned tasks section
        if (result.pinnedTasks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.push_pin, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Pinned',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          ...result.pinnedTasks.map((allocatedTask) => _TaskTile(
            task: allocatedTask.task,
            onTap: () => onEntityTap(allocatedTask.task.id, 'task'),
            onComplete: () => onEntityAction(
              allocatedTask.task.id,
              'task',
              allocatedTask.task.completed
                  ? EntityActionType.uncomplete
                  : EntityActionType.complete,
              null,
            ),
          )),
        ],

        // Regular allocated tasks
        ...result.allocatedTasks.map((task) => _TaskTile(
          task: task,
          onTap: () => onEntityTap(task.id, 'task'),
          onComplete: () => onEntityAction(
            task.id,
            'task',
            task.completed
                ? EntityActionType.uncomplete
                : EntityActionType.complete,
            null,
          ),
        )),

        // Summary
        if (result.totalAvailable > result.allocatedTasks.length)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${result.allocatedTasks.length} of ${result.totalAvailable} tasks shown',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
```

---

## Task 7.4: Add Pin/Unpin Actions

### 7.4.1: Update EntityActionService

Ensure pin/unpin actions work (may need implementation):

```dart
/// Pin a task for allocation.
Future<void> pinTask(String taskId) async {
  talker.serviceLog('EntityActionService', 'pinTask: $taskId');
  // Implementation depends on how pinning is stored
  // May need to update task or separate pinned_tasks table
  await _taskRepository.pinForAllocation(taskId);
}

/// Unpin a task from allocation.
Future<void> unpinTask(String taskId) async {
  talker.serviceLog('EntityActionService', 'unpinTask: $taskId');
  await _taskRepository.unpinFromAllocation(taskId);
}
```

### 7.4.2: Add Pin Action to Task Tile

For allocation screens, add a pin/unpin action:

```dart
class _AllocationTaskTile extends StatelessWidget {
  // ... existing code ...

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // ... existing content ...
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            ),
            onPressed: () => onAction(
              task.id,
              'task',
              isPinned ? EntityActionType.unpin : EntityActionType.pin,
              null,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Task 7.5: Functional Testing

### Today Screen
- [ ] Shows overdue tasks first
- [ ] Shows tasks due today
- [ ] Date group headers display correctly
- [ ] Completing a task works
- [ ] Task disappears from today after completion

### Upcoming Screen
- [ ] Shows future tasks grouped by date
- [ ] Date headers are correct
- [ ] No overdue tasks shown
- [ ] Completing a task works

### Next Actions Screen
- [ ] Shows allocated tasks
- [ ] Pinned tasks appear first
- [ ] Pin/unpin actions work
- [ ] Completing a task works
- [ ] Summary shows X of Y tasks

---

## Validation Checklist

- [ ] `flutter analyze` returns 0 errors, 0 warnings (ignore test file errors)
- [ ] Today screen uses `UnifiedScreenPage`
- [ ] Upcoming screen uses `UnifiedScreenPage`
- [ ] Next Actions screen uses `UnifiedScreenPage`
- [ ] All allocation features work
- [ ] All date grouping works
- [ ] Pin/unpin actions work

---

## Files Modified

| File | Change |
|------|--------|
| `lib/domain/models/screens/system_screen_definitions.dart` | Verify/update Today, Upcoming, NextActions definitions |
| `lib/presentation/features/screens/widgets/section_list_widget.dart` | Enhance allocation section rendering |
| `lib/domain/services/screens/entity_action_service.dart` | Implement pin/unpin if needed |

---

## Notes

The allocation system (`AllocationOrchestrator`) is already integrated with `SectionDataService`. The `AllocationSectionResult` contains all the data needed for rendering.

---

## Next Phase

Proceed to **Phase 8: User-Created Screen Parity** after functional testing passes.
