import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskly_domain/domain/journal/model/journal_entry.dart';
import 'package:taskly_domain/domain/journal/model/mood_rating.dart';
import 'package:taskly_domain/domain/journal/model/tracker_definition.dart';
import 'package:taskly_domain/domain/journal/model/tracker_event.dart';

class JournalTodayComposer extends StatelessWidget {
  const JournalTodayComposer({
    required this.pinnedTrackers,
    required this.onAddLog,
    required this.onQuickAddTracker,
    super.key,
  });

  final List<TrackerDefinition> pinnedTrackers;
  final VoidCallback onAddLog;
  final ValueChanged<String> onQuickAddTracker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Today',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: onAddLog,
              icon: const Icon(Icons.add),
              label: const Text('Add log'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        if (pinnedTrackers.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Quick add',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tracker in pinnedTrackers)
                ActionChip(
                  label: Text(tracker.name),
                  onPressed: () => onQuickAddTracker(tracker.id),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class JournalTodayEntriesSection extends StatelessWidget {
  const JournalTodayEntriesSection({
    required this.entries,
    required this.eventsByEntryId,
    required this.definitionById,
    required this.moodTrackerId,
    required this.onEntryTap,
    super.key,
  });

  final List<JournalEntry> entries;
  final Map<String, List<TrackerEvent>> eventsByEntryId;
  final Map<String, TrackerDefinition> definitionById;
  final String? moodTrackerId;
  final ValueChanged<JournalEntry> onEntryTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Logs',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          const JournalTodayEmptyState()
        else
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: JournalLogCard(
                entry: entry,
                events: eventsByEntryId[entry.id] ?? const <TrackerEvent>[],
                definitionById: definitionById,
                moodTrackerId: moodTrackerId,
                onTap: () => onEntryTap(entry),
              ),
            ),
          ),
      ],
    );
  }
}

class JournalTodayEmptyState extends StatelessWidget {
  const JournalTodayEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_stories_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No logs yet today.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class JournalLogCard extends StatelessWidget {
  const JournalLogCard({
    required this.entry,
    required this.events,
    required this.definitionById,
    required this.moodTrackerId,
    required this.onTap,
    super.key,
  });

  final JournalEntry entry;
  final List<TrackerEvent> events;
  final Map<String, TrackerDefinition> definitionById;
  final String? moodTrackerId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeLabel = DateFormat.jm().format(entry.occurredAt.toLocal());

    final mood = _findMood();

    final nonMoodBoolEvents = events
        .where((e) => e.trackerId != moodTrackerId)
        .where((e) => e.value is bool)
        .where((e) => e.value! as bool)
        .toList(growable: false);

    final note = entry.journalText?.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    timeLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (mood != null)
                    Tooltip(
                      message: mood.label,
                      child: Chip(
                        label: Text('${mood.emoji} ${mood.value}'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
              if (note != null && note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (nonMoodBoolEvents.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in nonMoodBoolEvents)
                      Chip(
                        label: Text(
                          '✓ ${definitionById[e.trackerId]?.name ?? 'Tracker'}',
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  MoodRating? _findMood() {
    final id = moodTrackerId;
    if (id == null) return null;

    for (final e in events) {
      if (e.trackerId == id && e.value is int) {
        return MoodRating.fromValue(e.value! as int);
      }
    }

    return null;
  }
}
