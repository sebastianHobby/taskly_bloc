import 'package:flutter/material.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class CorrelationCard extends StatelessWidget {
  const CorrelationCard({
    required this.correlation,
    this.onTap,
    super.key,
  });
  final CorrelationResult correlation;
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
            children: [
              Row(
                children: [
                  _buildCorrelationIndicator(context),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${correlation.sourceLabel} → ${correlation.targetLabel}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: TasklyTokens.of(context).spaceSm),
                        Text(
                          _getStrengthLabel(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getStrengthColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: TasklyTokens.of(context).spaceSm),
              Text(
                correlation.insight ?? '',
                style: theme.textTheme.bodyMedium,
              ),
              if (correlation.differencePercent != null) ...[
                SizedBox(height: TasklyTokens.of(context).spaceSm),
                Row(
                  children: [
                    Icon(
                      correlation.differencePercent! > 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 16,
                      color: correlation.differencePercent! > 0
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.error,
                    ),
                    SizedBox(height: TasklyTokens.of(context).spaceSm),
                    Text(
                      '${correlation.differencePercent!.abs().toStringAsFixed(0)}% difference',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: TasklyTokens.of(context).spaceSm),
              Text(
                'Sample size: ${correlation.sampleSize} days',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              // Show statistical significance if available
              if (correlation.statisticalSignificance != null) ...[
                SizedBox(height: TasklyTokens.of(context).spaceSm),
                _buildSignificanceInfo(context),
              ],
              // Show performance metrics if available
              if (correlation.performanceMetrics != null) ...[
                SizedBox(height: TasklyTokens.of(context).spaceSm),
                _buildPerformanceInfo(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCorrelationIndicator(BuildContext context) {
    final value = (correlation.coefficient * 100).abs().toInt();

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: _getStrengthColor(context).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(TasklyTokens.of(context).radiusMd),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$value%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _getStrengthColor(context),
            ),
          ),
          Icon(
            correlation.coefficient > 0
                ? Icons.trending_up
                : Icons.trending_down,
            size: 16,
            color: _getStrengthColor(context),
          ),
        ],
      ),
    );
  }

  String _getStrengthLabel() {
    return switch (correlation.strength) {
      CorrelationStrength.strongPositive => 'Strong Positive',
      CorrelationStrength.moderatePositive => 'Moderate Positive',
      CorrelationStrength.weakPositive => 'Weak Positive',
      CorrelationStrength.negligible => 'Negligible',
      CorrelationStrength.weakNegative => 'Weak Negative',
      CorrelationStrength.moderateNegative => 'Moderate Negative',
      CorrelationStrength.strongNegative => 'Strong Negative',
    };
  }

  Color _getStrengthColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final abs = correlation.coefficient.abs();

    if (abs > 0.5) return scheme.tertiary;
    if (abs > 0.3) return scheme.secondary;
    return scheme.onSurfaceVariant;
  }

  Widget _buildSignificanceInfo(BuildContext context) {
    final sig = correlation.statisticalSignificance!;
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          sig.isSignificant ? Icons.check_circle : Icons.info_outline,
          size: 14,
          color: sig.isSignificant
              ? theme.colorScheme.tertiary
              : theme.colorScheme.onSurfaceVariant,
        ),
        SizedBox(height: TasklyTokens.of(context).spaceSm),
        Text(
          sig.isSignificant
              ? 'Statistically significant (p=${sig.pValue.toStringAsFixed(3)})'
              : 'Not statistically significant (p=${sig.pValue.toStringAsFixed(3)})',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceInfo(BuildContext context) {
    final perf = correlation.performanceMetrics!;
    final theme = Theme.of(context);

    return Text(
      'Calculated in ${perf.calculationTimeMs}ms using ${perf.algorithm}',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        fontSize: 10,
      ),
    );
  }
}
