import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_domain/domain/journal/model/mood_rating.dart';
import 'package:taskly_domain/domain/journal/model/tracker_definition.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/add_log_cubit.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';

class AddLogSheet extends StatefulWidget {
  const AddLogSheet._({required this.preselectedTrackerIds});

  static Future<void> show({
    required BuildContext context,
    Set<String> preselectedTrackerIds = const <String>{},
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: AddLogSheet._(
          preselectedTrackerIds: preselectedTrackerIds,
        ),
      ),
    );
  }

  final Set<String> preselectedTrackerIds;

  @override
  State<AddLogSheet> createState() => _AddLogSheetState();
}

class _AddLogSheetState extends State<AddLogSheet> {
  late final AddLogCubit _cubit;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _cubit = getIt<AddLogCubit>(param1: widget.preselectedTrackerIds);
    _noteController.addListener(() {
      _cubit.noteChanged(_noteController.text);
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<AddLogCubit, AddLogState>(
        listenWhen: (prev, next) =>
            prev.status.runtimeType != next.status.runtimeType,
        listener: (context, state) {
          switch (state.status) {
            case AddLogSaved():
              Navigator.of(context).pop();
            case AddLogError(:final message):
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            default:
              break;
          }
        },
        builder: (context, state) {
          final isSaving = state.status is AddLogSaving;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Add Log',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Mood',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _MoodScalePicker(
                  value: state.mood,
                  enabled: !isSaving,
                  onChanged: (value) =>
                      context.read<AddLogCubit>().moodChanged(value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    border: OutlineInputBorder(),
                  ),
                  enabled: !isSaving,
                ),
                const SizedBox(height: 16),
                Text(
                  'Quick add',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _QuickAddChips(
                  trackers: state.quickAddTrackers,
                  selectedTrackerIds: state.selectedTrackerIds,
                  isSaving: isSaving,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isSaving
                        ? null
                        : () => context.read<AddLogCubit>().save(),
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Save'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuickAddChips extends StatelessWidget {
  const _QuickAddChips({
    required this.trackers,
    required this.selectedTrackerIds,
    required this.isSaving,
  });

  final List<TrackerDefinition> trackers;
  final Set<String> selectedTrackerIds;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    if (trackers.isEmpty) {
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
                    'Enable a few to make logging faster.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: isSaving
                  ? null
                  : () => Routing.pushScreenKey(
                      context,
                      'journal_manage_trackers',
                    ),
              child: const Text('Manage'),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tracker in trackers)
          FilterChip(
            label: Text(tracker.name),
            selected: selectedTrackerIds.contains(tracker.id),
            onSelected: isSaving
                ? null
                : (_) => context.read<AddLogCubit>().toggleTracker(tracker.id),
          ),
      ],
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

Color _getMoodColor(MoodRating mood, ColorScheme colorScheme) {
  return switch (mood) {
    MoodRating.veryLow => Colors.red.shade600,
    MoodRating.low => Colors.orange.shade700,
    MoodRating.neutral => colorScheme.primary,
    MoodRating.good => Colors.teal.shade600,
    MoodRating.excellent => Colors.green.shade700,
  };
}
