import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_history_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_entry_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/journal_today_shared_widgets.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class JournalHubPage extends StatefulWidget {
  const JournalHubPage({super.key});

  @override
  State<JournalHubPage> createState() => _JournalHubPageState();
}

class _JournalHubPageState extends State<JournalHubPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoadMoreInFlight = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (maxScroll <= 0 || current < maxScroll - 320) return;
    if (_isLoadMoreInFlight) return;

    final bloc = context.read<JournalHistoryBloc>();
    final filters = switch (bloc.state) {
      JournalHistoryLoading(:final filters) => filters,
      JournalHistoryLoaded(:final filters) => filters,
      JournalHistoryError(:final filters) => filters,
    };
    if (filters.rangeStart != null && filters.rangeEnd != null) return;

    _isLoadMoreInFlight = true;
    bloc.add(const JournalHistoryLoadMoreRequested());
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

  void _onSearchChanged(String value, JournalHistoryFilters filters) {
    context.read<JournalHistoryBloc>().add(
      JournalHistoryFiltersChanged(
        filters.copyWith(searchText: value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nowLocal = context.read<NowService>().nowLocal();

    return BlocProvider<JournalHistoryBloc>(
      create: (context) => JournalHistoryBloc(
        repository: context.read<JournalRepositoryContract>(),
        dayKeyService: context.read<HomeDayKeyService>(),
      )..add(const JournalHistoryStarted()),
      child: BlocListener<JournalHistoryBloc, JournalHistoryState>(
        listener: (_, state) {
          if (state is JournalHistoryLoaded || state is JournalHistoryError) {
            _isLoadMoreInFlight = false;
          }
        },
        child: BlocBuilder<JournalHistoryBloc, JournalHistoryState>(
          builder: (context, state) {
            final filters = switch (state) {
              JournalHistoryLoaded(:final filters) => filters,
              JournalHistoryLoading(:final filters) => filters,
              JournalHistoryError(:final filters) => filters,
            };

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
              JournalHistoryLoaded(:final days) => _TimelineList(
                days: days,
                isLoadingMore: _isLoadMoreInFlight,
                scrollController: _scrollController,
              ),
            };

            return Scaffold(
              appBar: AppBar(
                actions: [
                  IconButton(
                    tooltip: context.l10n.filtersLabel,
                    onPressed: () => _showFilters(context, filters),
                    icon: const Icon(Icons.tune),
                  ),
                  IconButton(
                    tooltip: context.l10n.journalManageTrackersTitle,
                    onPressed: () => Routing.pushScreenKey(
                      context,
                      'journal_manage_trackers',
                    ),
                    icon: const Icon(Icons.settings_input_component),
                  ),
                ],
              ),
              body: Column(
                children: [
                  const _JournalTitleHeader(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      TasklyTokens.of(context).spaceLg,
                      TasklyTokens.of(context).spaceSm,
                      TasklyTokens.of(context).spaceLg,
                      TasklyTokens.of(context).spaceMd,
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: context.l10n.journalSearchEntriesLabel,
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (value) => _onSearchChanged(value, filters),
                    ),
                  ),
                  Expanded(child: body),
                ],
              ),
              floatingActionButton: EntityAddFab(
                tooltip: context.l10n.journalAddEntry,
                heroTag: 'journal_add_entry_fab',
                onPressed: () => JournalEntryEditorRoutePage.showQuickCapture(
                  context,
                  selectedDayLocal: nowLocal,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _JournalTitleHeader extends StatelessWidget {
  const _JournalTitleHeader();

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
            context.l10n.journalTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({
    required this.days,
    required this.isLoadingMore,
    required this.scrollController,
  });

  final List<JournalHistoryDaySummary> days;
  final bool isLoadingMore;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return Center(child: Text(context.l10n.journalNoRecentLogs));
    }

    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(
        TasklyTokens.of(context).spaceLg,
        0,
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceLg,
      ),
      itemCount: days.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= days.length) {
          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: TasklyTokens.of(context).spaceMd,
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return _DayTimelineSection(summary: days[index]);
      },
    );
  }
}

class _DayTimelineSection extends StatelessWidget {
  const _DayTimelineSection({required this.summary});

  final JournalHistoryDaySummary summary;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final dateLabel = DateFormat.yMMMEd().format(summary.day.toLocal());
    final metadata = _buildMetadataLabel(context, summary);

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: tokens.spaceSm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: tokens.spaceXxs),
                Text(
                  metadata,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          for (final entry in summary.entries)
            Padding(
              padding: EdgeInsets.only(bottom: tokens.spaceSm),
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

  String _buildMetadataLabel(
    BuildContext context,
    JournalHistoryDaySummary summary,
  ) {
    final entryCount = context.l10n.journalEntryCountLabel(
      summary.entries.length,
    );
    final mood = summary.moodAverage == null
        ? context.l10n.journalMoodAverageEmpty
        : context.l10n.journalMoodAverageValue(
            summary.moodAverage!.toStringAsFixed(1),
          );
    return '$entryCount · $mood';
  }
}
