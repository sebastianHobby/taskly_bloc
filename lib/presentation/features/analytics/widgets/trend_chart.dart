import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({
    required this.data,
    this.title,
    this.color,
    this.showAverage = true,
    super.key,
  });
  final TrendData data;
  final String? title;
  final Color? color;
  final bool showAverage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chartColor = color ?? theme.colorScheme.primary;

    if (data.points.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(TasklyTokens.of(context).spaceLg),
          child: Center(
            child: Text(
              context.l10n.analyticsNoDataLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(TasklyTokens.of(context).spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: TasklyTokens.of(context).spaceSm),
            ],
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: theme.textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= data.points.length) {
                            return SizedBox();
                          }
                          final point = data.points[value.toInt()];
                          final label = _formatDate(
                            context,
                            point.date,
                            data.granularity,
                          );
                          return Text(
                            label,
                            style: theme.textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(),
                    rightTitles: const AxisTitles(),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.points
                          .asMap()
                          .entries
                          .map(
                            (e) => FlSpot(
                              e.key.toDouble(),
                              e.value.value,
                            ),
                          )
                          .toList(),
                      isCurved: true,
                      color: chartColor,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: chartColor.withValues(alpha: 0.1),
                      ),
                    ),
                    if (showAverage && data.average != null)
                      LineChartBarData(
                        spots: [
                          FlSpot(0, data.average!),
                          FlSpot(data.points.length - 1, data.average!),
                        ],
                        color: theme.colorScheme.onSurfaceVariant,
                        barWidth: 1,
                        dotData: const FlDotData(show: false),
                        dashArray: [5, 5],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(
    BuildContext context,
    DateTime date,
    TrendGranularity granularity,
  ) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final l10n = context.l10n;
    return switch (granularity) {
      TrendGranularity.daily => DateFormat.Md(locale).format(date),
      TrendGranularity.weekly => l10n.analyticsWeekLabel(_getWeekNumber(date)),
      TrendGranularity.monthly => DateFormat.yMMM(locale).format(date),
    };
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil() + 1;
  }
}
