import 'package:flutter/material.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    required this.stat,
    this.onTap,
    super.key,
  });
  final StatResult stat;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final presentation = StatPresentation.fromStat(stat);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TasklyTokens.of(context).radiusMd),
        child: Padding(
          padding: EdgeInsets.all(TasklyTokens.of(context).spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      presentation.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (stat.trend != null) _buildTrendIndicator(context),
                ],
              ),
              SizedBox(height: TasklyTokens.of(context).spaceSm),
              Text(
                presentation.valueText,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: _getSeverityColor(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (presentation.description != null) ...[
                SizedBox(height: TasklyTokens.of(context).spaceSm),
                Text(
                  presentation.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
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

  Widget _buildTrendIndicator(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = switch (stat.trend!) {
      TrendDirection.up => Icons.trending_up,
      TrendDirection.down => Icons.trending_down,
      TrendDirection.stable => Icons.trending_flat,
    };

    final color = switch (stat.trend!) {
      TrendDirection.up => scheme.tertiary,
      TrendDirection.down => scheme.error,
      TrendDirection.stable => scheme.onSurfaceVariant,
    };

    return Icon(icon, color: color, size: 20);
  }

  Color _getSeverityColor(BuildContext context) {
    if (stat.severity == null) {
      return Theme.of(context).colorScheme.onSurface;
    }

    return switch (stat.severity!) {
      StatSeverity.normal => Theme.of(context).colorScheme.onSurface,
      StatSeverity.warning => Theme.of(context).colorScheme.secondary,
      StatSeverity.critical => Theme.of(context).colorScheme.error,
      StatSeverity.positive => Theme.of(context).colorScheme.tertiary,
    };
  }
}

class StatPresentation {
  const StatPresentation({
    required this.label,
    required this.valueText,
    this.description,
  });

  factory StatPresentation.fromStat(StatResult stat) {
    final value = stat.value;
    return switch (stat.statType) {
      TaskStatType.totalCount => StatPresentation(
        label: 'Total Tasks',
        valueText: value.toStringAsFixed(0),
      ),
      TaskStatType.completedCount => StatPresentation(
        label: 'Completed',
        valueText: value.toStringAsFixed(0),
      ),
      TaskStatType.completionRate => StatPresentation(
        label: 'Completion Rate',
        valueText: '${value.toStringAsFixed(0)}%',
      ),
      TaskStatType.staleCount => StatPresentation(
        label: 'Stale Tasks',
        valueText: value.toStringAsFixed(0),
        description: _staleDescription(stat.metadata),
      ),
      TaskStatType.overdueCount => StatPresentation(
        label: 'Overdue',
        valueText: value.toStringAsFixed(0),
      ),
      TaskStatType.avgDaysToComplete => StatPresentation(
        label: 'Avg Days to Complete',
        valueText: value == 0 ? 'N/A' : '${value.toStringAsFixed(1)} days',
      ),
      TaskStatType.completedThisWeek => StatPresentation(
        label: 'Completed This Week',
        valueText: value.toStringAsFixed(0),
      ),
      TaskStatType.velocity => StatPresentation(
        label: 'Velocity',
        valueText: '${value.toStringAsFixed(1)} tasks/week',
      ),
    };
  }

  final String label;
  final String valueText;
  final String? description;

  static String? _staleDescription(Map<String, Object?> metadata) {
    final threshold = metadata['staleThresholdDays'];
    if (threshold is int) {
      return 'No activity for $threshold+ days';
    }
    return null;
  }
}
