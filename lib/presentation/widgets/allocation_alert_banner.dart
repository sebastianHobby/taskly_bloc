import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/domain/models/settings/alert_severity.dart';
import 'package:taskly_bloc/domain/models/settings/evaluated_alert.dart';

/// Compact banner showing allocation alert summary.
///
/// Displays count of items outside Focus with severity-based styling.
/// Tapping triggers scroll to Outside Focus section.
class AllocationAlertBanner extends StatelessWidget {
  const AllocationAlertBanner({
    required this.alertResult,
    required this.onReviewTap,
    super.key,
  });

  final AlertEvaluationResult alertResult;
  final VoidCallback onReviewTap;

  @override
  Widget build(BuildContext context) {
    if (!alertResult.hasAlerts) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    final severity = alertResult.highestSeverity!;
    final colors = _colorsForSeverity(severity, colorScheme);

    return Semantics(
      label:
          'Alert: ${alertResult.totalCount} items need attention. '
          'Tap to review.',
      button: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Material(
          color: colors.background,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onReviewTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    _iconForSeverity(severity),
                    color: colors.foreground,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatMessage(alertResult.totalCount, l10n),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.foreground,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    l10n.myDayAlertBannerReview,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: colors.foreground,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatMessage(int count, AppLocalizations l10n) {
    if (count == 1) {
      return l10n.myDayAlertBannerSingular;
    }
    return l10n.myDayAlertBannerPlural(count);
  }

  IconData _iconForSeverity(AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.critical => Icons.error_outline,
      AlertSeverity.warning => Icons.warning_amber_outlined,
      AlertSeverity.notice => Icons.info_outline,
    };
  }

  _BannerColors _colorsForSeverity(
    AlertSeverity severity,
    ColorScheme colorScheme,
  ) {
    return switch (severity) {
      AlertSeverity.critical => _BannerColors(
        background: colorScheme.errorContainer,
        foreground: colorScheme.onErrorContainer,
      ),
      AlertSeverity.warning => _BannerColors(
        background: Color.alphaBlend(
          Colors.amber.withValues(alpha: 0.2),
          colorScheme.surface,
        ),
        foreground: Colors.amber.shade800,
      ),
      AlertSeverity.notice => _BannerColors(
        background: colorScheme.primaryContainer,
        foreground: colorScheme.onPrimaryContainer,
      ),
    };
  }
}

class _BannerColors {
  const _BannerColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}
