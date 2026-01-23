import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_ritual_bloc.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverToBoxAdapter(
            child: _RitualCard(
              dayKeyUtc: data.dayKeyUtc,
              planned: planned,
              dueWindowDays: data.dueWindowDays,
              showAvailableToStart: data.showAvailableToStart,
              curated: curated,
              snoozed: snoozed,
              completedPicks: completedPicks,
              selected: selected,
              curatedReasons: data.curatedReasons,
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
              onAcceptAllCurated: () => context.read<MyDayRitualBloc>().add(
                const MyDayRitualAcceptAllCurated(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary.withOpacity(0.12),
                theme.colorScheme.surface,
              ],
            ),
          ),
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
        ),
      ],
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
    required this.snoozed,
    required this.completedPicks,
    required this.selected,
    required this.curatedReasons,
    required this.curatedReasonCodesByTaskId,
    required this.gateState,
    required this.isResume,
    required this.onAddValues,
    required this.onDueWindowDaysChanged,
    required this.onShowAvailableToStartChanged,
    required this.onAcceptAllDue,
    required this.onAcceptAllStarts,
    required this.onAcceptAllCurated,
    required this.onGenerateMoreCurated,
    required this.initialSection,
  });

  final DateTime dayKeyUtc;
  final List<Task> planned;
  final int dueWindowDays;
  final bool showAvailableToStart;
  final List<Task> curated;
  final List<Task> snoozed;
  final List<Task> completedPicks;
  final Set<String> selected;
  final Map<String, String> curatedReasons;
  final Map<String, List<AllocationReasonCode>> curatedReasonCodesByTaskId;
  final MyDayGateLoaded? gateState;
  final bool isResume;
  final VoidCallback onAddValues;
  final ValueChanged<int> onDueWindowDaysChanged;
  final ValueChanged<bool> onShowAvailableToStartChanged;
  final VoidCallback onAcceptAllDue;
  final VoidCallback onAcceptAllStarts;
  final VoidCallback onAcceptAllCurated;
  final VoidCallback onGenerateMoreCurated;
  final MyDayRitualWizardInitialSection? initialSection;

  @override
  State<_RitualCard> createState() => _RitualCardState();
}

class _RitualCardState extends State<_RitualCard> {
  static const _curatedPreviewCount = 4;

  static const _waitingPreviewCountPerGroup = 3;

  static const _bulkPickConfirmThreshold = 5;

  final GlobalKey<State<StatefulWidget>> _suggestedHeaderKey = GlobalKey();
  final GlobalKey<State<StatefulWidget>> _whatsWaitingHeaderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _curatedExpanded = false;
    _completedExpanded = !widget.isResume;
    _snoozedExpanded = false;

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

  late bool _completedExpanded;
  late bool _snoozedExpanded;
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
    return '$base · ${suffixes.join(' · ')}';
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

  Future<void> _showWhyTheseWhatsWaitingSheet(BuildContext context) {
    final l10n = context.l10n;
    final dueWindowDays = widget.dueWindowDays.clamp(1, 30);

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
                  l10n.myDayWhyTheseWhatsWaitingBody(dueWindowDays),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.myDayDueSoonWindowHelp(dueWindowDays),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmPickAllCurated(
    BuildContext context, {
    required int count,
  }) {
    if (count <= 0) return Future.value();
    if (count <= _bulkPickConfirmThreshold) {
      widget.onAcceptAllCurated();
      return Future.value();
    }

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final l10n = sheetContext.l10n;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.myDayPickAllSuggestedTitle,
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.myDayPickAllConfirmBody(count),
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          widget.onAcceptAllCurated();
                        },
                        child: Text(l10n.myDayPickAllButton),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: Text(l10n.cancelLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  late bool _curatedExpanded;

  @override
  void didUpdateWidget(covariant _RitualCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.curated.length != widget.curated.length) {
      if (widget.curated.length <= _curatedPreviewCount) {
        _curatedExpanded = true;
      }
    }
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
    final due = planned.due;
    final starts = widget.showAvailableToStart
        ? planned.starts
        : const <Task>[];

    final whatsWaitingCount = due.length + starts.length;

    final curatedVisible = _curatedExpanded
        ? widget.curated
        : widget.curated.take(_curatedPreviewCount).toList(growable: false);
    final curatedHasMore = widget.curated.length > _curatedPreviewCount;

    final curatedVisibleIds = curatedVisible.map((t) => t.id).toSet();

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          children: [
            if (completedCount > 0) ...[
              if (!_completedExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () =>
                          setState(() => _completedExpanded = true),
                      child: Text(
                        '${context.l10n.myDayShowCompletedLabel} · $completedCount',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
              else ...[
                _SubsectionHeader(
                  title: context.l10n.myDayCompletedSectionTitle,
                  count: completedCount,
                  action: TextButton(
                    onPressed: () => setState(() => _completedExpanded = false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    child: Text(context.l10n.myDayHideCompletedLabel),
                  ),
                ),
                _TaskTileColumn(
                  dayKeyUtc: widget.dayKeyUtc,
                  tasks: widget.completedPicks,
                  selected: widget.selected,
                  reasonTextByTaskId: const <String, String>{},
                  reasonTooltipTextByTaskId: const <String, String>{},
                  enableSnooze: false,
                  enableSelection: false,
                  completedStatusLabel: context.l10n.projectCompletedLabel,
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Divider(
                  color: cs.outlineVariant,
                  thickness: 1,
                  height: 1,
                ),
              ),
            ],

            // Suggested first.
            KeyedSubtree(
              key: _suggestedHeaderKey,
              child: _SuggestedHeader(
                count: curatedCount,
                needsSetup: needsSetup,
                onAddValues: widget.onAddValues,
                onWhyThesePressed: () => _showWhyTheseWhatMattersSheet(context),
                onOpenSuggestionSettings: () => _openSuggestionSettingsSheet(
                  context,
                  dueWindowDays: widget.dueWindowDays,
                  showAvailableToStart: widget.showAvailableToStart,
                ),
                onPickAllCurated: () =>
                    _confirmPickAllCurated(context, count: curatedCount),
              ),
            ),
            if (needsSetup)
              _SuggestedSetupCard(gateState: widget.gateState!)
            else if (curatedCount == 0)
              _EmptyPanel(
                title: context.l10n.myDaySuggestedCompleteTitle,
                description: context.l10n.myDaySuggestedCompleteBody,
                footer: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: widget.onGenerateMoreCurated,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(context.l10n.myDayGenerateNewBatchLabel),
                  ),
                ),
              )
            else
              Column(
                children: [
                  Builder(
                    builder: (context) {
                      final groups = <String, List<Task>>{};
                      final order = <String>[];
                      for (final task in widget.curated) {
                        final key =
                            task.effectivePrimaryValue?.name ??
                            l10n.groupingMissingValues;
                        if (!groups.containsKey(key)) {
                          groups[key] = <Task>[];
                          order.add(key);
                        }
                        groups[key]!.add(task);
                      }

                      return Column(
                        children: [
                          for (final key in order)
                            () {
                              final groupTasks = groups[key]!;
                              final visibleGroupTasks = groupTasks
                                  .where(
                                    (t) => curatedVisibleIds.contains(t.id),
                                  )
                                  .toList(growable: false);
                              if (visibleGroupTasks.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return Column(
                                children: [
                                  _MiniGroupHeader(
                                    title: key,
                                    count: groupTasks.length,
                                  ),
                                  Builder(
                                    builder: (context) {
                                      final supportingTextById =
                                          <String, String>{};
                                      for (final task in visibleGroupTasks) {
                                        final text =
                                            _supportingTextForWhatMattersTask(
                                              context,
                                              task,
                                            );
                                        if (text.isNotEmpty) {
                                          supportingTextById[task.id] = text;
                                        }
                                      }

                                      return _TaskTileColumn(
                                        dayKeyUtc: widget.dayKeyUtc,
                                        tasks: visibleGroupTasks,
                                        selected: widget.selected,
                                        reasonTextByTaskId: supportingTextById,
                                        reasonTooltipTextByTaskId:
                                            const <String, String>{},
                                        enableSnooze: false,
                                        enableSelection: true,
                                        selectionPillLabel:
                                            l10n.myDayAddToMyDayAction,
                                        selectionPillSelectedLabel:
                                            l10n.myDayAddedLabel,
                                        snoozeTooltip: l10n.myDaySnoozeAction,
                                      );
                                    },
                                  ),
                                ],
                              );
                            }(),
                        ],
                      );
                    },
                  ),
                  if (widget.curated.isNotEmpty &&
                      widget.curated.every(
                        (t) => widget.selected.contains(t.id),
                      ))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cs.outlineVariant.withOpacity(0.6),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.l10n.myDaySuggestedAnotherBatchPrompt,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            TextButton(
                              onPressed: widget.onGenerateMoreCurated,
                              child: Text(context.l10n.myDayGenerateLabel),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (curatedHasMore)
                    _ShowMoreRow(
                      isExpanded: _curatedExpanded,
                      remainingCount:
                          widget.curated.length - curatedVisible.length,
                      totalCount: widget.curated.length,
                      labelExpanded: context.l10n.myDayShowFewerLabel,
                      labelCollapsed: context.l10n.myDayShowAllPicksLabel,
                      onPressed: () =>
                          setState(() => _curatedExpanded = !_curatedExpanded),
                    ),
                ],
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Divider(
                color: cs.outlineVariant,
                thickness: 1,
                height: 1,
              ),
            ),

            KeyedSubtree(
              key: _whatsWaitingHeaderKey,
              child: Column(
                children: [
                  _SubsectionHeader(
                    title: l10n.myDayWhatsWaitingSectionTitle,
                    count: whatsWaitingCount,
                    subtitle: l10n.myDayWhatsWaitingSubtitle,
                    action: TextButton(
                      onPressed: () => _showWhyTheseWhatsWaitingSheet(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      child: Text(l10n.myDayWhyTheseAction),
                    ),
                  ),
                  if (whatsWaitingCount == 0)
                    _SectionEmptyPanel(
                      title: l10n.myDayWhatsWaitingSectionTitle,
                      description: l10n.myDayYoureCaughtUpBody,
                    )
                  else
                    Column(
                      children: [
                        if (due.isNotEmpty)
                          () {
                            final dueVisible = _dueExpanded
                                ? due
                                : due
                                      .take(_waitingPreviewCountPerGroup)
                                      .toList(growable: false);
                            final dueHasMore =
                                due.length > _waitingPreviewCountPerGroup;

                            final reasonTextById = <String, String>{
                              for (final task in dueVisible)
                                task.id: task.effectiveValues.isEmpty
                                    ? l10n.myDayDueSoonLabel
                                    : '${l10n.myDayDueSoonLabel} • ${l10n.myDayValueAlignedLabel}',
                            };

                            return Column(
                              children: [
                                _MiniGroupHeader(
                                  title: l10n.myDayDueSoonLabel,
                                  count: due.length,
                                ),
                                _TaskTileColumn(
                                  dayKeyUtc: widget.dayKeyUtc,
                                  tasks: dueVisible,
                                  selected: widget.selected,
                                  reasonTextByTaskId: reasonTextById,
                                  reasonTooltipTextByTaskId:
                                      const <String, String>{},
                                  enableSnooze: true,
                                  enableSelection: true,
                                  selectionPillLabel:
                                      l10n.myDayAddToMyDayAction,
                                  selectionPillSelectedLabel:
                                      l10n.myDayAddedLabel,
                                  snoozeTooltip: l10n.myDaySnoozeAction,
                                ),
                                if (dueHasMore)
                                  _ShowMoreRow(
                                    isExpanded: _dueExpanded,
                                    remainingCount:
                                        due.length - dueVisible.length,
                                    totalCount: due.length,
                                    labelExpanded: l10n.myDayShowFewerLabel,
                                    labelCollapsed: l10n
                                        .myDayShowMoreCountLabel(
                                          due.length - dueVisible.length,
                                        ),
                                    onPressed: () => setState(
                                      () => _dueExpanded = !_dueExpanded,
                                    ),
                                  ),
                              ],
                            );
                          }(),
                        if (starts.isNotEmpty)
                          () {
                            final startsVisible = _startsExpanded
                                ? starts
                                : starts
                                      .take(_waitingPreviewCountPerGroup)
                                      .toList(growable: false);
                            final startsHasMore =
                                starts.length > _waitingPreviewCountPerGroup;

                            final reasonTextById = <String, String>{
                              for (final task in startsVisible)
                                task.id: task.effectiveValues.isEmpty
                                    ? l10n.myDayAvailableToStartLabel
                                    : '${l10n.myDayAvailableToStartLabel} • ${l10n.myDayValueAlignedLabel}',
                            };

                            return Column(
                              children: [
                                _MiniGroupHeader(
                                  title: l10n.myDayAvailableToStartLabel,
                                  count: starts.length,
                                ),
                                _TaskTileColumn(
                                  dayKeyUtc: widget.dayKeyUtc,
                                  tasks: startsVisible,
                                  selected: widget.selected,
                                  reasonTextByTaskId: reasonTextById,
                                  reasonTooltipTextByTaskId:
                                      const <String, String>{},
                                  enableSnooze: true,
                                  enableSelection: true,
                                  selectionPillLabel:
                                      l10n.myDayAddToMyDayAction,
                                  selectionPillSelectedLabel:
                                      l10n.myDayAddedLabel,
                                  snoozeTooltip: l10n.myDaySnoozeAction,
                                ),
                                if (startsHasMore)
                                  _ShowMoreRow(
                                    isExpanded: _startsExpanded,
                                    remainingCount:
                                        starts.length - startsVisible.length,
                                    totalCount: starts.length,
                                    labelExpanded: l10n.myDayShowFewerLabel,
                                    labelCollapsed: l10n
                                        .myDayShowMoreCountLabel(
                                          starts.length - startsVisible.length,
                                        ),
                                    onPressed: () => setState(
                                      () => _startsExpanded = !_startsExpanded,
                                    ),
                                  ),
                              ],
                            );
                          }(),
                      ],
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Divider(
                color: cs.outlineVariant,
                thickness: 1,
                height: 1,
              ),
            ),

            if (snoozedCount > 0) ...[
              if (!_snoozedExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
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
                      textStyle: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    child: Text(context.l10n.myDayHideLabel),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
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
        ),
      ),
    );
  }

  DateTime? _deadlineDateOnly(Task task) {
    final raw = task.occurrence?.deadline ?? task.deadlineDate;
    return dateOnlyOrNull(raw);
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

enum _SuggestedMenuAction { pickAllPicks, suggestionSettings }

class _SubsectionHeader extends StatelessWidget {
  const _SubsectionHeader({
    required this.title,
    required this.count,
    this.subtitle,
    this.action,
  });

  final String title;
  final int count;
  final String? subtitle;

  /// Optional trailing action widget (e.g. overflow menu).
  ///
  /// When provided, this is rendered instead of [actionLabel]/[onAction].
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$title · $count',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ?action,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniGroupHeader extends StatelessWidget {
  const _MiniGroupHeader({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$title ($count)',
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestedHeader extends StatelessWidget {
  const _SuggestedHeader({
    required this.count,
    required this.needsSetup,
    required this.onAddValues,
    required this.onWhyThesePressed,
    required this.onOpenSuggestionSettings,
    required this.onPickAllCurated,
  });

  final int count;
  final bool needsSetup;
  final VoidCallback onAddValues;
  final VoidCallback onWhyThesePressed;
  final VoidCallback onOpenSuggestionSettings;
  final VoidCallback onPickAllCurated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.myDayWhatMattersSectionTitle} · $count',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!needsSetup)
                TextButton(
                  onPressed: onWhyThesePressed,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(l10n.myDayWhyTheseAction),
                ),
              if (!needsSetup)
                PopupMenuButton<_SuggestedMenuAction>(
                  tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
                  onSelected: (action) {
                    switch (action) {
                      case _SuggestedMenuAction.pickAllPicks:
                        onPickAllCurated();
                      case _SuggestedMenuAction.suggestionSettings:
                        onOpenSuggestionSettings();
                    }
                  },
                  itemBuilder: (context) {
                    return <PopupMenuEntry<_SuggestedMenuAction>>[
                      PopupMenuItem(
                        value: _SuggestedMenuAction.pickAllPicks,
                        child: Text(l10n.myDayPickAllPicksMenuLabel),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: _SuggestedMenuAction.suggestionSettings,
                        child: Text(l10n.myDaySuggestionSettingsTitle),
                      ),
                    ];
                  },
                )
              else
                TextButton(
                  onPressed: onAddValues,
                  child: Text(
                    l10n.selectValuesHint,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.myDayWhatMattersSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
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

class _SectionEmptyPanel extends StatelessWidget {
  const _SectionEmptyPanel({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTileColumn extends StatelessWidget {
  const _TaskTileColumn({
    required this.dayKeyUtc,
    required this.tasks,
    required this.selected,
    required this.reasonTextByTaskId,
    required this.reasonTooltipTextByTaskId,
    required this.enableSnooze,
    required this.enableSelection,
    this.selectionPillLabel,
    this.selectionPillSelectedLabel,
    this.snoozeTooltip,
    this.completedStatusLabel,
  });

  final DateTime dayKeyUtc;
  final List<Task> tasks;
  final Set<String> selected;
  final Map<String, String> reasonTextByTaskId;
  final Map<String, String> reasonTooltipTextByTaskId;
  final bool enableSnooze;
  final bool enableSelection;
  final String? selectionPillLabel;
  final String? selectionPillSelectedLabel;
  final String? snoozeTooltip;
  final String? completedStatusLabel;

  @override
  Widget build(BuildContext context) {
    final labels = TasklyTaskRowLabels(
      completedStatusLabel: completedStatusLabel,
      pinnedSemanticLabel: context.l10n.pinnedSemanticLabel,
      selectionPillLabel: selectionPillLabel,
      selectionPillSelectedLabel: selectionPillSelectedLabel,
      snoozeTooltip: snoozeTooltip,
    );

    final rows = <TasklyRowSpec>[
      for (final task in tasks)
        () {
          final tileCapabilities = EntityTileCapabilitiesResolver.forTask(task);
          final isSelected = selected.contains(task.id);

          final data = buildTaskRowData(
            context,
            task: task,
            tileCapabilities: tileCapabilities,
            showProjectLabel: false,
          );

          final supportingText = reasonTextByTaskId[task.id];
          final supportingTooltipText = reasonTooltipTextByTaskId[task.id];

          final updatedData = TasklyTaskRowData(
            id: data.id,
            title: data.title,
            completed: data.completed,
            meta: data.meta,
            titlePrimaryValue: data.titlePrimaryValue,
            leadingChip: data.leadingChip,
            supportingText: supportingText,
            supportingTooltipText: supportingTooltipText,
            deemphasized: data.deemphasized,
            checkboxSemanticLabel: data.checkboxSemanticLabel,
            labels: labels,
          );

          return TasklyRowSpec.task(
            key: 'myday-picker-${task.id}',
            data: updatedData,
            intent: TasklyTaskRowIntent.selectionPicker(selected: isSelected),
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
                        dayKeyUtc: dayKeyUtc,
                        task: task,
                      ),
            ),
          );
        }(),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TasklyFeedRenderer.buildSection(
        TasklySectionSpec.standardList(
          id: 'myday-plan-picker',
          rows: rows,
        ),
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
        : remainingCount > 0
        ? context.l10n.showMoreCountLabel(
            remainingCount,
            labelCollapsed,
            totalCount,
          )
        : context.l10n.labelWithTotal(labelCollapsed, totalCount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: onPressed,
          child: Text(
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

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.title,
    required this.description,
    this.footer,
  });

  final String title;
  final String description;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (footer != null) ...[
              const SizedBox(height: 12),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
