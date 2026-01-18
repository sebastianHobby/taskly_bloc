import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_entry_editor_cubit.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';

class JournalEntryEditorRoutePage extends StatefulWidget {
  const JournalEntryEditorRoutePage({
    required this.entryId,
    required this.preselectedTrackerIds,
    super.key,
  });

  final String? entryId;
  final Set<String> preselectedTrackerIds;

  @override
  State<JournalEntryEditorRoutePage> createState() =>
      _JournalEntryEditorRoutePageState();
}

class _JournalEntryEditorRoutePageState
    extends State<JournalEntryEditorRoutePage> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JournalEntryEditorCubit>(
      create: (context) => JournalEntryEditorCubit(
        repository: getIt<JournalRepositoryContract>(),
        errorReporter: context.read<AppErrorReporter>(),
        entryId: widget.entryId,
        preselectedTrackerIds: widget.preselectedTrackerIds,
        nowUtc: getIt<NowService>().nowUtc,
      ),
      child: BlocConsumer<JournalEntryEditorCubit, JournalEntryEditorState>(
        listenWhen: (prev, next) =>
            prev.status.runtimeType != next.status.runtimeType,
        listener: (context, state) {
          switch (state.status) {
            case JournalEntryEditorSaved():
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Saved log'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.pop(true);
            case JournalEntryEditorError(:final message):
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            default:
              break;
          }
        },
        builder: (context, state) {
          final isSaving = state.status is JournalEntryEditorSaving;
          final isLoading = state.status is JournalEntryEditorLoading;
          final canSave =
              !isSaving &&
              state.mood != null &&
              (!state.isEditingExisting || state.isDirty);

          if (_noteController.text != state.note && !isLoading) {
            // Keep controller in sync with prefill.
            _noteController.text = state.note;
            _noteController.selection = TextSelection.fromPosition(
              TextPosition(offset: _noteController.text.length),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(state.isEditingExisting ? 'Edit log' : 'New log'),
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: FilledButton.icon(
                  onPressed: canSave
                      ? () => context.read<JournalEntryEditorCubit>().save()
                      : null,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Save log'),
                ),
              ),
            ),
            body: SafeArea(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
                      children: [
                        _TodayHeader(now: getIt<NowService>().nowLocal()),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'Mood',
                          subtitle: 'Tap what matches your day so far.',
                          child: _MoodScalePicker(
                            value: state.mood,
                            enabled: !isSaving,
                            onChanged: (m) => context
                                .read<JournalEntryEditorCubit>()
                                .moodChanged(m),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'Trackers',
                          subtitle: 'Optional — keep it light.',
                          child: _TrackerCards(
                            trackers: state.availableTrackers,
                            selectedTrackerIds: state.selectedTrackerIds,
                            enabled: !isSaving,
                            onToggle: (id) => context
                                .read<JournalEntryEditorCubit>()
                                .toggleTracker(id),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'Note',
                          subtitle: 'One sentence is enough.',
                          child: TextField(
                            controller: _noteController,
                            onChanged: (v) => context
                                .read<JournalEntryEditorCubit>()
                                .noteChanged(v),
                            maxLines: 6,
                            enabled: !isSaving,
                            decoration: const InputDecoration(
                              hintText: 'What do you want to remember?',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _TodayHeader extends StatelessWidget {
  const _TodayHeader({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final materialLocalizations = MaterialLocalizations.of(context);
    final date = materialLocalizations.formatFullDate(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Today', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 2),
        Text(
          date,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _MoodScalePicker extends StatelessWidget {
  const _MoodScalePicker({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final MoodRating? value;
  final bool enabled;
  final ValueChanged<MoodRating?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final mood in MoodRating.values)
          _MoodOptionButton(
            mood: mood,
            enabled: enabled,
            selected: value == mood,
            onTap: () => onChanged(mood),
          ),
      ],
    );
  }
}

class _MoodOptionButton extends StatelessWidget {
  const _MoodOptionButton({
    required this.mood,
    required this.enabled,
    required this.selected,
    required this.onTap,
  });

  final MoodRating mood;
  final bool enabled;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moodColor = _getMoodColor(mood, theme.colorScheme);
    final bg = selected
        ? moodColor.withValues(alpha: 0.18)
        : theme.colorScheme.surface;
    final border = selected
        ? BorderSide(color: moodColor, width: 2)
        : BorderSide(color: theme.dividerColor);

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: 'Mood: ${mood.label}',
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.fromBorderSide(border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mood.emoji,
                style: TextStyle(
                  fontSize: 26,
                  color: enabled ? null : theme.disabledColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${mood.value}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected
                      ? moodColor
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackerCards extends StatelessWidget {
  const _TrackerCards({
    required this.trackers,
    required this.selectedTrackerIds,
    required this.enabled,
    required this.onToggle,
  });

  final List<TrackerDefinition> trackers;
  final Set<String> selectedTrackerIds;
  final bool enabled;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (trackers.isEmpty) {
      return _TrackersEmptyState(enabled: enabled);
    }

    return Column(
      children: [
        for (final tracker in trackers)
          _TrackerCard(
            tracker: tracker,
            selected: selectedTrackerIds.contains(tracker.id),
            enabled: enabled,
            onToggle: () => onToggle(tracker.id),
          ),
      ],
    );
  }
}

class _TrackersEmptyState extends StatelessWidget {
  const _TrackersEmptyState({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.tune,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No quick-add trackers yet',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'Enable a few to make logging feel effortless.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: enabled
                ? () =>
                      Routing.pushScreenKey(context, 'journal_manage_trackers')
                : null,
            child: const Text('Manage'),
          ),
        ],
      ),
    );
  }
}

class _TrackerCard extends StatelessWidget {
  const _TrackerCard({
    required this.tracker,
    required this.selected,
    required this.enabled,
    required this.onToggle,
  });

  final TrackerDefinition tracker;
  final bool selected;
  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _trackerIcon(tracker);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled ? onToggle : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tracker.name,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                Switch.adaptive(
                  value: selected,
                  onChanged: enabled ? (_) => onToggle() : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _getMoodColor(MoodRating mood, ColorScheme colorScheme) {
  return switch (mood) {
    MoodRating.veryLow => Colors.red.shade600,
    MoodRating.low => Colors.orange.shade700,
    MoodRating.neutral => colorScheme.primary,
    MoodRating.good => Colors.teal.shade600,
    MoodRating.excellent => Colors.green.shade700,
  };
}

IconData _trackerIcon(TrackerDefinition tracker) {
  return switch (tracker.systemKey) {
    'exercise' => Icons.fitness_center,
    'meds' => Icons.medication_outlined,
    'meditation' => Icons.self_improvement,
    _ => Icons.bookmark_border,
  };
}
