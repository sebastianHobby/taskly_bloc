import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_history_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/ui/tracker_value_formatter.dart';
import 'package:taskly_bloc/presentation/features/journal/utils/tracker_icon_utils.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/journal_today_shared_widgets.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class JournalHubPage extends StatefulWidget {
  const JournalHubPage({super.key});

  @override
  State<JournalHubPage> createState() => _JournalHubPageState();
}

class _TodayJournalBody extends StatelessWidget {
  const _TodayJournalBody({
    required this.state,
    required this.todayLocal,
  });

  final JournalHistoryLoaded state;
  final DateTime todayLocal;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final todayUtc = dateOnly(todayLocal);
    final summaries = state.days;
    final todayIndex = summaries.indexWhere(
      (summary) => dateOnly(summary.day) == todayUtc,
    );
    final todaySummary = todayIndex == -1
        ? JournalHistoryDaySummary(
            day: todayUtc,
            entries: const <JournalEntry>[],
            eventsByEntryId: const <String, List<TrackerEvent>>{},
            latestEventByTrackerId: const <String, TrackerEvent>{},
            definitionById: const <String, TrackerDefinition>{},
            moodTrackerId: null,
            moodAverage: null,
            dayQuantityTotalsByTrackerId: const <String, double>{},
            factorTrackerIds: const <String>{},
            choiceLabelsByTrackerId: const <String, Map<String, String>>{},
          )
        : summaries[todayIndex];
    return ListView(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceXs,
        tokens.spaceLg,
        tokens.spaceLg,
      ),
      children: [
        if (state.topInsight != null)
          _TopInsightCard(insight: state.topInsight!)
        else if (state.showInsightsNudge)
          _TopInsightNudgeCard(),
        SizedBox(height: tokens.spaceSm),
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.journalDailySummaryTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _showDailySummaryPreferencesSheet(
                context,
                state,
                todaySummary,
              ),
              child: Text(context.l10n.journalCustomizeDailySummaryTitle),
            ),
          ],
        ),
        SizedBox(height: tokens.spaceSm),
        _DailySummaryGrid(
          summary: todaySummary,
          hiddenTrackerIds: state.hiddenSummaryTrackerIds,
        ),
        SizedBox(height: tokens.spaceMd),
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.journalMomentsTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Routing.toJournalHistory(context),
              child: Text(context.l10n.journalBrowseHistoryLabel),
            ),
          ],
        ),
        SizedBox(height: tokens.spaceSm),
        if (todaySummary.entries.isEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.journalNoLogsToday,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: tokens.spaceXxs),
              Text(
                context.l10n.journalTodayEmptyBody,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: tokens.spaceSm),
              Wrap(
                spacing: tokens.spaceSm,
                runSpacing: tokens.spaceSm,
                children: [
                  FilledButton(
                    onPressed: () => Routing.toJournalEntryNew(
                      context,
                      selectedDayLocal: todayLocal,
                    ),
                    child: Text(context.l10n.journalAddEntry),
                  ),
                ],
              ),
            ],
          )
        else
          for (final entry in todaySummary.entries)
            Padding(
              padding: EdgeInsets.only(bottom: tokens.spaceSm),
              child: JournalLogCard(
                entry: entry,
                events:
                    todaySummary.eventsByEntryId[entry.id] ??
                    const <TrackerEvent>[],
                definitionById: todaySummary.definitionById,
                moodTrackerId: todaySummary.moodTrackerId,
                density: state.density,
                choiceLabelsByTrackerId: todaySummary.choiceLabelsByTrackerId,
                onTap: () => Routing.toJournalEntryEdit(context, entry.id),
              ),
            ),
      ],
    );
  }

  Future<void> _showDailySummaryPreferencesSheet(
    BuildContext context,
    JournalHistoryLoaded state,
    JournalHistoryDaySummary summary,
  ) async {
    final tokens = TasklyTokens.of(context);
    final hidden = <String>{...state.hiddenSummaryTrackerIds};
    final items = _buildDailySummaryItems(
      context: context,
      summary: summary,
    );
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.all(tokens.spaceMd),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sheetContext.l10n.journalDailySummaryTitle,
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  SizedBox(height: tokens.spaceXxs),
                  Text(
                    sheetContext.l10n.journalDailySummarySubtitle,
                    style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        sheetContext,
                      ).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: tokens.spaceSm),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final item in items)
                          SwitchListTile(
                            value: !hidden.contains(item.trackerId),
                            onChanged: (enabled) {
                              setSheetState(() {
                                if (enabled) {
                                  hidden.remove(item.trackerId);
                                } else {
                                  hidden.add(item.trackerId);
                                }
                              });
                            },
                            title: Text(item.label),
                            secondary: Icon(item.icon),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: tokens.spaceSm),
                  Row(
                    children: [
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          context.read<JournalHistoryBloc>().add(
                            JournalHistorySummaryPreferencesChanged(
                              hiddenTrackerIds: hidden,
                            ),
                          );
                          Navigator.of(sheetContext).pop();
                        },
                        child: Text(sheetContext.l10n.saveLabel),
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
}

class _JournalHubPageState extends State<JournalHubPage> {
  bool _starterPromptShownThisSession = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _showStarterPackSheet(
    BuildContext context,
    JournalHistoryLoaded state,
  ) async {
    final selected = <String>{
      for (final option in state.starterOptions)
        if (option.defaultSelected) option.id,
    };
    final grouped = <String, List<JournalStarterOption>>{
      context.l10n.journalScopeMomentary: [
        ...state.starterOptions.where(
          (option) => option.scope.trim().toLowerCase() == 'entry',
        ),
      ],
      context.l10n.journalScopeDailyTotal: [
        ...state.starterOptions.where(
          (option) => option.scope.trim().toLowerCase() != 'entry',
        ),
      ],
    };

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
                    sheetContext.l10n.journalStarterPackTitle,
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  SizedBox(height: TasklyTokens.of(sheetContext).spaceXxs),
                  Text(
                    sheetContext.l10n.journalStarterPackSubtitle,
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
                          Text(
                            entry.key == sheetContext.l10n.journalScopeMomentary
                                ? sheetContext
                                      .l10n
                                      .journalScopeMomentarySubtitle
                                : sheetContext
                                      .l10n
                                      .journalScopeDailyTotalSubtitle,
                            style: Theme.of(sheetContext).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    sheetContext,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          for (final option in entry.value)
                            CheckboxListTile(
                              value: selected.contains(option.id),
                              dense: true,
                              title: Text(option.name),
                              subtitle: Text(
                                sheetContext.l10n.journalStarterPackOptionMeta(
                                  option.valueType,
                                  option.scope,
                                ),
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
                        child: Text(sheetContext.l10n.journalAddSelectedLabel),
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

  Future<void> _showHomeActions(
    BuildContext context,
    JournalHistoryLoaded? loaded,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(TasklyTokens.of(sheetContext).spaceMd),
            child: ListView(
              shrinkWrap: true,
              children: [
                if (loaded != null)
                  ListTile(
                    leading: const Icon(Icons.insights_outlined),
                    title: Text(context.l10n.journalInsightsTitle),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Routing.toJournalInsights(context);
                    },
                  ),
                if (loaded != null)
                  ListTile(
                    leading: Icon(
                      loaded.density == DisplayDensity.compact
                          ? Icons.view_agenda_outlined
                          : Icons.view_stream_outlined,
                    ),
                    title: Text(
                      loaded.density == DisplayDensity.compact
                          ? context.l10n.displayDensityStandard
                          : context.l10n.displayDensityCompact,
                    ),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.read<JournalHistoryBloc>().add(
                        const JournalHistoryDensityToggled(),
                      );
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.monitor_heart_outlined),
                  title: Text(context.l10n.journalManageTrackersTitle),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Routing.pushScreenKey(context, 'journal_manage_factors');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final nowLocal = context.read<NowService>().nowLocal();
    final todayLocal = DateTime(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day,
    );

    return BlocProvider<JournalHistoryBloc>(
      create: (context) => JournalHistoryBloc(
        repository: context.read<JournalRepositoryContract>(),
        dayKeyService: context.read<HomeDayKeyService>(),
        settingsRepository: context.read<SettingsRepositoryContract>(),
        nowUtc: context.read<NowService>().nowUtc,
        initialFiltersOverride: JournalHistoryFilters.initial().copyWith(
          rangeStart: todayLocal,
          rangeEnd: todayLocal,
          lookbackDays: 1,
        ),
        persistFilters: false,
      )..add(const JournalHistoryStarted()),
      child: BlocListener<JournalHistoryBloc, JournalHistoryState>(
        listener: (context, state) {
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
            final body = switch (state) {
              JournalHistoryLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              JournalHistoryError(:final message) => Center(
                child: Text(message),
              ),
              JournalHistoryLoaded() => _TodayJournalBody(
                state: state,
                todayLocal: todayLocal,
              ),
            };

            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                toolbarHeight: 60,
                leading: IconButton(
                  tooltip: context.l10n.moreLabel,
                  onPressed: () => _showHomeActions(
                    context,
                    state is JournalHistoryLoaded ? state : null,
                  ),
                  icon: const Icon(Icons.menu),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.dateToday,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      DateFormat.MMMEd().format(todayLocal),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: context.l10n.journalHistoryTitle,
                    onPressed: () => Routing.toJournalHistory(context),
                    icon: const Icon(Icons.history),
                  ),
                ],
              ),
              body: DecoratedBox(
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
              floatingActionButton: EntityAddFab(
                tooltip: context.l10n.journalAddEntry,
                heroTag: 'journal_add_entry_fab',
                onPressed: () => Routing.toJournalEntryNew(
                  context,
                  selectedDayLocal: nowLocal,
                ),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endFloat,
            );
          },
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
    final theme = Theme.of(context);
    final deltaValue = insight.deltaMood.abs().toStringAsFixed(1);
    final delta = insight.deltaMood >= 0 ? '+$deltaValue' : '-$deltaValue';
    final confidenceLabel = insight.confidence == JournalInsightConfidence.high
        ? context.l10n.journalInsightHighConfidence
        : context.l10n.journalInsightMediumConfidence;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: EdgeInsets.all(tokens.spaceMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb,
              color: theme.colorScheme.onPrimaryContainer,
              size: 18,
            ),
          ),
          SizedBox(width: tokens.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.insightTypeCorrelationDiscovery.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.8,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: tokens.spaceXxs),
                Text(
                  context.l10n.journalTopInsightAssociated(
                    insight.factorName,
                    delta,
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
                SizedBox(height: tokens.spaceXxs),
                Text(
                  context.l10n.journalTopInsightMeta(
                    confidenceLabel,
                    insight.sampleSize,
                    insight.windowDays,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
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

class _TopInsightNudgeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: EdgeInsets.all(tokens.spaceMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: tokens.spaceXs),
          Expanded(
            child: Text(
              context.l10n.journalInsightsNudge,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

final class _DailySummaryItem {
  const _DailySummaryItem({
    required this.trackerId,
    required this.label,
    required this.icon,
    required this.formatted,
  });

  final String trackerId;
  final String label;
  final IconData icon;
  final JournalTrackerFormattedValue formatted;
}

class _DailySummaryGrid extends StatelessWidget {
  const _DailySummaryGrid({
    required this.summary,
    required this.hiddenTrackerIds,
  });

  final JournalHistoryDaySummary summary;
  final Set<String> hiddenTrackerIds;

  static const int _maxVisible = 4;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final allItems = _buildDailySummaryItems(
      context: context,
      summary: summary,
    );
    final items = allItems
        .where((item) => !hiddenTrackerIds.contains(item.trackerId))
        .toList(growable: false);
    if (items.isEmpty) {
      return Text(
        context.l10n.journalDailySummaryEmpty,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    final visible = items.take(_maxVisible).toList(growable: false);
    final remaining = items.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - tokens.spaceSm) / 2;
            return Wrap(
              spacing: tokens.spaceSm,
              runSpacing: tokens.spaceSm,
              children: [
                for (final item in visible)
                  SizedBox(
                    width: itemWidth,
                    child: _DailySummaryTile(item: item),
                  ),
              ],
            );
          },
        ),
        if (remaining > 0) ...[
          SizedBox(height: tokens.spaceXs),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _showDailySummaryListSheet(
                context,
                items,
              ),
              icon: const Icon(Icons.expand_more),
              label: Text(context.l10n.viewMoreLabel(remaining)),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showDailySummaryListSheet(
    BuildContext context,
    List<_DailySummaryItem> items,
  ) async {
    final tokens = TasklyTokens.of(context);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.all(tokens.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sheetContext.l10n.journalDailySummaryTitle,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              SizedBox(height: tokens.spaceXs),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Divider(
                    height: tokens.spaceSm,
                    color: Theme.of(sheetContext).colorScheme.outlineVariant,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      leading: Icon(item.icon),
                      title: Text(item.label),
                      subtitle: Text(item.formatted.valueText),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DailySummaryTile extends StatelessWidget {
  const _DailySummaryTile({required this.item});

  final _DailySummaryItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = _summaryColors(
      scheme,
      item.formatted.state,
      item.formatted.hasValue,
    );

    return Container(
      padding: EdgeInsets.all(tokens.spaceSm),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, size: 16, color: colors.foreground),
              SizedBox(width: tokens.spaceXs),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spaceSm),
          Text(
            item.formatted.valueText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

({Color background, Color border, Color foreground}) _summaryColors(
  ColorScheme scheme,
  JournalTrackerValueState state,
  bool hasValue,
) {
  if (!hasValue) {
    return (
      background: scheme.surfaceContainerLow,
      border: scheme.outlineVariant.withValues(alpha: 0.6),
      foreground: scheme.onSurfaceVariant,
    );
  }
  return switch (state) {
    JournalTrackerValueState.warn => (
      background: scheme.errorContainer.withValues(alpha: 0.25),
      border: scheme.error.withValues(alpha: 0.7),
      foreground: scheme.onSurface,
    ),
    JournalTrackerValueState.goalHit => (
      background: scheme.tertiaryContainer.withValues(alpha: 0.4),
      border: scheme.tertiary.withValues(alpha: 0.7),
      foreground: scheme.onSurface,
    ),
    JournalTrackerValueState.normal => (
      background: scheme.surfaceContainerLow,
      border: scheme.outlineVariant,
      foreground: scheme.onSurface,
    ),
  };
}

List<_DailySummaryItem> _buildDailySummaryItems({
  required BuildContext context,
  required JournalHistoryDaySummary summary,
}) {
  final l10n = context.l10n;
  final definitions = summary.definitionById.values
      .where((d) => d.deletedAt == null && d.isActive)
      .toList(growable: false);
  if (definitions.isEmpty) return const <_DailySummaryItem>[];

  final eventsByTrackerId = <String, List<TrackerEvent>>{};
  for (final entryEvents in summary.eventsByEntryId.values) {
    for (final event in entryEvents) {
      (eventsByTrackerId[event.trackerId] ??= <TrackerEvent>[]).add(event);
    }
  }
  for (final event in summary.latestEventByTrackerId.values) {
    if (event.entryId == null) {
      (eventsByTrackerId[event.trackerId] ??= <TrackerEvent>[]).add(event);
    }
  }

  bool isAggregateDefinition(TrackerDefinition d) {
    final valueType = d.valueType.trim().toLowerCase();
    final valueKind = (d.valueKind ?? '').trim().toLowerCase();
    return valueType == 'rating' ||
        valueType == 'quantity' ||
        valueKind == 'number';
  }

  double? averageForTracker(String trackerId) {
    final events = eventsByTrackerId[trackerId];
    if (events == null || events.isEmpty) return null;
    final values = <double>[];
    for (final event in events) {
      final value = event.value;
      if (value is int) {
        values.add(value.toDouble());
      } else if (value is double) {
        values.add(value);
      }
    }
    if (values.isEmpty) return null;
    final sum = values.fold<double>(0, (a, b) => a + b);
    return sum / values.length;
  }

  Object? resolveAggregateValue(TrackerDefinition definition) {
    final valueType = definition.valueType.trim().toLowerCase();
    final valueKind = (definition.valueKind ?? '').trim().toLowerCase();
    if (valueType == 'rating') {
      return averageForTracker(definition.id);
    }
    if (valueType == 'quantity' || valueKind == 'number') {
      final opKind = definition.opKind.trim().toLowerCase();
      if (opKind == 'add') {
        return summary.dayQuantityTotalsByTrackerId[definition.id];
      }
      return summary.latestEventByTrackerId[definition.id]?.value;
    }
    return summary.latestEventByTrackerId[definition.id]?.value;
  }

  TrackerDefinition? findByKeywords({
    required List<String> keywords,
    String? valueType,
    String? unitKind,
  }) {
    final candidates = definitions
        .where((definition) {
          if (valueType != null &&
              definition.valueType.trim().toLowerCase() != valueType) {
            return false;
          }
          if (unitKind != null &&
              definition.unitKind?.trim().toLowerCase() != unitKind) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
    for (final definition in candidates) {
      final name = definition.name.trim().toLowerCase();
      if (keywords.every(name.contains)) return definition;
    }
    for (final definition in candidates) {
      final name = definition.name.trim().toLowerCase();
      if (keywords.any(name.contains)) return definition;
    }
    return null;
  }

  final orderedIds = <String>[];
  void addIfPresent(TrackerDefinition? definition) {
    if (definition == null) return;
    if (!orderedIds.contains(definition.id)) {
      orderedIds.add(definition.id);
    }
  }

  final moodId = summary.moodTrackerId;
  if (moodId != null) {
    addIfPresent(summary.definitionById[moodId]);
  }
  addIfPresent(
    findByKeywords(keywords: const ['energy'], valueType: 'rating'),
  );
  addIfPresent(
    findByKeywords(
      keywords: const ['sleep', 'duration'],
      valueType: 'quantity',
      unitKind: 'hours',
    ),
  );
  addIfPresent(
    findByKeywords(
      keywords: const ['sleep', 'quality'],
      valueType: 'rating',
    ),
  );

  final items = <_DailySummaryItem>[];
  void addItem(TrackerDefinition definition, {Object? rawOverride}) {
    if (!isAggregateDefinition(definition) &&
        definition.id != summary.moodTrackerId) {
      return;
    }
    final rawValue = rawOverride ?? resolveAggregateValue(definition);
    final formatted = JournalTrackerValueFormatter.format(
      l10n: l10n,
      label: definition.name,
      definition: definition,
      rawValue: rawValue,
      choiceLabelsByTrackerId: summary.choiceLabelsByTrackerId,
    );
    items.add(
      _DailySummaryItem(
        trackerId: definition.id,
        label: definition.name,
        icon: trackerIconData(definition),
        formatted: formatted,
      ),
    );
  }

  for (final id in orderedIds) {
    final definition = summary.definitionById[id];
    if (definition == null) continue;
    final rawOverride = id == summary.moodTrackerId
        ? summary.moodAverage
        : null;
    addItem(definition, rawOverride: rawOverride);
  }

  final remaining =
      definitions
          .where(isAggregateDefinition)
          .where((definition) => !orderedIds.contains(definition.id))
          .where((definition) => definition.id != summary.moodTrackerId)
          .toList(growable: false)
        ..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
  remaining.forEach(addItem);

  return items;
}
