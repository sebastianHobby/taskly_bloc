import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

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
    final l10n = context.l10n;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TasklyTokens.of(context).radiusMd),
        child: Padding(
          padding: EdgeInsets.all(TasklyTokens.of(context).spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildInsightIcon(context),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
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
                        SizedBox(height: TasklyTokens.of(context).spaceSm),
                        Text(
                          _getInsightTypeLabel(l10n),
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
                      tooltip: l10n.dismissLabel,
                    ),
                ],
              ),
              SizedBox(height: TasklyTokens.of(context).spaceSm),
              Text(
                insight.description,
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: TasklyTokens.of(context).spaceSm),
              Row(
                children: [
                  if (insight.confidence != null) ...[
                    Icon(
                      Icons.psychology,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(height: TasklyTokens.of(context).spaceSm),
                    Text(
                      l10n.insightConfidenceLabel(
                        (insight.confidence! * 100).round(),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: TasklyTokens.of(context).spaceSm),
                  ],
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                  Text(
                    _formatDateRange(context),
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
        borderRadius: BorderRadius.circular(TasklyTokens.of(context).radiusMd),
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

  String _getInsightTypeLabel(AppLocalizations l10n) {
    return switch (insight.insightType) {
      InsightType.correlationDiscovery => l10n.insightTypeCorrelationDiscovery,
      InsightType.trendAlert => l10n.insightTypeTrendAlert,
      InsightType.anomalyDetection => l10n.insightTypeAnomalyDetected,
      InsightType.productivityPattern => l10n.insightTypeProductivityPattern,
      InsightType.moodPattern => l10n.insightTypeMoodPattern,
      InsightType.recommendation => l10n.insightTypeRecommendation,
    };
  }

  Color _getInsightColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return insight.isPositive ? scheme.tertiary : scheme.secondary;
  }

  String _formatDateRange(BuildContext context) {
    final start = insight.periodStart;
    final end = insight.periodEnd;
    final locale = Localizations.localeOf(context).toLanguageTag();

    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return DateFormat.yMMMd(locale).format(start);
    }

    if (start.year == end.year) {
      final formatter = DateFormat.MMMd(locale);
      return '${formatter.format(start)} - ${formatter.format(end)}';
    }

    final formatter = DateFormat.yMMMd(locale);
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }
}
