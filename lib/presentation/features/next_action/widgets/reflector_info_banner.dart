import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';

/// Banner shown when Reflector mode lacks sufficient history.
///
/// Informs the user that Reflector works better with more completion
/// data and is currently using value weights as a fallback.
class ReflectorInfoBanner extends StatelessWidget {
  const ReflectorInfoBanner({
    required this.completionCount,
    required this.lookbackDays,
    super.key,
  });

  /// Number of completions in the lookback period.
  final int completionCount;

  /// Number of days in the lookback period.
  final int lookbackDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insights,
            color: colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.reflectorBuildingHistory,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.reflectorHistoryExplanation(
                    completionCount,
                    lookbackDays,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
