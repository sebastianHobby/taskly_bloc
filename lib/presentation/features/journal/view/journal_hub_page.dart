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
  bool _isSearchExpanded = false;
  bool _starterPromptShownThisSession = false;

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

  Future<void> _showStarterPackSheet(
    BuildContext context,
    JournalHistoryLoaded state,
  ) async {
    final selected = <String>{
      for (final option in state.starterOptions)
        if (option.defaultSelected) option.id,
    };
    final grouped = <String, List<JournalStarterOption>>{};
    for (final option in state.starterOptions) {
      (grouped[option.category] ??= <JournalStarterOption>[]).add(option);
    }

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                TasklyTokens.of(sheetContext).spaceLg,
                TasklyTokens.of(sheetContext).spaceSm,
                TasklyTokens.of(sheetContext).spaceLg,
                TasklyTokens.of(sheetContext).spaceLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set up your starter trackers',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  SizedBox(height: TasklyTokens.of(sheetContext).spaceXxs),
                  Text(
                    'Choose what to add now. You can edit anytime.',
                    style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        sheetContext,
                      ).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: TasklyTokens.of(sheetContext).spaceSm),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final entry in grouped.entries) ...[
                          Padding(
                            padding: EdgeInsets.only(
                              top: TasklyTokens.of(sheetContext).spaceSm,
                            ),
                            child: Text(
                              entry.key,
                              style: Theme.of(sheetContext).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          for (final option in entry.value)
                            CheckboxListTile(
                              value: selected.contains(option.id),
                              dense: true,
                              title: Text(option.name),
                              subtitle: Text(
                                '${option.valueType} · ${option.scope}',
                              ),
                              onChanged: (checked) {
                                setSheetState(() {
                                  if (checked == true) {
                                    selected.add(option.id);
                                  } else {
                                    selected.remove(option.id);
                                  }
                                });
                              },
                            ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: TasklyTokens.of(sheetContext).spaceSm),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(false),
                        child: Text(sheetContext.l10n.notNowLabel),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          context.read<JournalHistoryBloc>().add(
                            JournalHistoryStarterPackApplied(selected),
                          );
                          Navigator.of(sheetContext).pop(true);
                        },
                        child: Text('Add selected'),
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

    if (!context.mounted) return;
    if (applied != true) {
      context.read<JournalHistoryBloc>().add(
        const JournalHistoryStarterPackDismissed(),
      );
    }
  }

  Future<void> _showManageSheet(BuildContext context) async {
    final l10n = context.l10n;
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(l10n.journalDailyCheckInsTitle),
                subtitle: Text(l10n.journalDailyAppliesTodaySubtitle),
                onTap: () => Navigator.of(sheetContext).pop('daily'),
              ),
              ListTile(
                leading: const Icon(Icons.tune),
                title: Text(l10n.journalTrackersTitle),
                subtitle: Text(l10n.journalTrackerPerLogSubtitle),
                onTap: () => Navigator.of(sheetContext).pop('trackers'),
              ),
            ],
          ),
        );
      },
    );
    if (!context.mounted || selected == null) return;
    final routeKey = selected == 'daily'
        ? 'journal_manage_daily_checkins'
        : 'journal_manage_trackers';
    Routing.pushScreenKey(context, routeKey);
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
        settingsRepository: context.read<SettingsRepositoryContract>(),
        nowUtc: context.read<NowService>().nowUtc,
      )..add(const JournalHistoryStarted()),
      child: BlocListener<JournalHistoryBloc, JournalHistoryState>(
        listener: (context, state) {
          if (state is JournalHistoryLoaded || state is JournalHistoryError) {
            _isLoadMoreInFlight = false;
          }
          if (state is JournalHistoryLoaded &&
              state.showStarterPack &&
              !_starterPromptShownThisSession) {
            _starterPromptShownThisSession = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              _showStarterPackSheet(context, state);
            });
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
            if (filters.searchText.isNotEmpty) {
              _isSearchExpanded = true;
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

            final days = switch (state) {
              JournalHistoryLoaded(:final days) => days,
              _ => const <JournalHistoryDaySummary>[],
            };

            final todaySummary = days.firstWhere(
              (day) => _isSameLocalDay(day.day, nowLocal),
              orElse: () => _emptySummaryFor(nowLocal),
            );

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
                    onPressed: () => _showManageSheet(context),
                    icon: const Icon(Icons.monitor_heart_outlined),
                  ),
                ],
              ),
              body: Column(
                children: [
                  const _JournalTitleHeader(),
                  _SearchHeader(
                    controller: _searchController,
                    isExpanded: _isSearchExpanded,
                    onToggle: () {
                      setState(() {
                        _isSearchExpanded = !_isSearchExpanded;
                        if (!_isSearchExpanded &&
                            _searchController.text.isNotEmpty) {
                          _searchController.clear();
                          _onSearchChanged('', filters);
                        }
                      });
                    },
                    onChanged: (value) => _onSearchChanged(value, filters),
                  ),
                  _TodayPulseCard(summary: todaySummary),
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

  static JournalHistoryDaySummary _emptySummaryFor(DateTime nowLocal) {
    return JournalHistoryDaySummary(
      day: DateTime.utc(nowLocal.year, nowLocal.month, nowLocal.day),
      entries: const <JournalEntry>[],
      eventsByEntryId: const <String, List<TrackerEvent>>{},
      definitionById: const <String, TrackerDefinition>{},
      moodTrackerId: null,
      moodAverage: null,
      dayQuantityTotalsByTrackerId: const <String, double>{},
      dailySummaryItems: const <JournalDailySummaryItem>[],
      dailyCompletedCount: 0,
      dailySummaryTotalCount: 0,
    );
  }

  static bool _isSameLocalDay(DateTime a, DateTime b) {
    final al = a.toLocal();
    final bl = b.toLocal();
    return al.year == bl.year && al.month == bl.month && al.day == bl.day;
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.isExpanded,
    required this.onToggle,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isExpanded;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceSm,
        tokens.spaceLg,
        tokens.spaceSm,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: context.l10n.journalSearchEntriesLabel,
            onPressed: onToggle,
            icon: Icon(isExpanded ? Icons.close : Icons.search),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: isExpanded
                  ? TextField(
                      key: const ValueKey('journal_search_field'),
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: context.l10n.journalSearchEntriesLabel,
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: onChanged,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayPulseCard extends StatelessWidget {
  const _TodayPulseCard({required this.summary});

  final JournalHistoryDaySummary summary;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final hasMood = summary.moodAverage != null;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        0,
        tokens.spaceLg,
        tokens.spaceSm,
      ),
      padding: EdgeInsets.all(tokens.spaceMd),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(hasMood ? _moodEmoji(summary.moodAverage!) : '—'),
          ),
          SizedBox(width: tokens.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today Pulse',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: tokens.spaceXxs),
                Text(
                  hasMood
                      ? 'Mood ${summary.moodAverage!.toStringAsFixed(1)} · '
                            '${summary.dailyCompletedCount}/${summary.dailySummaryTotalCount} trackers'
                      : '${summary.dailyCompletedCount}/${summary.dailySummaryTotalCount} trackers',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            context.l10n.journalEntryCountLabel(summary.entries.length),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }

  String _moodEmoji(double value) {
    if (value < 1.5) return '😟';
    if (value < 2.5) return '🙁';
    if (value < 3.5) return '😐';
    if (value < 4.5) return '🙂';
    return '😄';
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
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: tokens.spaceSm),
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceSm,
              vertical: tokens.spaceXs,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateLabel,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      SizedBox(height: tokens.spaceXxs),
                      Text(
                        metadata,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (summary.moodAverage != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.spaceSm,
                      vertical: tokens.spaceXxs,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(tokens.radiusPill),
                    ),
                    child: Text(
                      '${_moodEmoji(summary.moodAverage!)} ${summary.moodAverage!.toStringAsFixed(1)}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
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
                dayQuantityTotalsByTrackerId:
                    summary.dayQuantityTotalsByTrackerId,
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
        ? null
        : context.l10n.journalMoodAverageValue(
            summary.moodAverage!.toStringAsFixed(1),
          );
    if (mood == null) return entryCount;
    return '$entryCount · $mood';
  }

  String _moodEmoji(double value) {
    if (value < 1.5) return '😟';
    if (value < 2.5) return '🙁';
    if (value < 3.5) return '😐';
    if (value < 4.5) return '🙂';
    return '😄';
  }
}
