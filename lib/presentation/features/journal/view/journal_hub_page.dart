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
import 'package:taskly_domain/preferences.dart';
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
    List<TrackerDefinition> factorDefinitions,
    List<TrackerGroup> factorGroups,
  ) async {
    DateTime? rangeStart = filters.rangeStart;
    DateTime? rangeEnd = filters.rangeEnd;
    final selectedFactorIds = <String>{...filters.factorTrackerIds};
    String? factorGroupId = filters.factorGroupId;
    final now = context.read<NowService>().nowLocal();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final dateLabel = rangeStart == null || rangeEnd == null
                ? context.l10n.journalAnyTimeLabel
                : '${DateFormat.yMMMd().format(rangeStart!.toLocal())} - '
                      '${DateFormat.yMMMd().format(rangeEnd!.toLocal())}';

            DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
            final today = dayOnly(now);
            final last7Start = today.subtract(const Duration(days: 6));
            final thisMonthStart = DateTime(today.year, today.month);
            final thisMonthEnd = DateTime(today.year, today.month + 1, 0);
            final isToday =
                rangeStart != null &&
                rangeEnd != null &&
                dayOnly(rangeStart!) == today &&
                dayOnly(rangeEnd!) == today;
            final isLast7 =
                rangeStart != null &&
                rangeEnd != null &&
                dayOnly(rangeStart!) == last7Start &&
                dayOnly(rangeEnd!) == today;
            final isThisMonth =
                rangeStart != null &&
                rangeEnd != null &&
                dayOnly(rangeStart!) == thisMonthStart &&
                dayOnly(rangeEnd!) == thisMonthEnd;

            return Container(
              padding: EdgeInsets.only(
                left: TasklyTokens.of(context).spaceLg,
                right: TasklyTokens.of(context).spaceLg,
                top: TasklyTokens.of(context).spaceLg,
                bottom:
                    MediaQuery.viewInsetsOf(context).bottom +
                    TasklyTokens.of(context).spaceLg,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(TasklyTokens.of(context).radiusXxl),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Filter Journal',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            rangeStart = null;
                            rangeEnd = null;
                            factorGroupId = null;
                            selectedFactorIds.clear();
                          });
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: TasklyTokens.of(context).spaceXs),
                      Text(
                        'Date Range',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  SizedBox(height: TasklyTokens.of(context).spaceXs),
                  Wrap(
                    spacing: TasklyTokens.of(context).spaceXs,
                    runSpacing: TasklyTokens.of(context).spaceXs,
                    children: [
                      ChoiceChip(
                        label: const Text('Today'),
                        selected: isToday,
                        selectedColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isToday
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) {
                          setState(() {
                            rangeStart = today;
                            rangeEnd = today;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Last 7 Days'),
                        selected: isLast7,
                        selectedColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isLast7
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) {
                          setState(() {
                            rangeStart = last7Start;
                            rangeEnd = today;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('This Month'),
                        selected: isThisMonth,
                        selectedColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isThisMonth
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) {
                          setState(() {
                            rangeStart = thisMonthStart;
                            rangeEnd = thisMonthEnd;
                          });
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.calendar_today, size: 16),
                        label: const Text('Custom'),
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            initialDateRange:
                                rangeStart != null && rangeEnd != null
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
                    ],
                  ),
                  SizedBox(height: TasklyTokens.of(context).spaceXs),
                  Text(
                    dateLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                  DropdownButtonFormField<String?>(
                    value: factorGroupId,
                    decoration: InputDecoration(
                      labelText: context.l10n.groupsTitle,
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(context.l10n.allLabel),
                      ),
                      for (final group in factorGroups)
                        DropdownMenuItem<String?>(
                          value: group.id,
                          child: Text(group.name),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        factorGroupId = value;
                      });
                    },
                  ),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                  Text(
                    context.l10n.journalTrackersTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: TasklyTokens.of(context).spaceXs),
                  Wrap(
                    spacing: TasklyTokens.of(context).spaceXs,
                    runSpacing: TasklyTokens.of(context).spaceXs,
                    children: [
                      for (final definition in factorDefinitions)
                        FilterChip(
                          avatar: Icon(
                            Icons.circle,
                            size: 8,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          label: Text(definition.name),
                          selected: selectedFactorIds.contains(definition.id),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedFactorIds.add(definition.id);
                              } else {
                                selectedFactorIds.remove(definition.id);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  SizedBox(height: TasklyTokens.of(context).spaceMd),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(context.l10n.cancelLabel),
                        ),
                      ),
                      SizedBox(width: TasklyTokens.of(context).spaceSm),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: () {
                            context.read<JournalHistoryBloc>().add(
                              JournalHistoryFiltersChanged(
                                filters.copyWith(
                                  rangeStart: rangeStart,
                                  rangeEnd: rangeEnd,
                                  factorGroupId: factorGroupId,
                                  factorTrackerIds: selectedFactorIds,
                                ),
                              ),
                            );
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.filter_alt_outlined),
                          label: Text(
                            '${context.l10n.applyLabel} (${selectedFactorIds.length + (factorGroupId == null ? 0 : 1) + (rangeStart != null && rangeEnd != null ? 1 : 0)})',
                          ),
                        ),
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

            final topDay =
                state is JournalHistoryLoaded && state.days.isNotEmpty
                ? state.days.first
                : null;
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
                density: state.density,
                topInsight: state.topInsight,
                showInsightsNudge: state.showInsightsNudge,
                filters: filters,
                factorDefinitions: state.factorDefinitions,
                factorGroups: state.factorGroups,
              ),
            };

            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                title: topDay == null
                    ? Text(context.l10n.journalTitle)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat.MMMEd().format(topDay.day.toLocal()),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Daily Overview',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                actions: [
                  IconButton(
                    tooltip: context.l10n.filtersLabel,
                    onPressed: () {
                      final loaded = state is JournalHistoryLoaded
                          ? state
                          : null;
                      _showFilters(
                        context,
                        filters,
                        loaded?.factorDefinitions ??
                            const <TrackerDefinition>[],
                        loaded?.factorGroups ?? const <TrackerGroup>[],
                      );
                    },
                    icon: const Icon(Icons.tune),
                  ),
                  if (state is JournalHistoryLoaded)
                    IconButton(
                      tooltip: context.l10n.journalInsightsTitle,
                      onPressed: () => Routing.toJournalInsights(context),
                      icon: const Icon(Icons.insights_outlined),
                    ),
                  if (state is JournalHistoryLoaded)
                    IconButton(
                      tooltip: state.density == DisplayDensity.compact
                          ? context.l10n.displayDensityStandard
                          : context.l10n.displayDensityCompact,
                      onPressed: () => context.read<JournalHistoryBloc>().add(
                        const JournalHistoryDensityToggled(),
                      ),
                      icon: Icon(
                        state.density == DisplayDensity.compact
                            ? Icons.view_agenda_outlined
                            : Icons.view_stream_outlined,
                      ),
                    ),
                  IconButton(
                    tooltip: context.l10n.journalManageTrackersTitle,
                    onPressed: () => Routing.pushScreenKey(
                      context,
                      'journal_manage_factors',
                    ),
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
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.surface,
                            Theme.of(context).colorScheme.surfaceContainerLow,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: body,
                    ),
                  ),
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
        tokens.spaceSm,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.journalTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                context.l10n.journalEntriesTitle,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
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
    required this.density,
    required this.topInsight,
    required this.showInsightsNudge,
    required this.filters,
    required this.factorDefinitions,
    required this.factorGroups,
  });

  final List<JournalHistoryDaySummary> days;
  final bool isLoadingMore;
  final ScrollController scrollController;
  final DisplayDensity density;
  final JournalTopInsight? topInsight;
  final bool showInsightsNudge;
  final JournalHistoryFilters filters;
  final List<TrackerDefinition> factorDefinitions;
  final List<TrackerGroup> factorGroups;

  @override
  Widget build(BuildContext context) {
    final hasFilters =
        filters.rangeStart != null ||
        filters.rangeEnd != null ||
        filters.factorGroupId != null ||
        filters.factorTrackerIds.isNotEmpty;
    if (days.isEmpty) {
      if (hasFilters) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            TasklyTokens.of(context).spaceLg,
            0,
            TasklyTokens.of(context).spaceLg,
            TasklyTokens.of(context).spaceLg,
          ),
          children: [
            _AppliedFiltersRow(
              filters: filters,
              factorDefinitions: factorDefinitions,
              factorGroups: factorGroups,
            ),
            SizedBox(height: TasklyTokens.of(context).spaceMd),
            Center(
              child: Text(context.l10n.journalNoMatchingMomentsForFilters),
            ),
          ],
        );
      }
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
      itemCount: days.length + (isLoadingMore ? 1 : 0) + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          final topDay = days.first;
          return Padding(
            padding: EdgeInsets.only(bottom: TasklyTokens.of(context).spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Day',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
                _YourDayCard(summary: topDay),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
                if (topInsight != null)
                  _TopInsightCard(insight: topInsight!)
                else if (showInsightsNudge)
                  _TopInsightNudgeCard(),
                _AppliedFiltersRow(
                  filters: filters,
                  factorDefinitions: factorDefinitions,
                  factorGroups: factorGroups,
                ),
              ],
            ),
          );
        }
        final adjustedIndex = index - 1;
        if (adjustedIndex >= days.length) {
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (adjustedIndex == 0)
              Padding(
                padding: EdgeInsets.only(
                  top: TasklyTokens.of(context).spaceSm,
                  bottom: TasklyTokens.of(context).spaceSm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Moments',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
            _DayTimelineSection(
              summary: days[adjustedIndex],
              density: density,
            ),
          ],
        );
      },
    );
  }
}

class _YourDayCard extends StatelessWidget {
  const _YourDayCard({required this.summary});

  final JournalHistoryDaySummary summary;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final quantityEntries =
        summary.dayQuantityTotalsByTrackerId.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final firstQuantity = quantityEntries.isNotEmpty
        ? quantityEntries.first
        : null;
    final firstQuantityDef = firstQuantity == null
        ? null
        : summary.definitionById[firstQuantity.key];
    final socialDef = summary.definitionById.values
        .cast<TrackerDefinition?>()
        .firstWhere(
          (definition) =>
              definition?.name.toLowerCase().contains('social') ?? false,
          orElse: () => null,
        );

    Widget metricTile({
      required String title,
      required String value,
      required IconData icon,
      Color? accent,
    }) {
      return Container(
        padding: EdgeInsets.all(tokens.spaceSm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: accent ?? theme.colorScheme.primary,
                ),
                SizedBox(width: tokens.spaceXxs),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.spaceXxs),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surfaceContainerHigh,
            theme.colorScheme.surfaceContainerLow,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: metricTile(
                    title: 'Mood',
                    value: summary.moodAverage == null
                        ? context.l10n.journalMoodAverageEmpty
                        : summary.moodAverage!.toStringAsFixed(1),
                    icon: Icons.sentiment_satisfied_alt,
                    accent: theme.colorScheme.tertiary,
                  ),
                ),
                SizedBox(width: tokens.spaceSm),
                Expanded(
                  child: metricTile(
                    title:
                        firstQuantityDef?.name ??
                        context.l10n.journalTrackersTitle,
                    value: firstQuantity == null
                        ? '-'
                        : firstQuantity.value ==
                              firstQuantity.value.roundToDouble()
                        ? firstQuantity.value.round().toString()
                        : firstQuantity.value.toStringAsFixed(1),
                    icon: Icons.water_drop_outlined,
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.spaceSm),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceSm,
                vertical: tokens.spaceXs,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(tokens.radiusMd),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    socialDef == null ? Icons.event_note : Icons.trending_up,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: tokens.spaceXs),
                  Expanded(
                    child: Text(
                      socialDef?.name ?? context.l10n.journalEntriesTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: tokens.spaceXs),
            Text(
              '${DateFormat.yMMMEd().format(summary.day.toLocal())} · '
              '${context.l10n.journalEntryCountLabel(summary.entries.length)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopInsightCard extends StatelessWidget {
  const _TopInsightCard({required this.insight});

  final JournalTopInsight insight;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final deltaValue = insight.deltaMood.abs().toStringAsFixed(1);
    final delta = insight.deltaMood >= 0 ? '+$deltaValue' : '-$deltaValue';
    final confidenceLabel = insight.confidence == JournalInsightConfidence.high
        ? context.l10n.journalInsightHighConfidence
        : context.l10n.journalInsightMediumConfidence;
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.insightTypeCorrelationDiscovery,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            SizedBox(height: tokens.spaceXxs),
            Text(
              context.l10n.journalTopInsightAssociated(
                insight.factorName,
                delta,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: tokens.spaceXxs),
            Text(
              context.l10n.journalTopInsightMeta(
                confidenceLabel,
                insight.sampleSize,
                insight.windowDays,
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopInsightNudgeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceMd),
        child: Text(
          context.l10n.journalInsightsNudge,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _AppliedFiltersRow extends StatelessWidget {
  const _AppliedFiltersRow({
    required this.filters,
    required this.factorDefinitions,
    required this.factorGroups,
  });

  final JournalHistoryFilters filters;
  final List<TrackerDefinition> factorDefinitions;
  final List<TrackerGroup> factorGroups;

  @override
  Widget build(BuildContext context) {
    final hasFilters =
        filters.rangeStart != null ||
        filters.rangeEnd != null ||
        filters.factorGroupId != null ||
        filters.factorTrackerIds.isNotEmpty;
    if (!hasFilters) return const SizedBox.shrink();

    final defsById = {for (final def in factorDefinitions) def.id: def};
    final groupsById = {for (final group in factorGroups) group.id: group};
    final tokens = TasklyTokens.of(context);
    final chips = <Widget>[];

    if (filters.rangeStart != null && filters.rangeEnd != null) {
      chips.add(
        Chip(
          label: Text(
            '${DateFormat.yMMMd().format(filters.rangeStart!.toLocal())} - '
            '${DateFormat.yMMMd().format(filters.rangeEnd!.toLocal())}',
          ),
        ),
      );
    }
    final groupId = filters.factorGroupId;
    if (groupId != null && groupId.isNotEmpty) {
      chips.add(
        Chip(
          label: Text(
            groupsById[groupId]?.name ?? context.l10n.groupsTitle,
          ),
        ),
      );
    }
    for (final trackerId in filters.factorTrackerIds) {
      chips.add(
        Chip(
          label: Text(
            defsById[trackerId]?.name ??
                context.l10n.journalRemovedTrackerFilterLabel,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: tokens.spaceSm, bottom: tokens.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.journalAppliedFiltersLabel,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.spaceXs),
          Wrap(
            spacing: tokens.spaceXs,
            runSpacing: tokens.spaceXs,
            children: chips,
          ),
        ],
      ),
    );
  }
}

class _DayTimelineSection extends StatelessWidget {
  const _DayTimelineSection({required this.summary, required this.density});

  final JournalHistoryDaySummary summary;
  final DisplayDensity density;

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
                density: density,
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
