import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/analytics/model/correlation_result.dart';

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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildCorrelationIndicator(context),
                  const SizedBox(width: 12),
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
                        const SizedBox(height: 4),
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
              const SizedBox(height: 12),
              Text(
                correlation.insight ?? '',
                style: theme.textTheme.bodyMedium,
              ),
              if (correlation.differencePercent != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      correlation.differencePercent! > 0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 16,
                      color: correlation.differencePercent! > 0
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${correlation.differencePercent!.abs().toStringAsFixed(0)}% difference',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Sample size: ${correlation.sampleSize} days',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              // Show statistical significance if available
              if (correlation.statisticalSignificance != null) ...[
                const SizedBox(height: 8),
                _buildSignificanceInfo(context),
              ],
              // Show performance metrics if available
              if (correlation.performanceMetrics != null) ...[
                const SizedBox(height: 4),
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
        borderRadius: BorderRadius.circular(8),
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
    final abs = correlation.coefficient.abs();

    if (abs > 0.5) return Colors.green;
    if (abs > 0.3) return Colors.orange;
    return Colors.grey;
  }

  Widget _buildSignificanceInfo(BuildContext context) {
    final sig = correlation.statisticalSignificance!;
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          sig.isSignificant ? Icons.check_circle : Icons.info_outline,
          size: 14,
          color: sig.isSignificant ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 4),
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
