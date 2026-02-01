import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/guided_tour_anchors.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/plan_my_day_bloc.dart';
import 'package:taskly_bloc/presentation/screens/view/my_day_values_gate.dart';
import 'package:taskly_bloc/presentation/shared/ui/routine_tile_model_mapper.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';

class PlanMyDayPage extends StatelessWidget {
  const PlanMyDayPage({
    required this.onCloseRequested,
    super.key,
  });

  final VoidCallback onCloseRequested;

  Future<void> _handleClose(
    BuildContext context, {
    PlanMyDayReady? data,
  }) async {
    if (data == null) {
      onCloseRequested();
      return;
    }

    final hasSelections =
        data.selectedTaskIds.isNotEmpty || data.selectedRoutineIds.isNotEmpty;
    if (!hasSelections) {
      onCloseRequested();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Exit without saving?'),
          content: const Text("Your picks won't be saved to today's plan."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Stay'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );

    if (confirmed ?? false) {
      onCloseRequested();
    }
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
        BlocListener<PlanMyDayBloc, PlanMyDayState>(
          listenWhen: (previous, current) {
            if (previous is! PlanMyDayReady || current is! PlanMyDayReady) {
              return false;
            }
            return previous.toastRequestId != current.toastRequestId;
          },
          listener: (context, state) {
            if (state is! PlanMyDayReady) return;
            final toast = state.toast;
            if (toast == null) return;
            final messenger = ScaffoldMessenger.of(context);
            messenger.clearSnackBars();
            messenger.showSnackBar(
              SnackBar(
                content: Text(toast.message),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
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
                    title: Text(context.l10n.myDayPlanTitle),
                    actions: [
                      IconButton(
                        tooltip: 'Exit plan',
                        icon: const Icon(Icons.close),
                        onPressed: () => _handleClose(
                          context,
                          data: planState,
                        ),
                      ),
                    ],
                  ),
                  body: SafeArea(
                    bottom: false,
                    child: _PlanMyDayBody(
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

class _PlanMyDayBody extends StatelessWidget {
  const _PlanMyDayBody({
    required this.data,
    required this.gateState,
  });

  final PlanMyDayReady data;
  final MyDayGateState gateState;

  @override
  Widget build(BuildContext context) {
    if (data.requiresValueSetup && gateState is MyDayGateLoaded) {
      return const MyDayValuesGate();
    }

    if (data.requiresRatings) {
      return _RatingsGate(
        onRateRequested: () => Routing.toScreenKey(context, 'settings'),
        onSwitchRequested: () => context.read<PlanMyDayBloc>().add(
          const PlanMyDaySwitchToBehaviorSuggestionsRequested(),
        ),
      );
    }

    final tokens = TasklyTokens.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceSm,
        tokens.spaceLg,
        tokens.spaceXl,
      ),
      children: [
        Text(
          "Build today's plan.",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: tokens.spaceSm),
        _PlanSummaryBar(data: data),
        SizedBox(height: tokens.spaceLg),
        if (data.dueTodayTasks.isNotEmpty)
          _TaskShelf(
            title: 'Due Today',
            actionLabel: 'Reschedule all due',
            anchorKey: GuidedTourAnchors.planMyDayTriage,
            onAction: () => _showRescheduleSheet(
              context,
              title: 'Reschedule all',
              subtitle: 'Choose a new day for these items.',
              dayKeyUtc: data.dayKeyUtc,
              onSelected: (date) => context.read<PlanMyDayBloc>().add(
                PlanMyDayBulkRescheduleDueRequested(newDayUtc: date),
              ),
            ),
            rows: _buildTaskRows(
              context,
              tasks: data.dueTodayTasks,
              selectedTaskIds: data.selectedTaskIds,
              style: ({required bool selected}) =>
                  TasklyTaskRowStyle.planPick(selected: selected),
              allowSelection: false,
              onActionPressed: (task) => _showRescheduleSheet(
                context,
                title: 'Reschedule task',
                subtitle: 'Choose a new day for this task.',
                dayKeyUtc: data.dayKeyUtc,
                onSelected: (date) => context.read<PlanMyDayBloc>().add(
                  PlanMyDayRescheduleDueTaskRequested(
                    taskId: task.id,
                    newDayUtc: date,
                  ),
                ),
              ),
              dayKeyUtc: data.dayKeyUtc,
            ),
          )
        else
          _EmptyShelf(
            title: 'Due Today',
            body: 'Nothing due today.',
            anchorKey: GuidedTourAnchors.planMyDayTriage,
          ),
        SizedBox(height: tokens.spaceLg),
        if (data.plannedTasks.isNotEmpty)
          _TaskShelf(
            title: 'Planned',
            actionLabel: 'Reschedule all planned',
            onAction: () => _showRescheduleSheet(
              context,
              title: 'Reschedule all',
              subtitle: 'Choose a new day for these items.',
              dayKeyUtc: data.dayKeyUtc,
              onSelected: (date) => context.read<PlanMyDayBloc>().add(
                PlanMyDayBulkReschedulePlannedRequested(newDayUtc: date),
              ),
            ),
            rows: _buildTaskRows(
              context,
              tasks: data.plannedTasks,
              selectedTaskIds: data.selectedTaskIds,
              style: ({required bool selected}) =>
                  TasklyTaskRowStyle.planPick(selected: selected),
              allowSelection: false,
              onActionPressed: (task) => _showRescheduleSheet(
                context,
                title: 'Reschedule task',
                subtitle: 'Choose a new day for this task.',
                dayKeyUtc: data.dayKeyUtc,
                onSelected: (date) => context.read<PlanMyDayBloc>().add(
                  PlanMyDayReschedulePlannedTaskRequested(
                    taskId: task.id,
                    newDayUtc: date,
                  ),
                ),
              ),
              dayKeyUtc: data.dayKeyUtc,
            ),
          )
        else
          _EmptyShelf(title: 'Planned', body: 'Nothing planned for today.'),
        SizedBox(height: tokens.spaceLg),
        if (data.allRoutines.isNotEmpty)
          _RoutineShelf(
            data: data,
            dayKeyUtc: data.dayKeyUtc,
            scheduledAnchorKey: GuidedTourAnchors.planMyDayScheduledRoutines,
            flexibleAnchorKey: GuidedTourAnchors.planMyDayFlexibleRoutines,
          ),
        if (!data.overCapacity && data.valueSuggestionGroups.isNotEmpty) ...[
          SizedBox(height: tokens.spaceLg),
          _SuggestionsShelf(data: data),
        ],
        if (data.overCapacity) ...[
          SizedBox(height: tokens.spaceLg),
          _OverCapacityCard(
            count: data.plannedCount,
            limit: data.dailyLimit,
          ),
        ],
      ],
    );
  }
}

class _PlanSummaryBar extends StatelessWidget {
  const _PlanSummaryBar({required this.data});

  final PlanMyDayReady data;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(tokens.spaceMd),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "Today's plan: ${data.plannedCount} items",
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _LimitStepper(limit: data.dailyLimit),
        ],
      ),
    );
  }
}

class _LimitStepper extends StatelessWidget {
  const _LimitStepper({required this.limit});

  final int limit;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PlanMyDayBloc>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Decrease limit',
          onPressed: () => bloc.add(PlanMyDayDailyLimitChanged(limit - 1)),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text(
          'Limit: $limit',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        IconButton(
          tooltip: 'Increase limit',
          onPressed: () => bloc.add(PlanMyDayDailyLimitChanged(limit + 1)),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}

class _TaskShelf extends StatelessWidget {
  const _TaskShelf({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.rows,
    this.anchorKey,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final List<TasklyRowSpec> rows;
  final Key? anchorKey;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);

    return Column(
      key: anchorKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
        SizedBox(height: tokens.spaceSm),
        _AnimatedRowList(rows: rows),
      ],
    );
  }
}

class _RoutineShelf extends StatelessWidget {
  const _RoutineShelf({
    required this.data,
    required this.dayKeyUtc,
    this.scheduledAnchorKey,
    this.flexibleAnchorKey,
  });

  final PlanMyDayReady data;
  final DateTime dayKeyUtc;
  final Key? scheduledAnchorKey;
  final Key? flexibleAnchorKey;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final routineRows = <TasklyRowSpec>[];

    for (final item in data.allRoutines) {
      final showSelection =
          !item.isScheduled && !item.completedToday && item.isEligibleToday;
      routineRows.add(
        _buildRoutineRow(
          context,
          data: data,
          item: item,
          allowSelection: showSelection,
          dayKeyUtc: dayKeyUtc,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            if (scheduledAnchorKey != null)
              Positioned(
                left: 0,
                top: 0,
                child: SizedBox(
                  key: scheduledAnchorKey,
                  width: 1,
                  height: 1,
                ),
              ),
            if (flexibleAnchorKey != null)
              Positioned(
                left: 12,
                top: 0,
                child: SizedBox(
                  key: flexibleAnchorKey,
                  width: 1,
                  height: 1,
                ),
              ),
            Text(
              'Routines',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spaceSm),
        _AnimatedRowList(rows: routineRows),
      ],
    );
  }
}

class _SuggestionsShelf extends StatelessWidget {
  const _SuggestionsShelf({required this.data});

  final PlanMyDayReady data;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final groups = data.valueSuggestionGroups;
    final suggestions = <Widget>[];

    for (var i = 0; i < groups.length; i += 1) {
      final group = groups[i];
      suggestions.add(
        _ValueSuggestionChip(
          value: group.value,
          anchorKey: i == 0 ? GuidedTourAnchors.planMyDayValuesCard : null,
        ),
      );
      suggestions.add(SizedBox(height: tokens.spaceSm2));
      final visibleTasks = group.tasks
          .take(group.visibleCount)
          .toList(growable: false);
      final rows = _buildTaskRows(
        context,
        tasks: visibleTasks,
        selectedTaskIds: data.selectedTaskIds,
        style: TasklyTaskRowStyle.planPick,
        allowSelection: true,
        dayKeyUtc: data.dayKeyUtc,
        onSwapRequested: (task) => _showSwapSheet(
          context,
          data: data,
          group: group,
          currentTask: task,
        ),
      );
      suggestions.add(_AnimatedRowList(rows: rows));
      if (i != groups.length - 1) {
        suggestions.add(SizedBox(height: tokens.spaceLg));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggestions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: tokens.spaceSm),
        ...suggestions,
      ],
    );
  }
}

class _ValueSuggestionChip extends StatelessWidget {
  const _ValueSuggestionChip({
    required this.value,
    this.anchorKey,
  });

  final Value value;
  final Key? anchorKey;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final chipData = value.toChipData(context);

    return Container(
      key: anchorKey,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSm2,
        vertical: tokens.spaceXs2,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(tokens.radiusPill),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            chipData.icon,
            size: tokens.spaceMd2,
            color: chipData.color,
          ),
          SizedBox(width: tokens.spaceXxs2),
          Text(
            chipData.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverCapacityCard extends StatelessWidget {
  const _OverCapacityCard({
    required this.count,
    required this.limit,
  });

  final int count;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(tokens.spaceMd),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.error),
          SizedBox(width: tokens.spaceSm),
          Expanded(
            child: Text(
              'Over capacity ($count/$limit). Reschedule items or adjust limit.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyShelf extends StatelessWidget {
  const _EmptyShelf({
    required this.title,
    required this.body,
    this.anchorKey,
  });

  final String title;
  final String body;
  final Key? anchorKey;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Column(
      key: anchorKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: tokens.spaceSm),
        Text(
          body,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    final tokens = TasklyTokens.of(context);
    final l10n = context.l10n;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLg,
          tokens.spaceSm2,
          tokens.spaceLg,
          tokens.spaceLg,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${data.plannedCount} selected',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: tokens.spaceSm),
            FilledButton(
              onPressed: () => context.read<PlanMyDayBloc>().add(
                const PlanMyDayConfirm(closeOnSuccess: true),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(tokens.radiusMd),
                ),
              ),
              child: Text(l10n.myDaySavePlanLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedRowList extends StatefulWidget {
  const _AnimatedRowList({
    required this.rows,
  });

  final List<TasklyRowSpec> rows;

  @override
  State<_AnimatedRowList> createState() => _AnimatedRowListState();
}

class _AnimatedRowListState extends State<_AnimatedRowList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<TasklyRowSpec> _rows;

  @override
  void initState() {
    super.initState();
    _rows = List<TasklyRowSpec>.from(widget.rows);
  }

  @override
  void didUpdateWidget(covariant _AnimatedRowList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRows(widget.rows);
  }

  void _syncRows(List<TasklyRowSpec> nextRows) {
    final oldKeys = _rows.map(_rowKey).toList(growable: false);
    final newKeys = nextRows.map(_rowKey).toList(growable: false);

    for (var i = oldKeys.length - 1; i >= 0; i -= 1) {
      if (newKeys.contains(oldKeys[i])) continue;
      final removed = _rows.removeAt(i);
      _listKey.currentState?.removeItem(
        i,
        (context, animation) => _buildAnimatedRow(
          context,
          removed,
          animation,
        ),
        duration: const Duration(milliseconds: 200),
      );
    }

    for (var i = 0; i < newKeys.length; i += 1) {
      if (oldKeys.contains(newKeys[i])) continue;
      _rows.insert(i, nextRows[i]);
      _listKey.currentState?.insertItem(
        i,
        duration: const Duration(milliseconds: 200),
      );
    }

    _rows = List<TasklyRowSpec>.from(nextRows);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      initialItemCount: _rows.length,
      itemBuilder: (context, index, animation) => _buildAnimatedRow(
        context,
        _rows[index],
        animation,
      ),
    );
  }

  Widget _buildAnimatedRow(
    BuildContext context,
    TasklyRowSpec row,
    Animation<double> animation,
  ) {
    final tokens = TasklyTokens.of(context);
    final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    final size = CurvedAnimation(parent: animation, curve: Curves.easeInOut);

    final child = TasklyFeedRenderer.buildRow(
      row,
      context: context,
    );
    final isLast = _rows.isNotEmpty && identical(row, _rows.last);
    final padded = Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 0 : tokens.feedEntityRowSpacing,
      ),
      child: child,
    );

    return SizeTransition(
      sizeFactor: size,
      child: FadeTransition(
        opacity: fade,
        child: padded,
      ),
    );
  }

  String _rowKey(TasklyRowSpec row) {
    return switch (row) {
      TasklyHeaderRowSpec(:final key) => key,
      TasklySubheaderRowSpec(:final key) => key,
      TasklyDividerRowSpec(:final key) => key,
      TasklyInlineActionRowSpec(:final key) => key,
      TasklyTaskRowSpec(:final key) => key,
      TasklyProjectRowSpec(:final key) => key,
      TasklyValueRowSpec(:final key) => key,
      TasklyRoutineRowSpec(:final key) => key,
    };
  }
}

List<TasklyRowSpec> _buildTaskRows(
  BuildContext context, {
  required List<Task> tasks,
  required Set<String> selectedTaskIds,
  required TasklyTaskRowStyle Function({required bool selected}) style,
  required bool allowSelection,
  required DateTime dayKeyUtc,
  ValueChanged<Task>? onActionPressed,
  ValueChanged<Task>? onSwapRequested,
}) {
  final today = dateOnly(dayKeyUtc);
  final showAction = allowSelection || onActionPressed != null;
  final snoozeUntil = dateOnly(dayKeyUtc).add(const Duration(days: 1));

  return tasks
      .map((task) {
        final tileCapabilities = EntityTileCapabilitiesResolver.forTask(task);
        final isSelected = selectedTaskIds.contains(task.id);

        final data = buildTaskRowData(
          context,
          task: task,
          tileCapabilities: tileCapabilities,
          overrideIsOverdue: _isOverdue(task, today),
          overrideIsDueToday: _isDueToday(task, today),
        );

        return TasklyRowSpec.task(
          key: 'plan-task-${task.id}',
          data: data,
          style: style(selected: isSelected),
          actions: TasklyTaskRowActions(
            onTap: buildTaskOpenEditorHandler(context, task: task),
            onToggleSelected: showAction
                ? () {
                    if (onActionPressed != null) {
                      onActionPressed(task);
                      return;
                    }
                    if (allowSelection) {
                      context.read<PlanMyDayBloc>().add(
                        PlanMyDayToggleTask(task.id, selected: !isSelected),
                      );
                    }
                  }
                : null,
            onSwapRequested: onSwapRequested == null
                ? null
                : () => onSwapRequested(task),
            onSnoozeRequested: () => context.read<PlanMyDayBloc>().add(
              PlanMyDaySnoozeTaskRequested(
                taskId: task.id,
                untilUtc: snoozeUntil,
              ),
            ),
          ),
        );
      })
      .toList(growable: false);
}

List<TasklyRowSpec> _buildSwapRows(
  BuildContext context, {
  required List<Task> tasks,
  required DateTime dayKeyUtc,
  required ValueChanged<Task> onSelected,
}) {
  final today = dateOnly(dayKeyUtc);

  return tasks
      .map((task) {
        final tileCapabilities = EntityTileCapabilitiesResolver.forTask(task);
        final dueLabel = _compactDueLabel(context, task: task, today: today);
        final data = buildTaskRowData(
          context,
          task: task,
          tileCapabilities: tileCapabilities,
          overrideDeadlineDateLabel: dueLabel,
          overrideIsOverdue: _isOverdue(task, today),
          overrideIsDueToday: _isDueToday(task, today),
        );

        return TasklyRowSpec.task(
          key: 'swap-task-${task.id}',
          data: data,
          style: const TasklyTaskRowStyle.compact(),
          actions: TasklyTaskRowActions(
            onTap: () => onSelected(task),
          ),
        );
      })
      .toList(growable: false);
}

TasklyRowSpec _buildRoutineRow(
  BuildContext context, {
  required PlanMyDayReady data,
  required PlanMyDayRoutineItem item,
  required bool allowSelection,
  required DateTime dayKeyUtc,
}) {
  final routine = item.routine;
  final labels = TasklyRoutineRowLabels(
    selectionTooltipLabel: context.l10n.myDayAddToMyDayAction,
    selectionTooltipSelectedLabel: context.l10n.myDayAddedLabel,
  );

  final dataRow = buildRoutineRowData(
    context,
    routine: routine,
    snapshot: item.snapshot,
    selected: item.selected,
    completed: item.completedToday,
    showProgress:
        routine.routineType == RoutineType.weeklyFlexible ||
        routine.routineType == RoutineType.monthlyFlexible,
    forceProgress: true,
    showScheduleRow: false,
    dayKeyUtc: data.dayKeyUtc,
    completionsInPeriod: item.completionsInPeriod,
    labels: labels,
  );

  return TasklyRowSpec.routine(
    key: 'plan-routine-${routine.id}',
    data: dataRow,
    style: const TasklyRoutineRowStyle.planPick(),
    actions: TasklyRoutineRowActions(
      onTap: () => Routing.toRoutineEdit(context, routine.id),
      onToggleSelected: allowSelection
          ? () => context.read<PlanMyDayBloc>().add(
              PlanMyDayToggleRoutine(
                routine.id,
                selected: !item.selected,
              ),
            )
          : null,
    ),
  );
}

String? _compactDueLabel(
  BuildContext context, {
  required Task task,
  required DateTime today,
}) {
  final deadline = task.occurrence?.deadline ?? task.deadlineDate;
  final dateOnlyDeadline = dateOnlyOrNull(deadline);
  if (dateOnlyDeadline == null) return null;
  if (dateOnlyDeadline.isBefore(today)) return 'Overdue';
  if (dateOnlyDeadline.isAtSameMomentAs(today)) return 'Due today';
  return MaterialLocalizations.of(context).formatMediumDate(deadline!);
}

bool _isOverdue(Task task, DateTime today) {
  final deadline = task.occurrence?.deadline ?? task.deadlineDate;
  if (deadline == null) return false;
  final day = dateOnly(deadline);
  return day.isBefore(today);
}

bool _isDueToday(Task task, DateTime today) {
  final deadline = task.occurrence?.deadline ?? task.deadlineDate;
  if (deadline == null) return false;
  final day = dateOnly(deadline);
  return day.isAtSameMomentAs(today);
}

Future<void> _showSwapSheet(
  BuildContext context, {
  required PlanMyDayReady data,
  required PlanMyDayValueSuggestionGroup group,
  required Task currentTask,
}) async {
  final candidates = group.tasks
      .where((task) => task.id != currentTask.id)
      .where((task) => !data.selectedTaskIds.contains(task.id))
      .toList(growable: false);

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final tokens = TasklyTokens.of(sheetContext);
      final scheme = Theme.of(sheetContext).colorScheme;
      final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.7;

      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            tokens.spaceSm,
            tokens.spaceLg,
            tokens.spaceLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Swap suggestion',
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: tokens.spaceXs2),
              Text(
                'Choose another option in ${group.value.name}.',
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: tokens.spaceSm),
              if (candidates.isEmpty)
                Text(
                  'No other options for this value.',
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else
                Builder(
                  builder: (context) {
                    final rows = _buildSwapRows(
                      context,
                      tasks: candidates,
                      dayKeyUtc: data.dayKeyUtc,
                      onSelected: (task) {
                        final bloc = sheetContext.read<PlanMyDayBloc>();
                        Navigator.of(sheetContext).pop();
                        bloc.add(
                          PlanMyDaySwapSuggestionRequested(
                            fromTaskId: currentTask.id,
                            toTaskId: task.id,
                          ),
                        );
                      },
                    );

                    return ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxHeight),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: rows.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: tokens.feedEntityRowSpacing),
                        itemBuilder: (context, index) =>
                            TasklyFeedRenderer.buildRow(
                              rows[index],
                              context: context,
                            ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _showRescheduleSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required DateTime dayKeyUtc,
  required ValueChanged<DateTime> onSelected,
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
  final nextWeek = nextWeekday(today, DateTime.monday);

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(title),
              subtitle: Text(subtitle),
            ),
            ListTile(
              leading: const Icon(Icons.today),
              title: const Text('Tomorrow'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onSelected(tomorrow);
              },
            ),
            ListTile(
              leading: const Icon(Icons.weekend_outlined),
              title: const Text('This weekend'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onSelected(thisWeekend);
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Next week'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                onSelected(nextWeek);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Pick a date'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: sheetContext,
                  initialDate: today.add(const Duration(days: 1)),
                  firstDate: today.add(const Duration(days: 1)),
                  lastDate: DateTime(
                    today.year + 3,
                    today.month,
                    today.day,
                  ),
                );
                if (picked == null) return;
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                onSelected(dateOnly(picked));
              },
            ),
          ],
        ),
      );
    },
  );
}

class _RatingsGate extends StatelessWidget {
  const _RatingsGate({
    required this.onRateRequested,
    required this.onSwitchRequested,
  });

  final VoidCallback onRateRequested;
  final VoidCallback onSwitchRequested;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: tokens.spaceLg3,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: tokens.spaceSm),
            Text(
              'Rate your values to unlock suggestions',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: tokens.spaceSm),
            Text(
              'Or switch to behavior-based suggestions to keep planning.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: tokens.spaceMd),
            FilledButton(
              onPressed: onRateRequested,
              child: const Text('Rate values'),
            ),
            SizedBox(height: tokens.spaceSm),
            TextButton(
              onPressed: onSwitchRequested,
              child: const Text('Switch to behavior-based'),
            ),
          ],
        ),
      ),
    );
  }
}
