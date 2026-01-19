import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_today_bloc.dart';

class JournalTodayComposer extends StatelessWidget {
  const JournalTodayComposer({
    required this.pinnedTrackers,
    required this.moodWeek,
    required this.moodStreakDays,
    required this.onAddLog,
    required this.onQuickAddTracker,
    super.key,
  });

  final List<TrackerDefinition> pinnedTrackers;
  final List<JournalMoodDay> moodWeek;
  final int moodStreakDays;
  final VoidCallback onAddLog;
  final ValueChanged<String> onQuickAddTracker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DateFormat('EEEE, MMM d').format(DateTime.now());

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
        const SizedBox(height: 4),
        Text(
          dateLabel,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (moodWeek.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'This week',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (moodStreakDays > 0) _StreakChip(days: moodStreakDays),
            ],
          ),
          const SizedBox(height: 8),
          _MoodStrip(days: moodWeek),
        ],
        if (pinnedTrackers.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Quick add',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: pinnedTrackers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tracker = pinnedTrackers[index];
                return ActionChip(
                  avatar: CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      tracker.name.isNotEmpty
                          ? tracker.name[0].toUpperCase()
                          : 'T',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  label: Text(tracker.name),
                  onPressed: () => onQuickAddTracker(tracker.id),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _MoodStrip extends StatelessWidget {
  const _MoodStrip({required this.days});

  final List<JournalMoodDay> days;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final day in days) _MoodStripDay(day: day),
      ],
    );
  }
}

class _MoodStripDay extends StatelessWidget {
  const _MoodStripDay({required this.day});

  final JournalMoodDay day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mood = day.mood;
    final dateLabel = DateFormat('E').format(day.dayUtc.toLocal());

    final background = mood == null
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.primaryContainer;
    final foreground = mood == null
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onPrimaryContainer;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            mood?.emoji ?? '•',
            style: theme.textTheme.titleMedium?.copyWith(
              color: foreground,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dateLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = days == 1 ? '1 day streak' : '$days day streak';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

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
          JournalTodayEmptyState(onAddLog: onAddLog)
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
  const JournalTodayEmptyState({required this.onAddLog, super.key});

  final VoidCallback onAddLog;

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

    final mood = _findMood();

    final nonMoodBoolEvents = events
        .where((e) => e.trackerId != moodTrackerId)
        .where((e) => e.value is bool)
        .where((e) => e.value! as bool)
        .toList(growable: false);

    final note = entry.journalText?.trim();

    final surface = theme.colorScheme.surfaceContainerHigh;
    final border = theme.colorScheme.outlineVariant;
    final hasMood = mood != null;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
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
                const SizedBox(height: 10),
                Text(
                  note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (nonMoodBoolEvents.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in nonMoodBoolEvents)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: border),
                        ),
                        child: Text(
                          '✓ ${definitionById[e.trackerId]?.name ?? 'Tracker'}',
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
}
