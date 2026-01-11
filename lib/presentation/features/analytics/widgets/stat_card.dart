import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/analytics/model/stat_result.dart';

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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
              const SizedBox(height: 8),
              Text(
                stat.formattedValue ?? stat.value.toString(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: _getSeverityColor(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (stat.description != null) ...[
                const SizedBox(height: 4),
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
    final icon = switch (stat.trend!) {
      TrendDirection.up => Icons.trending_up,
      TrendDirection.down => Icons.trending_down,
      TrendDirection.stable => Icons.trending_flat,
    };

    final color = switch (stat.trend!) {
      TrendDirection.up => Colors.green,
      TrendDirection.down => Colors.red,
      TrendDirection.stable => Colors.grey,
    };

    return Icon(icon, color: color, size: 20);
  }

  Color _getSeverityColor(BuildContext context) {
    if (stat.severity == null) {
      return Theme.of(context).colorScheme.onSurface;
    }

    return switch (stat.severity!) {
      StatSeverity.normal => Theme.of(context).colorScheme.onSurface,
      StatSeverity.warning => Colors.orange,
      StatSeverity.critical => Colors.red,
      StatSeverity.positive => Colors.green,
    };
  }
}
