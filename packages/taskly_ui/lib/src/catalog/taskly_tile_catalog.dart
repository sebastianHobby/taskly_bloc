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
        key: 'catalog-tasks-primary-icon-only',
        title: 'Task · Primary icon-only',
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
        key: 'catalog-tasks-plan-pick',
        title: 'Task · Plan pick',
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
        key: 'catalog-routine-standard',
        data: TasklyRoutineRowData(
          id: 'r-standard-1',
          title: 'Gym session',
          targetLabel: '3×/week',
          remainingLabel: '2 left',
          windowLabel: '4 days left (Mon–Sun)',
          valueChip: valueHealth,
          labels: const TasklyRoutineRowLabels(
            primaryActionLabel: 'Do today',
          ),
        ),
        actions: _routineActions,
      ),
      TasklyRowSpec.routine(
        key: 'catalog-routine-flexible',
        data: TasklyRoutineRowData(
          id: 'r-flex-1',
          title: 'Read non-fiction',
          targetLabel: '3x/week',
          remainingLabel: '2 left',
          windowLabel: '4 days left',
          valueChip: valueKnowledge,
          progress: const TasklyRoutineProgressData(
            completedCount: 1,
            targetCount: 3,
            windowLabel: '4 days left',
          ),
          labels: const TasklyRoutineRowLabels(
            primaryActionLabel: 'Do today',
          ),
        ),
        actions: _routineActions,
      ),
      TasklyRowSpec.routine(
        key: 'catalog-routine-scheduled',
        data: TasklyRoutineRowData(
          id: 'r-scheduled-1',
          title: 'Morning routine',
          targetLabel: 'Scheduled',
          remainingLabel: '2 left',
          windowLabel: 'Mon-Sun',
          valueChip: valueHealth,
          scheduleRow: const TasklyRoutineScheduleRowData(
            days: [
              TasklyRoutineScheduleDay(
                label: 'M',
                isToday: false,
                state: TasklyRoutineScheduleDayState.missedScheduled,
              ),
              TasklyRoutineScheduleDay(
                label: 'T',
                isToday: false,
                state: TasklyRoutineScheduleDayState.none,
              ),
              TasklyRoutineScheduleDay(
                label: 'W',
                isToday: true,
                state: TasklyRoutineScheduleDayState.loggedScheduled,
              ),
              TasklyRoutineScheduleDay(
                label: 'T',
                isToday: false,
                state: TasklyRoutineScheduleDayState.loggedUnscheduled,
              ),
              TasklyRoutineScheduleDay(
                label: 'F',
                isToday: false,
                state: TasklyRoutineScheduleDayState.scheduled,
              ),
              TasklyRoutineScheduleDay(
                label: 'S',
                isToday: false,
                state: TasklyRoutineScheduleDayState.none,
              ),
              TasklyRoutineScheduleDay(
                label: 'S',
                isToday: false,
                state: TasklyRoutineScheduleDayState.scheduled,
              ),
            ],
          ),
          labels: const TasklyRoutineRowLabels(
            primaryActionLabel: 'Do today',
          ),
        ),
        actions: _routineActions,
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
