import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/analytics/widgets/correlation_card.dart';
import 'package:taskly_bloc/presentation/features/analytics/widgets/distribution_chart.dart';
import 'package:taskly_bloc/presentation/features/analytics/widgets/trend_chart.dart';
import 'package:taskly_bloc/presentation/features/statistics/bloc/statistics_dashboard_bloc.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';
import 'package:taskly_bloc/presentation/shared/errors/friendly_error_message.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/ui/sparkline_painter.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class StatisticsDashboardPage extends StatelessWidget {
  const StatisticsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StatisticsDashboardBloc(
        analyticsService: context.read<AnalyticsService>(),
        valueRepository: context.read<ValueRepositoryContract>(),
        nowService: context.read<NowService>(),
      )..add(const StatisticsDashboardRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: const _StatisticsAppBarTitle(),
          centerTitle: false,
        ),
        body: BlocBuilder<StatisticsDashboardBloc, StatisticsDashboardState>(
          builder: (context, state) {
            final tokens = TasklyTokens.of(context);
            final l10n = context.l10n;
            return ListView(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.sectionPaddingH,
                vertical: tokens.spaceLg,
              ),
              children: [
                _RangeSelector(
                  selectedDays: state.rangeDays,
                  onChanged: (days) => context
                      .read<StatisticsDashboardBloc>()
                      .add(StatisticsDashboardRangeChanged(days)),
                ),
                SizedBox(height: tokens.spaceLg),
                _SectionHeader(
                  title: l10n.statisticsValuesFocusTitle,
                  subtitle: l10n.statisticsValuesFocusSubtitle(
                    _formatDate(context, state.range.start),
                    _formatDate(context, state.range.end),
                  ),
                ),
                _ValuesFocusSection(section: state.valuesFocus),
                SizedBox(height: tokens.spaceLg),
                _SectionHeader(title: l10n.statisticsProgressByValueTitle),
                _ValueTrendsSection(
                  section: state.valueTrends,
                  valuesFocus: state.valuesFocus.data,
                ),
                SizedBox(height: tokens.spaceLg),
                _SectionHeader(title: l10n.statisticsMoodJournalTitle),
                _MoodStatsSection(section: state.moodStats),
                SizedBox(height: tokens.spaceLg),
                _SectionHeader(
                  title: l10n.statisticsCorrelationsTitle,
                  subtitle: l10n.statisticsCorrelationsSubtitle,
                ),
                _CorrelationsSection(section: state.correlations),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.selectedDays,
    required this.onChanged,
  });

  final int selectedDays;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.rangeLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: tokens.spaceSm),
        SegmentedButton<int>(
          segments: [
            ButtonSegment(
              value: 30,
              label: Text(context.l10n.rangeDaysShort(30)),
            ),
            ButtonSegment(
              value: 90,
              label: Text(context.l10n.rangeDaysShort(90)),
            ),
            ButtonSegment(
              value: 180,
              label: Text(context.l10n.rangeDaysShort(180)),
            ),
            ButtonSegment(
              value: 365,
              label: Text(context.l10n.rangeDaysShort(365)),
            ),
          ],
          selected: {selectedDays},
          onSelectionChanged: (selection) {
            if (selection.isEmpty) return;
            onChanged(selection.first);
          },
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = TasklyTokens.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: tokens.spaceXs),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ValuesFocusSection extends StatelessWidget {
  const _ValuesFocusSection({required this.section});

  final StatisticsSection<ValuesFocusData> section;

  @override
  Widget build(BuildContext context) {
    return _SectionStateContainer(
      section: section,
      emptyMessage: context.l10n.statisticsValuesEmptyLabel,
      builder: (data) {
        final tokens = TasklyTokens.of(context);

        final topItems = data.items.take(6).toList(growable: false);
        final needsAttention = data.needsAttention;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.statisticsCompletionShareLabel(
                      data.totalCompletions,
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: tokens.spaceSm),
                  _CompletionShareChart(items: topItems),
                  SizedBox(height: tokens.spaceSm),
                  for (final item in topItems) ...[
                    _ValueShareRow(item: item),
                    SizedBox(height: tokens.spaceSm),
                  ],
                ],
              ),
            ),
            if (needsAttention.isNotEmpty) ...[
              SizedBox(height: tokens.spaceLg),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.statisticsNeedsAttentionLabel(
                        data.gapWarningThresholdPercent,
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: tokens.spaceSm),
                    for (final item in needsAttention.take(5)) ...[
                      _NeedsAttentionRow(item: item),
                      SizedBox(height: tokens.spaceSm),
                    ],
                  ],
                ),
              ),
            ],
            SizedBox(height: tokens.spaceLg),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.statisticsPrimarySecondaryTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: tokens.spaceSm),
                  for (final item in topItems) ...[
                    _PrimarySecondaryRow(item: item),
                    SizedBox(height: tokens.spaceSm),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ValueTrendsSection extends StatelessWidget {
  const _ValueTrendsSection({
    required this.section,
    required this.valuesFocus,
  });

  final StatisticsSection<ValueTrendsData> section;
  final ValuesFocusData? valuesFocus;

  @override
  Widget build(BuildContext context) {
    return _SectionStateContainer(
      section: section,
      emptyMessage: context.l10n.statisticsTrendsEmptyLabel,
      builder: (data) {
        final tokens = TasklyTokens.of(context);
        final sorted = [...data.items];

        if (valuesFocus != null) {
          final order = {
            for (var i = 0; i < valuesFocus!.items.length; i++)
              valuesFocus!.items[i].value.id: i,
          };
          sorted.sort(
            (a, b) =>
                (order[a.value.id] ?? 999).compareTo(order[b.value.id] ?? 999),
          );
        }

        final topItems = sorted.take(5).toList(growable: false);

        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.statisticsWeeklyTrendLabel(data.weeks),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: tokens.spaceSm),
              for (final item in topItems) ...[
                _ValueTrendRow(item: item),
                SizedBox(height: tokens.spaceSm),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MoodStatsSection extends StatelessWidget {
  const _MoodStatsSection({required this.section});

  final StatisticsSection<MoodStatsData> section;

  @override
  Widget build(BuildContext context) {
    return _SectionStateContainer(
      section: section,
      emptyMessage: context.l10n.statisticsMoodEmptyLabel,
      builder: (data) {
        final tokens = TasklyTokens.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TrendChart(
              data: data.trend,
              title: context.l10n.statisticsMoodTrendTitle,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            SizedBox(height: tokens.spaceLg),
            DistributionChart(
              distribution: {
                for (final entry in data.distribution.entries)
                  entry.key.toString(): entry.value,
              },
              title: context.l10n.statisticsMoodDistributionTitle,
            ),
            SizedBox(height: tokens.spaceLg),
            _MoodSummaryRow(summary: data.summary),
          ],
        );
      },
    );
  }
}

class _CorrelationsSection extends StatelessWidget {
  const _CorrelationsSection({required this.section});

  final StatisticsSection<CorrelationData> section;

  @override
  Widget build(BuildContext context) {
    return _SectionStateContainer(
      section: section,
      emptyMessage: context.l10n.statisticsCorrelationsEmptyLabel,
      builder: (data) {
        final tokens = TasklyTokens.of(context);
        if (data.correlations.isEmpty) {
          return _Card(
            child: Text(
              context.l10n.statisticsCorrelationsEmptyBody,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        return Column(
          children: [
            for (final correlation in data.correlations) ...[
              CorrelationCard(
                correlation: correlation,
                insightOverride: _correlationInsight(context.l10n, correlation),
              ),
              SizedBox(height: tokens.spaceSm),
            ],
            SizedBox(height: tokens.spaceSm),
            Text(
              context.l10n.statisticsCorrelationDisclaimer,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionStateContainer<T> extends StatelessWidget {
  const _SectionStateContainer({
    required this.section,
    required this.emptyMessage,
    required this.builder,
  });

  final StatisticsSection<T> section;
  final String emptyMessage;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return switch (section.status) {
      StatisticsSectionStatus.loading => const _Card(
        child: _LoadingRow(),
      ),
      StatisticsSectionStatus.failure => _Card(
        child: Text(
          friendlyErrorMessageForUi(
            section.error ?? context.l10n.statisticsLoadSectionFailed,
            context.l10n,
          ),
        ),
      ),
      StatisticsSectionStatus.ready when section.data != null => builder(
        section.data as T,
      ),
      _ => _Card(child: Text(emptyMessage)),
    };
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(TasklyTokens.of(context).spaceLg),
        child: child,
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: TasklyTokens.of(context).spaceSm),
        Text(
          context.l10n.loadingTitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _ValueShareRow extends StatelessWidget {
  const _ValueShareRow({required this.item});

  final ValueAlignmentItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final color = ColorUtils.valueColorForTheme(context, item.value.color);

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: tokens.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: tokens.spaceXs),
              LinearProgressIndicator(
                value: (item.completionPercent / 100).clamp(0, 1),
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            ],
          ),
        ),
        SizedBox(width: tokens.spaceSm),
        Text(
          '${item.completionPercent.toStringAsFixed(0)}%',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CompletionShareChart extends StatelessWidget {
  const _CompletionShareChart({required this.items});

  final List<ValueAlignmentItem> items;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);

    final sections = <PieChartSectionData>[
      for (final item in items)
        if (item.completionPercent > 0)
          PieChartSectionData(
            color: ColorUtils.valueColorForTheme(context, item.value.color),
            value: item.completionPercent,
            radius: tokens.spaceLg2,
            title: '',
          ),
    ];

    if (sections.isEmpty) {
      return Container(
        height: tokens.spaceXl,
        alignment: Alignment.centerLeft,
        child: Text(
          context.l10n.statisticsNoCompletionsLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return SizedBox(
      height: tokens.spaceXl + tokens.spaceSm,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: tokens.spaceSm2,
          sectionsSpace: 1.5,
          startDegreeOffset: -90,
        ),
      ),
    );
  }
}

class _NeedsAttentionRow extends StatelessWidget {
  const _NeedsAttentionRow({required this.item});

  final ValueAlignmentItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final gap = item.targetPercent - item.completionPercent;

    return Row(
      children: [
        Icon(Icons.warning_amber, size: 18, color: theme.colorScheme.error),
        SizedBox(width: tokens.spaceSm),
        Expanded(
          child: Text(
            item.value.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '-${gap.toStringAsFixed(0)}%',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ],
    );
  }
}

class _PrimarySecondaryRow extends StatelessWidget {
  const _PrimarySecondaryRow({required this.item});

  final ValueAlignmentItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final stats = item.primarySecondaryStats;
    if (stats == null) {
      return Text(
        context.l10n.statisticsNoCoverageLabel(item.value.name),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            item.value.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          context.l10n.statisticsPrimarySecondaryTaskLabel(
            stats.primaryTaskCount,
            stats.secondaryTaskCount,
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(width: tokens.spaceSm),
        Text(
          context.l10n.statisticsPrimarySecondaryProjectLabel(
            stats.primaryProjectCount,
            stats.secondaryProjectCount,
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ValueTrendRow extends StatelessWidget {
  const _ValueTrendRow({required this.item});

  final ValueTrendItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final color = ColorUtils.valueColorForTheme(context, item.value.color);
    final data = item.weeklyPercentages;
    final hasData = data.isNotEmpty && data.any((v) => v > 0);

    return Row(
      children: [
        Expanded(
          child: Text(
            item.value.name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          width: 120,
          height: 24,
          child: hasData
              ? CustomPaint(
                  painter: SparklinePainter(data: data, color: color),
                )
              : Text(
                  context.l10n.analyticsNoDataLabel,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
        SizedBox(width: tokens.spaceSm),
        Text(
          context.l10n.analyticsPercentValue(
            data.isEmpty ? 0 : data.last.round(),
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MoodSummaryRow extends StatelessWidget {
  const _MoodSummaryRow({required this.summary});

  final MoodSummary summary;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.statisticsAverageLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: tokens.spaceXs),
                Text(
                  summary.average.toStringAsFixed(1),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.statisticsEntriesLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: tokens.spaceXs),
                Text(
                  summary.totalEntries.toString(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.statisticsRangeLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: tokens.spaceXs),
                Text(
                  '${summary.min}-${summary.max}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _formatDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(locale).format(date);
}

String _correlationInsight(
  AppLocalizations l10n,
  CorrelationResult correlation,
) {
  final sampleSize = correlation.sampleSize ?? 0;
  final significant =
      correlation.statisticalSignificance?.isSignificant ?? false;
  final difference = correlation.differencePercent;

  if (!significant || sampleSize < 10) {
    return l10n.statisticsCorrelationEarlyPatternLabel(sampleSize);
  }

  if (difference != null) {
    final direction = difference >= 0
        ? l10n.statisticsCorrelationDirectionHigher
        : l10n.statisticsCorrelationDirectionLower;
    final absPercent = difference.abs().toStringAsFixed(0);
    return l10n.statisticsCorrelationDifferenceLabel(
      correlation.sourceLabel,
      correlation.targetLabel,
      absPercent,
      direction,
      sampleSize,
    );
  }

  return l10n.statisticsCorrelationBasicLabel(
    correlation.sourceLabel,
    correlation.targetLabel,
    sampleSize,
  );
}

class _StatisticsAppBarTitle extends StatelessWidget {
  const _StatisticsAppBarTitle();

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconSet = const NavigationIconResolver().resolve(
      screenId: 'statistics',
      iconName: null,
    );

    return Row(
      children: [
        Icon(
          iconSet.selectedIcon,
          color: scheme.primary,
          size: tokens.spaceLg3,
        ),
        SizedBox(width: tokens.spaceSm),
        Text(
          context.l10n.statisticsTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
