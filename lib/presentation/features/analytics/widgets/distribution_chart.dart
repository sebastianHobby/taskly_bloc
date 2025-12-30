import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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
          padding: const EdgeInsets.all(16),
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
        padding: const EdgeInsets.all(16),
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
              const SizedBox(height: 16),
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
                if (value.toInt() >= entries.length) return const SizedBox();
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
                    borderRadius: const BorderRadius.vertical(
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

    return PieChart(
      PieChartData(
        sections: entries
            .asMap()
            .entries
            .map(
              (e) => PieChartSectionData(
                value: e.value.value.toDouble(),
                title: '${((e.value.value / total) * 100).toStringAsFixed(0)}%',
                color: _getColor(e.key, theme),
                radius: 100,
                titleStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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

  Color _getColor(int index, ThemeData theme) {
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];
    return colors[index % colors.length];
  }
}
