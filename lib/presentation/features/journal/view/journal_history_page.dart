import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_history_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/ui/journal_motion_tokens.dart';
import 'package:taskly_bloc/presentation/features/journal/ui/tracker_value_formatter.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/journal_filters_sheet.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/journal_factor_token.dart';
import 'package:taskly_bloc/presentation/features/journal/utils/tracker_icon_utils.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class JournalHistoryPage extends StatefulWidget {
  const JournalHistoryPage({super.key});

  @override
  State<JournalHistoryPage> createState() => _JournalHistoryPageState();
}

class _JournalHistoryPageState extends State<JournalHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _isLoadMoreInFlight = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
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

  void _onSearchChanged(String value, JournalHistoryFilters filters) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context.read<JournalHistoryBloc>().add(
        JournalHistoryFiltersChanged(
          filters.copyWith(searchText: value.trim()),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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

            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                title: Text(context.l10n.journalHistoryTitle),
                actions: [
                  IconButton(
                    tooltip: context.l10n.filtersLabel,
                    onPressed: state is JournalHistoryLoaded
                        ? () => showJournalFiltersSheet(
                            context,
                            filters: filters,
                            factorDefinitions: state.factorDefinitions,
                            factorGroups: state.factorGroups,
                            onApply: (next) {
                              context.read<JournalHistoryBloc>().add(
                                JournalHistoryFiltersChanged(next),
                              );
                            },
                          )
                        : null,
                    icon: const Icon(Icons.filter_alt_outlined),
                  ),
                ],
              ),
              body: switch (state) {
                JournalHistoryLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                JournalHistoryError(:final message) => Center(
                  child: Padding(
                    padding: EdgeInsets.all(TasklyTokens.of(context).spaceLg),
                    child: Text(message),
                  ),
                ),
                JournalHistoryLoaded() => _HistoryBody(
                  state: state,
                  filters: filters,
                  scrollController: _scrollController,
                  searchController: _searchController,
                  onSearchChanged: (value) => _onSearchChanged(value, filters),
                ),
              },
            );
          },
        ),
      ),
    );
  }
}

JournalHistoryFilters _clearedFilters(JournalHistoryFilters filters) {
  return filters.copyWith(
    searchText: '',
    rangeStart: null,
    rangeEnd: null,
    factorTrackerIds: const <String>{},
    factorGroupId: null,
  );
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({
    required this.state,
    required this.filters,
    required this.scrollController,
    required this.searchController,
    required this.onSearchChanged,
  });

  final JournalHistoryLoaded state;
  final JournalHistoryFilters filters;
  final ScrollController scrollController;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final hasFilters =
        filters.rangeStart != null ||
        filters.rangeEnd != null ||
        filters.factorGroupId != null ||
        filters.factorTrackerIds.isNotEmpty ||
        filters.searchText.trim().isNotEmpty;
    final hasDateRange = filters.rangeStart != null && filters.rangeEnd != null;
    final days = state.days;

    return DecoratedBox(
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
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLg,
          tokens.spaceSm,
          tokens.spaceLg,
          tokens.spaceLg,
        ),
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: context.l10n.journalSearchEntriesLabel,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: context.l10n.clearLabel,
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
            onChanged: onSearchChanged,
          ),
          SizedBox(height: tokens.spaceSm),
          _HistoryAppliedFiltersRow(
            filters: filters,
            factorDefinitions: state.factorDefinitions,
            factorGroups: state.factorGroups,
            onClear: () {
              context.read<JournalHistoryBloc>().add(
                JournalHistoryFiltersChanged(_clearedFilters(filters)),
              );
            },
          ),
          if (days.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: tokens.spaceLg),
              child: Column(
                children: [
                  Text(
                    hasFilters
                        ? context.l10n.journalNoMatchingMomentsForFilters
                        : context.l10n.journalNoRecentLogs,
                    textAlign: TextAlign.center,
                  ),
                  if (hasFilters) ...[
                    SizedBox(height: tokens.spaceSm),
                    FilledButton(
                      onPressed: () {
                        context.read<JournalHistoryBloc>().add(
                          JournalHistoryFiltersChanged(
                            _clearedFilters(filters),
                          ),
                        );
                      },
                      child: Text(context.l10n.resetLabel),
                    ),
                  ],
                  if (!hasDateRange) ...[
                    SizedBox(height: tokens.spaceSm),
                    OutlinedButton(
                      onPressed: () {
                        context.read<JournalHistoryBloc>().add(
                          const JournalHistoryLoadMoreRequested(),
                        );
                      },
                      child: Text(context.l10n.journalLoadOlderEntriesLabel),
                    ),
                  ],
                ],
              ),
            )
          else ...[
            SizedBox(height: tokens.spaceSm),
            for (final summary in days)
              Padding(
                padding: EdgeInsets.only(bottom: tokens.spaceSm),
                child: _HistoryDayCard(
                  summary: summary,
                  dayTrackerDefinitions: state.dayTrackerDefinitions,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _HistoryAppliedFiltersRow extends StatelessWidget {
  const _HistoryAppliedFiltersRow({
    required this.filters,
    required this.factorDefinitions,
    required this.factorGroups,
    required this.onClear,
  });

  final JournalHistoryFilters filters;
  final List<TrackerDefinition> factorDefinitions;
  final List<TrackerGroup> factorGroups;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasFilters =
        filters.rangeStart != null ||
        filters.rangeEnd != null ||
        filters.factorGroupId != null ||
        filters.factorTrackerIds.isNotEmpty ||
        filters.searchText.trim().isNotEmpty;
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
    if (filters.searchText.trim().isNotEmpty) {
      chips.add(
        Chip(
          label: Text(
            context.l10n.searchQueryLabel(filters.searchText.trim()),
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
      padding: EdgeInsets.only(bottom: tokens.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.journalAppliedFiltersLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: onClear,
                child: Text(context.l10n.resetLabel),
              ),
            ],
          ),
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

class _HistoryDayCard extends StatefulWidget {
  const _HistoryDayCard({
    required this.summary,
    required this.dayTrackerDefinitions,
  });

  final JournalHistoryDaySummary summary;
  final List<TrackerDefinition> dayTrackerDefinitions;

  @override
  State<_HistoryDayCard> createState() => _HistoryDayCardState();
}

class _HistoryDayCardState extends State<_HistoryDayCard> {
  bool _expanded = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final dateLabel = DateFormat.yMMMEd().format(widget.summary.day.toLocal());
    final mood = widget.summary.moodAverage;
    final entries = widget.summary.entries;
    final latestNote = entries.isEmpty
        ? null
        : entries.first.journalText?.trim();

    final rows = _buildFactorRows(
      widget.summary,
      widget.dayTrackerDefinitions,
      l10n,
    );
    final withValue = rows.where((row) => row.hasValue).toList(growable: false);
    final withoutValue = rows
        .where((row) => !row.hasValue)
        .toList(growable: false);

    return InkWell(
      onTap: () => Routing.toJournalDayDetail(context, widget.summary.day),
      onHighlightChanged: (value) {
        if (_pressed == value) return;
        setState(() => _pressed = value);
      },
      borderRadius: BorderRadius.circular(tokens.radiusLg),
      child: AnimatedScale(
        duration: kJournalMotionDuration,
        curve: kJournalMotionCurve,
        scale: _pressed ? 0.988 : 1,
        child: Container(
          padding: EdgeInsets.all(tokens.spaceMd),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(tokens.radiusLg),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dateLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (mood != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.spaceSm,
                        vertical: tokens.spaceXxs,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(tokens.radiusPill),
                      ),
                      child: Text(
                        mood.toStringAsFixed(1),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: tokens.spaceXxs),
              Text(
                context.l10n.journalDaySummaryMetaLabel(
                  entries.length,
                  withValue.length,
                ),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (withValue.isNotEmpty) ...[
                SizedBox(height: tokens.spaceSm),
                _FactorGrid(rows: _expanded ? rows : withValue),
              ],
              if (withoutValue.isNotEmpty) ...[
                SizedBox(height: tokens.spaceXs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(
                      _expanded
                          ? context.l10n.collapseLabel
                          : context.l10n.viewMoreLabel(withoutValue.length),
                    ),
                  ),
                ),
              ],
              if (latestNote != null && latestNote.isNotEmpty) ...[
                SizedBox(height: tokens.spaceXs),
                Text(
                  latestNote,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<_FactorRow> _buildFactorRows(
    JournalHistoryDaySummary summary,
    List<TrackerDefinition> definitions,
    AppLocalizations l10n,
  ) {
    final rows = <_FactorRow>[];
    for (final definition in definitions) {
      final raw =
          summary.dayQuantityTotalsByTrackerId[definition.id] ??
          summary.latestEventByTrackerId[definition.id]?.value;
      final formatted = JournalTrackerValueFormatter.format(
        l10n: l10n,
        label: definition.name,
        definition: definition,
        rawValue: raw,
        choiceLabelsByTrackerId: summary.choiceLabelsByTrackerId,
      );
      rows.add(
        _FactorRow(
          text: formatted.text,
          hasValue: formatted.hasValue,
          icon: trackerIconData(definition),
          state: formatted.state,
        ),
      );
    }
    return rows;
  }
}

class _FactorGrid extends StatelessWidget {
  const _FactorGrid({required this.rows});

  final List<_FactorRow> rows;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - tokens.spaceSm) / 2;
        return Wrap(
          spacing: tokens.spaceSm,
          runSpacing: tokens.spaceXs,
          children: [
            for (final row in rows)
              SizedBox(
                width: itemWidth,
                child: _FactorRowTile(row: row),
              ),
          ],
        );
      },
    );
  }
}

class _FactorRowTile extends StatelessWidget {
  const _FactorRowTile({required this.row});

  final _FactorRow row;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: JournalFactorToken(
        icon: row.icon,
        text: row.text,
        state: row.state,
      ),
    );
  }
}

class _FactorRow {
  const _FactorRow({
    required this.text,
    required this.hasValue,
    required this.icon,
    required this.state,
  });

  final String text;
  final bool hasValue;
  final IconData icon;
  final JournalTrackerValueState state;
}
