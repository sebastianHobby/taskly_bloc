import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_ritual_bloc.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/core.dart' hide MyDayRitualState;
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';
import 'package:taskly_ui/taskly_ui_entities.dart';

class MyDayRitualWizardPage extends StatelessWidget {
  const MyDayRitualWizardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<MyDayRitualBloc, MyDayRitualState>(
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
      child: BlocBuilder<MyDayRitualBloc, MyDayRitualState>(
        builder: (context, ritualState) {
          return BlocBuilder<MyDayGateBloc, MyDayGateState>(
            builder: (context, gateState) {
              final gateMissing =
                  gateState is MyDayGateLoaded &&
                  (gateState.needsFocusModeSetup || gateState.needsValuesSetup);

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
                  bottomNavigationBar: gateMissing
                      ? null
                      : _RitualBottomBar(data: ritualState),
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
    final dateLabel = DateFormat('EEEE, MMM d').format(DateTime.now());

    final gate = gateState;
    final gateMissing =
        gate is MyDayGateLoaded &&
        (gate.needsFocusModeSetup || gate.needsValuesSetup);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _HeroHeader(
            dateLabel: dateLabel,
            title: 'Choose what matters today.',
            subtitle: 'Planned items first, then curated picks.',
          ),
        ),
        if (gateMissing)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverToBoxAdapter(
              child: _RitualGateCard(gateState: gate),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverToBoxAdapter(
              child: _RitualCard(
                focusMode: data.focusMode,
                dayKeyUtc: data.dayKeyUtc,
                planned: planned,
                curated: curated,
                selected: selected,
                curatedReasons: data.curatedReasons,
                onChangeFocusMode: () => context.read<MyDayRitualBloc>().add(
                  const MyDayRitualFocusModeWizardRequested(),
                ),
                onAcceptAllPlanned: () => context.read<MyDayRitualBloc>().add(
                  const MyDayRitualAcceptAllPlanned(),
                ),
                onAcceptAllCurated: () => context.read<MyDayRitualBloc>().add(
                  const MyDayRitualAcceptAllCurated(),
                ),
                onSuggestedInfo: () => _showSuggestedInfo(context),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }
}

class _RitualGateCard extends StatelessWidget {
  const _RitualGateCard({required this.gateState});

  final MyDayGateLoaded gateState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finish setup to start your day',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              gateState.descriptionText,
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

    if (gateState.needsValuesSetup) {
      Routing.toScreenKeyWithQuery(
        context,
        'focus_setup',
        queryParameters: const {'step': 'values'},
      );
    }
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

class _RitualBottomBar extends StatelessWidget {
  const _RitualBottomBar({required this.data});

  final MyDayRitualReady data;

  @override
  Widget build(BuildContext context) {
    final selectedCount = data.selectedTaskIds.length;
    final label = selectedCount > 0
        ? 'Start my day · $selectedCount'
        : 'Start my day';

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
                onPressed: selectedCount == 0
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
    required this.dateLabel,
    required this.title,
    required this.subtitle,
  });

  final String dateLabel;
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
                dateLabel.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.stepLabel,
    this.helperText,
  });

  final String? stepLabel;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stepLabel != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                stepLabel!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (helperText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                helperText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RitualCard extends StatefulWidget {
  const _RitualCard({
    required this.focusMode,
    required this.dayKeyUtc,
    required this.planned,
    required this.curated,
    required this.selected,
    required this.curatedReasons,
    required this.onChangeFocusMode,
    required this.onAcceptAllPlanned,
    required this.onAcceptAllCurated,
    required this.onSuggestedInfo,
  });

  final FocusMode focusMode;
  final DateTime dayKeyUtc;
  final List<Task> planned;
  final List<Task> curated;
  final Set<String> selected;
  final Map<String, String> curatedReasons;
  final VoidCallback onChangeFocusMode;
  final VoidCallback onAcceptAllPlanned;
  final VoidCallback onAcceptAllCurated;
  final VoidCallback onSuggestedInfo;

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

    final due = <Task>[];
    final starts = <Task>[];
    for (final task in widget.planned) {
      final deadline = _deadlineDateOnly(task);
      if (deadline != null && !deadline.isAfter(today)) {
        due.add(task);
      } else {
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
            _SectionHeader(
              stepLabel: 'Step 1 · Planned',
              title: 'Planned · $plannedCount',
              actionLabel: 'Accept all planned',
              helperText: plannedCount == 0
                  ? null
                  : 'Start with planned or time‑sensitive.',
              onAction: widget.onAcceptAllPlanned,
            ),
            if (plannedCount == 0)
              const _EmptyPanel(
                title: 'No planned tasks',
                description: 'Nothing is due or scheduled to start today.',
              )
            else
              Column(
                children: [
                  if (due.isNotEmpty) ...[
                    _SubsectionHeader(
                      title: 'Overdue & due',
                      count: due.length,
                    ),
                    _TaskTileColumn(
                      tasks: dueVisible,
                      selected: widget.selected,
                      reasonTextByTaskId: const <String, String>{},
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
                  if (starts.isNotEmpty) ...[
                    _SubsectionHeader(
                      title: 'Starts today',
                      count: starts.length,
                    ),
                    _TaskTileColumn(
                      tasks: startsVisible,
                      selected: widget.selected,
                      reasonTextByTaskId: const <String, String>{},
                    ),
                    if (startsHasMore)
                      _ShowMoreRow(
                        isExpanded: _startsExpanded,
                        remainingCount: starts.length - startsVisible.length,
                        totalCount: starts.length,
                        labelExpanded: 'Show fewer',
                        labelCollapsed: 'Show all starts',
                        onPressed: () =>
                            setState(() => _startsExpanded = !_startsExpanded),
                      ),
                  ],
                ],
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Divider(color: cs.outlineVariant),
            ),
            _SuggestedHeader(
              count: curatedCount,
              focusMode: widget.focusMode,
              onChangeFocusMode: widget.onChangeFocusMode,
              onAcceptAllCurated: widget.onAcceptAllCurated,
              onSuggestedInfo: widget.onSuggestedInfo,
            ),
            if (curatedCount == 0)
              const _EmptyPanel(
                title: 'No curated picks today',
                description: 'Your focus mode has no suggestions yet.',
              )
            else
              Column(
                children: [
                  _TaskTileColumn(
                    tasks: curatedVisible,
                    selected: widget.selected,
                    reasonTextByTaskId: widget.curatedReasons,
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
  const _SubsectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$title · $count',
              style: theme.textTheme.labelLarge?.copyWith(
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
    required this.focusMode,
    required this.onChangeFocusMode,
    required this.onAcceptAllCurated,
    required this.onSuggestedInfo,
  });

  final int count;
  final FocusMode focusMode;
  final VoidCallback onChangeFocusMode;
  final VoidCallback onAcceptAllCurated;
  final VoidCallback onSuggestedInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2 · Suggested',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Suggested · $count',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 18),
                onPressed: onSuggestedInfo,
                tooltip: 'Why these picks?',
              ),
              TextButton(
                onPressed: onChangeFocusMode,
                child: Text(focusMode.displayName),
              ),
              TextButton(
                onPressed: onAcceptAllCurated,
                child: Text(
                  'Accept all picks',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (count > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Based on values + focus mode.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskTileColumn extends StatelessWidget {
  const _TaskTileColumn({
    required this.tasks,
    required this.selected,
    required this.reasonTextByTaskId,
  });

  final List<Task> tasks;
  final Set<String> selected;
  final Map<String, String> reasonTextByTaskId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final task in tasks)
          _TaskTileRow(
            task: task,
            selected: selected.contains(task.id),
            reasonText: reasonTextByTaskId[task.id],
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
    required this.task,
    required this.selected,
    required this.reasonText,
  });

  final Task task;
  final bool selected;
  final String? reasonText;

  @override
  Widget build(BuildContext context) {
    final tileCapabilities = EntityTileCapabilitiesResolver.forTask(task);
    final model = buildTaskListRowTileModel(
      context,
      task: task,
      tileCapabilities: tileCapabilities,
      showProjectLabel: true,
    );

    return TaskListRowTile(
      model: model,
      onTap: () => _toggleSelection(context),
      onToggleCompletion: null,
      subtitle: reasonText == null
          ? null
          : Text(
              reasonText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
      trailing: _SelectPill(
        selected: selected,
        onPressed: () => _toggleSelection(context),
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
}

class _SelectPill extends StatelessWidget {
  const _SelectPill({
    required this.selected,
    required this.onPressed,
  });

  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = selected ? 'Added' : 'Add';
    final background = selected
        ? scheme.surfaceContainerLow
        : scheme.surfaceContainerHighest;
    final foreground = selected
        ? scheme.onSurfaceVariant
        : scheme.onSurfaceVariant;
    final border = selected ? Border.all(color: scheme.outlineVariant) : null;

    return InkWell(
      onTap: selected ? null : onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        constraints: const BoxConstraints(minWidth: 64),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: border,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

void _showSuggestedInfo(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Why these picks?'),
      content: const Text(
        'Suggested tasks are selected based on your focus mode and current '
        'signals like values, neglect, and time sensitivity.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
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
