import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/domain/journal/model/journal_entry.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_event.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_today_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/add_log_sheet.dart';

class JournalTodayPage extends StatelessWidget {
  const JournalTodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JournalTodayBloc>(
      create: (_) => getIt<JournalTodayBloc>(),
      child: BlocBuilder<JournalTodayBloc, JournalTodayState>(
        builder: (context, state) {
          return switch (state) {
            JournalTodayLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            JournalTodayError(:final message) => _ErrorState(message: message),
            JournalTodayLoaded(
              :final pinnedTrackers,
              :final entries,
              :final eventsByEntryId,
              :final definitionById,
              :final moodTrackerId,
            ) =>
              entries.isEmpty
                  ? _EmptyToday(
                      onAdd: () => AddLogSheet.show(context: context),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: entries.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _PinnedTrackerQuickAddRow(
                            trackers: pinnedTrackers,
                            onTapTracker: (trackerId) => AddLogSheet.show(
                              context: context,
                              preselectedTrackerIds: {trackerId},
                            ),
                          );
                        }

                        final entry = entries[index - 1];
                        final entryEvents =
                            eventsByEntryId[entry.id] ?? const <TrackerEvent>[];

                        return _JournalEntryCard(
                          entry: entry,
                          events: entryEvents,
                          definitionById: definitionById,
                          moodTrackerId: moodTrackerId,
                        );
                      },
                    ),
          };
        },
      ),
    );
  }
}

class _PinnedTrackerQuickAddRow extends StatelessWidget {
  const _PinnedTrackerQuickAddRow({
    required this.trackers,
    required this.onTapTracker,
  });

  final List<TrackerDefinition> trackers;
  final ValueChanged<String> onTapTracker;

  @override
  Widget build(BuildContext context) {
    if (trackers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick add', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tracker in trackers)
                ActionChip(
                  label: Text(tracker.name),
                  onPressed: () => onTapTracker(tracker.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyToday extends StatelessWidget {
  const _EmptyToday({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.book_outlined, size: 56, color: scheme.primary),
            const SizedBox(height: 12),
            Text(
              'No logs yet today',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a mood and optional notes or trackers.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Log'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message),
      ),
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  const _JournalEntryCard({
    required this.entry,
    required this.events,
    required this.definitionById,
    required this.moodTrackerId,
  });

  final JournalEntry entry;
  final List<TrackerEvent> events;
  final Map<String, TrackerDefinition> definitionById;
  final String? moodTrackerId;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(entry.occurredAt.toLocal());
    final note = entry.journalText?.trim();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  time.format(context),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                _MoodChip(events: events, moodTrackerId: moodTrackerId),
              ],
            ),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(note),
            ],
            const SizedBox(height: 10),
            _TrackerEventChips(
              events: events,
              definitionById: definitionById,
              moodTrackerId: moodTrackerId,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({required this.events, required this.moodTrackerId});

  final List<TrackerEvent> events;
  final String? moodTrackerId;

  @override
  Widget build(BuildContext context) {
    final id = moodTrackerId;
    if (id == null) return const SizedBox.shrink();

    int? moodValue;
    for (final e in events) {
      if (e.trackerId == id && e.value is int) {
        moodValue = e.value! as int;
        break;
      }
    }

    if (moodValue == null) {
      return const SizedBox.shrink();
    }

    return Chip(
      label: Text('Mood: $moodValue'),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _TrackerEventChips extends StatelessWidget {
  const _TrackerEventChips({
    required this.events,
    required this.definitionById,
    required this.moodTrackerId,
  });

  final List<TrackerEvent> events;
  final Map<String, TrackerDefinition> definitionById;
  final String? moodTrackerId;

  @override
  Widget build(BuildContext context) {
    final nonMood = events
        .where((e) => e.trackerId != moodTrackerId)
        .where((e) => e.value is bool)
        .toList(growable: false);
    if (nonMood.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in nonMood)
          Chip(
            label: Text('✓ ${definitionById[e.trackerId]?.name ?? 'Tracker'}'),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}
