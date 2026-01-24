import 'package:flutter/material.dart';

import 'package:taskly_ui/src/forms/taskly_form_preset.dart';

class TasklyFormProjectChip extends StatelessWidget {
  const TasklyFormProjectChip({
    required this.label,
    required this.hasValue,
    required this.onTap,
    required this.preset,
    this.onClear,
    super.key,
  });

  final String label;
  final bool hasValue;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final TasklyFormChipPreset preset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canClear = hasValue && onClear != null;

    final chipColor = hasValue
        ? scheme.secondaryContainer
        : scheme.surfaceContainerHigh;
    final contentColor =
        hasValue ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;

    return Material(
      color: chipColor,
      borderRadius: BorderRadius.circular(preset.borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(preset.borderRadius),
        child: Padding(
          padding: EdgeInsets.only(
            left: preset.padding.left,
            right: canClear ? preset.clearHitPadding : preset.padding.right,
            top: preset.padding.top,
            bottom: preset.padding.bottom,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_rounded,
                size: preset.iconSize,
                color: contentColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: contentColor,
                      fontWeight: hasValue ? FontWeight.w500 : null,
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
                      Icons.close_rounded,
                      size: preset.clearIconSize,
                      color: contentColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
