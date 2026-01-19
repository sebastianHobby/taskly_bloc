import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_today_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/add_log_sheet.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/journal_today_shared_widgets.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/contracts.dart';

class JournalTodayPage extends StatelessWidget {
  const JournalTodayPage({required this.day, super.key});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JournalTodayBloc>(
      key: ValueKey<DateTime>(DateTime(day.year, day.month, day.day)),
      create: (_) => JournalTodayBloc(
        repository: getIt<JournalRepositoryContract>(),
        nowUtc: getIt<NowService>().nowUtc,
        selectedDay: day,
      ),
      child: BlocBuilder<JournalTodayBloc, JournalTodayState>(
        builder: (context, state) {
          return switch (state) {
            JournalTodayLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            JournalTodayError(:final message) => _ErrorState(message: message),
            JournalTodayLoaded(
              :final entries,
              :final eventsByEntryId,
              :final definitionById,
              :final moodTrackerId,
            ) =>
              ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                children: [
                  _TodaySummary(
                    entries: entries,
                    eventsByEntryId: eventsByEntryId,
                    moodTrackerId: moodTrackerId,
                  ),
                  const SizedBox(height: 12),
                  _Timeline(
                    entries: entries,
                    eventsByEntryId: eventsByEntryId,
                    definitionById: definitionById,
                    moodTrackerId: moodTrackerId,
                    onAddLog: () => AddLogSheet.show(
                      context: context,
                      selectedDayLocal: day,
                    ),
                    onEntryTap: (entry) => Routing.toJournalEntryEdit(
                      context,
                      entry.id,
                    ),
                  ),
                ],
              ),
          };
        },
      ),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  const _TodaySummary({
    required this.entries,
    required this.eventsByEntryId,
    required this.moodTrackerId,
  });

  final List<JournalEntry> entries;
  final Map<String, List<TrackerEvent>> eventsByEntryId;
  final String? moodTrackerId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moodValues = <int>[];

    final id = moodTrackerId;
    if (id != null) {
      for (final entry in entries) {
        final events = eventsByEntryId[entry.id] ?? const <TrackerEvent>[];
        for (final e in events) {
          if (e.trackerId == id && e.value is int) {
            moodValues.add(e.value! as int);
            break;
          }
        }
      }
    }

    final double? moodAverage = moodValues.isEmpty
        ? null
        : moodValues.reduce((a, b) => a + b) / moodValues.length;
    final MoodRating? moodDisplay = moodAverage == null
        ? null
        : MoodRating.fromValue(moodAverage.round().clamp(1, 5));

    final moodText = moodAverage == null
        ? 'Mood avg: —'
        : 'Mood avg: ${moodAverage.toStringAsFixed(1)}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              moodDisplay?.emoji ?? '•',
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moodText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entries.length == 1 ? '1 entry' : '${entries.length} entries',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.entries,
    required this.eventsByEntryId,
    required this.definitionById,
    required this.moodTrackerId,
    required this.onAddLog,
    required this.onEntryTap,
  });

  final List<JournalEntry> entries;
  final Map<String, List<TrackerEvent>> eventsByEntryId;
  final Map<String, TrackerDefinition> definitionById;
  final String? moodTrackerId;
  final VoidCallback onAddLog;
  final ValueChanged<JournalEntry> onEntryTap;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return JournalTodayEmptyState(onAddLog: onAddLog);
    }

    return Column(
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: JournalLogCard(
              entry: entry,
              events: eventsByEntryId[entry.id] ?? const <TrackerEvent>[],
              definitionById: definitionById,
              moodTrackerId: moodTrackerId,
              onTap: () => onEntryTap(entry),
            ),
          ),
      ],
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
