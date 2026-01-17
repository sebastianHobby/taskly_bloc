import 'package:flutter/material.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/domain/screens/language/models/value_stats.dart'
    as domain;
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/values/widgets/value_needs_attention_sheet.dart';

class ValueNeedsAttentionBadge extends StatelessWidget {
  const ValueNeedsAttentionBadge({
    required this.value,
    required this.stats,
    super.key,
  });

  final Value value;
  final domain.ValueStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Semantics(
      button: true,
      label: l10n.valueNeedsAttentionBadgeLabel,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => ValueNeedsAttentionSheet.show(
          context,
          value: value,
          stats: stats,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.priority_high,
                size: 14,
                color: colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.valueNeedsAttentionBadgeLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
