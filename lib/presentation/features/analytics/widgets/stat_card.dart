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
                      stat.label,
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
                stat.formattedValue ?? stat.value.toString(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: _getSeverityColor(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (stat.description != null) ...[
                SizedBox(height: TasklyTokens.of(context).spaceSm),
                Text(
                  stat.description!,
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
