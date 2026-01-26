import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_history_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/journal_daily_detail_sheet.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/journal_today_shared_widgets.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_ui/taskly_ui_sections.dart';

class JournalHistoryPage extends StatelessWidget {
  const JournalHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JournalHistoryBloc>(
      create: (_) =>
          getIt<JournalHistoryBloc>()..add(const JournalHistoryStarted()),
      child: BlocBuilder<JournalHistoryBloc, JournalHistoryState>(
        builder: (context, state) {
          return switch (state) {
            JournalHistoryLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            JournalHistoryError(:final message) => Center(
              child: Text(message),
            ),
            JournalHistoryLoaded(:final days) => _HistoryList(days: days),
          };
        },
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.days});

  final List<JournalHistoryDaySummary> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const Center(child: Text('No recent logs.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        return _DaySection(summary: day);
      },
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.summary});

  final JournalHistoryDaySummary summary;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat.yMMMEd().format(summary.day.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TasklyJournalDailySummarySection(
            moodEmoji: _moodEmoji(summary.moodAverage),
            moodLabel: _moodLabel(summary.moodAverage),
            entryCountLabel: summary.entries.length == 1
                ? '1 entry'
                : '${summary.entries.length} entries',
            items: [
              for (final item in summary.dailySummaryItems)
                TasklyJournalDailySummaryItem(
                  label: item.label,
                  value: item.value,
                ),
            ],
            onSeeAll:
                summary.dailySummaryTotalCount >
                    summary.dailySummaryItems.length
                ? () => JournalDailyDetailSheet.show(
                    context: context,
                    selectedDayLocal: summary.day,
                    readOnly: true,
                  )
                : null,
          ),
          const SizedBox(height: 8),
          for (final entry in summary.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: JournalLogCard(
                entry: entry,
                events:
                    summary.eventsByEntryId[entry.id] ?? const <TrackerEvent>[],
                definitionById: summary.definitionById,
                moodTrackerId: summary.moodTrackerId,
                onTap: () => Routing.toJournalEntryEdit(context, entry.id),
              ),
            ),
        ],
      ),
    );
  }
}

String _moodEmoji(double? moodAverage) {
  if (moodAverage == null) return '-';
  return MoodRating.fromValue(moodAverage.round().clamp(1, 5)).emoji;
}

String _moodLabel(double? moodAverage) {
  if (moodAverage == null) return 'Mood avg: -';
  return 'Mood avg: ${moodAverage.toStringAsFixed(1)}';
}
