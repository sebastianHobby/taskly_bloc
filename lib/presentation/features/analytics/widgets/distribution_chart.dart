import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

enum ChartType { bar, pie, horizontalBar }

class DistributionChart extends StatelessWidget {
  const DistributionChart({
    required this.distribution,
    this.type = ChartType.bar,
    this.title,
    super.key,
  });
  final Map<String, num> distribution;
  final ChartType type;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (distribution.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(TasklyTokens.of(context).spaceLg),
          child: Center(
            child: Text(
              'No data available',
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
              child: switch (type) {
                ChartType.bar => _buildBarChart(context),
                ChartType.pie => _buildPieChart(context),
                ChartType.horizontalBar => _buildHorizontalBarChart(context),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context) {
    final theme = Theme.of(context);
    final entries = distribution.entries.toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY:
            entries
                .map((e) => e.value.toDouble())
                .reduce((a, b) => a > b ? a : b) *
            1.2,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= entries.length) return SizedBox();
                return Text(
                  entries[value.toInt()].key,
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        borderData: FlBorderData(show: false),
        barGroups: entries
            .asMap()
            .entries
            .map(
              (e) => BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.value.toDouble(),
                    color: theme.colorScheme.primary,
                    width: 20,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context) {
    final theme = Theme.of(context);
    final entries = distribution.entries.toList();
    final total = entries.fold<num>(0, (sum, e) => sum + e.value);
    final palette = _buildPalette(theme.colorScheme);

    return PieChart(
      PieChartData(
        sections: entries
            .asMap()
            .entries
            .map(
              (e) => PieChartSectionData(
                value: e.value.value.toDouble(),
                title: '${((e.value.value / total) * 100).toStringAsFixed(0)}%',
                color: palette[e.key % palette.length].color,
                radius: 100,
                titleStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: palette[e.key % palette.length].onColor,
                ),
              ),
            )
            .toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 0,
      ),
    );
  }

  Widget _buildHorizontalBarChart(BuildContext context) {
    return _buildBarChart(context); // Simplified implementation
  }

  List<_SliceColor> _buildPalette(ColorScheme scheme) {
    return [
      _SliceColor(color: scheme.primary, onColor: scheme.onPrimary),
      _SliceColor(color: scheme.secondary, onColor: scheme.onSecondary),
      _SliceColor(color: scheme.tertiary, onColor: scheme.onTertiary),
      _SliceColor(color: scheme.error, onColor: scheme.onError),
      _SliceColor(
        color: scheme.primaryContainer,
        onColor: scheme.onPrimaryContainer,
      ),
      _SliceColor(
        color: scheme.secondaryContainer,
        onColor: scheme.onSecondaryContainer,
      ),
    ];
  }
}

class _SliceColor {
  const _SliceColor({required this.color, required this.onColor});

  final Color color;
  final Color onColor;
}
