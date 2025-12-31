import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/analytics/analytics_insight.dart';

class InsightCard extends StatelessWidget {
  const InsightCard({
    required this.insight,
    this.onTap,
    this.onDismiss,
    super.key,
  });
  final AnalyticsInsight insight;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

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
            children: [
              Row(
                children: [
                  _buildInsightIcon(context),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getInsightTypeLabel(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getInsightColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onDismiss != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: onDismiss,
                      tooltip: 'Dismiss',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                insight.description,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (insight.confidence != null) ...[
                    Icon(
                      Icons.psychology,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(insight.confidence! * 100).toStringAsFixed(0)}% confidence',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateRange(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightIcon(BuildContext context) {
    final color = _getInsightColor(context);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getInsightIcon(),
        color: color,
        size: 24,
      ),
    );
  }

  IconData _getInsightIcon() {
    return switch (insight.insightType) {
      InsightType.correlationDiscovery => Icons.trending_up,
      InsightType.trendAlert => Icons.show_chart,
      InsightType.anomalyDetection => Icons.warning_amber,
      InsightType.productivityPattern => Icons.work_outline,
      InsightType.moodPattern => Icons.mood,
      InsightType.recommendation => Icons.lightbulb_outline,
    };
  }

  String _getInsightTypeLabel() {
    return switch (insight.insightType) {
      InsightType.correlationDiscovery => 'Correlation Discovery',
      InsightType.trendAlert => 'Trend Alert',
      InsightType.anomalyDetection => 'Anomaly Detected',
      InsightType.productivityPattern => 'Productivity Pattern',
      InsightType.moodPattern => 'Mood Pattern',
      InsightType.recommendation => 'Recommendation',
    };
  }

  Color _getInsightColor(BuildContext context) {
    if (insight.isPositive) {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }

  String _formatDateRange() {
    final start = insight.periodStart;
    final end = insight.periodEnd;

    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return '${start.month}/${start.day}/${start.year}';
    }

    return '${start.month}/${start.day} - ${end.month}/${end.day}';
  }
}
