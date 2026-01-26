import 'package:flutter/material.dart';

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

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(
              row.icon,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
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
              const SizedBox(width: 4),
              IconButton(
                onPressed: row.onClear,
                icon: const Icon(Icons.close_rounded),
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
