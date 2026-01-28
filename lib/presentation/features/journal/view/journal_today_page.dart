import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_today_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/add_log_sheet.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/journal_daily_detail_sheet.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/journal_today_shared_widgets.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_ui/taskly_ui_sections.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class JournalTodayPage extends StatefulWidget {
  const JournalTodayPage({required this.day, super.key});

  final DateTime day;

  @override
  State<JournalTodayPage> createState() => _JournalTodayPageState();
}

class _JournalTodayPageState extends State<JournalTodayPage> {
  bool _showDailyDetails = true;

  @override
  Widget build(BuildContext context) {
    final day = widget.day;

    return BlocProvider<JournalTodayBloc>(
      key: ValueKey<DateTime>(DateTime(day.year, day.month, day.day)),
      create: (context) => JournalTodayBloc(
        repository: context.read<JournalRepositoryContract>(),
        selectedDay: day,
      )..add(JournalTodayStarted(selectedDay: day)),
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
              :final moodAverage,
              :final dailySummaryItems,
              :final dailySummaryTotalCount,
            ) =>
              ListView(
                padding: EdgeInsets.fromLTRB(
                  TasklyTokens.of(context).spaceMd,
                  TasklyTokens.of(context).spaceMd,
                  TasklyTokens.of(context).spaceMd,
                  TasklyTokens.of(context).spaceLg,
                ),
                children: [
                  _DailySummaryHeader(
                    isExpanded: _showDailyDetails,
                    onToggle: () => setState(() {
                      _showDailyDetails = !_showDailyDetails;
                    }),
                  ),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                  TasklyJournalDailySummarySection(
                    moodEmoji: _moodEmoji(moodAverage),
                    moodLabel: _moodLabel(moodAverage),
                    entryCountLabel: entries.length == 1
                        ? '1 entry'
                        : '${entries.length} entries',
                    items: [
                      for (final item in dailySummaryItems)
                        TasklyJournalDailySummaryItem(
                          label: item.label,
                          value: item.value,
                        ),
                    ],
                    showItems: _showDailyDetails,
                    onEditDaily: () => JournalDailyDetailSheet.show(
                      context: context,
                      selectedDayLocal: day,
                      readOnly: false,
                    ),
                    onSeeAll: dailySummaryTotalCount > dailySummaryItems.length
                        ? () => JournalDailyDetailSheet.show(
                            context: context,
                            selectedDayLocal: day,
                            readOnly: true,
                          )
                        : null,
                  ),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                  _EntriesHeader(
                    showAdd: entries.isEmpty,
                    onAddLog: () => AddLogSheet.show(
                      context: context,
                      selectedDayLocal: day,
                    ),
                  ),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
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

class _DailySummaryHeader extends StatelessWidget {
  const _DailySummaryHeader({
    required this.isExpanded,
    required this.onToggle,
  });

  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Daily summary', style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        IconButton(
          tooltip: isExpanded ? 'Collapse' : 'Expand',
          onPressed: onToggle,
          icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
        ),
      ],
    );
  }
}

class _EntriesHeader extends StatelessWidget {
  const _EntriesHeader({
    required this.showAdd,
    required this.onAddLog,
  });

  final bool showAdd;
  final VoidCallback onAddLog;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Entries', style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        if (showAdd)
          TextButton(
            onPressed: onAddLog,
            child: const Text('Add entry'),
          ),
      ],
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
            padding: EdgeInsets.only(bottom: TasklyTokens.of(context).spaceSm),
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
        padding: EdgeInsets.all(TasklyTokens.of(context).spaceLg),
        child: Text(message),
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
