import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/domain/analytics/model/date_range.dart';
import 'package:taskly_bloc/domain/interfaces/journal_repository_contract.dart';
import 'package:taskly_bloc/domain/journal/model/journal_entry.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_event.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_preference.dart';
import 'package:taskly_bloc/domain/queries/journal_query.dart';
import 'package:taskly_bloc/domain/time/date_only.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/add_log_sheet.dart';

class JournalTodayPage extends StatelessWidget {
  const JournalTodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = getIt<JournalRepositoryContract>();
    final nowUtc = DateTime.now().toUtc();
    final startUtc = dateOnly(nowUtc);
    final endUtc = startUtc
        .add(const Duration(days: 1))
        .subtract(const Duration(microseconds: 1));

    return StreamBuilder<List<TrackerDefinition>>(
      stream: repo.watchTrackerDefinitions(),
      builder: (context, defsSnapshot) {
        if (defsSnapshot.hasError) return const _ErrorState();
        if (!defsSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final definitions = defsSnapshot.data ?? const <TrackerDefinition>[];
        final definitionById = {
          for (final d in definitions) d.id: d,
        };
        final moodTrackerId = definitions
            .where((d) => d.systemKey == 'mood')
            .map((d) => d.id)
            .cast<String?>()
            .firstWhere((id) => id != null, orElse: () => null);

        return StreamBuilder<List<TrackerPreference>>(
          stream: repo.watchTrackerPreferences(),
          builder: (context, prefsSnapshot) {
            if (prefsSnapshot.hasError) return const _ErrorState();
            if (!prefsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final prefs = prefsSnapshot.data ?? const <TrackerPreference>[];
            final pinnedTrackers =
                definitions
                    .where((d) => d.isActive && d.deletedAt == null)
                    .where((d) => d.systemKey != 'mood')
                    .where((d) {
                      final pref = prefs
                          .where((p) => p.trackerId == d.id)
                          .cast<TrackerPreference?>()
                          .firstWhere(
                            (p) => p != null,
                            orElse: () => null,
                          );
                      return (pref?.pinned ?? false) ||
                          (pref?.showInQuickAdd ?? false);
                    })
                    .toList(growable: false)
                  ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

            return StreamBuilder<List<JournalEntry>>(
              stream: repo.watchJournalEntriesByQuery(
                JournalQuery.forDate(nowUtc),
              ),
              builder: (context, entriesSnapshot) {
                final entries = entriesSnapshot.data ?? const <JournalEntry>[];

                return StreamBuilder<List<TrackerEvent>>(
                  stream: repo.watchTrackerEvents(
                    range: DateRange(start: startUtc, end: endUtc),
                    anchorType: 'entry',
                  ),
                  builder: (context, eventsSnapshot) {
                    final events =
                        eventsSnapshot.data ?? const <TrackerEvent>[];

                    if (entriesSnapshot.hasError || eventsSnapshot.hasError) {
                      return const _ErrorState();
                    }

                    if (!entriesSnapshot.hasData || !eventsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (entries.isEmpty) {
                      return _EmptyToday(
                        onAdd: () => AddLogSheet.show(context: context),
                      );
                    }

                    return ListView.separated(
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
                        final entryEvents = events
                            .where((e) => e.entryId == entry.id)
                            .toList(growable: false);

                        return _JournalEntryCard(
                          entry: entry,
                          events: entryEvents,
                          definitionById: definitionById,
                          moodTrackerId: moodTrackerId,
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
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
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Failed to load Journal data.'),
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
