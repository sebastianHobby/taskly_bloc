import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/utils/task_sorting.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/plan_my_day_bloc.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_sections.dart';

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
                    child: _PlanBody(
                      data: planState,
                      gateState: gateState,
                    ),
                  ),
                  bottomNavigationBar: _PlanBottomBar(
                    data: planState,
                  ),
                ),
              };
            },
          );
        },
      ),
    );
  }
}

class _PlanBody extends StatelessWidget {
  const _PlanBody({
    required this.data,
    required this.gateState,
  });

  final PlanMyDayReady data;
  final MyDayGateState gateState;

  @override
  Widget build(BuildContext context) {
    final suggested = data.suggested;
    final reviewDue = data.reviewDue;
    final reviewStarts = data.reviewStarts;
    final pinnedTasks = data.pinnedTasks;
    final snoozed = data.snoozed;
    final selected = data.selectedTaskIds;
    final completedPicks = data.completedPicks;

    final gate = gateState is MyDayGateLoaded
        ? gateState as MyDayGateLoaded
        : null;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: _PlanCard(
              dayKeyUtc: data.dayKeyUtc,
              suggested: suggested,
              reviewDue: reviewDue,
              reviewStarts: reviewStarts,
              dueWindowDays: data.dueWindowDays,
              showAvailableToStart: data.showAvailableToStart,
              showDueSoon: data.showDueSoon,
              pinnedTasks: pinnedTasks,
              snoozed: snoozed,
              completedPicks: completedPicks,
              selected: selected,
              gateState: gate,
              onAddValues: () => Routing.toScreenKey(context, 'values'),
              onDueWindowDaysChanged: (days) =>
                  context.read<PlanMyDayBloc>().add(
                    PlanMyDayDueWindowDaysChanged(days),
                  ),
              onShowAvailableToStartChanged: (enabled) =>
                  context.read<PlanMyDayBloc>().add(
                    PlanMyDayShowAvailableToStartChanged(enabled),
                  ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
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
    final selectedCount = data.selectedTaskIds.length;
    final isEnabled = selectedCount > 0;
    final label = selectedCount == 0
        ? l10n.myDaySelectItemsToContinueLabel
        : l10n.myDayUpdateMyDayLabel(selectedCount);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
            Expanded(
              child: FilledButton(
                onPressed: !isEnabled
                    ? null
                    : () async {
                        if (!context.mounted) return;

                        context.read<PlanMyDayBloc>().add(
                          const PlanMyDayConfirm(closeOnSuccess: true),
                        );
                      },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatefulWidget {
  const _PlanCard({
    required this.dayKeyUtc,
    required this.suggested,
    required this.reviewDue,
    required this.reviewStarts,
    required this.dueWindowDays,
    required this.showAvailableToStart,
    required this.showDueSoon,
    required this.pinnedTasks,
    required this.snoozed,
    required this.completedPicks,
    required this.selected,
    required this.gateState,
    required this.onAddValues,
    required this.onDueWindowDaysChanged,
    required this.onShowAvailableToStartChanged,
  });

  final DateTime dayKeyUtc;
  final List<Task> suggested;
  final List<Task> reviewDue;
  final List<Task> reviewStarts;
  final int dueWindowDays;
  final bool showAvailableToStart;
  final bool showDueSoon;
  final List<Task> pinnedTasks;
  final List<Task> snoozed;
  final List<Task> completedPicks;
  final Set<String> selected;
  final MyDayGateLoaded? gateState;
  final VoidCallback onAddValues;
  final ValueChanged<int> onDueWindowDaysChanged;
  final ValueChanged<bool> onShowAvailableToStartChanged;

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  final GlobalKey<State<StatefulWidget>> _suggestedHeaderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _valuesExpanded = true;
    _completedExpanded = false;
    _snoozedExpanded = false;
    _pinnedExpanded = true;
  }

  late bool _valuesExpanded;
  late bool _completedExpanded;
  late bool _snoozedExpanded;
  late bool _pinnedExpanded;

  List<TasklyRowSpec> _buildPickerRows(
    BuildContext context, {
    required List<Task> tasks,
    required bool enableSnooze,
    required bool enableSelection,
    required String? selectionPillLabel,
    required String? selectionPillSelectedLabel,
    required String? snoozeTooltip,
    String? completedStatusLabel,
  }) {
    final labels = TasklyTaskRowLabels(
      completedStatusLabel: completedStatusLabel,
      pinnedSemanticLabel: context.l10n.pinnedSemanticLabel,
      selectionPillLabel: selectionPillLabel,
      selectionPillSelectedLabel: selectionPillSelectedLabel,
      snoozeTooltip: snoozeTooltip,
    );

    return tasks
        .map((task) {
          final tileCapabilities = EntityTileCapabilitiesResolver.forTask(task);
          final isSelected = widget.selected.contains(task.id);

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
            deemphasized: data.deemphasized,
            checkboxSemanticLabel: data.checkboxSemanticLabel,
            labels: labels,
            pinned: task.isPinned,
          );

          return TasklyRowSpec.task(
            key: 'myday-plan-${task.id}',
            data: updatedData,
            style: enableSelection
                ? TasklyTaskRowStyle.planPick(selected: isSelected)
                : TasklyTaskRowStyle.picker(selected: isSelected),
            actions: TasklyTaskRowActions(
              onTap: !enableSelection
                  ? null
                  : () => context.read<PlanMyDayBloc>().add(
                      PlanMyDayToggleTask(
                        task.id,
                        selected: !isSelected,
                      ),
                    ),
              onToggleSelected: !enableSelection
                  ? null
                  : () => context.read<PlanMyDayBloc>().add(
                      PlanMyDayToggleTask(
                        task.id,
                        selected: !isSelected,
                      ),
                    ),
              onSnoozeRequested: !enableSnooze
                  ? null
                  : () => _showSnoozeSheet(
                      context,
                      dayKeyUtc: widget.dayKeyUtc,
                      task: task,
                    ),
            ),
          );
        })
        .toList(growable: false);
  }

  List<TasklyRowSpec> _buildPinnedRows(
    BuildContext context, {
    required List<Task> tasks,
  }) {
    return tasks
        .map((task) {
          final tileCapabilities = EntityTileCapabilitiesResolver.forTask(task);

          final data = buildTaskRowData(
            context,
            task: task,
            tileCapabilities: tileCapabilities,
          );

          final labels = TasklyTaskRowLabels(
            pinnedSemanticLabel: context.l10n.pinnedSemanticLabel,
            pinLabel: context.l10n.pinAction,
            pinnedLabel: context.l10n.unpinAction,
          );

          final updatedData = TasklyTaskRowData(
            id: data.id,
            title: data.title,
            completed: data.completed,
            meta: data.meta,
            leadingChip: data.leadingChip,
            secondaryChips: data.secondaryChips,
            deemphasized: data.deemphasized,
            checkboxSemanticLabel: data.checkboxSemanticLabel,
            labels: labels,
            pinned: task.isPinned,
          );

          return TasklyRowSpec.task(
            key: 'myday-plan-pinned-${task.id}',
            data: updatedData,
            style: const TasklyTaskRowStyle.standard(),
            actions: TasklyTaskRowActions(
              onTap: buildTaskOpenEditorHandler(context, task: task),
            ),
          );
        })
        .toList(growable: false);
  }

  Widget? _buildValuesHeaderAction(
    BuildContext context, {
    required bool needsSetup,
  }) {
    final l10n = context.l10n;
    if (needsSetup) {
      return TextButton(
        onPressed: widget.onAddValues,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(l10n.selectValuesHint),
      );
    }

    return TextButton(
      onPressed: () => Routing.toScreenKey(context, 'settings'),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(l10n.myDayCustomizeSuggestionsAction),
    );
  }

  Future<void> _openTimeSensitiveSheet(
    BuildContext context, {
    required List<Task> due,
    required List<Task> planned,
  }) {
    if (due.isEmpty && planned.isEmpty) {
      return Future.value();
    }

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final l10n = sheetContext.l10n;
        final theme = Theme.of(sheetContext);
        final cs = theme.colorScheme;

        final dueRows = _buildPickerRows(
          sheetContext,
          tasks: due,
          enableSnooze: true,
          enableSelection: true,
          selectionPillLabel: l10n.myDayAddToMyDayAction,
          selectionPillSelectedLabel: l10n.myDayAddedLabel,
          snoozeTooltip: l10n.myDaySnoozeAction,
        );
        final plannedRows = _buildPickerRows(
          sheetContext,
          tasks: planned,
          enableSnooze: true,
          enableSelection: true,
          selectionPillLabel: l10n.myDayAddToMyDayAction,
          selectionPillSelectedLabel: l10n.myDayAddedLabel,
          snoozeTooltip: l10n.myDaySnoozeAction,
        );

        final hasDue = dueRows.isNotEmpty;
        final hasPlanned = plannedRows.isNotEmpty;

        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, controller) {
              return ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  Text(
                    l10n.myDayWhatsWaitingSectionTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.myDayTimeSensitiveSheetSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                  if (!hasDue && !hasPlanned) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.myDayPlanCaughtUpTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.myDayPlanReviewAvailableAboveSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (hasDue) ...[
                    const SizedBox(height: 16),
                    _SubsectionHeader(
                      icon: Icons.warning_rounded,
                      title: l10n.myDayDueSoonLabel,
                      count: dueRows.length,
                      iconColor: cs.error,
                    ),
                    TasklyFeedRenderer.buildSection(
                      TasklySectionSpec.standardList(
                        id: 'myday-plan-sheet-due',
                        rows: dueRows,
                      ),
                    ),
                  ],
                  if (hasPlanned) ...[
                    const SizedBox(height: 16),
                    _SubsectionHeader(
                      icon: Icons.event_note_rounded,
                      title: l10n.myDayPlannedSectionTitle,
                      count: plannedRows.length,
                      iconColor: cs.secondary,
                    ),
                    TasklyFeedRenderer.buildSection(
                      TasklySectionSpec.standardList(
                        id: 'myday-plan-sheet-planned',
                        rows: plannedRows,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final suggestedCount = widget.suggested.length;
    final completedCount = widget.completedPicks.length;
    final snoozedCount = widget.snoozed.length;

    final needsSetup =
        widget.gateState != null && widget.gateState!.needsValuesSetup;

    final due = widget.showDueSoon
        ? sortTasksByDeadline(
            widget.reviewDue,
            today: dateOnly(widget.dayKeyUtc),
          )
        : const <Task>[];
    final startsRaw = widget.showAvailableToStart
        ? widget.reviewStarts
        : const <Task>[];
    final starts = sortTasksByStartDate(startsRaw);

    final valuesRows = _buildPickerRows(
      context,
      tasks: widget.suggested,
      enableSnooze: true,
      enableSelection: true,
      selectionPillLabel: l10n.myDayAddToMyDayAction,
      selectionPillSelectedLabel: l10n.myDayAddedLabel,
      snoozeTooltip: l10n.myDaySnoozeAction,
    );

    final pinnedSorted = sortTasksByDeadlineThenStartThenName(
      widget.pinnedTasks,
      today: dateOnly(widget.dayKeyUtc),
    );
    final pinnedRows = _buildPinnedRows(
      context,
      tasks: pinnedSorted,
    );

    final completedRows = _buildPickerRows(
      context,
      tasks: widget.completedPicks,
      enableSnooze: false,
      enableSelection: false,
      selectionPillLabel: null,
      selectionPillSelectedLabel: null,
      snoozeTooltip: null,
      completedStatusLabel: l10n.projectCompletedLabel,
    );

    final hasTimeSensitive = due.isNotEmpty || starts.isNotEmpty;

    return Column(
      children: [
        if (hasTimeSensitive)
          _TimeSensitiveBanner(
            dueCount: due.length,
            plannedCount: starts.length,
            onReview: () => _openTimeSensitiveSheet(
              context,
              due: due,
              planned: starts,
            ),
          ),
        TasklyMyDaySectionStack(
          pinned: pinnedRows.isEmpty
              ? null
              : TasklyMyDaySectionConfig(
                  title: l10n.pinnedTasksSection,
                  icon: Icons.push_pin_rounded,
                  count: pinnedSorted.length,
                  showCount: false,
                  iconBadge: false,
                  expanded: _pinnedExpanded,
                  onToggleExpanded: () =>
                      setState(() => _pinnedExpanded = !_pinnedExpanded),
                  list: TasklyMyDaySectionList(
                    id: 'myday-plan-pinned',
                    rows: pinnedRows,
                  ),
                  emptyState: TasklyMyDayEmptyState(
                    title: l10n.pinnedTasksSection,
                    description: l10n.myDayPinnedSectionSubtitle,
                  ),
                  showEmpty: false,
                ),
          valuesAligned: TasklyMyDaySectionConfig(
            headerKey: _suggestedHeaderKey,
            title: l10n.myDayWhatMattersSectionTitle,
            icon: Icons.explore_rounded,
            count: suggestedCount,
            showCount: false,
            subtitle: l10n.myDayWhatMattersSubtitle,
            iconBadge: true,
            expanded: _valuesExpanded,
            onToggleExpanded: () =>
                setState(() => _valuesExpanded = !_valuesExpanded),
            action: _buildValuesHeaderAction(
              context,
              needsSetup: needsSetup,
            ),
            emptyState: TasklyMyDayEmptyState(
              title: l10n.myDayPlanValuesEmptyTitle,
              description: l10n.myDayPlanValuesEmptyBody,
            ),
            showEmpty: !needsSetup,
            list: TasklyMyDaySectionList(
              id: 'myday-plan-values',
              rows: valuesRows,
            ),
          ),
          completed: TasklyMyDaySectionConfig(
            title: l10n.myDayCompletedSectionTitle,
            icon: Icons.check_circle_outline,
            count: completedCount,
            showCount: false,
            iconBadge: false,
            expanded: _completedExpanded,
            onToggleExpanded: () =>
                setState(() => _completedExpanded = !_completedExpanded),
            list: TasklyMyDaySectionList(
              id: 'myday-plan-completed',
              rows: completedRows,
            ),
            emptyState: TasklyMyDayEmptyState(
              title: l10n.myDayCompletedSectionTitle,
              description: l10n.myDayCompletedSectionEmptyBody,
            ),
            showEmpty: false,
          ),
        ),
        if (snoozedCount > 0) ...[
          if (!_snoozedExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _snoozedExpanded = true),
                  child: Text(
                    context.l10n.myDaySnoozedCollapsedTitle(snoozedCount),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          else ...[
            _SubsectionHeader(
              icon: Icons.snooze_rounded,
              title: context.l10n.myDaySnoozedSectionTitle,
              count: snoozedCount,
              action: TextButton(
                onPressed: () => setState(() => _snoozedExpanded = false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(context.l10n.myDayHideLabel),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final task in widget.snoozed)
                    _SnoozedTaskRow(
                      dayKeyUtc: widget.dayKeyUtc,
                      task: task,
                    ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _TimeSensitiveBanner extends StatelessWidget {
  const _TimeSensitiveBanner({
    required this.dueCount,
    required this.plannedCount,
    required this.onReview,
  });

  final int dueCount;
  final int plannedCount;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;
    final tokens = TasklyEntityTileTheme.of(context);

    final title = dueCount > 0 && plannedCount > 0
        ? l10n.myDayTimeSensitiveBannerBoth(dueCount, plannedCount)
        : dueCount > 0
        ? l10n.myDayTimeSensitiveBannerDueOnly(dueCount)
        : l10n.myDayTimeSensitiveBannerPlannedOnly(plannedCount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Material(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens.taskRadius),
        child: InkWell(
          onTap: onReview,
          borderRadius: BorderRadius.circular(tokens.taskRadius),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 18,
                  color: cs.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.myDayTimeSensitiveBannerHelper,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onReview,
                  child: Text(l10n.myDayAlertBannerReview),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _SnoozedMenuAction { unsnooze, change }

class _SnoozedTaskRow extends StatelessWidget {
  const _SnoozedTaskRow({required this.dayKeyUtc, required this.task});

  final DateTime dayKeyUtc;
  final Task task;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final localizations = MaterialLocalizations.of(context);
    final untilUtc = task.myDaySnoozedUntilUtc;

    final subtitle = untilUtc == null
        ? l10n.myDaySnoozedRowSubtitle
        : l10n.myDaySnoozedUntilRowSubtitle(
            localizations.formatMediumDate(untilUtc.toLocal()),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          dense: true,
          title: Text(
            task.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: PopupMenuButton<_SnoozedMenuAction>(
            tooltip: l10n.myDaySnoozedOptionsTooltip,
            onSelected: (action) async {
              switch (action) {
                case _SnoozedMenuAction.unsnooze:
                  context.read<PlanMyDayBloc>().add(
                    PlanMyDaySnoozeTaskRequested(
                      taskId: task.id,
                      untilUtc: null,
                    ),
                  );
                case _SnoozedMenuAction.change:
                  await _showSnoozeSheet(
                    context,
                    dayKeyUtc: dayKeyUtc,
                    task: task,
                  );
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: _SnoozedMenuAction.unsnooze,
                  child: Text(l10n.myDayUnsnoozeAction),
                ),
                PopupMenuItem(
                  value: _SnoozedMenuAction.change,
                  child: Text(l10n.myDayChangeSnoozeAction),
                ),
              ];
            },
          ),
        ),
      ),
    );
  }
}

class _SubsectionHeader extends StatelessWidget {
  const _SubsectionHeader({
    required this.icon,
    required this.title,
    required this.count,
    this.iconColor,
    this.action,
  });
  final IconData icon;
  final String title;
  final int count;
  final Color? iconColor;

  /// Optional trailing action widget (e.g. overflow menu).
  ///
  /// When provided, this is rendered instead of [actionLabel]/[onAction].
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor ?? cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ...?(action == null ? null : [action!]),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            color: cs.outlineVariant.withOpacity(0.5),
          ),
        ],
      ),
    );
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
