import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class CorrelationCard extends StatelessWidget {
  const CorrelationCard({
    required this.correlation,
    this.insightOverride,
    this.onTap,
    super.key,
  });
  final CorrelationResult correlation;
  final String? insightOverride;
  final VoidCallback? onTap;

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
                  _buildCorrelationIndicator(context),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.analyticsCorrelationTitle(
                            correlation.sourceLabel,
                            correlation.targetLabel,
                          ),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: TasklyTokens.of(context).spaceSm),
                        Text(
                          _getStrengthLabel(l10n),
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
                insightOverride ?? correlation.insight ?? '',
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
                      l10n.analyticsDifferenceLabel(
                        correlation.differencePercent!.abs().round(),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: TasklyTokens.of(context).spaceSm),
              Text(
                l10n.analyticsSampleSizeLabel(correlation.sampleSize ?? 0),
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

  String _getStrengthLabel(AppLocalizations l10n) {
    return switch (correlation.strength) {
      CorrelationStrength.strongPositive =>
        l10n.analyticsStrengthStrongPositive,
      CorrelationStrength.moderatePositive =>
        l10n.analyticsStrengthModeratePositive,
      CorrelationStrength.weakPositive => l10n.analyticsStrengthWeakPositive,
      CorrelationStrength.negligible => l10n.analyticsStrengthNegligible,
      CorrelationStrength.weakNegative => l10n.analyticsStrengthWeakNegative,
      CorrelationStrength.moderateNegative =>
        l10n.analyticsStrengthModerateNegative,
      CorrelationStrength.strongNegative =>
        l10n.analyticsStrengthStrongNegative,
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
              ? context.l10n.analyticsSignificantLabel(
                  sig.pValue.toStringAsFixed(3),
                )
              : context.l10n.analyticsNotSignificantLabel(
                  sig.pValue.toStringAsFixed(3),
                ),
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
      context.l10n.analyticsPerformanceLabel(
        perf.calculationTimeMs,
        perf.algorithm,
      ),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        fontSize: 10,
      ),
    );
  }
}
