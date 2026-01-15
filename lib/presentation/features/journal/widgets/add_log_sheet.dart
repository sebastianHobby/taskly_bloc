import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/domain/journal/model/mood_rating.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/add_log_cubit.dart';

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
                DropdownButtonFormField<MoodRating>(
                  value: state.mood,
                  decoration: const InputDecoration(
                    labelText: 'Mood',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final rating in MoodRating.values)
                      DropdownMenuItem(
                        value: rating,
                        child: Text(rating.label),
                      ),
                  ],
                  onChanged: isSaving
                      ? null
                      : (value) =>
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
      return Text(
        'No quick-add trackers yet. Enable some in Trackers.',
        style: Theme.of(context).textTheme.bodyMedium,
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
