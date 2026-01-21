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
import 'package:taskly_ui/taskly_ui_entities.dart';
import 'package:taskly_ui/taskly_ui_sections.dart';

enum MyDayRitualWizardInitialSection { due, starts, suggested }

class MyDayRitualWizardPage extends StatelessWidget {
  const MyDayRitualWizardPage({
    super.key,
    this.allowClose = false,
    this.initialSection,
  });

  final bool allowClose;
  final MyDayRitualWizardInitialSection? initialSection;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<MyDayRitualBloc, MyDayRitualState>(
          listenWhen: (previous, current) {
            return previous is MyDayRitualReady &&
                current is MyDayRitualReady &&
                previous.navRequestId != current.navRequestId &&
                current.nav == MyDayRitualNav.openFocusSetupWizard;
          },
          listener: (context, state) {
            Routing.toScreenKeyWithQuery(
              context,
              'focus_setup',
              queryParameters: const {'step': 'select_focus_mode'},
            );
          },
        ),
        BlocListener<MyDayRitualBloc, MyDayRitualState>(
          listenWhen: (previous, current) {
            if (!allowClose) return false;
            return previous is MyDayRitualReady &&
                current is MyDayRitualReady &&
                previous.navRequestId != current.navRequestId &&
                current.nav == MyDayRitualNav.closeWizard;
          },
          listener: (context, state) {
            Navigator.of(context).maybePop();
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
                          leading: const CloseButton(),
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
              focusMode: data.focusMode,
              dayKeyUtc: data.dayKeyUtc,
              planned: planned,
              dueWindowDays: data.dueWindowDays,
              curated: curated,
              completedPicks: completedPicks,
              selected: selected,
              curatedReasons: data.curatedReasons,
              curatedReasonTooltips: data.curatedReasonTooltips,
              gateState: gate,
              onStartSetup: () => _openFocusSetup(context, gate),
              onChangeFocusMode: () => context.read<MyDayRitualBloc>().add(
                const MyDayRitualFocusModeWizardRequested(),
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

  void _openFocusSetup(BuildContext context, MyDayGateLoaded? gateState) {
    final needsFocusModeSetup = gateState?.needsFocusModeSetup ?? true;
    if (needsFocusModeSetup) {
      Routing.toScreenKeyWithQuery(
        context,
        'focus_setup',
        queryParameters: const {'step': 'select_focus_mode'},
      );
      return;
    }

    Routing.toScreenKeyWithQuery(
      context,
      'focus_setup',
      queryParameters: const {'step': 'values'},
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
    required this.focusMode,
    required this.dayKeyUtc,
    required this.planned,
    required this.dueWindowDays,
    required this.curated,
    required this.completedPicks,
    required this.selected,
    required this.curatedReasons,
    required this.curatedReasonTooltips,
    required this.gateState,
    required this.onStartSetup,
    required this.onChangeFocusMode,
    required this.onAcceptAllDue,
    required this.onAcceptAllStarts,
    required this.onAcceptAllCurated,
    required this.onGenerateMoreCurated,
    required this.initialSection,
  });

  final FocusMode focusMode;
  final DateTime dayKeyUtc;
  final List<Task> planned;
  final int dueWindowDays;
  final List<Task> curated;
  final List<Task> completedPicks;
  final Set<String> selected;
  final Map<String, String> curatedReasons;
  final Map<String, String> curatedReasonTooltips;
  final MyDayGateLoaded? gateState;
  final VoidCallback onStartSetup;
  final VoidCallback onChangeFocusMode;
  final VoidCallback onAcceptAllDue;
  final VoidCallback onAcceptAllStarts;
  final VoidCallback onAcceptAllCurated;
  final VoidCallback onGenerateMoreCurated;
  final MyDayRitualWizardInitialSection? initialSection;

  @override
  State<_RitualCard> createState() => _RitualCardState();
}

class _RitualCardState extends State<_RitualCard> {
  static const _plannedPreviewPerGroup = 2;
  static const _plannedPreviewTotal = 4;
  static const _curatedPreviewCount = 4;

  static const _bulkPickConfirmThreshold = 5;

  final GlobalKey<State<StatefulWidget>> _dueHeaderKey = GlobalKey();
  final GlobalKey<State<StatefulWidget>> _startsHeaderKey = GlobalKey();
  final GlobalKey<State<StatefulWidget>> _suggestedHeaderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _dueExpanded = widget.planned.length <= _plannedPreviewTotal;
    _startsExpanded = widget.planned.length <= _plannedPreviewTotal;
    _curatedExpanded = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final section = widget.initialSection;
      if (section == null) return;

      final context = switch (section) {
        MyDayRitualWizardInitialSection.due => _dueHeaderKey.currentContext,
        MyDayRitualWizardInitialSection.starts =>
          _startsHeaderKey.currentContext,
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

  Future<void> _confirmPickAllDue(BuildContext context, {required int count}) {
    if (count <= 0) return Future.value();
    if (count <= _bulkPickConfirmThreshold) {
      widget.onAcceptAllDue();
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
                  l10n.myDayPickAllDueTitle,
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
                          widget.onAcceptAllDue();
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

  Future<void> _confirmPickAllStarts(
    BuildContext context, {
    required int count,
  }) {
    if (count <= 0) return Future.value();
    if (count <= _bulkPickConfirmThreshold) {
      widget.onAcceptAllStarts();
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
                  l10n.myDayPickAllAvailableTitle,
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
                          widget.onAcceptAllStarts();
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

  late bool _dueExpanded;
  late bool _startsExpanded;
  late bool _curatedExpanded;

  @override
  void didUpdateWidget(covariant _RitualCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.planned.length != widget.planned.length) {
      if (widget.planned.length <= _plannedPreviewTotal) {
        _dueExpanded = true;
        _startsExpanded = true;
      }
    }
    if (oldWidget.curated.length != widget.curated.length) {
      if (widget.curated.length <= _curatedPreviewCount) {
        _curatedExpanded = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final plannedCount = widget.planned.length;
    final curatedCount = widget.curated.length;
    final completedCount = widget.completedPicks.length;
    final today = dateOnly(widget.dayKeyUtc);
    final dueWindowDays = widget.dueWindowDays.clamp(1, 30);
    final dueLimit = today.add(Duration(days: dueWindowDays - 1));

    final needsSetup =
        widget.gateState != null &&
        (widget.gateState!.needsFocusModeSetup ||
            widget.gateState!.needsValuesSetup);

    final due = <Task>[];
    final starts = <Task>[];
    for (final task in widget.planned) {
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

    final dueVisible = _dueExpanded
        ? due
        : due.take(_plannedPreviewPerGroup).toList(growable: false);
    final startsVisible = _startsExpanded
        ? starts
        : starts.take(_plannedPreviewPerGroup).toList(growable: false);

    final dueHasMore = due.length > _plannedPreviewPerGroup;
    final startsHasMore = starts.length > _plannedPreviewPerGroup;

    final curatedVisible = _curatedExpanded
        ? widget.curated
        : widget.curated.take(_curatedPreviewCount).toList(growable: false);
    final curatedHasMore = widget.curated.length > _curatedPreviewCount;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          children: [
            if (completedCount > 0) ...[
              _SubsectionHeader(
                title: context.l10n.myDayCompletedSectionTitle,
                count: completedCount,
                subtitle: context.l10n.myDayCompletedSectionSubtitle,
              ),
              _TaskTileColumn(
                dayKeyUtc: widget.dayKeyUtc,
                tasks: widget.completedPicks,
                selected: widget.selected,
                reasonTextByTaskId: const <String, String>{},
                reasonTooltipTextByTaskId: const <String, String>{},
                enableSnooze: false,
                enableSelection: false,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Divider(
                  color: cs.outlineVariant,
                  thickness: 1,
                  height: 1,
                ),
              ),
            ],
            if (plannedCount == 0)
              _EmptyPanel(
                title: context.l10n.myDayNothingPlannedYetTitle,
                description: context.l10n.myDayNothingPlannedYetBody,
              )
            else
              Column(
                children: [
                  if (due.isEmpty)
                    _SectionEmptyPanel(
                      title: context.l10n.myDayRitualOverdueDueTitle,
                      description: context.l10n.myDayYoureCaughtUpBody,
                    )
                  else ...[
                    KeyedSubtree(
                      key: _dueHeaderKey,
                      child: _SubsectionHeader(
                        title: context.l10n.myDayRitualOverdueDueTitle,
                        count: due.length,
                        action: PopupMenuButton<_DueMenuAction>(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).moreButtonTooltip,
                          onSelected: (action) {
                            switch (action) {
                              case _DueMenuAction.pickAllDue:
                                _confirmPickAllDue(
                                  context,
                                  count: due.length,
                                );
                            }
                          },
                          itemBuilder: (context) {
                            final l10n = context.l10n;
                            return <PopupMenuEntry<_DueMenuAction>>[
                              PopupMenuItem(
                                value: _DueMenuAction.pickAllDue,
                                child: Text(l10n.myDayPickAllDueMenuLabel),
                              ),
                            ];
                          },
                        ),
                      ),
                    ),
                    _TaskTileColumn(
                      dayKeyUtc: widget.dayKeyUtc,
                      tasks: dueVisible,
                      selected: widget.selected,
                      reasonTextByTaskId: const <String, String>{},
                      reasonTooltipTextByTaskId: const <String, String>{},
                      enableSnooze: true,
                      enableSelection: true,
                    ),
                    if (dueHasMore)
                      _ShowMoreRow(
                        isExpanded: _dueExpanded,
                        remainingCount: due.length - dueVisible.length,
                        totalCount: due.length,
                        labelExpanded: context.l10n.myDayShowFewerLabel,
                        labelCollapsed: context.l10n.myDayShowAllDueItemsLabel,
                        onPressed: () =>
                            setState(() => _dueExpanded = !_dueExpanded),
                      ),
                  ],
                  if (starts.isEmpty)
                    _SectionEmptyPanel(
                      title: context.l10n.myDayPlannedForTodayTitle,
                      description: context.l10n.myDayPlannedForTodayEmptyBody,
                    )
                  else ...[
                    KeyedSubtree(
                      key: _startsHeaderKey,
                      child: _SubsectionHeader(
                        title: context.l10n.myDayPlannedForTodayTitle,
                        count: starts.length,
                        subtitle: context.l10n.myDayPlannedForTodaySubtitle,
                        action: PopupMenuButton<_StartsMenuAction>(
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).moreButtonTooltip,
                          onSelected: (action) {
                            switch (action) {
                              case _StartsMenuAction.pickAllAvailable:
                                _confirmPickAllStarts(
                                  context,
                                  count: starts.length,
                                );
                            }
                          },
                          itemBuilder: (context) {
                            final l10n = context.l10n;
                            return <PopupMenuEntry<_StartsMenuAction>>[
                              PopupMenuItem(
                                value: _StartsMenuAction.pickAllAvailable,
                                child: Text(
                                  l10n.myDayPickAllAvailableMenuLabel,
                                ),
                              ),
                            ];
                          },
                        ),
                      ),
                    ),
                    _TaskTileColumn(
                      dayKeyUtc: widget.dayKeyUtc,
                      tasks: startsVisible,
                      selected: widget.selected,
                      reasonTextByTaskId: const <String, String>{},
                      reasonTooltipTextByTaskId: const <String, String>{},
                      enableSnooze: true,
                      enableSelection: true,
                    ),
                    if (startsHasMore)
                      _ShowMoreRow(
                        isExpanded: _startsExpanded,
                        remainingCount: starts.length - startsVisible.length,
                        totalCount: starts.length,
                        labelExpanded: context.l10n.myDayShowFewerLabel,
                        labelCollapsed: context.l10n.myDayShowAllAvailableLabel,
                        onPressed: () =>
                            setState(() => _startsExpanded = !_startsExpanded),
                      ),
                  ],
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
              key: _suggestedHeaderKey,
              child: _SuggestedHeader(
                count: curatedCount,
                focusMode: widget.focusMode,
                needsSetup: needsSetup,
                onStartSetup: widget.onStartSetup,
                onChangeFocusMode: widget.onChangeFocusMode,
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
                  _TaskTileColumn(
                    dayKeyUtc: widget.dayKeyUtc,
                    tasks: curatedVisible,
                    selected: widget.selected,
                    reasonTextByTaskId: widget.curatedReasons,
                    reasonTooltipTextByTaskId: widget.curatedReasonTooltips,
                    enableSnooze: false,
                    enableSelection: true,
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
                                'Suggested complete — generate another batch?',
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
                      labelExpanded: 'Show fewer',
                      labelCollapsed: 'Show all picks',
                      onPressed: () =>
                          setState(() => _curatedExpanded = !_curatedExpanded),
                    ),
                ],
              ),
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

enum _DueMenuAction { pickAllDue }

enum _StartsMenuAction { pickAllAvailable }

enum _SuggestedMenuAction { pickAllPicks }

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
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SuggestedHeader extends StatelessWidget {
  const _SuggestedHeader({
    required this.count,
    required this.focusMode,
    required this.needsSetup,
    required this.onStartSetup,
    required this.onChangeFocusMode,
    required this.onPickAllCurated,
  });

  final int count;
  final FocusMode focusMode;
  final bool needsSetup;
  final VoidCallback onStartSetup;
  final VoidCallback onChangeFocusMode;
  final VoidCallback onPickAllCurated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.myDaySuggestedForYouTitle(count),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!needsSetup)
                PopupMenuButton<_SuggestedMenuAction>(
                  tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
                  onSelected: (action) {
                    switch (action) {
                      case _SuggestedMenuAction.pickAllPicks:
                        onPickAllCurated();
                    }
                  },
                  itemBuilder: (context) {
                    final l10n = context.l10n;
                    return <PopupMenuEntry<_SuggestedMenuAction>>[
                      PopupMenuItem(
                        value: _SuggestedMenuAction.pickAllPicks,
                        child: Text(l10n.myDayPickAllPicksMenuLabel),
                      ),
                    ];
                  },
                )
              else
                TextButton(
                  onPressed: onStartSetup,
                  child: Text(
                    context.l10n.myDayStartSetupLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (!needsSetup)
            _FocusModeHelperLine(
              focusMode: focusMode,
              onChangeFocusMode: onChangeFocusMode,
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
              if (gateState.needsFocusModeSetup)
                _GateRow(
                  icon: Icons.tune,
                  label: l10n.myDayChooseFocusModeLabel,
                ),
              if (gateState.needsValuesSetup)
                _GateRow(
                  icon: Icons.favorite_outline,
                  label: l10n.myDayAddFirstValueLabel,
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openFocusSetup(context),
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

  void _openFocusSetup(BuildContext context) {
    if (gateState.needsFocusModeSetup) {
      Routing.toScreenKeyWithQuery(
        context,
        'focus_setup',
        queryParameters: const {'step': 'select_focus_mode'},
      );
      return;
    }

    Routing.toScreenKeyWithQuery(
      context,
      'focus_setup',
      queryParameters: const {'step': 'values'},
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

class _FocusModeHelperLine extends StatelessWidget {
  const _FocusModeHelperLine({
    required this.focusMode,
    required this.onChangeFocusMode,
  });

  final FocusMode focusMode;
  final VoidCallback onChangeFocusMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final helperStyle = theme.textTheme.bodySmall?.copyWith(
      color: cs.onSurfaceVariant,
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 6,
      children: [
        Text(
          context.l10n.focusModeHelperLine(
            focusMode.displayName,
            focusMode.tagline,
          ),
          style: helperStyle,
        ),
        TextButton(
          onPressed: onChangeFocusMode,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(context.l10n.changeButton),
        ),
      ],
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
  });

  final DateTime dayKeyUtc;
  final List<Task> tasks;
  final Set<String> selected;
  final Map<String, String> reasonTextByTaskId;
  final Map<String, String> reasonTooltipTextByTaskId;
  final bool enableSnooze;
  final bool enableSelection;

  @override
  Widget build(BuildContext context) {
    final items = tasks
        .map(
          (task) => _toPickerItem(
            context,
            dayKeyUtc: dayKeyUtc,
            task: task,
            selected: selected.contains(task.id),
            reasonText: reasonTextByTaskId[task.id],
            reasonTooltipText: reasonTooltipTextByTaskId[task.id],
          ),
        )
        .toList(growable: false);

    return MyDayPlanPickerTaskListSection(items: items);
  }

  MyDayPlanPickerTaskItem _toPickerItem(
    BuildContext context, {
    required DateTime dayKeyUtc,
    required Task task,
    required bool selected,
    required String? reasonText,
    required String? reasonTooltipText,
  }) {
    final tileCapabilities = EntityTileCapabilitiesResolver.forTask(task);
    final model = buildTaskListRowTileModel(
      context,
      task: task,
      tileCapabilities: tileCapabilities,
      showProjectLabel: false,
    );

    return MyDayPlanPickerTaskItem(
      model: model,
      selected: selected,
      supportingText: reasonText,
      supportingTooltipText: reasonTooltipText,
      markers: TaskTileMarkers(pinned: task.isPinned),
      onToggleSelected: !enableSelection
          ? null
          : () {
              context.read<MyDayRitualBloc>().add(
                MyDayRitualToggleTask(task.id, selected: !selected),
              );
            },
      onSnoozeRequested: !enableSnooze
          ? null
          : () => _showSnoozeSheet(
              context,
              dayKeyUtc: dayKeyUtc,
              task: task,
            ),
    );
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
                title: Text(context.l10n.snoozeTitle),
                subtitle: Text(context.l10n.snoozeSubtitle),
              ),
              ListTile(
                leading: const Icon(Icons.today),
                title: Text(context.l10n.dateTomorrow),
                onTap: () async {
                  await _confirmAndDispatchSnooze(
                    parentContext,
                    sheetContext,
                    task: task,
                    newStartDate: tomorrow,
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
                    newStartDate: nextWeek,
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
    required DateTime newStartDate,
  }) async {
    final bloc = parentContext.read<MyDayRitualBloc>();
    final navigator = Navigator.of(sheetContext);
    final deadline = dateOnlyOrNull(task.deadlineDate);

    if (deadline != null && newStartDate.isAfter(deadline)) {
      final localizations = MaterialLocalizations.of(sheetContext);
      final confirm = await showDialog<bool>(
        context: sheetContext,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(dialogContext.l10n.snoozePastDueDateTitle),
            content: Text(
              dialogContext.l10n.snoozePastDueDateBody(
                localizations.formatMediumDate(deadline),
                localizations.formatMediumDate(newStartDate),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(dialogContext.l10n.cancelLabel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(dialogContext.l10n.snoozeAnywayButton),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;
    }

    if (!navigator.mounted) return;

    if (navigator.canPop()) {
      navigator.pop();
    }

    bloc.add(
      MyDayRitualSnoozeTaskRequested(
        taskId: task.id,
        newStartDate: newStartDate,
      ),
    );
  }
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
