import 'package:flutter/material.dart';

import 'package:taskly_ui/src/feed/taskly_feed_renderer.dart';
import 'package:taskly_ui/src/feed/taskly_feed_spec.dart';
import 'package:taskly_ui/src/models/value_chip_data.dart';

/// Visual catalog for all supported entity tile presets.
class TasklyTileCatalog extends StatelessWidget {
  const TasklyTileCatalog({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final valueCareer = ValueChipData(
      label: 'Career',
      icon: Icons.work_rounded,
      color: scheme.primary,
    );
    final valueHealth = ValueChipData(
      label: 'Health',
      icon: Icons.favorite_rounded,
      color: scheme.secondary,
    );
    final valueFinance = ValueChipData(
      label: 'Finance',
      icon: Icons.savings_rounded,
      color: scheme.tertiary,
    );

    final rows = <TasklyRowSpec>[
      TasklyRowSpec.header(
        key: 'catalog-tasks',
        title: 'Tasks',
        trailingLabel: 'Presets',
      ),
      TasklyRowSpec.header(
        key: 'catalog-tasks-standard',
        title: 'Task Â· Standard',
      ),
      TasklyRowSpec.task(
        key: 'catalog-task-standard-1',
        data: _taskData(
          id: 't-standard-1',
          title: 'Finish onboarding checklist',
          meta: TasklyEntityMetaData(
            primaryValue: valueCareer,
            startDateLabel: 'Sep 12',
            deadlineDateLabel: 'Sep 14',
            priority: 1,
            isDueToday: true,
          ),
          pinned: true,
        ),
        style: const TasklyTaskRowStyle.standard(),
        actions: _taskActions,
      ),
      TasklyRowSpec.header(
        key: 'catalog-tasks-primary-icon-only',
        title: 'Task · Primary icon-only',
      ),
      TasklyRowSpec.task(
        key: 'catalog-task-primary-icon-only',
        data: _taskData(
          id: 't-standard-1b',
          title: 'Align team values',
          meta: TasklyEntityMetaData(
            primaryValue: valueHealth,
            startDateLabel: 'Sep 18',
            deadlineDateLabel: 'Sep 22',
            priority: 3,
          ),
          primaryValueIconOnly: true,
        ),
        style: const TasklyTaskRowStyle.standard(),
        actions: _taskActions,
      ),
      TasklyRowSpec.task(
        key: 'catalog-task-standard-overdue',
        data: _taskData(
          id: 't-standard-2',
          title: 'Submit quarterly summary',
          meta: TasklyEntityMetaData(
            primaryValue: valueFinance,
            deadlineDateLabel: 'Sep 02',
            priority: 2,
            isOverdue: true,
          ),
        ),
        style: const TasklyTaskRowStyle.standard(),
        emphasis: TasklyRowEmphasis.overdue,
        actions: _taskActions,
      ),
      TasklyRowSpec.header(
        key: 'catalog-tasks-pinned',
        title: 'Task · Pinned toggle',
      ),
      TasklyRowSpec.task(
        key: 'catalog-task-pinned-toggle',
        data: _taskData(
          id: 't-pinned-1',
          title: 'Review daily highlights',
          meta: TasklyEntityMetaData(primaryValue: valueHealth),
          labels: const TasklyTaskRowLabels(
            pinLabel: 'Pin',
            pinnedLabel: 'Pinned',
          ),
          pinned: true,
        ),
        style: const TasklyTaskRowStyle.pinnedToggle(),
        actions: _taskActionsWithPin,
      ),
      TasklyRowSpec.header(
        key: 'catalog-tasks-bulk',
        title: 'Task Â· Bulk selection',
      ),
      TasklyRowSpec.task(
        key: 'catalog-task-bulk-selected',
        data: _taskData(
          id: 't-bulk-1',
          title: 'Review hiring pipeline',
          meta: TasklyEntityMetaData(primaryValue: valueCareer),
        ),
        style: const TasklyTaskRowStyle.bulkSelection(selected: true),
        actions: _taskActions,
      ),
      TasklyRowSpec.task(
        key: 'catalog-task-bulk-unselected',
        data: _taskData(
          id: 't-bulk-2',
          title: 'Refactor analytics pipeline',
          meta: TasklyEntityMetaData(primaryValue: valueCareer),
        ),
        style: const TasklyTaskRowStyle.bulkSelection(selected: false),
        actions: _taskActions,
      ),
      TasklyRowSpec.header(
        key: 'catalog-tasks-picker',
        title: 'Task Â· Picker',
      ),
      TasklyRowSpec.task(
        key: 'catalog-task-picker-selected',
        data: _taskData(
          id: 't-picker-1',
          title: 'Morning run',
          meta: TasklyEntityMetaData(primaryValue: valueHealth),
          labels: const TasklyTaskRowLabels(
            selectionPillLabel: 'Add',
            selectionPillSelectedLabel: 'Added',
            snoozeTooltip: 'Snooze',
          ),
        ),
        style: const TasklyTaskRowStyle.picker(selected: true),
        actions: _taskActionsWithSnooze,
      ),
      TasklyRowSpec.task(
        key: 'catalog-task-picker-unselected',
        data: _taskData(
          id: 't-picker-2',
          title: 'Prep client presentation',
          meta: TasklyEntityMetaData(primaryValue: valueCareer),
          labels: const TasklyTaskRowLabels(
            selectionPillLabel: 'Add',
            selectionPillSelectedLabel: 'Added',
            snoozeTooltip: 'Snooze',
          ),
        ),
        style: const TasklyTaskRowStyle.picker(selected: false),
        actions: _taskActionsWithSnooze,
      ),
      TasklyRowSpec.header(
        key: 'catalog-tasks-picker-action',
        title: 'Task Ã‚Â· Picker action',
      ),
      TasklyRowSpec.task(
        key: 'catalog-task-picker-action-selected',
        data: _taskData(
          id: 't-picker-action-1',
          title: 'Evening walk',
          meta: TasklyEntityMetaData(primaryValue: valueHealth),
          labels: const TasklyTaskRowLabels(
            selectionPillLabel: 'Add',
            selectionPillSelectedLabel: 'Added',
            snoozeTooltip: 'Snooze',
          ),
        ),
        style: const TasklyTaskRowStyle.pickerAction(selected: true),
        actions: _taskActionsWithSnooze,
      ),
      TasklyRowSpec.task(
        key: 'catalog-task-picker-action-unselected',
        data: _taskData(
          id: 't-picker-action-2',
          title: 'Review financial plan',
          meta: TasklyEntityMetaData(primaryValue: valueFinance),
          labels: const TasklyTaskRowLabels(
            selectionPillLabel: 'Add',
            selectionPillSelectedLabel: 'Added',
            snoozeTooltip: 'Snooze',
          ),
        ),
        style: const TasklyTaskRowStyle.pickerAction(selected: false),
        actions: _taskActionsWithSnooze,
      ),
      TasklyRowSpec.header(
        key: 'catalog-tasks-plan-pick',
        title: 'Task · Plan pick',
      ),
      TasklyRowSpec.task(
        key: 'catalog-task-plan-pick-selected',
        data: _taskData(
          id: 't-plan-pick-1',
          title: 'Plan daily focus',
          meta: TasklyEntityMetaData(primaryValue: valueHealth, priority: 2),
          labels: const TasklyTaskRowLabels(
            selectionPillLabel: 'Add',
            selectionPillSelectedLabel: 'Added',
            snoozeTooltip: 'Snooze',
          ),
        ),
        style: const TasklyTaskRowStyle.planPick(selected: true),
        actions: _taskActionsWithSnooze,
      ),
      TasklyRowSpec.task(
        key: 'catalog-task-plan-pick-unselected',
        data: _taskData(
          id: 't-plan-pick-2',
          title: 'Reset weekly priorities',
          meta: TasklyEntityMetaData(primaryValue: valueCareer, priority: 1),
          labels: const TasklyTaskRowLabels(
            selectionPillLabel: 'Add',
            selectionPillSelectedLabel: 'Added',
            snoozeTooltip: 'Snooze',
          ),
        ),
        style: const TasklyTaskRowStyle.planPick(selected: false),
        actions: _taskActionsWithSnooze,
      ),
      TasklyRowSpec.header(
        key: 'catalog-projects',
        title: 'Projects',
        trailingLabel: 'Presets',
      ),
      TasklyRowSpec.header(
        key: 'catalog-projects-standard',
        title: 'Project Â· Standard',
      ),
      TasklyRowSpec.project(
        key: 'catalog-project-standard-1',
        data: _projectData(
          id: 'p-standard-1',
          title: 'Design system update',
          meta: TasklyEntityMetaData(
            primaryValue: valueCareer,
            startDateLabel: 'Sep 05',
            deadlineDateLabel: 'Oct 01',
            priority: 1,
          ),
          taskCount: 12,
          completedTaskCount: 6,
          dueSoonCount: 2,
        ),
        preset: const TasklyProjectRowPreset.standard(),
        actions: _projectActions,
      ),
      TasklyRowSpec.project(
        key: 'catalog-project-standard-overdue',
        data: _projectData(
          id: 'p-standard-2',
          title: 'Budget clean-up',
          meta: TasklyEntityMetaData(
            primaryValue: valueFinance,
            deadlineDateLabel: 'Aug 21',
            priority: 2,
            isOverdue: true,
          ),
          taskCount: 5,
          completedTaskCount: 2,
          dueSoonCount: 1,
        ),
        preset: const TasklyProjectRowPreset.standard(),
        emphasis: TasklyRowEmphasis.overdue,
        actions: _projectActions,
      ),
      TasklyRowSpec.header(
        key: 'catalog-projects-inbox',
        title: 'Project \u00b7 Inbox',
      ),
      TasklyRowSpec.project(
        key: 'catalog-project-inbox',
        data: TasklyProjectRowData(
          id: 'p-inbox',
          title: 'Inbox',
          completed: false,
          pinned: false,
          meta: const TasklyEntityMetaData(),
          taskCount: 8,
        ),
        preset: const TasklyProjectRowPreset.inbox(),
        actions: _projectActions,
      ),
      TasklyRowSpec.header(
        key: 'catalog-projects-bulk',
        title: 'Project Â· Bulk selection',
      ),
      TasklyRowSpec.project(
        key: 'catalog-project-bulk-selected',
        data: _projectData(
          id: 'p-bulk-1',
          title: 'Hiring plan',
          meta: TasklyEntityMetaData(primaryValue: valueCareer),
        ),
        preset: const TasklyProjectRowPreset.bulkSelection(selected: true),
        actions: _projectActions,
      ),
      TasklyRowSpec.project(
        key: 'catalog-project-bulk-unselected',
        data: _projectData(
          id: 'p-bulk-2',
          title: 'Wellness challenge',
          meta: TasklyEntityMetaData(primaryValue: valueHealth),
        ),
        preset: const TasklyProjectRowPreset.bulkSelection(selected: false),
        actions: _projectActions,
      ),
      TasklyRowSpec.header(
        key: 'catalog-projects-group',
        title: 'Project Â· Group header',
      ),
      TasklyRowSpec.project(
        key: 'catalog-project-group-expanded',
        data: TasklyProjectRowData(
          id: 'p-group-1',
          title: 'Inbox',
          completed: false,
          pinned: false,
          meta: const TasklyEntityMetaData(),
          groupLeadingIcon: Icons.inbox_outlined,
          groupTrailingLabel: '6',
        ),
        preset: const TasklyProjectRowPreset.groupHeader(expanded: true),
        actions: _projectActions,
      ),
      TasklyRowSpec.project(
        key: 'catalog-project-group-collapsed',
        data: TasklyProjectRowData(
          id: 'p-group-2',
          title: 'Growth Projects',
          completed: false,
          pinned: false,
          meta: const TasklyEntityMetaData(),
          groupLeadingIcon: Icons.folder_outlined,
          groupTrailingLabel: '4',
        ),
        preset: const TasklyProjectRowPreset.groupHeader(expanded: false),
        actions: _projectActions,
      ),
      TasklyRowSpec.header(
        key: 'catalog-values',
        title: 'Values',
        trailingLabel: 'Presets',
      ),
      TasklyRowSpec.header(
        key: 'catalog-values-standard',
        title: 'Value Â· Standard',
      ),
      TasklyRowSpec.value(
        key: 'catalog-value-standard',
        data: TasklyValueRowData(
          id: 'v-standard',
          title: 'Career',
          icon: Icons.work_rounded,
          accentColor: scheme.primary,
        ),
        preset: const TasklyValueRowPreset.standard(),
        actions: _valueActions,
      ),
      TasklyRowSpec.header(
        key: 'catalog-values-bulk',
        title: 'Value Â· Bulk selection',
      ),
      TasklyRowSpec.value(
        key: 'catalog-value-bulk-selected',
        data: TasklyValueRowData(
          id: 'v-bulk-1',
          title: 'Health',
          icon: Icons.favorite_rounded,
          accentColor: scheme.secondary,
        ),
        preset: const TasklyValueRowPreset.bulkSelection(selected: true),
        actions: _valueActions,
      ),
      TasklyRowSpec.value(
        key: 'catalog-value-bulk-unselected',
        data: TasklyValueRowData(
          id: 'v-bulk-2',
          title: 'Finance',
          icon: Icons.savings_rounded,
          accentColor: scheme.tertiary,
        ),
        preset: const TasklyValueRowPreset.bulkSelection(selected: false),
        actions: _valueActions,
      ),
    ];

    return TasklyFeedRenderer(
      spec: TasklyFeedSpec.content(
        sections: [
          TasklySectionSpec.standardList(
            id: 'tile-catalog',
            rows: rows,
          ),
        ],
      ),
    );
  }
}

TasklyTaskRowData _taskData({
  required String id,
  required String title,
  required TasklyEntityMetaData meta,
  TasklyTaskRowLabels? labels,
  bool pinned = false,
  bool primaryValueIconOnly = false,
}) {
  return TasklyTaskRowData(
    id: id,
    title: title,
    completed: false,
    meta: meta,
    leadingChip: meta.primaryValue,
    deemphasized: false,
    checkboxSemanticLabel: 'Toggle completion',
    labels: labels,
    pinned: pinned,
    primaryValueIconOnly: primaryValueIconOnly,
  );
}

TasklyProjectRowData _projectData({
  required String id,
  required String title,
  required TasklyEntityMetaData meta,
  int? taskCount,
  int? completedTaskCount,
  int? dueSoonCount,
}) {
  return TasklyProjectRowData(
    id: id,
    title: title,
    completed: false,
    pinned: false,
    meta: meta,
    leadingChip: meta.primaryValue,
    subtitle: 'Project overview',
    taskCount: taskCount,
    completedTaskCount: completedTaskCount,
    dueSoonCount: dueSoonCount,
  );
}

final TasklyTaskRowActions _taskActions = TasklyTaskRowActions(
  onTap: _noop,
  onToggleCompletion: (_) {},
  onToggleSelected: _noop,
  onLongPress: _noop,
);

final TasklyTaskRowActions _taskActionsWithPin = TasklyTaskRowActions(
  onTap: _noop,
  onToggleCompletion: (_) {},
  onTogglePinned: (_) {},
  onLongPress: _noop,
);
final TasklyTaskRowActions _taskActionsWithSnooze = TasklyTaskRowActions(
  onTap: _noop,
  onToggleCompletion: (_) {},
  onToggleSelected: _noop,
  onLongPress: _noop,
  onSnoozeRequested: _noop,
);

final TasklyProjectRowActions _projectActions = TasklyProjectRowActions(
  onTap: _noop,
  onToggleSelected: _noop,
  onToggleExpanded: _noop,
  onLongPress: _noop,
);

final TasklyValueRowActions _valueActions = TasklyValueRowActions(
  onTap: _noop,
  onToggleSelected: _noop,
  onLongPress: _noop,
);

void _noop() {}
