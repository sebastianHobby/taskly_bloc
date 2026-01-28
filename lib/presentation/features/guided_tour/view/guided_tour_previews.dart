import 'package:flutter/material.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_models.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

import 'package:taskly_bloc/presentation/features/guided_tour/model/guided_tour_step.dart';

class GuidedTourPreview extends StatelessWidget {
  const GuidedTourPreview({required this.type, super.key});

  final GuidedTourPreviewType type;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      GuidedTourPreviewType.anytimeOverview => _AnytimeOverviewPreview(),
      GuidedTourPreviewType.inboxDetail => _InboxDetailPreview(),
      GuidedTourPreviewType.projectDetail => _ProjectDetailPreview(),
      GuidedTourPreviewType.routines => _RoutinesPreview(),
      GuidedTourPreviewType.planMyDay => _PlanMyDayPreview(),
      GuidedTourPreviewType.myDayExecution => _MyDayPreview(),
      GuidedTourPreviewType.scheduled => _ScheduledPreview(),
      GuidedTourPreviewType.valuesIntro => _ValuesPreview(),
    };
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(tokens.spaceMd),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: tokens.cardShadowBlur,
            offset: tokens.cardShadowOffset,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AnytimeOverviewPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final rows = [
      TasklyRowSpec.project(
        key: 'tour-inbox',
        data: TasklyProjectRowData(
          id: 'inbox',
          title: 'Inbox',
          completed: false,
          pinned: false,
          meta: const TasklyEntityMetaData(),
          taskCount: 3,
        ),
        preset: const TasklyProjectRowPreset.inbox(),
        actions: const TasklyProjectRowActions(),
      ),
      TasklyRowSpec.project(
        key: 'tour-project-career',
        data: TasklyProjectRowData(
          id: 'proj-career',
          title: 'Move career forward',
          completed: false,
          pinned: false,
          meta: const TasklyEntityMetaData(),
          taskCount: 2,
          leadingChip: ValueChipData(
            label: 'Career',
            icon: Icons.work_rounded,
            color: scheme.primary,
            semanticLabel: 'Career',
          ),
        ),
        preset: const TasklyProjectRowPreset.standard(),
        actions: const TasklyProjectRowActions(),
      ),
      TasklyRowSpec.project(
        key: 'tour-project-health',
        data: TasklyProjectRowData(
          id: 'proj-health',
          title: 'Healthy routine',
          completed: false,
          pinned: false,
          meta: const TasklyEntityMetaData(),
          taskCount: 2,
          leadingChip: ValueChipData(
            label: 'Health',
            icon: Icons.favorite_rounded,
            color: scheme.secondary,
            semanticLabel: 'Health',
          ),
        ),
        preset: const TasklyProjectRowPreset.standard(),
        actions: const TasklyProjectRowActions(),
      ),
      TasklyRowSpec.project(
        key: 'tour-project-relationships',
        data: TasklyProjectRowData(
          id: 'proj-relationships',
          title: 'Friends & family',
          completed: false,
          pinned: false,
          meta: const TasklyEntityMetaData(),
          taskCount: 2,
          leadingChip: ValueChipData(
            label: 'Relationships',
            icon: Icons.people_alt_rounded,
            color: scheme.tertiary,
            semanticLabel: 'Relationships',
          ),
        ),
        preset: const TasklyProjectRowPreset.standard(),
        actions: const TasklyProjectRowActions(),
      ),
    ];

    return _PreviewCard(
      child: TasklyFeedRenderer(
        spec: TasklyFeedSpec.content(
          sections: [
            TasklySectionSpec.standardList(
              id: 'tour-anytime',
              rows: rows,
            ),
          ],
        ),
      ),
    );
  }
}

class _InboxDetailPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    TasklyTaskRowData taskRow(String id, String title) {
      return TasklyTaskRowData(
        id: id,
        title: title,
        completed: false,
        meta: const TasklyEntityMetaData(),
      );
    }

    final rows = [
      TasklyRowSpec.header(
        key: 'tour-inbox-header',
        title: 'Inbox',
      ),
      TasklyRowSpec.task(
        key: 'tour-inbox-task-1',
        data: taskRow('t-inbox-1', 'Book dentist appointment'),
        style: const TasklyTaskRowStyle.standard(),
        actions: const TasklyTaskRowActions(),
      ),
      TasklyRowSpec.task(
        key: 'tour-inbox-task-2',
        data: taskRow('t-inbox-2', 'Buy groceries for dinner'),
        style: const TasklyTaskRowStyle.standard(),
        actions: const TasklyTaskRowActions(),
      ),
      TasklyRowSpec.task(
        key: 'tour-inbox-task-3',
        data: taskRow('t-inbox-3', 'Review notes from last meeting'),
        style: const TasklyTaskRowStyle.standard(),
        actions: const TasklyTaskRowActions(),
      ),
    ];

    return _PreviewCard(
      child: TasklyFeedRenderer(
        spec: TasklyFeedSpec.content(
          sections: [
            TasklySectionSpec.standardList(
              id: 'tour-inbox-detail',
              rows: rows,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectDetailPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    TasklyTaskRowData taskRow(String id, String title, ValueChipData chip) {
      return TasklyTaskRowData(
        id: id,
        title: title,
        completed: false,
        meta: const TasklyEntityMetaData(),
        leadingChip: chip,
      );
    }

    final careerChip = ValueChipData(
      label: 'Career',
      icon: Icons.work_rounded,
      color: scheme.primary,
      semanticLabel: 'Career',
    );

    final rows = [
      TasklyRowSpec.header(
        key: 'tour-project-header',
        title: 'Move career forward',
      ),
      TasklyRowSpec.task(
        key: 'tour-project-task-1',
        data: taskRow('t-proj-1', 'Draft cover letter', careerChip),
        style: const TasklyTaskRowStyle.standard(),
        actions: const TasklyTaskRowActions(),
      ),
      TasklyRowSpec.task(
        key: 'tour-project-task-2',
        data: taskRow('t-proj-2', 'Apply to 2 roles', careerChip),
        style: const TasklyTaskRowStyle.standard(),
        actions: const TasklyTaskRowActions(),
      ),
      TasklyRowSpec.task(
        key: 'tour-project-task-3',
        data: taskRow('t-proj-3', 'Update resume', careerChip),
        style: const TasklyTaskRowStyle.standard(),
        actions: const TasklyTaskRowActions(),
      ),
    ];

    return _PreviewCard(
      child: TasklyFeedRenderer(
        spec: TasklyFeedSpec.content(
          sections: [
            TasklySectionSpec.standardList(
              id: 'tour-project-detail',
              rows: rows,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutinesPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final scheduled = TasklyRowSpec.routine(
      key: 'tour-routine-scheduled',
      data: TasklyRoutineRowData(
        id: 'r-scheduled',
        title: 'Morning walk',
        targetLabel: '3x/week',
        remainingLabel: '2 left',
        windowLabel: '4 days left',
        valueChip: ValueChipData(
          label: 'Health',
          icon: Icons.favorite_rounded,
          color: scheme.primary,
          semanticLabel: 'Health',
        ),
        labels: const TasklyRoutineRowLabels(primaryActionLabel: 'Do today'),
      ),
      actions: const TasklyRoutineRowActions(),
    );

    final flexible = TasklyRowSpec.routine(
      key: 'tour-routine-flex',
      data: TasklyRoutineRowData(
        id: 'r-flex',
        title: 'Strength training',
        targetLabel: '2x/week',
        remainingLabel: '1 left',
        windowLabel: '5 days left',
        valueChip: ValueChipData(
          label: 'Health',
          icon: Icons.fitness_center_rounded,
          color: scheme.secondary,
          semanticLabel: 'Health',
        ),
        labels: const TasklyRoutineRowLabels(primaryActionLabel: 'Do today'),
      ),
      actions: const TasklyRoutineRowActions(),
    );

    return _PreviewCard(
      child: TasklyFeedRenderer(
        spec: TasklyFeedSpec.content(
          sections: [
            TasklySectionSpec.standardList(
              id: 'tour-routines',
              rows: [scheduled, flexible],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanMyDayPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    TasklyTaskRowData taskRow(String id, String title, ValueChipData chip) {
      return TasklyTaskRowData(
        id: id,
        title: title,
        completed: false,
        meta: const TasklyEntityMetaData(),
        leadingChip: chip,
        labels: const TasklyTaskRowLabels(
          selectionPillLabel: 'Add',
          selectionPillSelectedLabel: 'Added',
        ),
      );
    }

    final careerChip = ValueChipData(
      label: 'Career',
      icon: Icons.work_rounded,
      color: scheme.primary,
      semanticLabel: 'Career',
    );
    final healthChip = ValueChipData(
      label: 'Health',
      icon: Icons.favorite_rounded,
      color: scheme.secondary,
      semanticLabel: 'Health',
    );

    final rows = [
      TasklyRowSpec.header(
        key: 'tour-plan-values-header',
        title: 'Values',
      ),
      TasklyRowSpec.task(
        key: 'tour-plan-task-career',
        data: taskRow('t1', 'Draft cover letter', careerChip),
        style: const TasklyTaskRowStyle.planPick(selected: true),
        actions: const TasklyTaskRowActions(),
      ),
      TasklyRowSpec.task(
        key: 'tour-plan-task-health',
        data: taskRow('t2', '30-minute walk', healthChip),
        style: const TasklyTaskRowStyle.planPick(selected: true),
        actions: const TasklyTaskRowActions(),
      ),
      TasklyRowSpec.header(
        key: 'tour-plan-routines-header',
        title: 'Routines',
      ),
      TasklyRowSpec.routine(
        key: 'tour-plan-routine',
        data: TasklyRoutineRowData(
          id: 'r1',
          title: 'Morning walk',
          targetLabel: '3x/week',
          remainingLabel: '2 left',
          windowLabel: '4 days left',
          valueChip: healthChip,
          labels: const TasklyRoutineRowLabels(primaryActionLabel: 'Add'),
        ),
        actions: const TasklyRoutineRowActions(),
      ),
      TasklyRowSpec.header(
        key: 'tour-plan-triage-header',
        title: 'Urgent / Planned',
      ),
      TasklyRowSpec.task(
        key: 'tour-plan-task-dentist',
        data: taskRow('t3', 'Schedule dentist', healthChip),
        style: const TasklyTaskRowStyle.planPick(selected: false),
        actions: const TasklyTaskRowActions(),
      ),
    ];

    return _PreviewCard(
      child: TasklyFeedRenderer(
        spec: TasklyFeedSpec.content(
          sections: [
            TasklySectionSpec.standardList(
              id: 'tour-plan',
              rows: rows,
            ),
          ],
        ),
      ),
    );
  }
}

class _MyDayPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    TasklyTaskRowData taskRow(String id, String title, ValueChipData chip) {
      return TasklyTaskRowData(
        id: id,
        title: title,
        completed: false,
        meta: const TasklyEntityMetaData(),
        leadingChip: chip,
      );
    }

    final careerChip = ValueChipData(
      label: 'Career',
      icon: Icons.work_rounded,
      color: scheme.primary,
      semanticLabel: 'Career',
    );
    final healthChip = ValueChipData(
      label: 'Health',
      icon: Icons.favorite_rounded,
      color: scheme.secondary,
      semanticLabel: 'Health',
    );

    final rows = [
      TasklyRowSpec.task(
        key: 'tour-myday-task-career',
        data: taskRow('t1', 'Draft cover letter', careerChip),
        style: const TasklyTaskRowStyle.standard(),
        actions: const TasklyTaskRowActions(),
      ),
      TasklyRowSpec.task(
        key: 'tour-myday-task-walk',
        data: taskRow('t2', '30-minute walk', healthChip),
        style: const TasklyTaskRowStyle.standard(),
        actions: const TasklyTaskRowActions(),
      ),
      TasklyRowSpec.task(
        key: 'tour-myday-task-dentist',
        data: taskRow('t3', 'Schedule dentist', healthChip),
        style: const TasklyTaskRowStyle.standard(),
        actions: const TasklyTaskRowActions(),
      ),
      TasklyRowSpec.routine(
        key: 'tour-myday-routine',
        data: TasklyRoutineRowData(
          id: 'r1',
          title: 'Morning walk',
          targetLabel: '3x/week',
          remainingLabel: '2 left',
          windowLabel: '4 days left',
          valueChip: healthChip,
          labels: const TasklyRoutineRowLabels(primaryActionLabel: 'Do today'),
        ),
        actions: const TasklyRoutineRowActions(),
      ),
    ];

    return _PreviewCard(
      child: TasklyFeedRenderer(
        spec: TasklyFeedSpec.content(
          sections: [
            TasklySectionSpec.standardList(
              id: 'tour-myday',
              rows: rows,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduledPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final healthChip = ValueChipData(
      label: 'Health',
      icon: Icons.favorite_rounded,
      color: scheme.secondary,
      semanticLabel: 'Health',
    );
    final careerChip = ValueChipData(
      label: 'Career',
      icon: Icons.work_rounded,
      color: scheme.primary,
      semanticLabel: 'Career',
    );

    TasklyTaskRowData taskRow(String id, String title, ValueChipData chip) {
      return TasklyTaskRowData(
        id: id,
        title: title,
        completed: false,
        meta: const TasklyEntityMetaData(),
        leadingChip: chip,
      );
    }

    final rows = [
      TasklyRowSpec.subheader(
        key: 'tour-sched-today',
        title: 'Today',
      ),
      TasklyRowSpec.task(
        key: 'tour-sched-dentist',
        data: taskRow('t1', 'Schedule dentist', healthChip),
        style: const TasklyTaskRowStyle.standard(),
        actions: const TasklyTaskRowActions(),
      ),
      TasklyRowSpec.subheader(
        key: 'tour-sched-tomorrow',
        title: 'Tomorrow',
      ),
      TasklyRowSpec.task(
        key: 'tour-sched-cover',
        data: taskRow('t2', 'Draft cover letter', careerChip),
        style: const TasklyTaskRowStyle.standard(),
        actions: const TasklyTaskRowActions(),
      ),
      TasklyRowSpec.subheader(
        key: 'tour-sched-week',
        title: 'This week',
      ),
      TasklyRowSpec.task(
        key: 'tour-sched-apply',
        data: taskRow('t3', 'Apply to 2 roles', careerChip),
        style: const TasklyTaskRowStyle.standard(),
        actions: const TasklyTaskRowActions(),
      ),
    ];

    return _PreviewCard(
      child: TasklyFeedRenderer(
        spec: TasklyFeedSpec.content(
          sections: [
            TasklySectionSpec.standardList(
              id: 'tour-scheduled',
              rows: rows,
            ),
          ],
        ),
      ),
    );
  }
}

class _ValuesPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final rows = [
      TasklyRowSpec.value(
        key: 'tour-value-health',
        data: TasklyValueRowData(
          id: 'v-health',
          title: 'Health',
          icon: Icons.favorite_rounded,
          accentColor: scheme.secondary,
        ),
        preset: const TasklyValueRowPreset.hero(),
        actions: const TasklyValueRowActions(),
      ),
      TasklyRowSpec.value(
        key: 'tour-value-career',
        data: TasklyValueRowData(
          id: 'v-career',
          title: 'Career',
          icon: Icons.work_rounded,
          accentColor: scheme.primary,
        ),
        preset: const TasklyValueRowPreset.hero(),
        actions: const TasklyValueRowActions(),
      ),
      TasklyRowSpec.value(
        key: 'tour-value-relationships',
        data: TasklyValueRowData(
          id: 'v-relationships',
          title: 'Relationships',
          icon: Icons.people_alt_rounded,
          accentColor: scheme.tertiary,
        ),
        preset: const TasklyValueRowPreset.hero(),
        actions: const TasklyValueRowActions(),
      ),
    ];

    return _PreviewCard(
      child: TasklyFeedRenderer(
        spec: TasklyFeedSpec.content(
          sections: [
            TasklySectionSpec.standardList(
              id: 'tour-values',
              rows: rows,
            ),
          ],
        ),
      ),
    );
  }
}
