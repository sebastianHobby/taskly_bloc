import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/plan_my_day_bloc.dart';
import 'package:taskly_bloc/presentation/screens/view/my_day_values_gate.dart';
import 'package:taskly_bloc/presentation/features/review/view/weekly_review_modal.dart';
import 'package:taskly_bloc/presentation/shared/ui/routine_tile_model_mapper.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/guided_tour_anchors.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/task_sorting.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

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

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Exit without saving?'),
          content: const Text(
            "Your picks won't be saved to today's plan.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Stay'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
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
                    leading: planState.currentStepIndex == 0
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () => context.read<PlanMyDayBloc>().add(
                              const PlanMyDayStepBackRequested(),
                            ),
                          ),
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
    final stepSubtitle = _stepSubtitle(context, data.currentStep);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            TasklyTokens.of(context).spaceLg,
            TasklyTokens.of(context).spaceSm,
            TasklyTokens.of(context).spaceLg,
            TasklyTokens.of(context).spaceSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stepTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: TasklyTokens.of(context).spaceSm),
              Text(
                stepSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              final offsetTween = Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              );
              return SlideTransition(
                position: animation.drive(offsetTween),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: switch (data.currentStep) {
              PlanMyDayStep.valuesStep => _PlanValuesStep(
                key: const ValueKey('plan-step-values'),
                data: data,
                gateState: gateState,
              ),
              PlanMyDayStep.routines => _PlanRoutinesStep(
                key: const ValueKey('plan-step-routines'),
                data: data,
              ),
              PlanMyDayStep.triage => _PlanTriageStep(
                key: const ValueKey('plan-step-triage'),
                data: data,
              ),
              PlanMyDayStep.summary => _PlanSummaryStep(
                key: const ValueKey('plan-step-summary'),
                data: data,
              ),
            },
          ),
        ),
      ],
    );
  }
}

class _PlanValuesStep extends StatelessWidget {
  const _PlanValuesStep({
    required this.data,
    required this.gateState,
    super.key,
  });

  final PlanMyDayReady data;
  final MyDayGateState gateState;

  @override
  Widget build(BuildContext context) {
    final groups = data.valueSuggestionGroups;
    final l10n = context.l10n;
    final usesRatings = data.suggestionSignal == SuggestionSignal.ratingsBased;
    final needsSetup =
        data.requiresValueSetup &&
        gateState is MyDayGateLoaded &&
        (gateState as MyDayGateLoaded).needsValuesSetup;

    if (needsSetup) {
      return const MyDayValuesGate();
    }

    if (data.requiresRatings) {
      return _RatingsGate(
        onRateRequested: () => showWeeklyReviewModal(
          context,
          settings: data.globalSettings,
        ),
        onSwitchRequested: () => context.read<PlanMyDayBloc>().add(
          const PlanMyDaySwitchToBehaviorSuggestionsRequested(),
        ),
      );
    }

    if (groups.isEmpty) {
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

    return ListView(
      padding: EdgeInsets.fromLTRB(
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceMd,
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceXl,
      ),
      children: [
        Row(
          children: [
            Tooltip(
              message: usesRatings
                  ? 'Suggestions are based on your weekly value ratings.'
                  : 'Suggestions are ranked by your values and priorities. '
                        'Recent completions shift what rises next.',
              triggerMode: TooltipTriggerMode.tap,
              child: IconButton(
                tooltip: l10n.myDayWhySuggestedSemanticLabel,
                onPressed: () {},
                icon: const Icon(Icons.info_outline),
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Sort',
              onPressed: () => _showSortSheet(context),
              icon: const Icon(Icons.sort_rounded),
            ),
          ],
        ),
        if (usesRatings) ...[
          Text(
            'Based on your ratings',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: TasklyTokens.of(context).spaceSm),
        ],
        SizedBox(height: TasklyTokens.of(context).spaceSm),
        for (var i = 0; i < groups.length; i += 1) ...[
          _ValueSuggestionCard(
            data: data,
            group: groups[i],
            anchorKey: i == 0 ? GuidedTourAnchors.planMyDayValuesCard : null,
          ),
          SizedBox(height: TasklyTokens.of(context).spaceLg),
        ],
      ],
    );
  }

  Future<void> _showSortSheet(BuildContext context) async {
    final currentSort = data.valueSort;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text(
                  'Sort suggestions',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              for (final option in PlanMyDayValueSort.values)
                RadioListTile<PlanMyDayValueSort>(
                  value: option,
                  groupValue: currentSort,
                  title: Text(_sortLabel(option)),
                  onChanged: (value) {
                    if (value == null) return;
                    context.read<PlanMyDayBloc>().add(
                      PlanMyDayValueSortChanged(value),
                    );
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  String _sortLabel(PlanMyDayValueSort sort) {
    return switch (sort) {
      PlanMyDayValueSort.attentionFirst => 'Attention first',
      PlanMyDayValueSort.priorityFirst => 'Priority first',
      PlanMyDayValueSort.mostSuggested => 'Most suggested',
      PlanMyDayValueSort.alphabetical => 'A-Z',
    };
  }
}

class _ValueSuggestionCard extends StatelessWidget {
  const _ValueSuggestionCard({
    required this.data,
    required this.group,
    this.anchorKey,
  });

  final PlanMyDayReady data;
  final PlanMyDayValueSuggestionGroup group;
  final Key? anchorKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);
    final l10n = context.l10n;

    final value = group.value;
    final totalCount = group.totalCount;
    final visibleCount = group.visibleCount.clamp(0, totalCount);
    final remaining = (totalCount - visibleCount).clamp(0, totalCount);
    final tasks = group.tasks.take(visibleCount).toList(growable: false);
    final needsAttention = group.attentionNeeded;
    final priorityLabel = _priorityLabel(l10n, value.priority);

    return Container(
      key: anchorKey,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.06),
            blurRadius: tokens.cardShadowBlur,
            offset: tokens.cardShadowOffset,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _ValueIconAvatar(
                  icon: value.iconName ?? 'star',
                  colorHex: value.color,
                ),
                SizedBox(width: tokens.spaceSm2),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          value.name,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(width: tokens.spaceSm),
                      _PriorityDot(
                        color: _priorityColor(scheme, value.priority),
                      ),
                      SizedBox(width: tokens.spaceXs2),
                      Text(
                        priorityLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => context.read<PlanMyDayBloc>().add(
                    PlanMyDayValueToggleExpanded(group.valueId),
                  ),
                  icon: Icon(
                    group.expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                  ),
                ),
              ],
            ),
            if (needsAttention) ...[
              SizedBox(height: tokens.spaceXs2),
              Row(
                children: [
                  Icon(
                    Icons.priority_high_rounded,
                    size: tokens.spaceMd2,
                    color: scheme.error,
                  ),
                  SizedBox(width: tokens.spaceXs2),
                  Text(
                    'Needs attention',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: tokens.spaceXs2),
                  Tooltip(
                    message: "Completions are behind this value's priority.",
                    triggerMode: TooltipTriggerMode.tap,
                    child: Icon(
                      Icons.info_outline,
                      size: tokens.spaceMd2,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: tokens.spaceSm),
            if (group.expanded) ...[
              if (tasks.isNotEmpty)
                TasklyFeedRenderer.buildSection(
                  TasklySectionSpec.standardList(
                    id: 'plan-values-',
                    rows: _buildTaskRows(
                      context,
                      tasks: tasks,
                      selectedTaskIds: data.selectedTaskIds,
                      enableSnooze: true,
                      dayKeyUtc: data.dayKeyUtc,
                      style: TasklyTaskRowStyle.planPick,
                      keyPrefix: 'plan-task-',
                    ),
                  ),
                ),
              if (remaining > 0) ...[
                SizedBox(height: tokens.spaceSm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => context.read<PlanMyDayBloc>().add(
                      PlanMyDayValueShowMore(group.valueId),
                    ),
                    child: Text('Show more ()'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _priorityLabel(AppLocalizations l10n, ValuePriority priority) {
    final priorityLabel = switch (priority) {
      ValuePriority.high => l10n.valuePriorityHighLabel,
      ValuePriority.medium => l10n.valuePriorityMediumLabel,
      ValuePriority.low => l10n.valuePriorityLowLabel,
    };
    return '$priorityLabel ${l10n.priorityLabel}';
  }

  Color _priorityColor(ColorScheme scheme, ValuePriority priority) {
    return switch (priority) {
      ValuePriority.high => scheme.error,
      ValuePriority.medium => scheme.tertiary,
      ValuePriority.low => scheme.onSurfaceVariant.withOpacity(0.6),
    };
  }
}

class _PriorityDot extends StatelessWidget {
  const _PriorityDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = TasklyTokens.of(context).spaceXs2;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ValueIconAvatar extends StatelessWidget {
  const _ValueIconAvatar({
    required this.icon,
    required this.colorHex,
  });

  final String icon;
  final String? colorHex;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final color = ColorUtils.valueColorForTheme(context, colorHex);
    final iconData = getIconDataFromName(icon) ?? Icons.star;
    return Container(
      width: tokens.spaceXl,
      height: tokens.spaceXl,
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: tokens.spaceLg),
    );
  }
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLg,
          tokens.spaceLg,
          tokens.spaceLg,
          tokens.spaceXl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_graph_rounded,
              size: 48,
              color: scheme.primary,
            ),
            SizedBox(height: tokens.spaceSm),
            Text(
              'Rate your values to unlock suggestions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: tokens.spaceSm),
            Text(
              'Weekly ratings keep suggestions aligned with what matters most.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: tokens.spaceLg),
            FilledButton(
              onPressed: onRateRequested,
              child: const Text('Rate values'),
            ),
            SizedBox(height: tokens.spaceSm),
            OutlinedButton(
              onPressed: onSwitchRequested,
              child: const Text('Switch to behavior-based suggestions'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanRoutinesStep extends StatefulWidget {
  const _PlanRoutinesStep({required this.data, super.key});

  final PlanMyDayReady data;

  @override
  State<_PlanRoutinesStep> createState() => _PlanRoutinesStepState();
}

class _PlanRoutinesStepState extends State<_PlanRoutinesStep> {
  static const int _scheduledLimit = 3;
  static const int _flexibleLimit = 4;
  var _showAllScheduled = false;
  var _showAllFlexible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheduled = widget.data.scheduledRoutines;
    final flexible = widget.data.flexibleRoutines;
    final scheduledVisible = _showAllScheduled
        ? scheduled
        : scheduled.take(_scheduledLimit).toList(growable: false);
    final flexibleVisible = _showAllFlexible
        ? flexible
        : flexible.take(_flexibleLimit).toList(growable: false);

    final rows = <TasklyRowSpec>[];

    if (scheduled.isNotEmpty) {
      rows.add(
        TasklyRowSpec.header(
          key: 'plan-routines-scheduled-header',
          title: l10n.routinePanelScheduledTitle,
          trailingLabel: '${scheduled.length}',
          anchorKey: GuidedTourAnchors.planMyDayScheduledRoutines,
        ),
      );
      rows.addAll(
        scheduledVisible.map(
          (item) => _buildRoutineRow(
            context,
            data: widget.data,
            item: item,
            primaryActionLabel: l10n.routinePrimaryActionLabel,
          ),
        ),
      );
      if (!_showAllScheduled && scheduled.length > _scheduledLimit) {
        final remaining = scheduled.length - _scheduledLimit;
        rows.add(
          TasklyRowSpec.inlineAction(
            key: 'plan-routines-scheduled-show-more',
            label: 'Show more ($remaining)',
            onTap: () => setState(() => _showAllScheduled = true),
          ),
        );
      }
    }

    if (flexible.isNotEmpty) {
      if (rows.isNotEmpty) {
        rows.add(
          TasklyRowSpec.divider(
            key: 'plan-routines-divider',
          ),
        );
      }
      rows.add(
        TasklyRowSpec.header(
          key: 'plan-routines-flexible-header',
          title: l10n.routinePanelFlexibleTitle,
          trailingLabel: '${flexible.length}',
          anchorKey: GuidedTourAnchors.planMyDayFlexibleRoutines,
        ),
      );
      rows.addAll(
        flexibleVisible.map(
          (item) => _buildRoutineRow(
            context,
            data: widget.data,
            item: item,
            primaryActionLabel: l10n.routinePrimaryActionLabel,
          ),
        ),
      );
      if (!_showAllFlexible && flexible.length > _flexibleLimit) {
        final remaining = flexible.length - _flexibleLimit;
        rows.add(
          TasklyRowSpec.inlineAction(
            key: 'plan-routines-flexible-show-more',
            label: 'Show more ($remaining)',
            onTap: () => setState(() => _showAllFlexible = true),
          ),
        );
      }
    }

    return ListView(
      key: GuidedTourAnchors.planMyDayTriage,
      padding: EdgeInsets.fromLTRB(
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceMd,
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceXl,
      ),
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

class _PlanTriageStep extends StatefulWidget {
  const _PlanTriageStep({required this.data, super.key});

  final PlanMyDayReady data;

  @override
  State<_PlanTriageStep> createState() => _PlanTriageStepState();
}

class _PlanTriageStepState extends State<_PlanTriageStep> {
  static const int _dueLimit = 3;
  static const int _plannedLimit = 3;
  var _showAllDue = false;
  var _showAllPlanned = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dayKey = dateOnly(widget.data.dayKeyUtc);
    final due = sortTasksByDeadline(
      widget.data.triageDue,
      today: dayKey,
    );
    final planned = sortTasksByStartDate(widget.data.triageStarts);

    final visibleDue = _showAllDue
        ? due
        : due.take(_dueLimit).toList(growable: false);
    final visiblePlanned = _showAllPlanned
        ? planned
        : planned.take(_plannedLimit).toList(growable: false);

    final rows = <TasklyRowSpec>[
      TasklyRowSpec.header(
        key: 'plan-triage-due-header',
        title: l10n.myDayDueSoonLabel,
        trailingLabel: due.isEmpty ? null : '${due.length}',
      ),
      if (due.isNotEmpty)
        ..._buildTaskRows(
          context,
          tasks: visibleDue,
          selectedTaskIds: widget.data.selectedTaskIds,
          enableSnooze: true,
          dayKeyUtc: widget.data.dayKeyUtc,
          style: TasklyTaskRowStyle.planPick,
          keyPrefix: 'plan-task-due',
        ),
      if (!_showAllDue && due.length > _dueLimit)
        TasklyRowSpec.inlineAction(
          key: 'plan-triage-due-show-more',
          label: 'Show more (${due.length - _dueLimit})',
          onTap: () => setState(() => _showAllDue = true),
        ),
      TasklyRowSpec.header(
        key: 'plan-triage-planned-header',
        title: l10n.myDayPlannedSectionTitle,
        trailingLabel: planned.isEmpty ? null : '${planned.length}',
      ),
      if (planned.isNotEmpty)
        ..._buildTaskRows(
          context,
          tasks: visiblePlanned,
          selectedTaskIds: widget.data.selectedTaskIds,
          enableSnooze: true,
          dayKeyUtc: widget.data.dayKeyUtc,
          style: TasklyTaskRowStyle.planPick,
          keyPrefix: 'plan-task-starts',
        ),
      if (!_showAllPlanned && planned.length > _plannedLimit)
        TasklyRowSpec.inlineAction(
          key: 'plan-triage-planned-show-more',
          label: 'Show more (${planned.length - _plannedLimit})',
          onTap: () => setState(() => _showAllPlanned = true),
        ),
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceMd,
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceXl,
      ),
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
  const _PlanSummaryStep({required this.data, super.key});

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
      padding: EdgeInsets.fromLTRB(
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceMd,
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceXl,
      ),
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
    final totalSelected =
        data.selectedTaskIds.length + data.selectedRoutineIds.length;
    final isSummary = data.currentStep == PlanMyDayStep.summary;

    final nextStep = !isSummary
        ? data.steps[data.currentStepIndex + 1]
        : PlanMyDayStep.summary;

    final primaryLabel = isSummary
        ? (data.needsPlan ? 'Confirm plan' : 'Update plan')
        : 'Next: ${_stepTitle(context, nextStep)}';

    final primaryEnabled = !isSummary || totalSelected > 0;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          TasklyTokens.of(context).spaceLg,
          TasklyTokens.of(context).spaceSm2,
          TasklyTokens.of(context).spaceLg,
          TasklyTokens.of(context).spaceLg,
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
              'Step ${data.currentStepIndex + 1} of ${data.steps.length} - '
              '$totalSelected selected',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: TasklyTokens.of(context).spaceSm),
            FilledButton(
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
                  borderRadius: BorderRadius.circular(
                    TasklyTokens.of(context).radiusMd,
                  ),
                ),
              ),
              child: Text(primaryLabel),
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

String _stepSubtitle(BuildContext context, PlanMyDayStep step) {
  return switch (step) {
    PlanMyDayStep.valuesStep => 'Then choose value-aligned suggestions.',
    PlanMyDayStep.routines => 'Add optional routines for today.',
    PlanMyDayStep.triage => "Start with what's time-sensitive.",
    PlanMyDayStep.summary => "Confirm today's plan.",
  };
}

List<TasklyRowSpec> _buildTaskRows(
  BuildContext context, {
  required List<Task> tasks,
  required Set<String> selectedTaskIds,
  required bool enableSnooze,
  required DateTime dayKeyUtc,
  required TasklyTaskRowStyle Function({required bool selected}) style,
  String keyPrefix = 'plan-task',
}) {
  final l10n = context.l10n;
  const badges = <TasklyBadgeData>[];

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
          key: '$keyPrefix-${task.id}',
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

  final actionLabel = item.completedToday
      ? context.l10n.doneLabel
      : primaryActionLabel;
  final labels = TasklyRoutineRowLabels(
    primaryActionLabel: actionLabel,
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
    showScheduleRow: routine.routineType == RoutineType.weeklyFixed,
    dayKeyUtc: data.dayKeyUtc,
    completionsInPeriod: item.completionsInPeriod,
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
    ),
  );
}

List<TasklyRowSpec> _buildSummaryRows(
  BuildContext context, {
  required PlanMyDayReady data,
}) {
  final rows = <TasklyRowSpec>[];

  final selectedTaskIds = data.selectedTaskIds;
  final selectedRoutineIds = data.selectedRoutineIds;

  final suggestedIds = data.suggested.map((task) => task.id).toSet();
  final dueIds = data.triageDue.map((task) => task.id).toSet();
  final startsIds = data.triageStarts.map((task) => task.id).toSet();
  final routineItemsById = {
    for (final item in data.allRoutines) item.routine.id: item,
  };

  final orderedRoutineIds = _orderedSelectedRoutineIds(data);

  if (data.steps.contains(PlanMyDayStep.triage)) {
    final triageIds = <String>{
      for (final id in dueIds)
        if (selectedTaskIds.contains(id)) id,
      for (final id in startsIds)
        if (selectedTaskIds.contains(id) && !suggestedIds.contains(id)) id,
    };

    final dueSorted = sortTasksByDeadline(
      data.triageDue.where((t) => triageIds.contains(t.id)).toList(),
      today: dateOnly(data.dayKeyUtc),
    );
    final startsSorted = sortTasksByStartDate(
      data.triageStarts.where((t) => triageIds.contains(t.id)).toList(),
    );
    final triageOrdered = [
      ...dueSorted,
      for (final task in startsSorted)
        if (!dueIds.contains(task.id)) task,
    ];

    rows.add(
      TasklyRowSpec.header(
        key: 'plan-summary-triage-header',
        title: _stepTitle(context, PlanMyDayStep.triage),
        trailingLabel: triageOrdered.isEmpty ? null : '${triageOrdered.length}',
      ),
    );
    rows.add(
      TasklyRowSpec.subheader(
        key: 'plan-summary-triage-subtitle',
        title: _stepSubtitle(context, PlanMyDayStep.triage),
      ),
    );
    rows.add(
      TasklyRowSpec.divider(
        key: 'plan-summary-triage-divider',
      ),
    );
    if (triageOrdered.isEmpty) {
      rows.add(
        TasklyRowSpec.subheader(
          key: 'plan-summary-triage-empty',
          title: 'Nothing to pick here today.',
        ),
      );
    } else {
      rows.addAll(
        _buildTaskRows(
          context,
          tasks: triageOrdered,
          selectedTaskIds: selectedTaskIds,
          enableSnooze: true,
          dayKeyUtc: data.dayKeyUtc,
          style: TasklyTaskRowStyle.planPick,
          keyPrefix: 'plan-summary-triage',
        ),
      );
    }
  }

  if (data.steps.contains(PlanMyDayStep.routines)) {
    final routineRows = <TasklyRowSpec>[
      for (final routineId in orderedRoutineIds)
        if (selectedRoutineIds.contains(routineId))
          if (routineItemsById[routineId] != null)
            _buildRoutineRow(
              context,
              data: data,
              item: routineItemsById[routineId]!,
              primaryActionLabel: context.l10n.myDayRemoveAction,
              allowRemove: true,
            ),
    ];

    rows.add(
      TasklyRowSpec.header(
        key: 'plan-summary-routines-header',
        title: _stepTitle(context, PlanMyDayStep.routines),
        trailingLabel: routineRows.isEmpty ? null : '${routineRows.length}',
      ),
    );
    rows.add(
      TasklyRowSpec.subheader(
        key: 'plan-summary-routines-subtitle',
        title: _stepSubtitle(context, PlanMyDayStep.routines),
      ),
    );
    rows.add(
      TasklyRowSpec.divider(
        key: 'plan-summary-routines-divider',
      ),
    );
    if (routineRows.isEmpty) {
      rows.add(
        TasklyRowSpec.subheader(
          key: 'plan-summary-routines-empty',
          title: 'Nothing to pick here today.',
        ),
      );
    } else {
      rows.addAll(routineRows);
    }
  }

  if (data.steps.contains(PlanMyDayStep.valuesStep)) {
    final suggestedOrdered = [
      for (final task in data.suggested)
        if (selectedTaskIds.contains(task.id)) task,
    ];

    rows.add(
      TasklyRowSpec.header(
        key: 'plan-summary-values-header',
        title: _stepTitle(context, PlanMyDayStep.valuesStep),
        trailingLabel: suggestedOrdered.isEmpty
            ? null
            : '${suggestedOrdered.length}',
      ),
    );
    rows.add(
      TasklyRowSpec.subheader(
        key: 'plan-summary-values-subtitle',
        title: _stepSubtitle(context, PlanMyDayStep.valuesStep),
      ),
    );
    rows.add(
      TasklyRowSpec.divider(
        key: 'plan-summary-values-divider',
      ),
    );
    if (suggestedOrdered.isEmpty) {
      rows.add(
        TasklyRowSpec.subheader(
          key: 'plan-summary-values-empty',
          title: 'Nothing to pick here today.',
        ),
      );
    } else {
      rows.addAll(
        _buildTaskRows(
          context,
          tasks: suggestedOrdered,
          selectedTaskIds: selectedTaskIds,
          enableSnooze: true,
          dayKeyUtc: data.dayKeyUtc,
          style: TasklyTaskRowStyle.planPick,
          keyPrefix: 'plan-summary-values',
        ),
      );
    }
  }

  return rows;
}

List<String> _orderedSelectedRoutineIds(PlanMyDayReady data) {
  final selected = data.selectedRoutineIds;
  final ordered = <String>[];
  for (final item in data.allRoutines) {
    if (selected.contains(item.routine.id)) {
      ordered.add(item.routine.id);
    }
  }
  for (final routineId in selected) {
    if (!ordered.contains(routineId)) ordered.add(routineId);
  }
  return ordered;
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
