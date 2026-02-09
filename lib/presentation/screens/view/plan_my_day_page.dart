import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/guided_tour_anchors.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/plan_my_day_bloc.dart';
import 'package:taskly_bloc/presentation/screens/view/my_day_values_gate.dart';
import 'package:taskly_bloc/presentation/shared/ui/routine_tile_model_mapper.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_bloc/presentation/shared/errors/friendly_error_message.dart';
import 'package:taskly_bloc/presentation/shared/widgets/reschedule_picker.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';

const Key kPlanMyDayBottomFadeKey = Key('plan_my_day_bottom_fade');
const Key kPlanMyDayLastChildKey = Key('plan_my_day_last_child');

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
          title: Text(context.l10n.planMyDayExitWithoutSavingTitle),
          content: Text(context.l10n.planMyDayExitWithoutSavingBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.stayLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n.exitLabel),
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
            final l10n = context.l10n;
            final message = switch (toast.kind) {
              PlanMyDayToastKind.updated => l10n.planMyDayUpdatedSnack,
              PlanMyDayToastKind.error =>
                toast.error == null
                    ? l10n.genericErrorFallback
                    : friendlyErrorMessageForUi(toast.error!, l10n),
            };
            final messenger = ScaffoldMessenger.of(context);
            messenger.clearSnackBars();
            messenger.showSnackBar(
              SnackBar(
                content: Text(message),
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
                        tooltip: context.l10n.planMyDayExitTooltip,
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

class _PlanMyDayBody extends StatefulWidget {
  const _PlanMyDayBody({
    required this.data,
    required this.gateState,
  });

  final PlanMyDayReady data;
  final MyDayGateState gateState;

  @override
  State<_PlanMyDayBody> createState() => _PlanMyDayBodyState();
}

class _PlanMyDayBodyState extends State<_PlanMyDayBody> {
  double? _lastChildHeight;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final gateState = widget.gateState;

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
    final l10n = context.l10n;
    final isCompact = context.isCompactScreen;
    const maxVisibleItems = ExpandableRowListDefaults.compactMaxVisible;
    final double fadeHeight;
    final double bottomPadding;

    final measuredHeight = _lastChildHeight ?? 0;
    if (measuredHeight > 0) {
      final desiredFade = (measuredHeight * 0.5).clamp(
        tokens.spaceMd,
        tokens.spaceXl,
      );
      final desiredCovered = (measuredHeight * 0.3).clamp(
        tokens.spaceXs2,
        desiredFade - 1,
      );
      fadeHeight = desiredFade;
      bottomPadding = (fadeHeight - desiredCovered).clamp(0, fadeHeight);
    } else {
      fadeHeight = tokens.spaceXl;
      bottomPadding = tokens.spaceSm;
    }

    final children = <Widget>[
      Text(
        l10n.planMyDayBuildPlanTitle,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      SizedBox(height: tokens.spaceSm),
      _PlanSummaryBar(data: data),
      SizedBox(height: tokens.spaceLg),
      if (data.dueTodayTasks.isNotEmpty)
        _TaskShelf(
          title: l10n.planMyDayDueTodayTitle,
          actionLabel: l10n.planMyDayRescheduleAllDueAction,
          anchorKey: GuidedTourAnchors.planMyDayTriage,
          rowKeyPrefix: 'plan-due',
          limitItems: isCompact,
          maxVisibleItems: maxVisibleItems,
          onAction: () async {
            final choice = await showRescheduleChoiceSheet(
              context,
              title: l10n.planMyDayRescheduleAllTitle,
              subtitle: l10n.planMyDayRescheduleAllSubtitle,
              dayKeyUtc: data.dayKeyUtc,
            );
            if (choice == null || !context.mounted) return;

            switch (choice) {
              case RescheduleQuickChoice(:final date):
                context.read<PlanMyDayBloc>().add(
                  PlanMyDayBulkRescheduleDueRequested(newDayUtc: date),
                );
              case ReschedulePickDateChoice():
                final today = dateOnly(data.dayKeyUtc);
                final picked = await showRescheduleDatePicker(
                  context,
                  initialDate: today.add(const Duration(days: 1)),
                  firstDate: today.add(const Duration(days: 1)),
                  lastDate: DateTime(
                    today.year + 3,
                    today.month,
                    today.day,
                  ),
                );
                if (picked == null || !context.mounted) return;
                context.read<PlanMyDayBloc>().add(
                  PlanMyDayBulkRescheduleDueRequested(newDayUtc: picked),
                );
            }
          },
          rows: _buildTaskRows(
            context,
            tasks: data.dueTodayTasks,
            selectedTaskIds: data.selectedTaskIds,
            style: ({required bool selected}) =>
                TasklyTaskRowStyle.planPick(selected: selected),
            allowSelection: false,
            onActionPressed: (task) async {
              final choice = await showRescheduleChoiceSheet(
                context,
                title: l10n.planMyDayRescheduleTaskTitle,
                subtitle: l10n.planMyDayRescheduleTaskSubtitle,
                dayKeyUtc: data.dayKeyUtc,
              );
              if (choice == null || !context.mounted) return;

              final bloc = context.read<PlanMyDayBloc>();
              switch (choice) {
                case RescheduleQuickChoice(:final date):
                  bloc.add(
                    PlanMyDayRescheduleDueTaskRequested(
                      taskId: task.id,
                      newDayUtc: date,
                    ),
                  );
                case ReschedulePickDateChoice():
                  buildTaskOpenEditorHandler(context, task: task)();
              }
            },
            dayKeyUtc: data.dayKeyUtc,
          ),
        )
      else
        _EmptyShelf(
          title: l10n.planMyDayDueTodayTitle,
          body: l10n.planMyDayDueTodayEmptyBody,
          anchorKey: GuidedTourAnchors.planMyDayTriage,
        ),
      SizedBox(height: tokens.spaceLg),
      if (data.plannedTasks.isNotEmpty)
        _TaskShelf(
          title: l10n.planMyDayYesterdayTitle,
          actionLabel: l10n.planMyDayRescheduleAllAction,
          rowKeyPrefix: 'plan-yesterday',
          limitItems: isCompact,
          maxVisibleItems: maxVisibleItems,
          onAction: () async {
            final choice = await showRescheduleChoiceSheet(
              context,
              title: l10n.planMyDayRescheduleAllTitle,
              subtitle: l10n.planMyDayRescheduleAllSubtitle,
              dayKeyUtc: data.dayKeyUtc,
            );
            if (choice == null || !context.mounted) return;

            switch (choice) {
              case RescheduleQuickChoice(:final date):
                context.read<PlanMyDayBloc>().add(
                  PlanMyDayBulkReschedulePlannedRequested(
                    newDayUtc: date,
                  ),
                );
              case ReschedulePickDateChoice():
                final today = dateOnly(data.dayKeyUtc);
                final picked = await showRescheduleDatePicker(
                  context,
                  initialDate: today.add(const Duration(days: 1)),
                  firstDate: today.add(const Duration(days: 1)),
                  lastDate: DateTime(
                    today.year + 3,
                    today.month,
                    today.day,
                  ),
                );
                if (picked == null || !context.mounted) return;
                context.read<PlanMyDayBloc>().add(
                  PlanMyDayBulkReschedulePlannedRequested(
                    newDayUtc: picked,
                  ),
                );
            }
          },
          rows: _buildTaskRows(
            context,
            tasks: data.plannedTasks,
            selectedTaskIds: data.selectedTaskIds,
            style: ({required bool selected}) =>
                TasklyTaskRowStyle.planPick(selected: selected),
            allowSelection: false,
            onActionPressed: (task) async {
              final choice = await showRescheduleChoiceSheet(
                context,
                title: l10n.planMyDayRescheduleTaskTitle,
                subtitle: l10n.planMyDayRescheduleTaskSubtitle,
                dayKeyUtc: data.dayKeyUtc,
              );
              if (choice == null || !context.mounted) return;

              final bloc = context.read<PlanMyDayBloc>();
              switch (choice) {
                case RescheduleQuickChoice(:final date):
                  bloc.add(
                    PlanMyDayReschedulePlannedTaskRequested(
                      taskId: task.id,
                      newDayUtc: date,
                    ),
                  );
                case ReschedulePickDateChoice():
                  buildTaskOpenEditorHandler(context, task: task)();
              }
            },
            dayKeyUtc: data.dayKeyUtc,
          ),
        )
      else
        _EmptyShelf(
          title: l10n.planMyDayYesterdayTitle,
          body: l10n.planMyDayYesterdayEmptyBody,
        ),
      SizedBox(height: tokens.spaceLg),
      if (data.allRoutines.isNotEmpty)
        _RoutineShelf(
          data: data,
          dayKeyUtc: data.dayKeyUtc,
          rowKeyPrefix: 'plan-routines',
          limitItems: isCompact,
          maxVisibleItems: maxVisibleItems,
          anchorKey: GuidedTourAnchors.planMyDayRoutinesBlock,
        ),
      if (!data.overCapacity && data.valueSuggestionGroups.isNotEmpty) ...[
        SizedBox(height: tokens.spaceLg),
        _SuggestionsShelf(
          data: data,
        ),
      ],
      if (data.overCapacity) ...[
        SizedBox(height: tokens.spaceLg),
        _OverCapacityCard(
          count: data.plannedCount,
          limit: data.dailyLimit,
        ),
      ],
    ];

    if (children.isNotEmpty) {
      final lastIndex = children.length - 1;
      children[lastIndex] = _MeasuredSize(
        key: kPlanMyDayLastChildKey,
        onChanged: (size) {
          if (!mounted) return;
          final nextHeight = size?.height ?? 0;
          if (nextHeight <= 0) return;
          if ((_lastChildHeight ?? 0) == nextHeight) return;
          setState(() => _lastChildHeight = nextHeight);
        },
        child: children[lastIndex],
      );
    }

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            tokens.spaceSm,
            tokens.spaceLg,
            bottomPadding,
          ),
          children: children,
        ),
        _BottomFadeHint(height: fadeHeight),
      ],
    );
  }
}

class _BottomFadeHint extends StatelessWidget {
  const _BottomFadeHint({
    required this.height,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          key: kPlanMyDayBottomFadeKey,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                scheme.surface.withOpacity(0),
                scheme.surface,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MeasuredSize extends SingleChildRenderObjectWidget {
  const _MeasuredSize({
    required this.onChanged,
    required Widget child,
    super.key,
  }) : super(child: child);

  final ValueChanged<Size?> onChanged;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderObject(onChanged);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _MeasureSizeRenderObject renderObject,
  ) {
    renderObject.onChanged = onChanged;
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  _MeasureSizeRenderObject(this.onChanged);

  ValueChanged<Size?> onChanged;
  Size? _oldSize;

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size;
    if (_oldSize == newSize) return;
    _oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) => onChanged(newSize));
  }
}

class _PlanSummaryBar extends StatelessWidget {
  const _PlanSummaryBar({required this.data});

  final PlanMyDayReady data;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

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
              l10n.planMyDaySummaryLabel(data.plannedCount),
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
    final l10n = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: l10n.planMyDayDecreaseLimitTooltip,
          onPressed: () => bloc.add(PlanMyDayDailyLimitChanged(limit - 1)),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text(
          l10n.planMyDayLimitLabel(limit),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        IconButton(
          tooltip: l10n.planMyDayIncreaseLimitTooltip,
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
    required this.rowKeyPrefix,
    required this.limitItems,
    required this.maxVisibleItems,
    this.anchorKey,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final List<TasklyRowSpec> rows;
  final String rowKeyPrefix;
  final bool limitItems;
  final int maxVisibleItems;
  final Key? anchorKey;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final l10n = context.l10n;

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
        ExpandableRowList(
          rows: rows,
          rowKeyPrefix: rowKeyPrefix,
          maxVisible: maxVisibleItems,
          enabled: limitItems,
          showMoreLabelBuilder: l10n.myDayPlanShowMore,
          showFewerLabel: l10n.myDayPlanShowFewer,
        ),
      ],
    );
  }
}

class _RoutineShelf extends StatelessWidget {
  const _RoutineShelf({
    required this.data,
    required this.dayKeyUtc,
    required this.rowKeyPrefix,
    required this.limitItems,
    required this.maxVisibleItems,
    this.anchorKey,
  });

  final PlanMyDayReady data;
  final DateTime dayKeyUtc;
  final String rowKeyPrefix;
  final bool limitItems;
  final int maxVisibleItems;
  final Key? anchorKey;

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

    final l10n = context.l10n;

    return Container(
      key: anchorKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.routinesTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: tokens.spaceSm),
          ExpandableRowList(
            rows: routineRows,
            rowKeyPrefix: rowKeyPrefix,
            maxVisible: maxVisibleItems,
            enabled: limitItems,
            showMoreLabelBuilder: l10n.myDayPlanShowMore,
            showFewerLabel: l10n.myDayPlanShowFewer,
          ),
        ],
      ),
    );
  }
}

class _SuggestionsShelf extends StatelessWidget {
  const _SuggestionsShelf({
    required this.data,
  });

  final PlanMyDayReady data;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final l10n = context.l10n;
    final groups = data.valueSuggestionGroups;
    final suggestions = <Widget>[];

    for (var i = 0; i < groups.length; i += 1) {
      final group = groups[i];
      suggestions.add(
        _ValueSuggestionChip(
          value: group.value,
          showSpotlightBadge: group.isSpotlight,
          anchorKey: i == 0 ? GuidedTourAnchors.planMyDayValuesCard : null,
        ),
      );
      suggestions.add(SizedBox(height: tokens.spaceSm2));
      final rows = _buildTaskRows(
        context,
        tasks: group.tasks,
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
      suggestions.add(
        ExpandableRowList(
          rows: rows,
          rowKeyPrefix: 'plan-suggest-${group.valueId}',
          maxVisible: group.visibleCount,
          enabled: true,
          showMoreLabelBuilder: l10n.myDayPlanShowMore,
          showFewerLabel: l10n.myDayPlanShowFewer,
        ),
      );
      if (i != groups.length - 1) {
        suggestions.add(SizedBox(height: tokens.spaceLg));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.planMyDaySuggestionsTitle,
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
    required this.showSpotlightBadge,
    this.anchorKey,
  });

  final Value value;
  final bool showSpotlightBadge;
  final Key? anchorKey;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final chipData = value.toChipData(context);
    final l10n = context.l10n;

    final chip = Container(
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

    if (!showSpotlightBadge) {
      return chip;
    }

    return Wrap(
      spacing: tokens.spaceXs2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        chip,
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceXs2,
            vertical: tokens.spaceXxs2,
          ),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(tokens.radiusPill),
          ),
          child: Text(
            l10n.myDayPlanSpotlightLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
      ],
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
    final l10n = context.l10n;

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
              l10n.planMyDayOverCapacityMessage(count, limit),
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
              l10n.selectedCountLabel(data.plannedCount),
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
        final labels = _compactDateLabels(context, task: task, today: today);

        final data = buildTaskRowData(
          context,
          task: task,
          tileCapabilities: tileCapabilities,
          overrideStartDateLabel: labels.startLabel,
          overrideDeadlineDateLabel: labels.deadlineLabel,
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
        final labels = _compactDateLabels(context, task: task, today: today);
        final data = buildTaskRowData(
          context,
          task: task,
          tileCapabilities: tileCapabilities,
          overrideStartDateLabel: labels.startLabel,
          overrideDeadlineDateLabel: labels.deadlineLabel,
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
    showProgress: true,
    showScheduleRow: routine.routineType == RoutineType.weeklyFixed,
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

({String? startLabel, String? deadlineLabel}) _compactDateLabels(
  BuildContext context, {
  required Task task,
  required DateTime today,
}) {
  final deadline = task.occurrence?.deadline ?? task.deadlineDate;
  final dateOnlyDeadline = dateOnlyOrNull(deadline);
  String? deadlineLabel;
  if (dateOnlyDeadline != null) {
    if (dateOnlyDeadline.isBefore(today)) {
      deadlineLabel = context.l10n.overdueLabel;
    } else if (dateOnlyDeadline.isAtSameMomentAs(today)) {
      deadlineLabel = context.l10n.dueTodayLabel;
    } else {
      deadlineLabel = MaterialLocalizations.of(context).formatMediumDate(
        deadline!,
      );
    }
  }

  final start = task.occurrence?.date ?? task.startDate;
  final startDay = dateOnlyOrNull(start);
  final startLabel = startDay == null || startDay.isBefore(today)
      ? null
      : MaterialLocalizations.of(context).formatMediumDate(start!);

  return (startLabel: startLabel, deadlineLabel: deadlineLabel);
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
                context.l10n.planMyDaySwapSuggestionTitle,
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: tokens.spaceXs2),
              Text(
                context.l10n.planMyDaySwapSuggestionBody(group.value.name),
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: tokens.spaceSm),
              if (candidates.isEmpty)
                Text(
                  context.l10n.planMyDaySwapSuggestionEmpty,
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
              context.l10n.planMyDayRatingsGateTitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: tokens.spaceSm),
            Text(
              context.l10n.planMyDayRatingsGateBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: tokens.spaceMd),
            FilledButton(
              onPressed: onRateRequested,
              child: Text(context.l10n.rateValuesLabel),
            ),
            SizedBox(height: tokens.spaceSm),
            TextButton(
              onPressed: onSwitchRequested,
              child: Text(context.l10n.switchToBehaviorBasedLabel),
            ),
          ],
        ),
      ),
    );
  }
}
