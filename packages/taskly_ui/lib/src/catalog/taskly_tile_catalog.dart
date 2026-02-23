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
    final routineSelectionActions = TasklyRoutineRowActions(
      onTap: _noop,
      onToggleSelected: _noop,
      onLongPress: _noop,
    );

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
    final valueKnowledge = ValueChipData(
      label: 'Knowledge',
      icon: Icons.psychology_rounded,
      color: scheme.primary,
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
            startDateLabel: 'Sep 12',
            deadlineDateLabel: 'Sep 14',
            priority: 1,
            isDueToday: true,
          ),
          leadingChip: valueCareer,
          pinned: true,
        ),
        style: const TasklyTaskRowStyle.standard(),
        actions: _taskActions,
      ),
      TasklyRowSpec.header(
        key: 'catalog-tasks-compact',
        title: 'Task Â· Compact',
      ),
      TasklyRowSpec.task(
        key: 'catalog-task-compact',
        data: _taskData(
          id: 't-compact-1',
          title: 'Review milestone risks',
          meta: TasklyEntityMetaData(
            deadlineDateLabel: 'Sep 18',
            isDueToday: true,
          ),
          leadingChip: valueFinance,
        ),
        style: const TasklyTaskRowStyle.compact(),
        actions: _taskActions,
      ),
      TasklyRowSpec.header(
        key: 'catalog-tasks-primary-icon-only',
        title: 'Task Â· Primary icon-only',
      ),
      TasklyRowSpec.task(
        key: 'catalog-task-primary-icon-only',
        data: _taskData(
          id: 't-standard-1b',
          title: 'Align team values',
          meta: TasklyEntityMetaData(
            startDateLabel: 'Sep 18',
            deadlineDateLabel: 'Sep 22',
            priority: 3,
          ),
          leadingChip: valueHealth,
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
            deadlineDateLabel: 'Sep 02',
            priority: 2,
            isOverdue: true,
          ),
          leadingChip: valueFinance,
        ),
        style: const TasklyTaskRowStyle.standard(),
        actions: _taskActions,
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
          meta: const TasklyEntityMetaData(),
          leadingChip: valueCareer,
        ),
        style: const TasklyTaskRowStyle.bulkSelection(selected: true),
        actions: _taskActions,
      ),
      TasklyRowSpec.task(
        key: 'catalog-task-bulk-unselected',
        data: _taskData(
          id: 't-bulk-2',
          title: 'Refactor analytics pipeline',
          meta: const TasklyEntityMetaData(),
          leadingChip: valueCareer,
        ),
        style: const TasklyTaskRowStyle.bulkSelection(selected: false),
        actions: _taskActions,
      ),
      TasklyRowSpec.header(
        key: 'catalog-tasks-bulk-compact',
        title: 'Task Ã‚Â· Bulk selection (compact)',
      ),
      TasklyRowSpec.task(
        key: 'catalog-task-bulk-compact-selected',
        data: _taskData(
          id: 't-bulk-c-1',
          title: 'Sync weekly status notes',
          meta: const TasklyEntityMetaData(),
          leadingChip: valueFinance,
        ),
        style: const TasklyTaskRowStyle.bulkSelectionCompact(selected: true),
        actions: _taskActions,
      ),
      TasklyRowSpec.task(
        key: 'catalog-task-bulk-compact-unselected',
        data: _taskData(
          id: 't-bulk-c-2',
          title: 'Update meeting notes',
          meta: const TasklyEntityMetaData(),
          leadingChip: valueFinance,
        ),
        style: const TasklyTaskRowStyle.bulkSelectionCompact(selected: false),
        actions: _taskActions,
      ),

      TasklyRowSpec.header(
        key: 'catalog-tasks-plan-pick',
        title: 'Task Â· Plan pick',
      ),
      TasklyRowSpec.task(
        key: 'catalog-task-plan-pick-selected',
        data: _taskData(
          id: 't-plan-pick-1',
          title: 'Plan daily focus',
          meta: const TasklyEntityMetaData(priority: 2),
          leadingChip: valueHealth,
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
          meta: const TasklyEntityMetaData(priority: 1),
          leadingChip: valueCareer,
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
        key: 'catalog-routines',
        title: 'Routines',
        trailingLabel: 'Rows',
      ),
      TasklyRowSpec.routine(
        key: 'catalog-routine-standard-flex',
        data: TasklyRoutineRowData(
          id: 'r-standard-flex',
          title: 'Mobility flow',
          actionLineText: '1/3 done - 4 days left',
          leadingIcon: valueHealth,
          labels: const TasklyRoutineRowLabels(
            primaryActionLabel: 'Log',
          ),
        ),
        actions: _routineActions,
      ),
      TasklyRowSpec.routine(
        key: 'catalog-routine-standard-daily',
        data: TasklyRoutineRowData(
          id: 'r-standard-daily',
          title: 'Hydration',
          dotRow: const TasklyRoutineDotRowData(
            completedCount: 1,
            targetCount: 3,
            label: 'Daily goal: 3x',
          ),
          leadingIcon: valueHealth,
          labels: const TasklyRoutineRowLabels(
            primaryActionLabel: 'Log',
          ),
        ),
        actions: _routineActions,
      ),
      TasklyRowSpec.routine(
        key: 'catalog-routine-standard-scheduled',
        data: TasklyRoutineRowData(
          id: 'r-standard-scheduled',
          title: 'Morning routine',
          scheduleRow: const TasklyRoutineScheduleRowData(
            days: [
              TasklyRoutineScheduleDay(
                label: 'M',
                isToday: false,
                state: TasklyRoutineScheduleDayState.missedScheduled,
              ),
              TasklyRoutineScheduleDay(
                label: 'W',
                isToday: true,
                state: TasklyRoutineScheduleDayState.loggedScheduled,
              ),
              TasklyRoutineScheduleDay(
                label: 'F',
                isToday: false,
                state: TasklyRoutineScheduleDayState.scheduled,
              ),
              TasklyRoutineScheduleDay(
                label: 'S',
                isToday: false,
                state: TasklyRoutineScheduleDayState.skippedScheduled,
              ),
              TasklyRoutineScheduleDay(
                label: 'T*',
                isToday: false,
                state: TasklyRoutineScheduleDayState.loggedUnscheduled,
              ),
            ],
          ),
          leadingIcon: valueKnowledge,
          labels: const TasklyRoutineRowLabels(
            primaryActionLabel: 'Log',
          ),
        ),
        actions: _routineActions,
      ),
      TasklyRowSpec.routine(
        key: 'catalog-routine-standard-monthly',
        data: TasklyRoutineRowData(
          id: 'r-standard-monthly',
          title: 'Budget review',
          actionLineText: '2/4 this month - Next: 15th',
          leadingIcon: valueFinance,
          labels: const TasklyRoutineRowLabels(
            primaryActionLabel: 'Log',
          ),
        ),
        actions: _routineActions,
      ),
      TasklyRowSpec.header(
        key: 'catalog-routines-plan-pick',
        title: 'Routine · Plan pick',
      ),
      TasklyRowSpec.routine(
        key: 'catalog-routine-plan-pick-selected',
        data: TasklyRoutineRowData(
          id: 'r-plan-pick-1',
          title: 'Stretch session',
          actionLineText: '1/3 done - 4 days left',
          leadingIcon: valueHealth,
          selected: true,
          labels: const TasklyRoutineRowLabels(
            selectionTooltipLabel: 'Add',
            selectionTooltipSelectedLabel: 'Added',
          ),
        ),
        style: const TasklyRoutineRowStyle.planPick(),
        actions: _routineActions,
      ),
      TasklyRowSpec.routine(
        key: 'catalog-routine-plan-pick-unselected',
        data: TasklyRoutineRowData(
          id: 'r-plan-pick-2',
          title: 'Reflect on the week',
          actionLineText: '0/1 done - 2 days left',
          leadingIcon: valueKnowledge,
          selected: false,
          labels: const TasklyRoutineRowLabels(
            selectionTooltipLabel: 'Add',
            selectionTooltipSelectedLabel: 'Added',
          ),
        ),
        style: const TasklyRoutineRowStyle.planPick(),
        actions: _routineActions,
      ),
      TasklyRowSpec.header(
        key: 'catalog-routines-bulk',
        title: 'Routine · Bulk selection',
      ),
      TasklyRowSpec.routine(
        key: 'catalog-routine-bulk-selected',
        data: TasklyRoutineRowData(
          id: 'r-bulk-1',
          title: 'Breathwork session',
          actionLineText: '1/3 done - 4 days left',
          leadingIcon: valueHealth,
          selected: true,
        ),
        style: const TasklyRoutineRowStyle.bulkSelection(),
        actions: routineSelectionActions,
      ),
      TasklyRowSpec.routine(
        key: 'catalog-routine-bulk-unselected',
        data: TasklyRoutineRowData(
          id: 'r-bulk-2',
          title: 'Book review',
          actionLineText: '0/1 done - 6 days left',
          leadingIcon: valueKnowledge,
          selected: false,
        ),
        style: const TasklyRoutineRowStyle.bulkSelection(),
        actions: routineSelectionActions,
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
            startDateLabel: 'Sep 05',
            deadlineDateLabel: 'Oct 01',
            priority: 1,
          ),
          leadingChip: valueCareer,
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
            deadlineDateLabel: 'Aug 21',
            priority: 2,
            isOverdue: true,
          ),
          leadingChip: valueFinance,
          taskCount: 5,
          completedTaskCount: 2,
          dueSoonCount: 1,
        ),
        preset: const TasklyProjectRowPreset.standard(),
        actions: _projectActions,
      ),
      TasklyRowSpec.header(
        key: 'catalog-projects-compact',
        title: 'Project \u00b7 Compact',
      ),
      TasklyRowSpec.project(
        key: 'catalog-project-compact',
        data: _projectData(
          id: 'p-compact-1',
          title: 'Client launch prep',
          meta: TasklyEntityMetaData(
            startDateLabel: 'Sep 20',
          ),
          leadingChip: valueCareer,
          taskCount: 8,
          completedTaskCount: 3,
          dueSoonCount: 1,
        ),
        preset: const TasklyProjectRowPreset.compact(),
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
          meta: const TasklyEntityMetaData(),
          leadingChip: valueCareer,
        ),
        preset: const TasklyProjectRowPreset.bulkSelection(selected: true),
        actions: _projectActions,
      ),
      TasklyRowSpec.project(
        key: 'catalog-project-bulk-unselected',
        data: _projectData(
          id: 'p-bulk-2',
          title: 'Wellness challenge',
          meta: const TasklyEntityMetaData(),
          leadingChip: valueHealth,
        ),
        preset: const TasklyProjectRowPreset.bulkSelection(selected: false),
        actions: _projectActions,
      ),
      TasklyRowSpec.header(
        key: 'catalog-projects-bulk-compact',
        title: 'Project Ã‚Â· Bulk selection (compact)',
      ),
      TasklyRowSpec.project(
        key: 'catalog-project-bulk-compact-selected',
        data: _projectData(
          id: 'p-bulk-c-1',
          title: 'Partner onboarding',
          meta: const TasklyEntityMetaData(),
          leadingChip: valueCareer,
          taskCount: 6,
          completedTaskCount: 2,
        ),
        preset: const TasklyProjectRowPreset.bulkSelectionCompact(
          selected: true,
        ),
        actions: _projectActions,
      ),
      TasklyRowSpec.project(
        key: 'catalog-project-bulk-compact-unselected',
        data: _projectData(
          id: 'p-bulk-c-2',
          title: 'Financial tidy-up',
          meta: const TasklyEntityMetaData(),
          leadingChip: valueFinance,
          taskCount: 4,
          completedTaskCount: 1,
        ),
        preset: const TasklyProjectRowPreset.bulkSelectionCompact(
          selected: false,
        ),
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
        key: 'catalog-values-hero',
        title: 'Value Â· Hero',
      ),
      TasklyRowSpec.value(
        key: 'catalog-value-hero',
        data: TasklyValueRowData(
          id: 'v-hero-1',
          title: 'Health & Energy',
          icon: Icons.favorite_rounded,
          accentColor: scheme.secondary,
          priorityLabel: 'High Priority',
          priorityDotColor: scheme.secondary,
          primaryStatLabel: '24% of completed tasks',
          primaryStatSubLabel: 'reflected this value',
          metrics: const [
            TasklyValueRowMetric(label: 'tasks', value: '12'),
            TasklyValueRowMetric(label: 'projects', value: '3'),
          ],
        ),
        preset: const TasklyValueRowPreset.hero(),
        actions: _valueActions,
      ),
      TasklyRowSpec.value(
        key: 'catalog-value-hero-selected',
        data: TasklyValueRowData(
          id: 'v-hero-2',
          title: 'Learning',
          icon: Icons.psychology_rounded,
          accentColor: scheme.primary,
          priorityLabel: 'Medium Priority',
          priorityDotColor: scheme.tertiary,
          emptyStatTitle: 'No completions yet',
          emptyStatSubtitle: 'Start small - every action counts',
          metrics: const [
            TasklyValueRowMetric(label: 'tasks', value: '4'),
            TasklyValueRowMetric(label: 'projects', value: '1'),
          ],
        ),
        preset: const TasklyValueRowPreset.heroSelection(selected: true),
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
  ValueChipData? leadingChip,
  TasklyTaskRowLabels? labels,
  bool pinned = false,
}) {
  return TasklyTaskRowData(
    id: id,
    title: title,
    completed: false,
    meta: meta,
    leadingChip: leadingChip,
    deemphasized: false,
    checkboxSemanticLabel: 'Toggle completion',
    labels: labels,
    pinned: pinned,
  );
}

TasklyProjectRowData _projectData({
  required String id,
  required String title,
  required TasklyEntityMetaData meta,
  ValueChipData? leadingChip,
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
    leadingChip: leadingChip,
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
  onLongPress: _noop,
);

final TasklyValueRowActions _valueActions = TasklyValueRowActions(
  onTap: _noop,
  onToggleSelected: _noop,
  onLongPress: _noop,
);

final TasklyRoutineRowActions _routineActions = TasklyRoutineRowActions(
  onTap: _noop,
  onPrimaryAction: _noop,
);

void _noop() {}
