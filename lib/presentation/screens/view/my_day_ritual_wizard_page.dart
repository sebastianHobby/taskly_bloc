import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_ritual_bloc.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/core.dart' hide MyDayRitualState;
import 'package:taskly_domain/services.dart';
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
        builder: (context, state) {
          return switch (state) {
            MyDayRitualLoading() => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            MyDayRitualReady() => Scaffold(
              body: SafeArea(
                bottom: false,
                child: _RitualBody(data: state),
              ),
              bottomNavigationBar: _RitualBottomBar(data: state),
            ),
          };
        },
      ),
    );
  }
}

class _RitualBody extends StatelessWidget {
  const _RitualBody({required this.data});

  final MyDayRitualReady data;

  @override
  Widget build(BuildContext context) {
    final planned = data.planned;
    final curated = data.curated;
    final selected = data.selectedTaskIds;
    final dateLabel = DateFormat('EEEE, MMM d').format(DateTime.now());

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _HeroHeader(
            dateLabel: dateLabel,
            title: 'Choose what matters today.',
            subtitle: 'Planned items first, then curated picks.',
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverToBoxAdapter(
            child: _RitualCard(
              focusMode: data.focusMode,
              onChangeFocusMode: () => context.read<MyDayRitualBloc>().add(
                const MyDayRitualFocusModeWizardRequested(),
              ),
              plannedCount: planned.length,
              curatedCount: curated.length,
              plannedBody: planned.isEmpty
                  ? const _EmptyPanel(
                      title: 'No planned tasks',
                      description:
                          'Nothing is due or scheduled to start today.',
                    )
                  : _TaskTileColumn(
                      tasks: planned,
                      selected: selected,
                      reasonsByTaskId: const {},
                    ),
              curatedBody: curated.isEmpty
                  ? const _EmptyPanel(
                      title: 'No curated picks today',
                      description: 'Your focus mode has no suggestions yet.',
                    )
                  : _TaskTileColumn(
                      tasks: curated,
                      selected: selected,
                      reasonsByTaskId: data.curatedReasons,
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

class _FocusBanner extends StatelessWidget {
  const _FocusBanner({
    required this.focusMode,
    required this.onChangeFocusMode,
  });

  final FocusMode focusMode;
  final VoidCallback onChangeFocusMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _focusIcon(focusMode),
            size: 18,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Value focus',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  focusMode.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChangeFocusMode,
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  IconData _focusIcon(FocusMode focusMode) {
    return switch (focusMode) {
      FocusMode.intentional => Icons.gps_fixed,
      FocusMode.sustainable => Icons.balance,
      FocusMode.responsive => Icons.bolt,
      FocusMode.personalized => Icons.tune,
    };
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.stepLabel,
    this.onInfo,
    this.helperText,
  });

  final String? stepLabel;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback? onInfo;
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
              if (onInfo != null)
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 18),
                  onPressed: onInfo,
                  tooltip: 'Why these picks?',
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

class _RitualCard extends StatelessWidget {
  const _RitualCard({
    required this.focusMode,
    required this.onChangeFocusMode,
    required this.plannedCount,
    required this.curatedCount,
    required this.plannedBody,
    required this.curatedBody,
    required this.onAcceptAllPlanned,
    required this.onAcceptAllCurated,
    required this.onSuggestedInfo,
  });

  final FocusMode focusMode;
  final VoidCallback onChangeFocusMode;
  final int plannedCount;
  final int curatedCount;
  final Widget plannedBody;
  final Widget curatedBody;
  final VoidCallback onAcceptAllPlanned;
  final VoidCallback onAcceptAllCurated;
  final VoidCallback onSuggestedInfo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: _FocusBanner(
                focusMode: focusMode,
                onChangeFocusMode: onChangeFocusMode,
              ),
            ),
            _SectionHeader(
              stepLabel: 'Step 1 · Planned',
              title: 'Planned for ${focusMode.displayName} · $plannedCount',
              actionLabel: 'Accept all planned',
              helperText: plannedCount == 0
                  ? null
                  : 'Start with planned or time‑sensitive.',
              onAction: onAcceptAllPlanned,
            ),
            plannedBody,
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Divider(color: cs.outlineVariant),
            ),
            _SectionHeader(
              stepLabel: 'Step 2 · Suggested',
              title: 'Suggested for ${focusMode.displayName} · $curatedCount',
              actionLabel: 'Accept all picks',
              helperText: curatedCount == 0
                  ? null
                  : 'Based on values + focus mode.',
              onAction: onAcceptAllCurated,
              onInfo: onSuggestedInfo,
            ),
            curatedBody,
          ],
        ),
      ),
    );
  }
}

class _TaskTileColumn extends StatelessWidget {
  const _TaskTileColumn({
    required this.tasks,
    required this.selected,
    required this.reasonsByTaskId,
  });

  final List<Task> tasks;
  final Set<String> selected;
  final Map<String, List<String>> reasonsByTaskId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final task in tasks)
          _TaskTileRow(
            task: task,
            selected: selected.contains(task.id),
            reasons: reasonsByTaskId[task.id] ?? const <String>[],
          ),
      ],
    );
  }
}

class _TaskTileRow extends StatelessWidget {
  const _TaskTileRow({
    required this.task,
    required this.selected,
    required this.reasons,
  });

  final Task task;
  final bool selected;
  final List<String> reasons;

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
      titlePrefix: _ReasonBadges(reasons: reasons),
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

class _ReasonBadges extends StatelessWidget {
  const _ReasonBadges({required this.reasons});

  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    if (reasons.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final reason in reasons)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Text(
              reason,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
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
