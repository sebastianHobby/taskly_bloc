import 'package:flutter/material.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/domain/screens/language/models/value_stats.dart'
    as domain;
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';

class ValueNeedsAttentionSheet extends StatelessWidget {
  const ValueNeedsAttentionSheet({
    required this.value,
    required this.stats,
    super.key,
  });

  final Value value;
  final domain.ValueStats stats;

  static Future<void> show(
    BuildContext context, {
    required Value value,
    required domain.ValueStats stats,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ValueNeedsAttentionSheet(value: value, stats: stats),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    final expectedRounded = stats.expectedRecentCompletionCount.round();
    final actual = stats.recentCompletionCount;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              l10n.valueNeedsAttentionSheetTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.valueNeedsAttentionSheetBody(value.name, stats.lookbackDays),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.valueNeedsAttentionSheetCounts(expectedRounded, actual),
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.valueNeedsAttentionSheetOnlyOne,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Routing.toTaskNew(context, defaultValueId: value.id);
                    },
                    icon: const Icon(Icons.add_task),
                    label: Text(l10n.pickSmallWinCta),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.closeLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
