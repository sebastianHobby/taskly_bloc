@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_ui/src/feed/taskly_feed_spec.dart';
import 'package:taskly_ui/src/models/value_chip_data.dart';

import 'helpers/test_helpers.dart';

void main() {
  testSafe('feed and section factories produce typed specs', () async {
    var inlineTapped = false;
    var actionTapped = false;

    const value = ValueChipData(
      label: 'Focus',
      color: Colors.blue,
      icon: Icons.bolt,
      semanticLabel: 'Focus value',
    );

    const taskMeta = TasklyEntityMetaData(
      startDateLabel: 'Jan 1',
      deadlineDateLabel: 'Jan 2',
      showOnlyDeadlineDate: false,
      isOverdue: false,
      isDueToday: true,
      priority: 2,
    );

    const taskData = TasklyTaskRowData(
      id: 't1',
      title: 'Task',
      completed: false,
      meta: taskMeta,
      leadingChip: value,
      secondaryChips: <ValueChipData>[value],
      badges: <TasklyBadgeData>[
        TasklyBadgeData(label: 'Today', color: Colors.green),
      ],
      deemphasized: false,
      pinned: true,
      labels: TasklyTaskRowLabels(
        pinnedSemanticLabel: 'Pinned',
        snoozeTooltip: 'Snooze',
        swapTooltip: 'Swap',
      ),
    );

    const projectData = TasklyProjectRowData(
      id: 'p1',
      title: 'Project',
      completed: false,
      pinned: false,
      meta: taskMeta,
      taskCount: 5,
      completedTaskCount: 2,
      dueSoonCount: 1,
      leadingChip: value,
      accentColor: Colors.purple,
      subtitle: 'Sub',
      deemphasized: false,
    );

    const routineData = TasklyRoutineRowData(
      id: 'r1',
      title: 'Routine',
      selected: true,
      completed: false,
      highlightCompleted: false,
      leadingIcon: value,
      dotRow: TasklyRoutineDotRowData(
        completedCount: 2,
        targetCount: 3,
        label: '2/3',
      ),
      scheduleRow: TasklyRoutineScheduleRowData(
        days: <TasklyRoutineScheduleDay>[
          TasklyRoutineScheduleDay(
            label: 'M',
            isToday: true,
            state: TasklyRoutineScheduleDayState.scheduled,
          ),
        ],
      ),
      labels: TasklyRoutineRowLabels(primaryActionLabel: 'Log'),
      badges: <TasklyBadgeData>[
        TasklyBadgeData(label: 'Streak', color: Colors.orange),
      ],
    );

    const valueData = TasklyValueRowData(
      id: 'v1',
      title: 'Value',
      icon: Icons.favorite,
      accentColor: Colors.red,
      priorityLabel: 'P1',
      primaryStatLabel: '7',
      primaryStatSubLabel: 'days',
      metrics: <TasklyValueRowMetric>[
        TasklyValueRowMetric(label: 'Done', value: '10'),
      ],
    );

    final rows = <TasklyRowSpec>[
      const TasklyRowSpec.header(
        key: 'h',
        title: 'Header',
        subtitle: 'Sub',
        trailingLabel: '12',
        depth: 1,
      ),
      const TasklyRowSpec.subheader(key: 'sh', title: 'Subheader', depth: 2),
      const TasklyRowSpec.divider(key: 'd', depth: 3),
      TasklyRowSpec.inlineAction(
        key: 'a',
        label: 'Act',
        onTap: () => inlineTapped = true,
        depth: 1,
      ),
      TasklyRowSpec.task(
        key: 't',
        data: taskData,
        actions: const TasklyTaskRowActions(),
        style: const TasklyTaskRowStyle.bulkSelection(selected: true),
      ),
      TasklyRowSpec.project(
        key: 'p',
        data: projectData,
        actions: const TasklyProjectRowActions(),
        preset: const TasklyProjectRowPreset.bulkSelectionCompact(
          selected: true,
        ),
      ),
      TasklyRowSpec.value(
        key: 'v',
        data: valueData,
        actions: const TasklyValueRowActions(),
        preset: const TasklyValueRowPreset.heroSelection(selected: true),
      ),
      TasklyRowSpec.routine(
        key: 'r',
        data: routineData,
        actions: const TasklyRoutineRowActions(),
        style: const TasklyRoutineRowStyle.planPick(),
      ),
    ];

    const loading = TasklyFeedSpec.loading(message: 'loading');
    final error = TasklyFeedSpec.error(
      message: 'error',
      retryLabel: 'Retry',
      onRetry: () => actionTapped = true,
    );
    final empty = TasklyFeedSpec.empty(
      empty: TasklyEmptyStateSpec(
        icon: Icons.inbox,
        title: 'Nothing',
        description: 'No items',
        actionLabel: 'Create',
        onAction: () => actionTapped = true,
      ),
    );
    final content = TasklyFeedSpec.content(
      sections: <TasklySectionSpec>[
        TasklySectionSpec.standardList(id: 's1', rows: rows),
        TasklySectionSpec.valueDistribution(
          id: 's2',
          title: 'Values',
          totalLabel: '10 total',
          entries: const <TasklyValueDistributionEntry>[
            TasklyValueDistributionEntry(value: value, count: 4),
          ],
        ),
        TasklySectionSpec.scheduledOverdue(
          id: 's3',
          title: 'Overdue',
          countLabel: '2',
          rows: rows,
          showMoreLabelBuilder: (remaining, total) => '$remaining/$total',
          emptyLabel: 'none',
          actionLabel: 'Add',
          actionTooltip: 'add one',
          onActionPressed: () => actionTapped = true,
        ),
        TasklySectionSpec.scheduledDay(
          id: 's4',
          day: DateTime.utc(2026, 2, 22),
          title: 'Today',
          isToday: true,
          rows: rows,
          countLabel: '8',
          emptyLabel: 'empty',
          addLabel: 'Add',
          onAddRequested: () => actionTapped = true,
        ),
      ],
    );

    expect(loading, isA<TasklyFeedLoading>());
    expect(error, isA<TasklyFeedError>());
    expect(empty, isA<TasklyFeedEmpty>());
    expect(content, isA<TasklyFeedContent>());

    final inlineAction = rows[3] as TasklyInlineActionRowSpec;
    inlineAction.onTap();
    expect(inlineTapped, isTrue);

    final scheduledOverdue =
        (content as TasklyFeedContent).sections[2]
            as TasklyScheduledOverdueSectionSpec;
    expect(scheduledOverdue.showMoreLabelBuilder(2, 8), '2/8');
    scheduledOverdue.onActionPressed?.call();

    final scheduledDay = content.sections[3] as TasklyScheduledDaySectionSpec;
    scheduledDay.onAddRequested?.call();
    (error as TasklyFeedError).onRetry?.call();
    (empty as TasklyFeedEmpty).empty.onAction?.call();

    final task = rows[4] as TasklyTaskRowSpec;
    final project = rows[5] as TasklyProjectRowSpec;
    final valueRow = rows[6] as TasklyValueRowSpec;
    final routine = rows[7] as TasklyRoutineRowSpec;

    expect(task.style, isA<TasklyTaskRowStyleBulkSelection>());
    expect(project.preset, isA<TasklyProjectRowPresetBulkSelectionCompact>());
    expect(valueRow.preset, isA<TasklyValueRowPresetHeroSelection>());
    expect(routine.style, isA<TasklyRoutineRowStylePlanPick>());
    expect(
      const TasklyValueDistributionEntry(value: value, count: 1).stableId,
      'focus',
    );
    expect(actionTapped, isTrue);
  });
}
