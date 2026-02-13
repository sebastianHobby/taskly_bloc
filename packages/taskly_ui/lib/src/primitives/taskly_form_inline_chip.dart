import 'package:flutter/material.dart';

import 'package:taskly_ui/src/forms/taskly_form_preset.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

class TasklyFormInlineChip extends StatelessWidget {
  const TasklyFormInlineChip({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.preset,
    this.valueLabel,
    this.hasValue = false,
    this.valueColor,
    this.showLabelWhenEmpty = true,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final TasklyFormChipPreset preset;
  final String? valueLabel;
  final bool hasValue;
  final Color? valueColor;
  final bool showLabelWhenEmpty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);
    final resolvedHasValue =
        hasValue && (valueLabel?.trim().isNotEmpty ?? false);
    final displayLabel = resolvedHasValue ? valueLabel! : label;
    final displayColor = resolvedHasValue
        ? (valueColor ?? scheme.primary)
        : scheme.onSurfaceVariant;
    final shouldShowLabel =
        (resolvedHasValue || showLabelWhenEmpty) &&
        displayLabel.trim().isNotEmpty;

    return Material(
      color: scheme.surface,
      shape: StadiumBorder(
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: preset.minHeight),
          child: Padding(
            padding: preset.padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: preset.iconSize,
                  color: displayColor,
                ),
                if (shouldShowLabel) ...[
                  SizedBox(width: tokens.spaceXs2),
                  Text(
                    displayLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: displayColor,
                      fontWeight: resolvedHasValue ? FontWeight.w600 : null,
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
