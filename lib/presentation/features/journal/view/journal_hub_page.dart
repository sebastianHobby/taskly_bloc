import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_history_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_entry_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/journal/ui/tracker_value_formatter.dart';
import 'package:taskly_bloc/presentation/features/journal/utils/tracker_icon_utils.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/journal_today_shared_widgets.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/theme/taskly_semantic_theme.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
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
    final theme = Theme.of(context);
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
            dayAggregateValuesByTrackerId: const <String, double>{},
            factorTrackerIds: const <String>{},
            choiceLabelsByTrackerId: const <String, Map<String, String>>{},
          )
        : summaries[todayIndex];
    return ListView(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceSm,
        tokens.spaceLg,
        tokens.spaceLg,
      ),
      children: [
        _SectionHeader(
          title: context.l10n.journalDailySummaryTitle.toUpperCase(),
          trailing: TextButton(
            onPressed: () => Routing.toJournalHistory(context),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceSm,
                vertical: tokens.spaceXxs,
              ),
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text('${context.l10n.viewLabel} ${context.l10n.allLabel}'),
          ),
        ),
        SizedBox(height: tokens.spaceSm),
        _DailySummaryGrid(
          summary: todaySummary,
          hiddenTrackerIds: state.hiddenSummaryTrackerIds,
        ),
        SizedBox(height: tokens.spaceLg),
        _SectionHeader(title: context.l10n.journalMomentsTitle.toUpperCase()),
        SizedBox(height: tokens.spaceSm),
        if (todaySummary.entries.isEmpty)
          Container(
            padding: EdgeInsets.all(tokens.spaceMd),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow.withValues(
                alpha: 0.72,
              ),
              borderRadius: BorderRadius.circular(tokens.radiusLg),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.34),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.journalNoLogsToday,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
                SizedBox(height: tokens.spaceXxs),
                Text(
                  context.l10n.journalTodayEmptyBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: tokens.spaceSm),
                Wrap(
                  spacing: tokens.spaceSm,
                  runSpacing: tokens.spaceSm,
                  children: [
                    FilledButton(
                      onPressed: () =>
                          JournalEntryEditorRoutePage.showQuickCapture(
                            context,
                            selectedDayLocal: todayLocal,
                          ),
                      child: Text(context.l10n.journalAddEntry),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          for (var i = 0; i < todaySummary.entries.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: tokens.spaceSm),
              child: JournalLogCard(
                entry: todaySummary.entries[i],
                events:
                    todaySummary.eventsByEntryId[todaySummary.entries[i].id] ??
                    const <TrackerEvent>[],
                definitionById: todaySummary.definitionById,
                moodTrackerId: todaySummary.moodTrackerId,
                density: state.density,
                choiceLabelsByTrackerId: todaySummary.choiceLabelsByTrackerId,
                onTap: () => Routing.toJournalEntryEdit(
                  context,
                  todaySummary.entries[i].id,
                ),
                showTimelineLine: i != todaySummary.entries.length - 1,
              ),
            ),
        if (state.topInsight != null) ...[
          SizedBox(height: tokens.spaceMd),
          _TopInsightCard(
            insight: state.topInsight!,
            onTap: () => Routing.toJournalInsights(context),
          ),
        ] else if (state.showInsightsNudge) ...[
          SizedBox(height: tokens.spaceMd),
          _InsightsNudgeCard(
            onTap: () => Routing.toJournalInsights(context),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
        ),
        ...?((trailing == null) ? null : [trailing!]),
      ],
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
            final theme = Theme.of(context);
            final scheme = theme.colorScheme;
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
                scrolledUnderElevation: 0,
                title: Text(
                  '${context.l10n.dateToday}, ${DateFormat.MMMd().format(todayLocal)}',
                  style:
                      Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                ),
                actions: [
                  IconButton(
                    tooltip: context.l10n.journalManageTrackersTitle,
                    onPressed: () => Routing.pushScreenKey(
                      context,
                      'journal_manage_factors',
                    ),
                    icon: const Icon(Icons.monitor_heart_outlined),
                  ),
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
                      scheme.surface,
                      scheme.surfaceContainerLowest,
                      scheme.surfaceContainerLow,
                    ],
                    stops: const [0, 0.34, 1],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -120,
                      right: -56,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              radius: 0.9,
                              colors: [
                                scheme.primary.withValues(alpha: 0.09),
                                scheme.primary.withValues(alpha: 0),
                              ],
                            ),
                          ),
                          child: const SizedBox(width: 280, height: 280),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 168,
                      left: -72,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              radius: 1,
                              colors: [
                                scheme.tertiary.withValues(alpha: 0.05),
                                scheme.tertiary.withValues(alpha: 0),
                              ],
                            ),
                          ),
                          child: const SizedBox(width: 220, height: 220),
                        ),
                      ),
                    ),
                    body,
                  ],
                ),
              ),
              floatingActionButton: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  tooltip: context.l10n.journalAddEntry,
                  heroTag: 'journal_add_entry_fab',
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                  onPressed: () => JournalEntryEditorRoutePage.showQuickCapture(
                    context,
                    selectedDayLocal: nowLocal,
                  ),
                  child: const Icon(Icons.add, size: 28),
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
  const _TopInsightCard({
    required this.insight,
    required this.onTap,
  });

  final JournalTopInsight insight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final panelTheme = TasklyPanelTheme.of(context);
    final deltaValue = insight.deltaMood.abs().toStringAsFixed(1);
    final delta = insight.deltaMood >= 0 ? '+$deltaValue' : '-$deltaValue';
    final confidenceLabel = insight.confidence == JournalInsightConfidence.high
        ? context.l10n.journalInsightHighConfidence
        : context.l10n.journalInsightMediumConfidence;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              panelTheme.emphasizedSurface,
              panelTheme.subtleSurface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          border: Border.all(color: panelTheme.mutedBorder),
          boxShadow: [
            BoxShadow(
              color: panelTheme.softShadow,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
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
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightsNudgeCard extends StatelessWidget {
  const _InsightsNudgeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surfaceContainer,
              theme.colorScheme.surfaceContainerLow,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.42),
          ),
        ),
        padding: EdgeInsets.all(tokens.spaceMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.insights_outlined,
                color: theme.colorScheme.onSecondaryContainer,
                size: 18,
              ),
            ),
            SizedBox(width: tokens.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.journalInsightsTitle.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 0.8,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: tokens.spaceXxs),
                  Text(
                    context.l10n.journalInsightsNudge,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
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
    required this.metaText,
  });

  final String trackerId;
  final String label;
  final IconData icon;
  final JournalTrackerFormattedValue formatted;
  final String metaText;
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

    final preferred = items
        .where((item) => item.formatted.hasValue)
        .toList(growable: false);
    final displayItems = preferred.isEmpty ? items : preferred;
    final visible = displayItems.take(_maxVisible).toList(growable: false);
    final remaining = displayItems.length - visible.length;

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
  static const double _tileHeight = 106;

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

    final topRight = item.metaText.isEmpty ? item.label : item.metaText;

    return SizedBox(
      height: _tileHeight,
      child: Container(
        padding: EdgeInsets.all(tokens.spaceSm),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.background,
              Color.alphaBlend(
                colors.foreground.withValues(alpha: 0.02),
                colors.background,
              ),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colors.foreground.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(tokens.radiusMd),
                  ),
                  child: Icon(item.icon, size: 14, color: colors.foreground),
                ),
                const Spacer(),
                Expanded(
                  child: Text(
                    topRight,
                    maxLines: 1,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.foreground.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (item.metaText.isNotEmpty)
              Text(
                item.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.foreground.withValues(alpha: 0.66),
                  fontWeight: FontWeight.w600,
                ),
              ),
            SizedBox(height: tokens.spaceSm),
            Text(
              item.formatted.valueText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
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
      border: scheme.outlineVariant.withValues(alpha: 0.32),
      foreground: scheme.onSurfaceVariant,
    );
  }
  return switch (state) {
    JournalTrackerValueState.warn => (
      background: scheme.errorContainer.withValues(alpha: 0.25),
      border: scheme.error.withValues(alpha: 0.42),
      foreground: scheme.onSurface,
    ),
    JournalTrackerValueState.goalHit => (
      background: scheme.tertiaryContainer.withValues(alpha: 0.4),
      border: scheme.tertiary.withValues(alpha: 0.42),
      foreground: scheme.onSurface,
    ),
    JournalTrackerValueState.normal => (
      background: scheme.surfaceContainerLow,
      border: scheme.outlineVariant.withValues(alpha: 0.32),
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
      final avg = averageForTracker(definition.id);
      return avg ?? summary.dayAggregateValuesByTrackerId[definition.id];
    }
    if (valueType == 'quantity' || valueKind == 'number') {
      final aggregated = summary.dayAggregateValuesByTrackerId[definition.id];
      if (aggregated != null) return aggregated;
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
    final valueType = definition.valueType.trim().toLowerCase();
    String metaText = '';
    if (valueType == 'rating') {
      metaText = 'Avg';
    } else {
      final target = definition.goal['target'] ?? definition.goal['daily'];
      if (target != null) {
        final unit = (definition.unitKind ?? '').trim();
        metaText = unit.isEmpty ? 'Target: $target' : 'Target: $target $unit';
      }
    }
    items.add(
      _DailySummaryItem(
        trackerId: definition.id,
        label: definition.name,
        icon: trackerIconData(definition),
        formatted: formatted,
        metaText: metaText,
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
