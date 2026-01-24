import 'package:flutter/material.dart';

import 'package:taskly_ui/src/forms/taskly_form_preset.dart';

class TasklyFormPriorityChip extends StatelessWidget {
  const TasklyFormPriorityChip({
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

    return Material(
      color: scheme.surfaceContainerHigh,
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
                hasValue ? Icons.flag_rounded : Icons.flag_outlined,
                size: preset.iconSize,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: hasValue ? FontWeight.w600 : null,
                    ),
              ),
              if (canClear)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: preset.minHeight,
                    minHeight: preset.minHeight,
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    size: preset.clearIconSize,
                    color: scheme.onSurfaceVariant,
                  ),
                  tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                  onPressed: onClear,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
