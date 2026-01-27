import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class JournalTodayEntriesSection extends StatelessWidget {
  const JournalTodayEntriesSection({
    required this.entries,
    required this.eventsByEntryId,
    required this.definitionById,
    required this.moodTrackerId,
    required this.onAddLog,
    required this.onEntryTap,
    super.key,
  });

  final List<JournalEntry> entries;
  final Map<String, List<TrackerEvent>> eventsByEntryId;
  final Map<String, TrackerDefinition> definitionById;
  final String? moodTrackerId;
  final VoidCallback onAddLog;
  final ValueChanged<JournalEntry> onEntryTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = TasklyTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Logs',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: TasklyTokens.of(context).spaceSm),
        if (entries.isEmpty)
          JournalTodayEmptyState(onAddLog: onAddLog)
        else
          ...entries.map(
            (entry) => Padding(
              padding: EdgeInsets.only(bottom: tokens.spaceSm),
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
  const JournalTodayEmptyState({required this.onAddLog, super.key});

  final VoidCallback onAddLog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = TasklyTokens.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(tokens.spaceLg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_stories_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: tokens.spaceSm),
          Expanded(
            child: Text(
              'No logs yet today.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: onAddLog,
            child: const Text('Add log'),
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
    final tokens = TasklyTokens.of(context);

    final mood = _findMood();
    final summaryItems = _buildSummaryItems();

    final note = entry.journalText?.trim();

    final surface = theme.colorScheme.surfaceContainerHigh;
    final border = theme.colorScheme.outlineVariant;
    final hasMood = mood != null;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(color: border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.spaceSm,
                      vertical: tokens.spaceXs,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(tokens.radiusMd),
                    ),
                    child: Text(
                      timeLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (hasMood)
                    Tooltip(
                      message: mood.label,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: tokens.spaceSm,
                          vertical: tokens.spaceXs,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(tokens.radiusMd),
                        ),
                        child: Text(
                          '${mood.emoji} ${mood.value}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (note != null && note.isNotEmpty) ...[
                SizedBox(height: tokens.spaceSm),
                Text(
                  note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (summaryItems.isNotEmpty) ...[
                SizedBox(height: tokens.spaceSm),
                Wrap(
                  spacing: tokens.spaceSm,
                  runSpacing: tokens.spaceSm,
                  children: [
                    for (final item in summaryItems)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: tokens.spaceSm,
                          vertical: tokens.spaceXs,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(tokens.radiusMd),
                          border: Border.all(color: border),
                        ),
                        child: Text(
                          item,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  List<String> _buildSummaryItems() {
    final candidates = <String>[];
    final moodId = moodTrackerId;

    for (final e in events) {
      if (moodId != null && e.trackerId == moodId) continue;

      final name = definitionById[e.trackerId]?.name ?? 'Tracker';
      final value = e.value;

      if (value is bool) {
        if (!value) continue;
        candidates.add('OK $name');
        continue;
      }

      if (value is int) {
        candidates.add('$name: $value');
        continue;
      }

      if (value is double) {
        candidates.add('$name: ${value.toStringAsFixed(1)}');
        continue;
      }

      if (value is String) {
        candidates.add('$name: $value');
        continue;
      }

      if (value != null) {
        candidates.add('$name: $value');
      }
    }

    if (candidates.length <= 4) return candidates;

    final remaining = candidates.length - 3;
    return [
      ...candidates.take(3),
      '+$remaining more',
    ];
  }
}
