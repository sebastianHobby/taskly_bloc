import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
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
    final presentation = StatPresentation.fromStat(stat, context.l10n);

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

  factory StatPresentation.fromStat(StatResult stat, AppLocalizations l10n) {
    final value = stat.value;
    return switch (stat.statType) {
      TaskStatType.totalCount => StatPresentation(
        label: l10n.analyticsStatTotalTasksLabel,
        valueText: value.toStringAsFixed(0),
      ),
      TaskStatType.completedCount => StatPresentation(
        label: l10n.analyticsStatCompletedLabel,
        valueText: value.toStringAsFixed(0),
      ),
      TaskStatType.completionRate => StatPresentation(
        label: l10n.analyticsStatCompletionRateLabel,
        valueText: l10n.analyticsPercentValue(value.round()),
      ),
      TaskStatType.staleCount => StatPresentation(
        label: l10n.analyticsStatStaleTasksLabel,
        valueText: value.toStringAsFixed(0),
        description: _staleDescription(stat.metadata, l10n),
      ),
      TaskStatType.overdueCount => StatPresentation(
        label: l10n.analyticsStatOverdueLabel,
        valueText: value.toStringAsFixed(0),
      ),
      TaskStatType.avgDaysToComplete => StatPresentation(
        label: l10n.analyticsStatAverageDaysLabel,
        valueText: value == 0
            ? l10n.analyticsNotAvailableLabel
            : l10n.analyticsDaysValue(value.toDouble()),
      ),
      TaskStatType.completedThisWeek => StatPresentation(
        label: l10n.analyticsStatCompletedThisWeekLabel,
        valueText: value.toStringAsFixed(0),
      ),
      TaskStatType.velocity => StatPresentation(
        label: l10n.analyticsStatVelocityLabel,
        valueText: l10n.analyticsVelocityValue(value.toDouble()),
      ),
    };
  }

  final String label;
  final String valueText;
  final String? description;

  static String? _staleDescription(
    Map<String, Object?> metadata,
    AppLocalizations l10n,
  ) {
    final threshold = metadata['staleThresholdDays'];
    if (threshold is int) {
      return l10n.analyticsStaleDescription(threshold);
    }
    return null;
  }
}
