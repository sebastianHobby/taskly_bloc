import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/utils/task_sorting.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_ritual_bloc.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_sections.dart';

enum MyDayRitualWizardInitialSection { suggested, due, starts }

class MyDayRitualWizardPage extends StatelessWidget {
  const MyDayRitualWizardPage({
    super.key,
    this.allowClose = false,
    this.initialSection,
    this.onCloseRequested,
  });

  final bool allowClose;
  final MyDayRitualWizardInitialSection? initialSection;
  final VoidCallback? onCloseRequested;

  void _handleClose(BuildContext context) {
    final handler = onCloseRequested;
    if (handler != null) {
      handler();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<MyDayRitualBloc, MyDayRitualState>(
          listenWhen: (previous, current) {
            if (!allowClose) return false;
            return previous is MyDayRitualReady &&
                current is MyDayRitualReady &&
                previous.navRequestId != current.navRequestId &&
                current.nav == MyDayRitualNav.closeWizard;
          },
          listener: (context, state) {
            _handleClose(context);
          },
        ),
      ],
      child: BlocBuilder<MyDayRitualBloc, MyDayRitualState>(
        builder: (context, ritualState) {
          return BlocBuilder<MyDayGateBloc, MyDayGateState>(
            builder: (context, gateState) {
              return switch (ritualState) {
                MyDayRitualLoading() => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
                MyDayRitualReady() => Scaffold(
                  appBar: allowClose
                      ? AppBar(
                          leading: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => _handleClose(context),
                          ),
                          title: Text(context.l10n.myDayUpdatePlanTitle),
                        )
                      : null,
                  body: SafeArea(
                    bottom: false,
                    child: _RitualBody(
                      data: ritualState,
                      gateState: gateState,
                      isResume: allowClose,
                      initialSection: initialSection,
                    ),
                  ),
                  bottomNavigationBar: _RitualBottomBar(
                    data: ritualState,
                    closeOnConfirm: allowClose,
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

class _RitualBody extends StatelessWidget {
  const _RitualBody({
    required this.data,
    required this.gateState,
    required this.isResume,
    required this.initialSection,
  });

  final MyDayRitualReady data;
  final MyDayGateState gateState;
  final bool isResume;
  final MyDayRitualWizardInitialSection? initialSection;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final planned = data.planned;
    final curated = data.curated;
    final pinnedTasks = data.pinnedTasks;
    final snoozed = data.snoozed;
    final selected = data.selectedTaskIds;
    final completedPicks = data.completedPicks;

    final gate = gateState is MyDayGateLoaded
        ? gateState as MyDayGateLoaded
        : null;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _HeroHeader(
            title: isResume ? l10n.myDayUpdatePlanTitle : l10n.myDayRitualTitle,
            subtitle: isResume
                ? (completedPicks.isEmpty
                      ? l10n.myDayUpdatePlanSubtitle
                      : l10n.myDayUpdatePlanSubtitleWithCompleted)
                : l10n.myDayRitualSubtitle,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: _RitualCard(
              dayKeyUtc: data.dayKeyUtc,
              planned: planned,
              dueWindowDays: data.dueWindowDays,
              showAvailableToStart: data.showAvailableToStart,
              curated: curated,
              pinnedTasks: pinnedTasks,
              snoozed: snoozed,
              completedPicks: completedPicks,
              selected: selected,
              curatedReasonCodesByTaskId: data.curatedReasonCodesByTaskId,
              gateState: gate,
              isResume: isResume,
              onAddValues: () => Routing.toScreenKey(context, 'values'),
              onDueWindowDaysChanged: (days) =>
                  context.read<MyDayRitualBloc>().add(
                    MyDayRitualDueWindowDaysChanged(days),
                  ),
              onShowAvailableToStartChanged: (enabled) =>
                  context.read<MyDayRitualBloc>().add(
                    MyDayRitualShowAvailableToStartChanged(enabled),
                  ),
              onAcceptAllDue: () => context.read<MyDayRitualBloc>().add(
                const MyDayRitualAcceptAllDue(),
              ),
              onAcceptAllStarts: () => context.read<MyDayRitualBloc>().add(
                const MyDayRitualAcceptAllStarts(),
              ),
              onGenerateMoreCurated: () => context.read<MyDayRitualBloc>().add(
                const MyDayRitualMoreSuggestionsRequested(),
              ),
              initialSection: initialSection,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}

class _RitualBottomBar extends StatelessWidget {
  const _RitualBottomBar({required this.data, required this.closeOnConfirm});

  final MyDayRitualReady data;
  final bool closeOnConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selectedCount = data.selectedTaskIds.length;
    final isEnabled = closeOnConfirm || selectedCount > 0;
    final label = closeOnConfirm
        ? (selectedCount == 0
              ? l10n.myDayClearMyDayLabel
              : l10n.myDayUpdateMyDayLabel(selectedCount))
        : (selectedCount == 0
              ? l10n.myDaySelectItemsToContinueLabel
              : l10n.myDayContinueToMyDayLabel(selectedCount));

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
                        if (closeOnConfirm && selectedCount == 0) {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) {
                              final dialogL10n = dialogContext.l10n;
                              return AlertDialog(
                                title: Text(
                                  dialogL10n.myDayClearPlanDialogTitle,
                                ),
                                content: Text(
                                  dialogL10n.myDayClearPlanDialogBody,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(false),
                                    child: Text(dialogL10n.cancelLabel),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(true),
                                    child: Text(dialogL10n.clearLabel),
                                  ),
                                ],
                              );
                            },
                          );
                          if (ok != true) return;
                        }

                        if (!context.mounted) return;

                        context.read<MyDayRitualBloc>().add(
                          MyDayRitualConfirm(closeOnSuccess: closeOnConfirm),
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

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RitualCard extends StatefulWidget {
  const _RitualCard({
    required this.dayKeyUtc,
    required this.planned,
    required this.dueWindowDays,
    required this.showAvailableToStart,
    required this.curated,
    required this.pinnedTasks,
    required this.snoozed,
    required this.completedPicks,
    required this.selected,
    required this.curatedReasonCodesByTaskId,
    required this.gateState,
    required this.isResume,
    required this.onAddValues,
    required this.onDueWindowDaysChanged,
    required this.onShowAvailableToStartChanged,
    required this.onAcceptAllDue,
    required this.onAcceptAllStarts,
    required this.onGenerateMoreCurated,
    required this.initialSection,
  });

  final DateTime dayKeyUtc;
  final List<Task> planned;
  final int dueWindowDays;
  final bool showAvailableToStart;
  final List<Task> curated;
  final List<Task> pinnedTasks;
  final List<Task> snoozed;
  final List<Task> completedPicks;
  final Set<String> selected;
  final Map<String, List<AllocationReasonCode>> curatedReasonCodesByTaskId;
  final MyDayGateLoaded? gateState;
  final bool isResume;
  final VoidCallback onAddValues;
  final ValueChanged<int> onDueWindowDaysChanged;
  final ValueChanged<bool> onShowAvailableToStartChanged;
  final VoidCallback onAcceptAllDue;
  final VoidCallback onAcceptAllStarts;
  final VoidCallback onGenerateMoreCurated;
  final MyDayRitualWizardInitialSection? initialSection;

  @override
  State<_RitualCard> createState() => _RitualCardState();
}

class _RitualCardState extends State<_RitualCard> {
  static const _waitingPreviewCountPerGroup = 3;

  final GlobalKey<State<StatefulWidget>> _suggestedHeaderKey = GlobalKey();
  final GlobalKey<State<StatefulWidget>> _whatsWaitingHeaderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _valuesExpanded = true;
    _timeSensitiveExpanded = true;
    _completedExpanded = false;
    _snoozedExpanded = false;
    _pinnedExpanded = true;
    _dueExpanded = false;
    _startsExpanded = false;
    if (widget.initialSection == MyDayRitualWizardInitialSection.due) {
      _dueExpanded = true;
    }
    if (widget.initialSection == MyDayRitualWizardInitialSection.starts) {
      _startsExpanded = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final section = widget.initialSection;
      if (section == null) {
        return;
      }

      final context = switch (section) {
        MyDayRitualWizardInitialSection.due =>
          _whatsWaitingHeaderKey.currentContext,
        MyDayRitualWizardInitialSection.starts =>
          _whatsWaitingHeaderKey.currentContext,
        MyDayRitualWizardInitialSection.suggested =>
          _suggestedHeaderKey.currentContext,
      };

      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    });
  }

  ({List<Task> due, List<Task> starts}) _computePlannedSections() {
    final today = dateOnly(widget.dayKeyUtc);
    final dueWindowDays = widget.dueWindowDays.clamp(1, 30);
    final dueLimit = today.add(Duration(days: dueWindowDays - 1));

    final curatedIds = widget.curated.map((t) => t.id).toSet();

    final due = <Task>[];
    final starts = <Task>[];
    for (final task in widget.planned) {
      // Defensive: do not duplicate tasks across sections.
      if (curatedIds.contains(task.id)) continue;
      final deadline = _deadlineDateOnly(task);
      final isDue = deadline != null && !deadline.isAfter(dueLimit);
      if (isDue) {
        due.add(task);
        continue;
      }

      final start = dateOnlyOrNull(task.occurrence?.date ?? task.startDate);
      final isAvailableToStart = start != null && !start.isAfter(today);
      if (isAvailableToStart) {
        starts.add(task);
      }
    }

    return (due: due, starts: starts);
  }

  late bool _valuesExpanded;
  late bool _timeSensitiveExpanded;
  late bool _completedExpanded;
  late bool _snoozedExpanded;
  late bool _pinnedExpanded;
  late bool _dueExpanded;
  late bool _startsExpanded;

  String _supportingTextForWhatMattersTask(BuildContext context, Task task) {
    final l10n = context.l10n;
    final primaryValueName = task.effectivePrimaryValue?.name.trim();
    if (primaryValueName == null || primaryValueName.isEmpty) return '';

    final reasonCodes =
        widget.curatedReasonCodesByTaskId[task.id] ??
        const <AllocationReasonCode>[];

    final suffixes = <String>[];
    if (reasonCodes.contains(AllocationReasonCode.urgency)) {
      suffixes.add(l10n.myDayDueSoonLabel);
    }
    if (reasonCodes.contains(AllocationReasonCode.priority)) {
      suffixes.add(l10n.priorityLabel);
    }
    if (reasonCodes.contains(AllocationReasonCode.neglectBalance)) {
      suffixes.add(l10n.myDayWhyTheseSignalBalance);
    }
    if (reasonCodes.contains(AllocationReasonCode.crossValue)) {
      suffixes.add(l10n.myDayWhyTheseSignalCrossValue);
    }

    final base = l10n.myDaySupportsValueLabel(primaryValueName);
    if (suffixes.isEmpty) return base;
    return '$base · ${suffixes.join('')}';
  }

  String _signalsSummaryForTasks(BuildContext context, List<Task> tasks) {
    final l10n = context.l10n;
    final union = <AllocationReasonCode>{
      for (final task in tasks) ...?widget.curatedReasonCodesByTaskId[task.id],
    };
    if (union.isEmpty) return '';

    final parts = <String>[];
    if (union.contains(AllocationReasonCode.valueAlignment)) {
      parts.add(l10n.myDayValueAlignedLabel);
    }
    if (union.contains(AllocationReasonCode.neglectBalance)) {
      parts.add(l10n.myDayWhyTheseSignalBalance);
    }
    if (union.contains(AllocationReasonCode.crossValue)) {
      parts.add(l10n.myDayWhyTheseSignalCrossValue);
    }
    if (union.contains(AllocationReasonCode.urgency)) {
      parts.add(l10n.myDayDueSoonLabel);
    }
    if (union.contains(AllocationReasonCode.priority)) {
      parts.add(l10n.priorityLabel);
    }

    return parts.join(', ');
  }

  Map<String, String> _buildReasonTextById(
    List<Task> tasks, {
    required String reasonLabel,
  }) {
    final l10n = context.l10n;
    return <String, String>{
      for (final task in tasks)
        task.id: task.effectiveValues.isEmpty
            ? reasonLabel
            : '$reasonLabel${l10n.dotSeparator}${l10n.myDayValueAlignedLabel}',
    };
  }

  List<TasklyRowSpec> _buildPickerRows({
    required List<Task> tasks,
    required Map<String, String> reasonTextByTaskId,
    required Map<String, String> reasonTooltipTextByTaskId,
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

          final supportingText = reasonTextByTaskId[task.id];
          final supportingTooltipText = reasonTooltipTextByTaskId[task.id];

          final updatedData = TasklyTaskRowData(
            id: data.id,
            title: data.title,
            completed: data.completed,
            meta: data.meta,
            leadingChip: data.leadingChip,
            secondaryChips: data.secondaryChips,
            supportingText: supportingText,
            supportingTooltipText: supportingTooltipText,
            deemphasized: data.deemphasized,
            checkboxSemanticLabel: data.checkboxSemanticLabel,
            labels: labels,
          );

          return TasklyRowSpec.task(
            key: 'myday-plan-${task.id}',
            data: updatedData,
            preset: enableSelection
                ? TasklyTaskRowPreset.pickerAction(selected: isSelected)
                : TasklyTaskRowPreset.picker(selected: isSelected),
            markers: TasklyTaskRowMarkers(pinned: task.isPinned),
            actions: TasklyTaskRowActions(
              onTap: !enableSelection
                  ? null
                  : () => context.read<MyDayRitualBloc>().add(
                      MyDayRitualToggleTask(
                        task.id,
                        selected: !isSelected,
                      ),
                    ),
              onToggleSelected: !enableSelection
                  ? null
                  : () => context.read<MyDayRitualBloc>().add(
                      MyDayRitualToggleTask(
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
            supportingText: data.supportingText,
            supportingTooltipText: data.supportingTooltipText,
            deemphasized: data.deemphasized,
            checkboxSemanticLabel: data.checkboxSemanticLabel,
            labels: labels,
          );

          return TasklyRowSpec.task(
            key: 'myday-plan-pinned-${task.id}',
            data: updatedData,
            preset: const TasklyTaskRowPreset.pinnedToggle(),
            markers: TasklyTaskRowMarkers(pinned: task.isPinned),
            actions: TasklyTaskRowActions(
              onTap: buildTaskOpenEditorHandler(context, task: task),
              onTogglePinned: buildTaskTogglePinnedHandler(
                context,
                task: task,
                tileCapabilities: tileCapabilities,
              ),
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () => _showWhyTheseWhatMattersSheet(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(l10n.myDayWhyTheseAction),
        ),
        PopupMenuButton<_SuggestedMenuAction>(
          tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
          onSelected: (action) {
            switch (action) {
              case _SuggestedMenuAction.suggestionSettings:
                _openSuggestionSettingsSheet(
                  context,
                  dueWindowDays: widget.dueWindowDays,
                  showAvailableToStart: widget.showAvailableToStart,
                );
            }
          },
          itemBuilder: (context) {
            return <PopupMenuEntry<_SuggestedMenuAction>>[
              PopupMenuItem(
                value: _SuggestedMenuAction.suggestionSettings,
                child: Text(l10n.myDaySuggestionSettingsTitle),
              ),
            ];
          },
        ),
      ],
    );
  }

  Widget? _buildValuesFooter(
    BuildContext context, {
    required int curatedCount,
    required bool needsSetup,
  }) {
    final l10n = context.l10n;

    if (needsSetup) {
      return _SuggestedSetupCard(gateState: widget.gateState!);
    }

    final footerChildren = <Widget>[];

    if (curatedCount == 0) {
      footerChildren.add(
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: widget.onGenerateMoreCurated,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.myDayGenerateNewBatchLabel),
          ),
        ),
      );
    }

    if (widget.curated.isNotEmpty &&
        widget.curated.every((t) => widget.selected.contains(t.id))) {
      footerChildren.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(
                  0.6,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.myDaySuggestedAnotherBatchPrompt,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onGenerateMoreCurated,
                  child: Text(l10n.myDayGenerateLabel),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (footerChildren.isEmpty) {
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: footerChildren,
    );
  }

  Widget? _buildShowMoreFooter(
    BuildContext context, {
    required bool isExpanded,
    required int remainingCount,
    required int totalCount,
    required VoidCallback onPressed,
    int previewCount = _waitingPreviewCountPerGroup,
  }) {
    if (totalCount <= previewCount) return null;

    return _ShowMoreRow(
      isExpanded: isExpanded,
      remainingCount: remainingCount,
      totalCount: totalCount,
      labelExpanded: context.l10n.myDayShowFewerLabel,
      labelCollapsed: context.l10n.myDayShowMoreCountLabel(remainingCount),
      onPressed: onPressed,
    );
  }

  List<TasklyRowSpec> _buildValuesRows(
    BuildContext context, {
    required List<Task> due,
    required List<Task> planned,
    required List<Task> anytime,
    required Map<String, String> reasonTextByTaskId,
  }) {
    final l10n = context.l10n;
    final rows = <TasklyRowSpec>[];

    void addGroup(String id, String title, List<Task> tasks) {
      if (tasks.isEmpty) return;
      rows.add(
        TasklyRowSpec.subheader(
          key: 'myday-plan-values-$id-header',
          title: title,
        ),
      );
      rows.addAll(
        _buildPickerRows(
          tasks: tasks,
          reasonTextByTaskId: reasonTextByTaskId,
          reasonTooltipTextByTaskId: const <String, String>{},
          enableSnooze: false,
          enableSelection: true,
          selectionPillLabel: l10n.myDayAddToMyDayAction,
          selectionPillSelectedLabel: l10n.myDayAddedLabel,
          snoozeTooltip: l10n.myDaySnoozeAction,
        ),
      );
    }

    addGroup('due', l10n.myDayDueSoonLabel, due);
    addGroup('planned', l10n.myDayPlannedSectionTitle, planned);
    addGroup('anytime', l10n.myDayAnytimeLabel, anytime);

    return rows;
  }

  Future<void> _showWhyTheseWhatMattersSheet(BuildContext context) {
    final l10n = context.l10n;

    final groups = <String, List<Task>>{};
    final order = <String>[];
    for (final task in widget.curated) {
      final key =
          task.effectivePrimaryValue?.name ?? l10n.groupingMissingValues;
      if (!groups.containsKey(key)) {
        groups[key] = <Task>[];
        order.add(key);
      }
      groups[key]!.add(task);
    }

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final cs = theme.colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.myDayWhyTheseTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.myDayWhyTheseWhatMattersBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final key in order)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            key,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            () {
                              final tasks = groups[key]!;
                              final countText = l10n
                                  .myDayWhyTheseValueGroupCount(
                                    tasks.length,
                                  );
                              final signals = _signalsSummaryForTasks(
                                sheetContext,
                                tasks,
                              );
                              return signals.isEmpty
                                  ? countText
                                  : '$countText • $signals';
                            }(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSuggestionSettingsSheet(
    BuildContext context, {
    required int dueWindowDays,
    required bool showAvailableToStart,
  }) {
    var dueDays = dueWindowDays.clamp(1, 30);
    var showStarts = showAvailableToStart;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final cs = theme.colorScheme;

        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setState) {
              final l10n = context.l10n;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.myDaySuggestionSettingsTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.myDaySuggestionSettingsBody,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      l10n.myDayDueSoonWindowLabel(dueDays),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Slider(
                      value: dueDays.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: '$dueDays',
                      onChanged: (value) {
                        final next = value.round().clamp(1, 30);
                        setState(() => dueDays = next);
                        widget.onDueWindowDaysChanged(next);
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.myDayDueSoonWindowHelp(dueDays),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),

                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.myDayShowAvailableToStartSettingTitle),
                      subtitle: Text(
                        l10n.myDayShowAvailableToStartSettingSubtitle,
                      ),
                      value: showStarts,
                      onChanged: (value) {
                        setState(() => showStarts = value);
                        widget.onShowAvailableToStartChanged(value);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final curatedCount = widget.curated.length;
    final completedCount = widget.completedPicks.length;
    final snoozedCount = widget.snoozed.length;

    final needsSetup =
        widget.gateState != null && widget.gateState!.needsValuesSetup;

    final planned = _computePlannedSections();
    final due = sortTasksByDeadline(
      planned.due,
      today: dateOnly(widget.dayKeyUtc),
    );
    final startsRaw = widget.showAvailableToStart
        ? planned.starts
        : const <Task>[];
    final starts = sortTasksByStartDate(startsRaw);

    final curatedSplit = _splitCuratedSections();
    final valuesDue = sortTasksByDeadline(
      curatedSplit.due,
      today: dateOnly(widget.dayKeyUtc),
    );
    final valuesPlanned = sortTasksByStartDate(curatedSplit.planned);
    final valuesAnytime = curatedSplit.anytime;

    final curatedReasonTextById = <String, String>{};
    for (final task in [
      ...valuesDue,
      ...valuesPlanned,
      ...valuesAnytime,
    ]) {
      final text = _supportingTextForWhatMattersTask(context, task);
      if (text.isNotEmpty) {
        curatedReasonTextById[task.id] = text;
      }
    }

    final dueVisible = _dueExpanded
        ? due
        : due.take(_waitingPreviewCountPerGroup).toList(growable: false);
    final startsVisible = _startsExpanded
        ? starts
        : starts.take(_waitingPreviewCountPerGroup).toList(growable: false);

    final valuesRows = _buildValuesRows(
      context,
      due: valuesDue,
      planned: valuesPlanned,
      anytime: valuesAnytime,
      reasonTextByTaskId: curatedReasonTextById,
    );

    final pinnedSorted = sortTasksByDeadlineThenStartThenName(
      widget.pinnedTasks,
      today: dateOnly(widget.dayKeyUtc),
    );
    final pinnedRows = _buildPinnedRows(
      context,
      tasks: pinnedSorted,
    );

    final dueReasonTextById = _buildReasonTextById(
      dueVisible,
      reasonLabel: l10n.myDayDueSoonLabel,
    );
    final startsReasonTextById = _buildReasonTextById(
      startsVisible,
      reasonLabel: l10n.myDayAvailableToStartLabel,
    );

    final dueRows = _buildPickerRows(
      tasks: dueVisible,
      reasonTextByTaskId: dueReasonTextById,
      reasonTooltipTextByTaskId: const <String, String>{},
      enableSnooze: true,
      enableSelection: true,
      selectionPillLabel: l10n.myDayAddToMyDayAction,
      selectionPillSelectedLabel: l10n.myDayAddedLabel,
      snoozeTooltip: l10n.myDaySnoozeAction,
    );

    final startsRows = _buildPickerRows(
      tasks: startsVisible,
      reasonTextByTaskId: startsReasonTextById,
      reasonTooltipTextByTaskId: const <String, String>{},
      enableSnooze: true,
      enableSelection: true,
      selectionPillLabel: l10n.myDayAddToMyDayAction,
      selectionPillSelectedLabel: l10n.myDayAddedLabel,
      snoozeTooltip: l10n.myDaySnoozeAction,
    );

    final completedRows = _buildPickerRows(
      tasks: widget.completedPicks,
      reasonTextByTaskId: const <String, String>{},
      reasonTooltipTextByTaskId: const <String, String>{},
      enableSnooze: false,
      enableSelection: false,
      selectionPillLabel: null,
      selectionPillSelectedLabel: null,
      snoozeTooltip: null,
      completedStatusLabel: l10n.projectCompletedLabel,
    );

    final valuesFooter = _buildValuesFooter(
      context,
      curatedCount: curatedCount,
      needsSetup: needsSetup,
    );

    final dueFooter = _buildShowMoreFooter(
      context,
      isExpanded: _dueExpanded,
      remainingCount: due.length - dueVisible.length,
      totalCount: due.length,
      onPressed: () => setState(() => _dueExpanded = !_dueExpanded),
    );

    final startsFooter = _buildShowMoreFooter(
      context,
      isExpanded: _startsExpanded,
      remainingCount: starts.length - startsVisible.length,
      totalCount: starts.length,
      onPressed: () => setState(() => _startsExpanded = !_startsExpanded),
    );

    return Column(
      children: [
        TasklyMyDaySectionStack(
          pinned: pinnedRows.isEmpty
              ? null
              : TasklyMyDaySectionConfig(
                  title: l10n.pinnedTasksSection,
                  subtitle: l10n.myDayPinnedSectionSubtitle,
                  icon: Icons.push_pin_rounded,
                  count: pinnedSorted.length,
                  showCount: false,
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
            icon: Icons.eco_rounded,
            count: curatedCount,
            showCount: false,
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
              footer: valuesFooter,
            ),
          ),
          timeSensitive: TasklyMyDayTimeSensitiveConfig(
            headerKey: _whatsWaitingHeaderKey,
            title: l10n.myDayWhatsWaitingSectionTitle,
            icon: Icons.access_time_rounded,
            showCount: false,
            subtitle: l10n.myDayTimeSensitiveOutsideValuesSubtitle,
            expanded: _timeSensitiveExpanded,
            onToggleExpanded: () => setState(
              () => _timeSensitiveExpanded = !_timeSensitiveExpanded,
            ),
            due: TasklyMyDaySubsectionConfig(
              title: l10n.myDayDueSoonLabel,
              icon: Icons.warning_rounded,
              iconColor: cs.error,
              count: due.length,
              expanded: _dueExpanded,
              onToggleExpanded: () =>
                  setState(() => _dueExpanded = !_dueExpanded),
              list: TasklyMyDaySectionList(
                id: 'myday-plan-due',
                rows: dueRows,
                footer: dueFooter,
              ),
              emptyState: TasklyMyDayEmptyState(
                title: l10n.myDayPlanDueEmptyTitle,
                description: l10n.myDayPlanDueEmptyBody,
              ),
              showEmpty: false,
            ),
            planned: TasklyMyDaySubsectionConfig(
              title: l10n.myDayPlannedSectionTitle,
              icon: Icons.event_note_rounded,
              iconColor: cs.secondary,
              count: starts.length,
              expanded: _startsExpanded,
              onToggleExpanded: () =>
                  setState(() => _startsExpanded = !_startsExpanded),
              list: TasklyMyDaySectionList(
                id: 'myday-plan-planned',
                rows: startsRows,
                footer: startsFooter,
              ),
              emptyState: TasklyMyDayEmptyState(
                title: l10n.myDayPlanPlannedEmptyTitle,
                description: l10n.myDayPlanPlannedEmptyBody,
              ),
              showEmpty: false,
            ),
          ),
          completed: TasklyMyDaySectionConfig(
            title: l10n.myDayCompletedSectionTitle,
            icon: Icons.check_circle_outline,
            count: completedCount,
            showCount: false,
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

  DateTime? _deadlineDateOnly(Task task) {
    final raw = task.occurrence?.deadline ?? task.deadlineDate;
    return dateOnlyOrNull(raw);
  }

  DateTime? _startDateOnly(Task task) {
    final raw = task.occurrence?.date ?? task.startDate;
    return dateOnlyOrNull(raw);
  }

  ({List<Task> due, List<Task> planned, List<Task> anytime})
  _splitCuratedSections() {
    final today = dateOnly(widget.dayKeyUtc);
    final dueLimit = today.add(
      Duration(days: widget.dueWindowDays.clamp(1, 30) - 1),
    );

    final due = <Task>[];
    final planned = <Task>[];
    final anytime = <Task>[];

    for (final task in widget.curated) {
      final deadline = _deadlineDateOnly(task);
      if (deadline != null && !deadline.isAfter(dueLimit)) {
        due.add(task);
        continue;
      }

      final start = _startDateOnly(task);
      final available =
          widget.showAvailableToStart && start != null && !start.isAfter(today);
      if (available) {
        planned.add(task);
        continue;
      }

      anytime.add(task);
    }

    return (due: due, planned: planned, anytime: anytime);
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
                  context.read<MyDayRitualBloc>().add(
                    MyDayRitualSnoozeTaskRequested(
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

enum _SuggestedMenuAction { suggestionSettings }

class _SubsectionHeader extends StatelessWidget {
  const _SubsectionHeader({
    required this.icon,
    required this.title,
    required this.count,
    this.action,
  });
  final IconData icon;
  final String title;
  final int count;

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
              Icon(icon, size: 16, color: cs.primary),
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

class _SuggestedSetupCard extends StatelessWidget {
  const _SuggestedSetupCard({required this.gateState});

  final MyDayGateLoaded gateState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Card(
        elevation: 0,
        color: cs.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.myDayUnlockSuggestionsTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.myDayUnlockSuggestionsBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              if (gateState.needsValuesSetup)
                _GateRow(
                  icon: Icons.favorite_outline,
                  label: l10n.myDayAddFirstValueLabel,
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Routing.toScreenKey(context, 'values'),
                  icon: Icon(gateState.ctaIcon),
                  label: Text(gateState.ctaLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GateRow extends StatelessWidget {
  const _GateRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
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
  final today = dateOnly(dayKeyUtc);
  final tomorrow = today.add(const Duration(days: 1));
  final nextWeek = today.add(const Duration(days: 7));

  final parentContext = context;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(context.l10n.myDayMyDaySnoozeSheetTitle),
              subtitle: Text(context.l10n.myDayMyDaySnoozeSheetSubtitle),
            ),
            ListTile(
              leading: const Icon(Icons.today),
              title: Text(context.l10n.dateTomorrow),
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
              leading: const Icon(Icons.date_range),
              title: Text(context.l10n.dateNextWeek),
              onTap: () async {
                await _confirmAndDispatchSnooze(
                  parentContext,
                  sheetContext,
                  task: task,
                  untilUtc: nextWeek,
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
  final bloc = parentContext.read<MyDayRitualBloc>();
  final navigator = Navigator.of(sheetContext);

  if (!navigator.mounted) return;

  if (navigator.canPop()) {
    navigator.pop();
  }

  bloc.add(
    MyDayRitualSnoozeTaskRequested(
      taskId: task.id,
      untilUtc: untilUtc,
    ),
  );
}

class _ShowMoreRow extends StatelessWidget {
  const _ShowMoreRow({
    required this.isExpanded,
    required this.remainingCount,
    required this.totalCount,
    required this.labelExpanded,
    required this.labelCollapsed,
    required this.onPressed,
  });

  final bool isExpanded;
  final int remainingCount;
  final int totalCount;
  final String labelExpanded;
  final String labelCollapsed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = isExpanded
        ? labelExpanded
        : (remainingCount > 0
              ? labelCollapsed
              : context.l10n.labelWithTotal(labelCollapsed, totalCount));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Center(
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          label: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
