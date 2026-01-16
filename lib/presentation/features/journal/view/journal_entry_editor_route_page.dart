import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/domain/journal/model/mood_rating.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_entry_editor_cubit.dart';

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
      create: (_) => getIt<JournalEntryEditorCubit>(
        param1: widget.entryId,
        param2: widget.preselectedTrackerIds,
      ),
      child: BlocConsumer<JournalEntryEditorCubit, JournalEntryEditorState>(
        listenWhen: (prev, next) =>
            prev.status.runtimeType != next.status.runtimeType,
        listener: (context, state) {
          switch (state.status) {
            case JournalEntryEditorSaved():
              if (!context.mounted) return;
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
              actions: [
                TextButton(
                  onPressed: isSaving || isLoading
                      ? null
                      : () => context.read<JournalEntryEditorCubit>().save(),
                  child: const Text('Save'),
                ),
              ],
            ),
            body: SafeArea(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _MoodPicker(
                          value: state.mood,
                          enabled: !isSaving,
                          onChanged: (m) => context
                              .read<JournalEntryEditorCubit>()
                              .moodChanged(m),
                        ),
                        const SizedBox(height: 16),
                        _QuickAddTrackers(
                          trackers: state.availableTrackers,
                          selectedTrackerIds: state.selectedTrackerIds,
                          enabled: !isSaving,
                          onToggle: (id) => context
                              .read<JournalEntryEditorCubit>()
                              .toggleTracker(id),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _noteController,
                          onChanged: (v) => context
                              .read<JournalEntryEditorCubit>()
                              .noteChanged(v),
                          maxLines: 6,
                          enabled: !isSaving,
                          decoration: const InputDecoration(
                            labelText: 'Note (optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: isSaving
                              ? null
                              : () => context
                                    .read<JournalEntryEditorCubit>()
                                    .save(),
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
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _MoodPicker extends StatelessWidget {
  const _MoodPicker({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final MoodRating? value;
  final bool enabled;
  final ValueChanged<MoodRating?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<MoodRating>(
      value: value,
      decoration: const InputDecoration(
        labelText: 'Mood (required)',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final rating in MoodRating.values)
          DropdownMenuItem(
            value: rating,
            child: Text(rating.label),
          ),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _QuickAddTrackers extends StatelessWidget {
  const _QuickAddTrackers({
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
      return Text(
        'No quick-add trackers yet. Enable some in Manage Trackers.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trackers',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tracker in trackers)
              FilterChip(
                label: Text(tracker.name),
                selected: selectedTrackerIds.contains(tracker.id),
                onSelected: enabled ? (_) => onToggle(tracker.id) : null,
              ),
          ],
        ),
      ],
    );
  }
}
