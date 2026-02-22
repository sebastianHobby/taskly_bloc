import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/features/review/bloc/weekly_review_cubit.dart';
import 'package:taskly_bloc/presentation/features/review/widgets/weekly_value_checkin_sheet.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/plan_my_day_bloc.dart';
import 'package:taskly_bloc/presentation/screens/view/my_day_values_gate.dart';
import 'package:taskly_bloc/presentation/shared/ui/routine_tile_model_mapper.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_bloc/presentation/shared/errors/friendly_error_message.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/widgets/reschedule_picker.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/attention.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/settings.dart' as settings;
import 'package:taskly_domain/time.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';

const Key kPlanMyDayBottomFadeKey = Key('plan_my_day_bottom_fade');
const Key kPlanMyDayLastChildKey = Key('plan_my_day_last_child');
const double _planMyDayTrendDisplayThreshold = 0.3;

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
        onRateRequested: () => _openRatingWizard(
          context,
          settings: data.globalSettings,
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
            style: ({required selected}) =>
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
        ),
      SizedBox(height: tokens.spaceLg),
      if (data.plannedTasks.isNotEmpty)
        _TaskShelf(
          title: l10n.myDayPlannedSectionTitle,
          actionLabel: l10n.planMyDayRescheduleAllAction,
          rowKeyPrefix: 'plan-planned',
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
            style: ({required selected}) =>
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
          title: l10n.myDayPlannedSectionTitle,
          body: l10n.myDayPlanPlannedEmptyBody,
        ),
      SizedBox(height: tokens.spaceLg),
      if (data.scheduledRoutines.isNotEmpty || data.flexibleRoutines.isNotEmpty)
        _RoutineShelf(
          data: data,
          dayKeyUtc: data.dayKeyUtc,
          rowKeyPrefix: 'plan-routines',
          limitItems: isCompact,
          maxVisibleItems: maxVisibleItems,
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
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final List<TasklyRowSpec> rows;
  final String rowKeyPrefix;
  final bool limitItems;
  final int maxVisibleItems;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final l10n = context.l10n;

    return Column(
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
  });

  final PlanMyDayReady data;
  final DateTime dayKeyUtc;
  final String rowKeyPrefix;
  final bool limitItems;
  final int maxVisibleItems;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final l10n = context.l10n;
    final scheduledRows = data.scheduledRoutines
        .map(
          (item) => _buildRoutineRow(
            context,
            data: data,
            item: item,
            allowSelection:
                item.selected && !item.completedToday && item.isEligibleToday,
            dayKeyUtc: dayKeyUtc,
          ),
        )
        .toList(growable: false);
    final flexibleRows = data.flexibleRoutines
        .map(
          (item) => _buildRoutineRow(
            context,
            data: data,
            item: item,
            allowSelection:
                !item.isScheduled &&
                !item.completedToday &&
                item.isEligibleToday,
            dayKeyUtc: dayKeyUtc,
          ),
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.routinesTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: tokens.spaceSm),
        if (scheduledRows.isNotEmpty) ...[
          Text(
            l10n.routinePanelScheduledTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.spaceXs2),
          ExpandableRowList(
            rows: scheduledRows,
            rowKeyPrefix: '$rowKeyPrefix-scheduled',
            maxVisible: maxVisibleItems,
            enabled: limitItems,
            showMoreLabelBuilder: l10n.myDayPlanShowMore,
            showFewerLabel: l10n.myDayPlanShowFewer,
          ),
        ],
        if (scheduledRows.isNotEmpty && flexibleRows.isNotEmpty)
          SizedBox(height: tokens.spaceMd),
        if (flexibleRows.isNotEmpty) ...[
          Text(
            l10n.routinePanelFlexibleTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.spaceXs2),
          ExpandableRowList(
            rows: flexibleRows,
            rowKeyPrefix: '$rowKeyPrefix-flexible',
            maxVisible: maxVisibleItems,
            enabled: limitItems,
            showMoreLabelBuilder: l10n.myDayPlanShowMore,
            showFewerLabel: l10n.myDayPlanShowFewer,
          ),
        ],
      ],
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
          averageRating: group.averageRating,
          trendDelta: group.trendDelta,
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
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.planMyDaySuggestionsTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _ValueSortMenu(data: data),
          ],
        ),
        SizedBox(height: tokens.spaceXs2),
        Text(
          l10n.planMyDaySuggestionsSubtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: tokens.spaceSm),
        ...suggestions,
        if (data.unratedValues.isNotEmpty) ...[
          SizedBox(height: tokens.spaceLg),
          Text(
            l10n.planMyDayNeedsRatingTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: tokens.spaceSm),
          for (final value in data.unratedValues) ...[
            _NeedsRatingRow(
              value: value,
              onRate: () => _openRatingWizard(
                context,
                settings: data.globalSettings,
                initialValueId: value.id,
              ),
            ),
            SizedBox(height: tokens.spaceSm),
          ],
        ],
      ],
    );
  }
}

class _ValueSuggestionChip extends StatelessWidget {
  const _ValueSuggestionChip({
    required this.value,
    required this.averageRating,
    required this.trendDelta,
  });

  final Value value;
  final double? averageRating;
  final double? trendDelta;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final chipData = value.toChipData(context);
    final l10n = context.l10n;

    final chip = Container(
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

    final averageLabel = averageRating == null
        ? l10n.planMyDayAverageLabel(l10n.notAvailableShortLabel)
        : l10n.planMyDayAverageLabel(averageRating!.toStringAsFixed(1));

    final showTrend =
        trendDelta != null &&
        trendDelta!.abs() >= _planMyDayTrendDisplayThreshold;
    final trendLabel = showTrend
        ? (trendDelta!.isNegative
              ? l10n.planMyDayTrendDownLabel(
                  trendDelta!.abs().toStringAsFixed(1),
                )
              : l10n.planMyDayTrendUpLabel(
                  trendDelta!.abs().toStringAsFixed(1),
                ))
        : null;
    final trendColor = trendDelta == null
        ? scheme.onSurfaceVariant
        : trendDelta!.isNegative
        ? scheme.error
        : scheme.primary;

    return Row(
      children: [
        Flexible(child: chip),
        SizedBox(width: tokens.spaceSm),
        Text(
          averageLabel,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (trendLabel != null) ...[
          SizedBox(width: tokens.spaceXs2),
          Text(
            trendLabel,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: trendColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _ValueSortMenu extends StatelessWidget {
  const _ValueSortMenu({required this.data});

  final PlanMyDayReady data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentLabel = _sortLabel(context, data.valueSort);

    return PopupMenuButton<PlanMyDayValueSort>(
      tooltip: l10n.sortMenuTitle,
      onSelected: (value) =>
          context.read<PlanMyDayBloc>().add(PlanMyDayValueSortChanged(value)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: PlanMyDayValueSort.lowestAverage,
          child: Text(l10n.planMyDaySortLowestAverage),
        ),
        PopupMenuItem(
          value: PlanMyDayValueSort.trendingDown,
          child: Text(l10n.planMyDaySortTrendingDown),
        ),
      ],
      child: TextButton.icon(
        onPressed: null,
        icon: const Icon(Icons.sort),
        label: Text(l10n.planMyDaySortByLabel(currentLabel)),
      ),
    );
  }

  String _sortLabel(BuildContext context, PlanMyDayValueSort sort) {
    final l10n = context.l10n;
    return switch (sort) {
      PlanMyDayValueSort.lowestAverage => l10n.planMyDaySortLowestAverage,
      PlanMyDayValueSort.trendingDown => l10n.planMyDaySortTrendingDown,
    };
  }
}

class _NeedsRatingRow extends StatelessWidget {
  const _NeedsRatingRow({
    required this.value,
    required this.onRate,
  });

  final Value value;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final chipData = value.toChipData(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSm,
        vertical: tokens.spaceXs2,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(tokens.radiusPill),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            chipData.icon,
            size: tokens.spaceMd2,
            color: chipData.color,
          ),
          SizedBox(width: tokens.spaceXxs2),
          Expanded(
            child: Text(
              chipData.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
          TextButton(
            onPressed: onRate,
            child: Text(context.l10n.rateValuesLabel),
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
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Column(
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
    showScheduleRow:
        routine.periodType == RoutinePeriodType.week &&
        routine.scheduleMode == RoutineScheduleMode.scheduled,
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
          ? () {
              if (item.isScheduled && item.selected) {
                _showScheduledRoutineDeselectActionSheet(
                  context,
                  item: item,
                  dayKeyUtc: dayKeyUtc,
                );
                return;
              }
              context.read<PlanMyDayBloc>().add(
                PlanMyDayToggleRoutine(
                  routine.id,
                  selected: !item.selected,
                ),
              );
            }
          : null,
    ),
  );
}

enum _ScheduledRoutineAction {
  skipInstance,
  moreOptions,
}

enum _ScheduledRoutineMoreAction {
  skipPeriod,
  pauseUntil,
}

Future<void> _showScheduledRoutineDeselectActionSheet(
  BuildContext context, {
  required PlanMyDayRoutineItem item,
  required DateTime dayKeyUtc,
}) async {
  final action = await showModalBottomSheet<_ScheduledRoutineAction>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.planMyDayRoutineActionSheetTitle),
              subtitle: Text(l10n.planMyDayRoutineActionSheetSubtitle),
            ),
            ListTile(
              leading: const Icon(Icons.skip_next_outlined),
              title: Text(l10n.planMyDayRoutineSkipInstanceAction),
              onTap: () => Navigator.of(
                sheetContext,
              ).pop(_ScheduledRoutineAction.skipInstance),
            ),
            ListTile(
              leading: const Icon(Icons.more_horiz_rounded),
              title: Text(l10n.moreOptionsLabel),
              onTap: () => Navigator.of(
                sheetContext,
              ).pop(_ScheduledRoutineAction.moreOptions),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(l10n.planMyDayRoutineKeepScheduledAction),
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      );
    },
  );

  if (!context.mounted) return;
  final bloc = context.read<PlanMyDayBloc>();
  switch (action) {
    case _ScheduledRoutineAction.skipInstance:
      bloc.add(
        PlanMyDaySkipRoutineInstanceRequested(
          routineId: item.routine.id,
        ),
      );
    case _ScheduledRoutineAction.moreOptions:
      await _showScheduledRoutineMoreOptionsSheet(
        context,
        item: item,
        dayKeyUtc: dayKeyUtc,
      );
    case null:
      return;
  }
}

Future<void> _showScheduledRoutineMoreOptionsSheet(
  BuildContext context, {
  required PlanMyDayRoutineItem item,
  required DateTime dayKeyUtc,
}) async {
  final skipPeriodType = _skipPeriodTypeFor(item.routine.periodType);
  final action = await showModalBottomSheet<_ScheduledRoutineMoreAction>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.planMyDayRoutineActionSheetTitle),
              subtitle: Text(l10n.planMyDayRoutineActionSheetSubtitle),
            ),
            if (skipPeriodType != null)
              ListTile(
                leading: const Icon(Icons.event_busy_outlined),
                title: Text(
                  item.routine.periodType == RoutinePeriodType.month
                      ? l10n.planMyDayRoutineSkipPeriodMonthAction
                      : l10n.planMyDayRoutineSkipPeriodWeekAction,
                ),
                onTap: () => Navigator.of(
                  sheetContext,
                ).pop(_ScheduledRoutineMoreAction.skipPeriod),
              ),
            ListTile(
              leading: const Icon(Icons.pause_circle_outline),
              title: Text(l10n.routinePauseLabel),
              onTap: () => Navigator.of(
                sheetContext,
              ).pop(_ScheduledRoutineMoreAction.pauseUntil),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(l10n.cancelLabel),
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      );
    },
  );

  if (!context.mounted || action == null) return;
  final bloc = context.read<PlanMyDayBloc>();
  switch (action) {
    case _ScheduledRoutineMoreAction.skipPeriod:
      if (skipPeriodType == null) return;
      bloc.add(
        PlanMyDaySkipRoutinePeriodRequested(
          routineId: item.routine.id,
          periodType: skipPeriodType,
          periodKeyUtc: item.snapshot.periodStartUtc,
        ),
      );
    case _ScheduledRoutineMoreAction.pauseUntil:
      final choice = await showRescheduleChoiceSheet(
        context,
        title: context.l10n.routinePauseSheetTitle,
        subtitle: context.l10n.routinePauseSheetSubtitle,
        dayKeyUtc: dayKeyUtc,
      );
      if (choice == null || !context.mounted) return;

      switch (choice) {
        case RescheduleQuickChoice(:final date):
          bloc.add(
            PlanMyDayPauseRoutineRequested(
              routineId: item.routine.id,
              pausedUntilUtc: date,
            ),
          );
        case ReschedulePickDateChoice():
          final today = dateOnly(dayKeyUtc);
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
          bloc.add(
            PlanMyDayPauseRoutineRequested(
              routineId: item.routine.id,
              pausedUntilUtc: picked,
            ),
          );
      }
  }
}

RoutineSkipPeriodType? _skipPeriodTypeFor(RoutinePeriodType periodType) {
  return switch (periodType) {
    RoutinePeriodType.week => RoutineSkipPeriodType.week,
    RoutinePeriodType.month => RoutineSkipPeriodType.month,
    _ => null,
  };
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

Future<void> _openRatingWizard(
  BuildContext context, {
  required settings.GlobalSettings settings,
  String? initialValueId,
}) {
  final config = WeeklyReviewConfig.fromSettings(settings);
  final parentContext = context;

  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) {
        return BlocProvider(
          create: (context) => WeeklyReviewBloc(
            analyticsService: parentContext.read<AnalyticsService>(),
            attentionEngine: parentContext.read<AttentionEngineContract>(),
            valueRepository: parentContext.read<ValueRepositoryContract>(),
            valueRatingsRepository: parentContext
                .read<ValueRatingsRepositoryContract>(),
            valueRatingsWriteService: parentContext
                .read<ValueRatingsWriteService>(),
            routineRepository: parentContext.read<RoutineRepositoryContract>(),
            taskRepository: parentContext.read<TaskRepositoryContract>(),
            nowService: parentContext.read<NowService>(),
          )..add(WeeklyReviewRequested(config)),
          child: WeeklyValueCheckInSheet(
            initialValueId: initialValueId,
            windowWeeks: config.checkInWindowWeeks,
          ),
        );
      },
    ),
  );
}

class _RatingsGate extends StatelessWidget {
  const _RatingsGate({
    required this.onRateRequested,
  });

  final VoidCallback onRateRequested;

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
          ],
        ),
      ),
    );
  }
}
