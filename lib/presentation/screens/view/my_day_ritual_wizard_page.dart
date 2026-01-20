import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_ritual_bloc.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';
import 'package:taskly_ui/taskly_ui_entities.dart';

class MyDayRitualWizardPage extends StatelessWidget {
  const MyDayRitualWizardPage({super.key});

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
                  body: SafeArea(
                    bottom: false,
                    child: _RitualBody(
                      data: ritualState,
                      gateState: gateState,
                    ),
                  ),
                  bottomNavigationBar: _RitualBottomBar(data: ritualState),
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
  const _RitualBody({required this.data, required this.gateState});

  final MyDayRitualReady data;
  final MyDayGateState gateState;

  @override
  Widget build(BuildContext context) {
    final planned = data.planned;
    final curated = data.curated;
    final selected = data.selectedTaskIds;

    final gate = gateState is MyDayGateLoaded
        ? gateState as MyDayGateLoaded
        : null;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _HeroHeader(
            title: 'Choose what matters',
            subtitle: 'My Day keeps you on track.',
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
  const _RitualBottomBar({required this.data});

  final MyDayRitualReady data;

  @override
  Widget build(BuildContext context) {
    final selectedCount = data.selectedTaskIds.length;
    final isEnabled = selectedCount > 0;
    final label = isEnabled
        ? 'Continue to My Day · $selectedCount'
        : 'Select items to continue';

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
                    : () => context.read<MyDayRitualBloc>().add(
                        const MyDayRitualConfirm(),
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
    required this.selected,
    required this.curatedReasons,
    required this.curatedReasonTooltips,
    required this.gateState,
    required this.onStartSetup,
    required this.onChangeFocusMode,
    required this.onAcceptAllDue,
    required this.onAcceptAllStarts,
    required this.onAcceptAllCurated,
  });

  final FocusMode focusMode;
  final DateTime dayKeyUtc;
  final List<Task> planned;
  final int dueWindowDays;
  final List<Task> curated;
  final Set<String> selected;
  final Map<String, String> curatedReasons;
  final Map<String, String> curatedReasonTooltips;
  final MyDayGateLoaded? gateState;
  final VoidCallback onStartSetup;
  final VoidCallback onChangeFocusMode;
  final VoidCallback onAcceptAllDue;
  final VoidCallback onAcceptAllStarts;
  final VoidCallback onAcceptAllCurated;

  @override
  State<_RitualCard> createState() => _RitualCardState();
}

class _RitualCardState extends State<_RitualCard> {
  static const _plannedPreviewPerGroup = 2;
  static const _plannedPreviewTotal = 4;
  static const _curatedPreviewCount = 4;

  late bool _dueExpanded;
  late bool _startsExpanded;
  late bool _curatedExpanded;

  @override
  void initState() {
    super.initState();
    _dueExpanded = widget.planned.length <= _plannedPreviewTotal;
    _startsExpanded = widget.planned.length <= _plannedPreviewTotal;
    _curatedExpanded = false;
  }

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
            if (plannedCount == 0)
              const _EmptyPanel(
                title: 'Nothing planned yet',
                description: 'No tasks are due soon or available to start.',
              )
            else
              Column(
                children: [
                  if (due.isEmpty)
                    const _SectionEmptyPanel(
                      title: 'Overdue & due',
                      description: "You're caught up.",
                    )
                  else ...[
                    _SubsectionHeader(
                      title: 'Overdue & due',
                      count: due.length,
                      actionLabel: 'Add all due',
                      onAction: widget.onAcceptAllDue,
                    ),
                    _TaskTileColumn(
                      dayKeyUtc: widget.dayKeyUtc,
                      tasks: dueVisible,
                      selected: widget.selected,
                      reasonTextByTaskId: const <String, String>{},
                      reasonTooltipTextByTaskId: const <String, String>{},
                      enableSnooze: true,
                    ),
                    if (dueHasMore)
                      _ShowMoreRow(
                        isExpanded: _dueExpanded,
                        remainingCount: due.length - dueVisible.length,
                        totalCount: due.length,
                        labelExpanded: 'Show fewer',
                        labelCollapsed: 'Show all due items',
                        onPressed: () =>
                            setState(() => _dueExpanded = !_dueExpanded),
                      ),
                  ],
                  if (starts.isEmpty)
                    const _SectionEmptyPanel(
                      title: 'Planned for today (or earlier)',
                      description:
                          'Tasks whose planned day is today or earlier. '
                          'Nothing available right now.',
                    )
                  else ...[
                    _SubsectionHeader(
                      title: 'Planned for today (or earlier)',
                      count: starts.length,
                      subtitle: 'Tasks whose planned day is today or earlier.',
                      actionLabel: 'Add all available',
                      onAction: widget.onAcceptAllStarts,
                    ),
                    _TaskTileColumn(
                      dayKeyUtc: widget.dayKeyUtc,
                      tasks: startsVisible,
                      selected: widget.selected,
                      reasonTextByTaskId: const <String, String>{},
                      reasonTooltipTextByTaskId: const <String, String>{},
                      enableSnooze: true,
                    ),
                    if (startsHasMore)
                      _ShowMoreRow(
                        isExpanded: _startsExpanded,
                        remainingCount: starts.length - startsVisible.length,
                        totalCount: starts.length,
                        labelExpanded: 'Show fewer',
                        labelCollapsed: 'Show all available',
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
            _SuggestedHeader(
              count: curatedCount,
              focusMode: widget.focusMode,
              needsSetup: needsSetup,
              onStartSetup: widget.onStartSetup,
              onChangeFocusMode: widget.onChangeFocusMode,
              onAcceptAllCurated: widget.onAcceptAllCurated,
            ),
            if (needsSetup)
              _SuggestedSetupCard(gateState: widget.gateState!)
            else if (curatedCount == 0)
              const _EmptyPanel(
                title: 'No suggested picks yet',
                description: 'Check back later or adjust your focus mode.',
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

class _SubsectionHeader extends StatelessWidget {
  const _SubsectionHeader({
    required this.title,
    required this.count,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final int count;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

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
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  child: Text(
                    actionLabel!,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
    required this.onAcceptAllCurated,
  });

  final int count;
  final FocusMode focusMode;
  final bool needsSetup;
  final VoidCallback onStartSetup;
  final VoidCallback onChangeFocusMode;
  final VoidCallback onAcceptAllCurated;

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
                  'Suggested for you · $count',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!needsSetup)
                TextButton(
                  onPressed: onAcceptAllCurated,
                  child: Text(
                    'Add all picks',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                TextButton(
                  onPressed: onStartSetup,
                  child: Text(
                    'Start setup',
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
                'Unlock suggestions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set up a focus mode and add your first value to get tailored picks here.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              if (gateState.needsFocusModeSetup)
                _GateRow(
                  icon: Icons.tune,
                  label: 'Choose a focus mode',
                ),
              if (gateState.needsValuesSetup)
                _GateRow(
                  icon: Icons.favorite_outline,
                  label: 'Add your first value',
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
          'Mode: ${focusMode.displayName} · ${focusMode.tagline}',
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
          child: const Text('Change'),
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
  });

  final DateTime dayKeyUtc;
  final List<Task> tasks;
  final Set<String> selected;
  final Map<String, String> reasonTextByTaskId;
  final Map<String, String> reasonTooltipTextByTaskId;
  final bool enableSnooze;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final task in tasks)
          _TaskTileRow(
            dayKeyUtc: dayKeyUtc,
            task: task,
            selected: selected.contains(task.id),
            reasonText: reasonTextByTaskId[task.id],
            reasonTooltipText: reasonTooltipTextByTaskId[task.id],
            enableSnooze: enableSnooze,
          ),
      ],
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
        ? 'Show $remainingCount more · $labelCollapsed ($totalCount)'
        : '$labelCollapsed ($totalCount)';

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

class _TaskTileRow extends StatelessWidget {
  const _TaskTileRow({
    required this.dayKeyUtc,
    required this.task,
    required this.selected,
    required this.reasonText,
    required this.reasonTooltipText,
    required this.enableSnooze,
  });

  final DateTime dayKeyUtc;
  final Task task;
  final bool selected;
  final String? reasonText;
  final String? reasonTooltipText;
  final bool enableSnooze;

  @override
  Widget build(BuildContext context) {
    final tileCapabilities = EntityTileCapabilitiesResolver.forTask(task);
    final model = buildTaskListRowTileModel(
      context,
      task: task,
      tileCapabilities: tileCapabilities,
      showProjectLabel: true,
    );

    return SelectableTaskEntityTile(
      model: model,
      selected: selected,
      reasonText: reasonText,
      reasonTooltipText: reasonTooltipText,
      onToggleSelected: () => _toggleSelection(context),
      onSnoozeRequested: !enableSnooze
          ? null
          : () => _showSnoozeSheet(
              context,
              dayKeyUtc: dayKeyUtc,
              task: task,
            ),
    );
  }

  void _toggleSelection(BuildContext context) {
    context.read<MyDayRitualBloc>().add(
      MyDayRitualToggleTask(
        task.id,
        selected: !selected,
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
                title: const Text('Snooze'),
                subtitle: const Text('Set a new planned day (availability).'),
              ),
              ListTile(
                leading: const Icon(Icons.today),
                title: const Text('Tomorrow'),
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
                title: const Text('Next week'),
                onTap: () async {
                  await _confirmAndDispatchSnooze(
                    parentContext,
                    sheetContext,
                    task: task,
                    newStartDate: nextWeek,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.event),
                title: const Text('Pick date…'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: sheetContext,
                    initialDate: tomorrow,
                    firstDate: tomorrow,
                    lastDate: today.add(const Duration(days: 365 * 5)),
                  );
                  if (picked == null) return;
                  if (!sheetContext.mounted || !parentContext.mounted) return;
                  await _confirmAndDispatchSnooze(
                    parentContext,
                    sheetContext,
                    task: task,
                    newStartDate: dateOnly(picked),
                  );
                },
              ),
              const SizedBox(height: 12),
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
            title: const Text('Snooze past due date?'),
            content: Text(
              'This task is due on ${localizations.formatMediumDate(deadline)}. '
              'Snoozing to ${localizations.formatMediumDate(newStartDate)} '
              'keeps the due date the same.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Snooze anyway'),
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

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

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
          ],
        ),
      ),
    );
  }
}
