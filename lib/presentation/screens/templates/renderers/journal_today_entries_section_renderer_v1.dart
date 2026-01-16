import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/domain/journal/model/journal_entry.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_event.dart';

final class JournalTodayEntriesSectionRendererV1 extends StatelessWidget {
  const JournalTodayEntriesSectionRendererV1({
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
    if (entries.isEmpty) {
      return const Text('No logs yet today.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Logs',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (final entry in entries) ...[
          _EntryCard(
            entry: entry,
            events: eventsByEntryId[entry.id] ?? const <TrackerEvent>[],
            definitionById: definitionById,
            moodTrackerId: moodTrackerId,
            onTap: () => onEntryTap(entry),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.events,
    required this.definitionById,
    required this.moodTrackerId,
    required this.onTap,
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

    final moodValue = _findMoodValue();
    final nonMoodBoolEvents = events
        .where((e) => e.trackerId != moodTrackerId)
        .where((e) => e.value is bool)
        .toList(growable: false);

    final note = entry.journalText?.trim();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
                  if (moodValue != null)
                    Chip(
                      label: Text('Mood: $moodValue'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              if (note != null && note.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(note),
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

  int? _findMoodValue() {
    final id = moodTrackerId;
    if (id == null) return null;

    for (final e in events) {
      if (e.trackerId == id && e.value is int) {
        return e.value! as int;
      }
    }

    return null;
  }
}
