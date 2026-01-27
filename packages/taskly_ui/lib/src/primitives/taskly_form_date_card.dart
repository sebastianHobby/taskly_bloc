import 'package:flutter/material.dart';

import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

@immutable
class TasklyFormDateRow {
  const TasklyFormDateRow({
    required this.icon,
    required this.label,
    required this.placeholderLabel,
    required this.onTap,
    this.valueLabel,
    this.hasValue = false,
    this.valueColor,
    this.onClear,
  });

  final IconData icon;
  final String label;
  final String placeholderLabel;
  final String? valueLabel;
  final bool hasValue;
  final Color? valueColor;
  final VoidCallback onTap;
  final VoidCallback? onClear;
}

class TasklyFormDateCard extends StatelessWidget {
  const TasklyFormDateCard({
    required this.rows,
    super.key,
  });

  final List<TasklyFormDateRow> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _DateRow(row: rows[i]),
            if (i != rows.length - 1)
              Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
          ],
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.row});

  final TasklyFormDateRow row;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);
    final hasValue =
        row.hasValue && row.valueLabel != null && row.valueLabel!.isNotEmpty;
    final trailingLabel = hasValue ? row.valueLabel! : row.placeholderLabel;
    final trailingColor = hasValue
        ? (row.valueColor ?? scheme.primary)
        : scheme.onSurfaceVariant;
    final canClear = hasValue && row.onClear != null;

    return InkWell(
      onTap: row.onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMd2,
          vertical: tokens.spaceMd,
        ),
        child: Row(
          children: [
            Icon(
              row.icon,
              size: tokens.spaceLg2,
              color: scheme.onSurfaceVariant,
            ),
            SizedBox(width: tokens.spaceSm2),
            Expanded(
              child: Text(
                row.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              trailingLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: trailingColor,
                fontWeight: hasValue ? FontWeight.w600 : null,
              ),
            ),
            if (canClear) ...[
              SizedBox(width: tokens.spaceXs),
              IconButton(
                onPressed: row.onClear,
                icon: const Icon(Icons.close_rounded),
                iconSize: tokens.spaceLg2,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: tokens.spaceXxl,
                  minHeight: tokens.spaceXxl,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
