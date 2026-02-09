import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_history_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/journal_daily_detail_sheet.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/journal_today_shared_widgets.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_ui/taskly_ui_sections.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class JournalHistoryPage extends StatefulWidget {
  const JournalHistoryPage({super.key});

  @override
  State<JournalHistoryPage> createState() => _JournalHistoryPageState();
}

class _JournalHistoryPageState extends State<JournalHistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  JournalHistoryFilters _filtersFromState(JournalHistoryState state) {
    return switch (state) {
      JournalHistoryLoaded(:final filters) => filters,
      JournalHistoryLoading(:final filters) => filters,
      JournalHistoryError(:final filters) => filters,
    };
  }

  void _updateSearch(
    BuildContext context,
    JournalHistoryFilters filters,
    String text,
  ) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<JournalHistoryBloc>().add(
        JournalHistoryFiltersChanged(
          filters.copyWith(searchText: text),
        ),
      );
    });
  }

  Future<void> _showFilters(
    BuildContext context,
    JournalHistoryFilters filters,
  ) async {
    DateTime? rangeStart = filters.rangeStart;
    DateTime? rangeEnd = filters.rangeEnd;
    int? moodMin = filters.moodMinValue;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final dateLabel = rangeStart == null || rangeEnd == null
                ? context.l10n.journalAnyTimeLabel
                : '${DateFormat.yMMMd().format(rangeStart!.toLocal())} - '
                      '${DateFormat.yMMMd().format(rangeEnd!.toLocal())}';

            final moodValue = (moodMin ?? 3).toDouble();
            final moodEnabled = moodMin != null;

            return Padding(
              padding: EdgeInsets.only(
                left: TasklyTokens.of(context).spaceLg,
                right: TasklyTokens.of(context).spaceLg,
                top: TasklyTokens.of(context).spaceLg,
                bottom:
                    MediaQuery.viewInsetsOf(context).bottom +
                    TasklyTokens.of(context).spaceLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.filtersLabel,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                  ListTile(
                    title: Text(context.l10n.journalDateRangeTitle),
                    subtitle: Text(dateLabel),
                    trailing: const Icon(Icons.date_range),
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        initialDateRange: rangeStart != null && rangeEnd != null
                            ? DateTimeRange(
                                start: rangeStart!,
                                end: rangeEnd!,
                              )
                            : null,
                      );
                      if (picked == null) return;
                      setState(() {
                        rangeStart = picked.start;
                        rangeEnd = picked.end;
                      });
                    },
                  ),
                  SwitchListTile(
                    title: Text(context.l10n.journalMoodMinimumTitle),
                    value: moodEnabled,
                    onChanged: (value) {
                      setState(() {
                        moodMin = value ? 3 : null;
                      });
                    },
                  ),
                  if (moodEnabled)
                    Slider(
                      value: moodValue,
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: moodValue.round().toString(),
                      onChanged: (value) {
                        setState(() {
                          moodMin = value.round();
                        });
                      },
                    ),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            rangeStart = null;
                            rangeEnd = null;
                            moodMin = null;
                          });
                        },
                        child: Text(context.l10n.clearLabel),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(context.l10n.cancelLabel),
                      ),
                      FilledButton(
                        onPressed: () {
                          context.read<JournalHistoryBloc>().add(
                            JournalHistoryFiltersChanged(
                              filters.copyWith(
                                rangeStart: rangeStart,
                                rangeEnd: rangeEnd,
                                moodMinValue: moodMin,
                              ),
                            ),
                          );
                          Navigator.of(context).pop();
                        },
                        child: Text(context.l10n.applyLabel),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JournalHistoryBloc>(
      create: (context) => JournalHistoryBloc(
        repository: context.read<JournalRepositoryContract>(),
        dayKeyService: context.read<HomeDayKeyService>(),
      )..add(const JournalHistoryStarted()),
      child: BlocBuilder<JournalHistoryBloc, JournalHistoryState>(
        builder: (context, state) {
          final filters = _filtersFromState(state);
          if (_searchController.text != filters.searchText) {
            _searchController.text = filters.searchText;
            _searchController.selection = TextSelection.fromPosition(
              TextPosition(offset: _searchController.text.length),
            );
          }

          final body = switch (state) {
            JournalHistoryLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            JournalHistoryError(:final message) => Center(
              child: Text(message),
            ),
            JournalHistoryLoaded(:final days) => _HistoryList(days: days),
          };

          return Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  tooltip: context.l10n.filtersLabel,
                  onPressed: () => _showFilters(context, filters),
                  icon: const Icon(Icons.tune),
                ),
              ],
            ),
            body: Column(
              children: [
                const _JournalHistoryTitleHeader(),
                Padding(
                  padding: EdgeInsets.all(TasklyTokens.of(context).spaceLg),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: context.l10n.journalSearchEntriesLabel,
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) =>
                        _updateSearch(context, filters, value),
                  ),
                ),
                Expanded(child: body),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _JournalHistoryTitleHeader extends StatelessWidget {
  const _JournalHistoryTitleHeader();

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconSet = const NavigationIconResolver().resolve(
      screenId: 'journal',
      iconName: null,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.sectionPaddingH,
        tokens.spaceMd,
        tokens.sectionPaddingH,
        tokens.spaceSm,
      ),
      child: Row(
        children: [
          Icon(
            iconSet.selectedIcon,
            color: scheme.primary,
            size: tokens.spaceLg3,
          ),
          SizedBox(width: tokens.spaceSm),
          Text(
            context.l10n.journalHistoryTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
      return Center(child: Text(context.l10n.journalNoRecentLogs));
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: TasklyTokens.of(context).spaceLg,
      ),
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
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: TasklyTokens.of(context).spaceLg,
        vertical: TasklyTokens.of(context).spaceSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateLabel, style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: TasklyTokens.of(context).spaceSm),
          TasklyJournalDailySummarySection(
            moodEmoji: _moodEmoji(summary.moodAverage),
            moodLabel: _moodLabel(l10n, summary.moodAverage),
            entryCountLabel: l10n.journalEntryCountLabel(
              summary.entries.length,
            ),
            items: [
              for (final item in summary.dailySummaryItems)
                TasklyJournalDailySummaryItem(
                  label: item.label,
                  value: item.value,
                ),
            ],
            emptyItemsLabel: l10n.journalDailyNoTrackers,
            seeAllLabel: l10n.journalSeeAll,
            editDailyLabel: l10n.journalEditDaily,
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
          SizedBox(height: TasklyTokens.of(context).spaceSm),
          for (final entry in summary.entries)
            Padding(
              padding: EdgeInsets.only(
                bottom: TasklyTokens.of(context).spaceSm,
              ),
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

String _moodLabel(AppLocalizations l10n, double? moodAverage) {
  if (moodAverage == null) return l10n.journalMoodAverageEmpty;
  return l10n.journalMoodAverageValue(moodAverage.toStringAsFixed(1));
}
