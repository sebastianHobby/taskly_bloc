import 'package:flutter/material.dart';

import 'package:taskly_ui/src/forms/taskly_form_preset.dart';

@immutable
class TasklyFormValueChipModel {
  const TasklyFormValueChipModel({
    required this.label,
    required this.color,
    required this.icon,
    this.semanticLabel,
  });

  final String label;
  final Color color;
  final IconData icon;
  final String? semanticLabel;
}

class TasklyFormValueChip extends StatelessWidget {
  const TasklyFormValueChip({
    required this.model,
    required this.onTap,
    required this.preset,
    this.isPrimary = false,
    super.key,
  });

  final TasklyFormValueChipModel model;
  final VoidCallback onTap;
  final TasklyFormChipPreset preset;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = model.color.withValues(alpha: 0.95);

    final bg = isPrimary
        ? model.color.withValues(alpha: 0.18)
        : scheme.surface;
    final borderColor = model.color.withValues(alpha: 0.8);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(preset.borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(preset.borderRadius),
        child: Padding(
          padding: preset.padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ValueIcon(
                icon: model.icon,
                color: color,
                borderColor: borderColor,
                size: preset.iconSize + 2,
              ),
              const SizedBox(width: 6),
              if (isPrimary)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    model.label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                )
              else
                Icon(
                  Icons.circle_outlined,
                  size: 10,
                  color: model.color.withValues(alpha: 0.75),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueIcon extends StatelessWidget {
  const _ValueIcon({
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final Color borderColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 2,
      height: size + 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.25),
      ),
      child: Center(
        child: Icon(
          icon,
          size: size - 6,
          color: color,
        ),
      ),
    );
  }
}
