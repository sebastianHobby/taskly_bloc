import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/plan_my_day_bloc.dart';
import 'package:taskly_bloc/presentation/shared/ui/routine_tile_model_mapper.dart';
import 'package:taskly_bloc/presentation/shared/utils/task_sorting.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';

class PlanMyDayPage extends StatelessWidget {
  const PlanMyDayPage({
    required this.onCloseRequested,
    super.key,
  });

  final VoidCallback onCloseRequested;

  void _handleClose(BuildContext context) {
    onCloseRequested();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PlanMyDayBloc, PlanMyDayState>(
          listenWhen: (previous, current) {
            return previous is PlanMyDayReady &&
                current is PlanMyDayReady &&
                previous.navRequestId != current.navRequestId &&
                current.nav == PlanMyDayNav.closePage;
          },
          listener: (context, state) {
            _handleClose(context);
          },
        ),
      ],
      child: BlocBuilder<PlanMyDayBloc, PlanMyDayState>(
        builder: (context, planState) {
          return BlocBuilder<MyDayGateBloc, MyDayGateState>(
            builder: (context, gateState) {
              return switch (planState) {
                PlanMyDayLoading() => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
                PlanMyDayReady() => Scaffold(
                  appBar: AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _handleClose(context),
                    ),
                    title: Text(context.l10n.myDayPlanTitle),
                    actions: [
                      IconButton(
                        tooltip: context.l10n.settingsTitle,
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () =>
                            Routing.toScreenKey(context, 'settings'),
                      ),
                    ],
                  ),
                  body: SafeArea(
                    bottom: false,
                    child: _PlanWizard(
                      data: planState,
                      gateState: gateState,
                    ),
                  ),
                  bottomNavigationBar: _PlanBottomBar(data: planState),
                ),
              };
            },
          );
        },
      ),
    );
  }
}

class _PlanWizard extends StatelessWidget {
  const _PlanWizard({
    required this.data,
    required this.gateState,
  });

  final PlanMyDayReady data;
  final MyDayGateState gateState;

  @override
  Widget build(BuildContext context) {
    final stepTitle = _stepTitle(context, data.currentStep);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stepTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final step in data.steps)
                    ChoiceChip(
                      label: Text(_stepLabel(context, step)),
                      selected: step == data.currentStep,
                      onSelected: (_) => context.read<PlanMyDayBloc>().add(
                        PlanMyDayStepRequested(step),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: switch (data.currentStep) {
            PlanMyDayStep.valuesStep => _PlanValuesStep(
              data: data,
              gateState: gateState,
            ),
            PlanMyDayStep.routines => _PlanRoutinesStep(data: data),
            PlanMyDayStep.triage => _PlanTriageStep(data: data),
            PlanMyDayStep.summary => _PlanSummaryStep(data: data),
          },
        ),
      ],
    );
  }
}

class _PlanValuesStep extends StatelessWidget {
  const _PlanValuesStep({
    required this.data,
    required this.gateState,
  });

  final PlanMyDayReady data;
  final MyDayGateState gateState;

  @override
  Widget build(BuildContext context) {
    final suggested = data.suggested;
    final l10n = context.l10n;
    final needsSetup =
        data.requiresValueSetup &&
        gateState is MyDayGateLoaded &&
        (gateState as MyDayGateLoaded).needsValuesSetup;

    if (needsSetup) {
      return TasklyFeedRenderer(
        spec: TasklyFeedSpec.empty(
          empty: TasklyEmptyStateSpec(
            icon: Icons.star_border,
            title: l10n.myDayUnlockSuggestionsTitle,
            description: l10n.myDayUnlockSuggestionsBody,
            actionLabel: l10n.myDayStartSetupLabel,
            onAction: () => Routing.toScreenKey(context, 'values'),
          ),
        ),
      );
    }

    if (suggested.isEmpty) {
      return TasklyFeedRenderer(
        spec: TasklyFeedSpec.empty(
          empty: TasklyEmptyStateSpec(
            icon: Icons.explore_outlined,
            title: l10n.myDayPlanValuesEmptyTitle,
            description: l10n.myDayPlanValuesEmptyBody,
          ),
        ),
      );
    }

    final rows = _buildTaskRows(
      context,
      tasks: suggested,
      selectedTaskIds: data.selectedTaskIds,
      enableSnooze: true,
      dayKeyUtc: data.dayKeyUtc,
      style: TasklyTaskRowStyle.planPick,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        TasklyFeedRenderer.buildSection(
          TasklySectionSpec.standardList(
            id: 'plan-values',
            rows: rows,
          ),
        ),
      ],
    );
  }
}

class _PlanRoutinesStep extends StatelessWidget {
  const _PlanRoutinesStep({required this.data});

  final PlanMyDayReady data;

  @override
  Widget build(BuildContext context) {
    final routines = data.routines;
    final l10n = context.l10n;

    if (routines.isEmpty) {
      return TasklyFeedRenderer(
        spec: TasklyFeedSpec.empty(
          empty: TasklyEmptyStateSpec(
            icon: Icons.self_improvement_outlined,
            title: l10n.routineEmptyTitle,
            description: l10n.routineEmptyDescription,
          ),
        ),
      );
    }

    final rows = routines
        .map(
          (item) => _buildRoutineRow(
            context,
            data: data,
            item: item,
            primaryActionLabel: l10n.routinePrimaryActionLabel,
          ),
        )
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        TasklyFeedRenderer.buildSection(
          TasklySectionSpec.standardList(
            id: 'plan-routines',
            rows: rows,
          ),
        ),
      ],
    );
  }
}

class _PlanTriageStep extends StatelessWidget {
  const _PlanTriageStep({required this.data});

  final PlanMyDayReady data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dayKey = dateOnly(data.dayKeyUtc);
    final due = sortTasksByDeadline(
      data.triageDue,
      today: dayKey,
    );
    final planned = sortTasksByStartDate(data.triageStarts);

    final rows = <TasklyRowSpec>[
      TasklyRowSpec.header(
        key: 'plan-triage-due-header',
        title: l10n.myDayDueSoonLabel,
        trailingLabel: due.isEmpty ? null : '${due.length}',
      ),
      if (due.isEmpty)
        TasklyRowSpec.subheader(
          key: 'plan-triage-due-empty',
          title: l10n.myDayPlanDueEmptyTitle,
        )
      else
        ..._buildTaskRows(
          context,
          tasks: due,
          selectedTaskIds: data.selectedTaskIds,
          enableSnooze: true,
          dayKeyUtc: data.dayKeyUtc,
          style: TasklyTaskRowStyle.planPick,
          badgeLabel: l10n.myDayBadgeDue,
        ),
      TasklyRowSpec.header(
        key: 'plan-triage-planned-header',
        title: l10n.myDayPlannedSectionTitle,
        trailingLabel: planned.isEmpty ? null : '${planned.length}',
      ),
      if (planned.isEmpty)
        TasklyRowSpec.subheader(
          key: 'plan-triage-planned-empty',
          title: l10n.myDayPlanPlannedEmptyTitle,
        )
      else
        ..._buildTaskRows(
          context,
          tasks: planned,
          selectedTaskIds: data.selectedTaskIds,
          enableSnooze: true,
          dayKeyUtc: data.dayKeyUtc,
          style: TasklyTaskRowStyle.planPick,
          badgeLabel: l10n.myDayBadgeStarts,
        ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        TasklyFeedRenderer.buildSection(
          TasklySectionSpec.standardList(
            id: 'plan-triage',
            rows: rows,
          ),
        ),
      ],
    );
  }
}

class _PlanSummaryStep extends StatelessWidget {
  const _PlanSummaryStep({required this.data});

  final PlanMyDayReady data;

  @override
  Widget build(BuildContext context) {
    final rows = _buildSummaryRows(context, data: data);
    if (rows.isEmpty) {
      return TasklyFeedRenderer(
        spec: TasklyFeedSpec.empty(
          empty: TasklyEmptyStateSpec(
            icon: Icons.check_circle_outline,
            title: context.l10n.myDayPlanNothingAddedYetTitle,
            description: context.l10n.myDayPlanReviewAvailableAboveSubtitle,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        TasklyFeedRenderer.buildSection(
          TasklySectionSpec.standardList(
            id: 'plan-summary',
            rows: rows,
          ),
        ),
      ],
    );
  }
}

class _PlanBottomBar extends StatelessWidget {
  const _PlanBottomBar({required this.data});

  final PlanMyDayReady data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final totalSelected =
        data.selectedTaskIds.length + data.selectedRoutineIds.length;
    final isSummary = data.currentStep == PlanMyDayStep.summary;
    final isFirst = data.currentStepIndex == 0;

    final primaryLabel = isSummary
        ? (totalSelected == 0
              ? l10n.myDaySelectItemsToContinueLabel
              : data.needsPlan
              ? l10n.myDayContinueToMyDayLabel(totalSelected)
              : l10n.myDayUpdateMyDayLabel(totalSelected))
        : l10n.myDayWizardNextLabel;

    final primaryEnabled = !isSummary || totalSelected > 0;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          children: [
            if (!isFirst)
              TextButton(
                onPressed: () => context.read<PlanMyDayBloc>().add(
                  const PlanMyDayStepBackRequested(),
                ),
                child: Text(l10n.myDayWizardBackLabel),
              )
            else
              const SizedBox(width: 12),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: !primaryEnabled
                    ? null
                    : () {
                        final bloc = context.read<PlanMyDayBloc>();
                        if (isSummary) {
                          bloc.add(
                            const PlanMyDayConfirm(closeOnSuccess: true),
                          );
                        } else {
                          bloc.add(const PlanMyDayStepNextRequested());
                        }
                      },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(primaryLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _stepTitle(BuildContext context, PlanMyDayStep step) {
  return switch (step) {
    PlanMyDayStep.valuesStep => context.l10n.myDayStepValuesTitle,
    PlanMyDayStep.routines => context.l10n.myDayStepRoutinesTitle,
    PlanMyDayStep.triage => context.l10n.myDayStepTriageTitle,
    PlanMyDayStep.summary => context.l10n.myDayStepSummaryTitle,
  };
}

String _stepLabel(BuildContext context, PlanMyDayStep step) {
  return switch (step) {
    PlanMyDayStep.valuesStep => context.l10n.myDayStepValuesLabel,
    PlanMyDayStep.routines => context.l10n.myDayStepRoutinesLabel,
    PlanMyDayStep.triage => context.l10n.myDayStepTriageLabel,
    PlanMyDayStep.summary => context.l10n.myDayStepSummaryLabel,
  };
}

List<TasklyRowSpec> _buildTaskRows(
  BuildContext context, {
  required List<Task> tasks,
  required Set<String> selectedTaskIds,
  required bool enableSnooze,
  required DateTime dayKeyUtc,
  required TasklyTaskRowStyle Function({required bool selected}) style,
  String? badgeLabel,
}) {
  final l10n = context.l10n;
  final badges = badgeLabel == null
      ? const <TasklyBadgeData>[]
      : [
          TasklyBadgeData(
            label: badgeLabel,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            tone: TasklyBadgeTone.outline,
          ),
        ];

  return tasks
      .map((task) {
        final tileCapabilities = EntityTileCapabilitiesResolver.forTask(task);
        final isSelected = selectedTaskIds.contains(task.id);

        final data = buildTaskRowData(
          context,
          task: task,
          tileCapabilities: tileCapabilities,
        );

        final updatedData = TasklyTaskRowData(
          id: data.id,
          title: data.title,
          completed: data.completed,
          meta: data.meta,
          leadingChip: data.leadingChip,
          secondaryChips: data.secondaryChips,
          badges: badges,
          deemphasized: data.deemphasized,
          checkboxSemanticLabel: data.checkboxSemanticLabel,
          labels: TasklyTaskRowLabels(
            pinnedSemanticLabel: l10n.pinnedSemanticLabel,
            selectionPillLabel: l10n.myDayAddToMyDayAction,
            selectionPillSelectedLabel: l10n.myDayAddedLabel,
            snoozeTooltip: l10n.myDaySnoozeAction,
          ),
          pinned: task.isPinned,
        );

        return TasklyRowSpec.task(
          key: 'plan-task-${task.id}',
          data: updatedData,
          style: style(selected: isSelected),
          actions: TasklyTaskRowActions(
            onTap: () => context.read<PlanMyDayBloc>().add(
              PlanMyDayToggleTask(task.id, selected: !isSelected),
            ),
            onToggleSelected: () => context.read<PlanMyDayBloc>().add(
              PlanMyDayToggleTask(task.id, selected: !isSelected),
            ),
            onSnoozeRequested: !enableSnooze
                ? null
                : () => _showSnoozeSheet(
                    context,
                    dayKeyUtc: DateTime.utc(
                      dayKeyUtc.year,
                      dayKeyUtc.month,
                      dayKeyUtc.day,
                    ),
                    task: task,
                  ),
          ),
        );
      })
      .toList(growable: false);
}

TasklyRowSpec _buildRoutineRow(
  BuildContext context, {
  required PlanMyDayReady data,
  required PlanMyDayRoutineItem item,
  required String primaryActionLabel,
  String? badgeLabel,
  bool allowRemove = false,
}) {
  final routine = item.routine;
  final badges = badgeLabel == null
      ? const <TasklyBadgeData>[]
      : [
          TasklyBadgeData(
            label: badgeLabel,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            tone: TasklyBadgeTone.outline,
          ),
        ];

  final labels = TasklyRoutineRowLabels(
    primaryActionLabel: primaryActionLabel,
    pauseLabel: allowRemove ? null : context.l10n.routinePauseLabel,
    editLabel: allowRemove ? null : context.l10n.routineEditLabel,
  );

  final dataRow = buildRoutineRowData(
    context,
    routine: routine,
    snapshot: item.snapshot,
    selected: item.selected,
    completed: item.completedToday,
    badges: badges,
    labels: labels,
  );

  return TasklyRowSpec.routine(
    key: 'plan-routine-${routine.id}',
    data: dataRow,
    actions: TasklyRoutineRowActions(
      onTap: item.completedToday
          ? null
          : () => context.read<PlanMyDayBloc>().add(
              PlanMyDayToggleRoutine(
                routine.id,
                selected: !item.selected,
              ),
            ),
      onPrimaryAction: item.completedToday
          ? null
          : () => context.read<PlanMyDayBloc>().add(
              PlanMyDayToggleRoutine(
                routine.id,
                selected: !allowRemove && !item.selected,
              ),
            ),
      onPause: allowRemove
          ? null
          : () => _showRoutinePauseSheet(
              context,
              routine: routine,
              dayKeyUtc: data.dayKeyUtc,
            ),
      onEdit: allowRemove
          ? null
          : () => Routing.toRoutineEdit(context, routine.id),
    ),
  );
}

List<TasklyRowSpec> _buildSummaryRows(
  BuildContext context, {
  required PlanMyDayReady data,
}) {
  final l10n = context.l10n;
  final rows = <TasklyRowSpec>[];

  if (!data.steps.contains(PlanMyDayStep.valuesStep)) {
    rows.add(
      TasklyRowSpec.subheader(
        key: 'plan-summary-no-values',
        title: l10n.myDaySummaryNoValues,
      ),
    );
  }
  if (!data.steps.contains(PlanMyDayStep.routines)) {
    rows.add(
      TasklyRowSpec.subheader(
        key: 'plan-summary-no-routines',
        title: l10n.myDaySummaryNoRoutines,
      ),
    );
  }
  if (!data.steps.contains(PlanMyDayStep.triage)) {
    rows.add(
      TasklyRowSpec.subheader(
        key: 'plan-summary-no-triage',
        title: l10n.myDaySummaryNoTriage,
      ),
    );
  }

  final tasksById = {for (final task in data.allTasks) task.id: task};
  final selectedTaskIds = data.selectedTaskIds;
  final selectedRoutineIds = data.selectedRoutineIds;

  final suggestedIds = data.suggested.map((task) => task.id).toSet();
  final dueIds = data.triageDue.map((task) => task.id).toSet();
  final startsIds = data.triageStarts.map((task) => task.id).toSet();
  final routineItemsById = {
    for (final item in data.routines) item.routine.id: item,
  };

  final orderedTaskIds = _orderedSelectedTaskIds(data);
  final orderedRoutineIds = _orderedSelectedRoutineIds(data);

  for (final routineId in orderedRoutineIds) {
    final item = routineItemsById[routineId];
    if (item == null) continue;
    rows.add(
      _buildRoutineRow(
        context,
        data: data,
        item: item,
        primaryActionLabel: l10n.myDayRemoveAction,
        badgeLabel: l10n.myDayBadgeRoutine,
        allowRemove: true,
      ),
    );
  }

  for (final taskId in orderedTaskIds) {
    final task = tasksById[taskId];
    if (task == null) continue;

    final badgeLabel = suggestedIds.contains(taskId)
        ? l10n.myDayBadgeValues
        : dueIds.contains(taskId)
        ? l10n.myDayBadgeDue
        : startsIds.contains(taskId)
        ? l10n.myDayBadgeStarts
        : l10n.myDayBadgeManual;

    final rowsForTask = _buildTaskRows(
      context,
      tasks: [task],
      selectedTaskIds: selectedTaskIds,
      enableSnooze: false,
      dayKeyUtc: data.dayKeyUtc,
      style: TasklyTaskRowStyle.pickerAction,
      badgeLabel: badgeLabel,
    );
    rows.addAll(rowsForTask);
  }

  if (selectedTaskIds.isEmpty && selectedRoutineIds.isEmpty) {
    return rows;
  }

  return rows;
}

List<String> _orderedSelectedTaskIds(PlanMyDayReady data) {
  final selected = data.selectedTaskIds;
  final ordered = <String>[];

  for (final task in data.suggested) {
    if (selected.contains(task.id)) ordered.add(task.id);
  }
  for (final task in data.triageDue) {
    if (selected.contains(task.id) && !ordered.contains(task.id)) {
      ordered.add(task.id);
    }
  }
  for (final task in data.triageStarts) {
    if (selected.contains(task.id) && !ordered.contains(task.id)) {
      ordered.add(task.id);
    }
  }
  for (final taskId in selected) {
    if (!ordered.contains(taskId)) ordered.add(taskId);
  }

  return ordered;
}

List<String> _orderedSelectedRoutineIds(PlanMyDayReady data) {
  final selected = data.selectedRoutineIds;
  final ordered = <String>[];
  for (final item in data.routines) {
    if (selected.contains(item.routine.id)) {
      ordered.add(item.routine.id);
    }
  }
  for (final routineId in selected) {
    if (!ordered.contains(routineId)) ordered.add(routineId);
  }
  return ordered;
}

Future<void> _showRoutinePauseSheet(
  BuildContext context, {
  required Routine routine,
  required DateTime dayKeyUtc,
}) async {
  final l10n = context.l10n;
  final nextWindow = _nextRoutineWindowStart(
    routineType: routine.routineType,
    dayKeyUtc: dayKeyUtc,
  );
  final formattedDate = MaterialLocalizations.of(
    context,
  ).formatMediumDate(nextWindow.toLocal());

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.routinePauseSheetTitle),
              subtitle: Text(l10n.routinePauseSheetSubtitle),
            ),
            ListTile(
              leading: const Icon(Icons.pause_circle_outline),
              title: Text(l10n.routinePauseUntilNextWindow(formattedDate)),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.read<PlanMyDayBloc>().add(
                  PlanMyDayPauseRoutineRequested(
                    routineId: routine.id,
                    pausedUntilUtc: nextWindow,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(l10n.routinePausePickDate),
              onTap: () async {
                final today = dateOnly(dayKeyUtc);
                final picked = await showDatePicker(
                  context: sheetContext,
                  initialDate: today.add(const Duration(days: 1)),
                  firstDate: today.add(const Duration(days: 1)),
                  lastDate: DateTime(today.year + 3, today.month, today.day),
                );
                if (picked == null || !sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                context.read<PlanMyDayBloc>().add(
                  PlanMyDayPauseRoutineRequested(
                    routineId: routine.id,
                    pausedUntilUtc: dateOnly(picked),
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

DateTime _nextRoutineWindowStart({
  required RoutineType routineType,
  required DateTime dayKeyUtc,
}) {
  final today = dateOnly(dayKeyUtc);
  switch (routineType) {
    case RoutineType.weeklyFixed:
    case RoutineType.weeklyFlexible:
      final delta = today.weekday - DateTime.monday;
      final weekStart = today.subtract(Duration(days: delta));
      return weekStart.add(const Duration(days: 7));
    case RoutineType.monthlyFixed:
    case RoutineType.monthlyFlexible:
      return DateTime.utc(today.year, today.month + 1);
  }
}

Future<void> _showSnoozeSheet(
  BuildContext context, {
  required DateTime dayKeyUtc,
  required Task task,
}) async {
  DateTime nextWeekday(DateTime day, int weekday) {
    final normalized = dateOnly(day);
    final rawDelta = weekday - normalized.weekday;
    final delta = rawDelta <= 0 ? rawDelta + 7 : rawDelta;
    return normalized.add(Duration(days: delta));
  }

  final today = dateOnly(dayKeyUtc);
  final tomorrow = today.add(const Duration(days: 1));
  final thisWeekend = nextWeekday(today, DateTime.saturday);
  final nextMonday = nextWeekday(today, DateTime.monday);

  final parentContext = context;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      final localToday = DateTime(today.year, today.month, today.day);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.myDayMyDaySnoozeSheetTitle),
              subtitle: Text(l10n.myDayMyDaySnoozeSheetSubtitle),
            ),
            ListTile(
              leading: const Icon(Icons.today),
              title: Text(l10n.dateTomorrow),
              onTap: () async {
                await _confirmAndDispatchSnooze(
                  parentContext,
                  sheetContext,
                  task: task,
                  untilUtc: tomorrow,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.weekend_outlined),
              title: Text(l10n.dateThisWeekend),
              onTap: () async {
                await _confirmAndDispatchSnooze(
                  parentContext,
                  sheetContext,
                  task: task,
                  untilUtc: thisWeekend,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: Text(l10n.dateNextMonday),
              onTap: () async {
                await _confirmAndDispatchSnooze(
                  parentContext,
                  sheetContext,
                  task: task,
                  untilUtc: nextMonday,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n.pickDateButton),
              onTap: () async {
                final picked = await showDatePicker(
                  context: sheetContext,
                  initialDate: localToday.add(const Duration(days: 1)),
                  firstDate: localToday.add(const Duration(days: 1)),
                  lastDate: DateTime(
                    localToday.year + 3,
                    localToday.month,
                    localToday.day,
                  ),
                );
                if (picked == null) return;
                if (!sheetContext.mounted || !parentContext.mounted) return;
                await _confirmAndDispatchSnooze(
                  parentContext,
                  sheetContext,
                  task: task,
                  untilUtc: dateOnly(picked),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _confirmAndDispatchSnooze(
  BuildContext parentContext,
  BuildContext sheetContext, {
  required Task task,
  required DateTime untilUtc,
}) async {
  final bloc = parentContext.read<PlanMyDayBloc>();
  final navigator = Navigator.of(sheetContext);

  if (!navigator.mounted) return;

  if (navigator.canPop()) {
    navigator.pop();
  }

  bloc.add(
    PlanMyDaySnoozeTaskRequested(
      taskId: task.id,
      untilUtc: untilUtc,
    ),
  );
}
