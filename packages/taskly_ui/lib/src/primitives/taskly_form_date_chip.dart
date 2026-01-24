import 'package:flutter/material.dart';

import 'package:taskly_ui/src/forms/taskly_form_preset.dart';

class TasklyFormDateChip extends StatelessWidget {
  const TasklyFormDateChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.preset,
    this.valueLabel,
    this.hasValue = false,
    this.isDeadline = false,
    this.isOverdue = false,
    this.onClear,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? valueLabel;
  final bool hasValue;
  final bool isDeadline;
  final bool isOverdue;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final TasklyFormChipPreset preset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final resolvedHasValue = hasValue && valueLabel != null;
    final overdue = isOverdue && resolvedHasValue;

    final chipColor = overdue
        ? scheme.errorContainer
        : resolvedHasValue
        ? (isDeadline
              ? scheme.primaryContainer
              : scheme.secondaryContainer)
        : (isDeadline
              ? scheme.surfaceContainerHighest
              : scheme.surfaceContainerHigh);

    final contentColor = overdue
        ? scheme.onErrorContainer
        : resolvedHasValue
        ? (isDeadline
              ? scheme.onPrimaryContainer
              : scheme.onSecondaryContainer)
        : scheme.onSurfaceVariant;

    final canClear = onClear != null && resolvedHasValue;

    return Material(
      color: chipColor,
      borderRadius: BorderRadius.circular(preset.borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(preset.borderRadius),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: preset.minHeight),
          child: Padding(
            padding: EdgeInsets.only(
              left: preset.padding.left,
              right: canClear
                  ? preset.clearHitPadding
                  : preset.padding.right,
              top: preset.padding.top,
              bottom: preset.padding.bottom,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: preset.iconSize,
                  color: contentColor,
                ),
                const SizedBox(width: 6),
                Text(
                  resolvedHasValue ? valueLabel! : label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: contentColor,
                        fontWeight:
                            resolvedHasValue ? FontWeight.w500 : null,
                      ),
                ),
                if (canClear) ...[
                  const SizedBox(width: 2),
                  InkWell(
                    onTap: onClear,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.all(preset.clearHitPadding),
                      child: Icon(
                        Icons.close,
                        size: preset.clearIconSize,
                        color: contentColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
