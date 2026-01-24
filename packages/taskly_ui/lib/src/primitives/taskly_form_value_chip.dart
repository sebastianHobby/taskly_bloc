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
    required this.isSelected,
    required this.preset,
    this.isPrimary = false,
    super.key,
  });

  final TasklyFormValueChipModel model;
  final VoidCallback onTap;
  final bool isSelected;
  final TasklyFormChipPreset preset;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = model.color.withValues(alpha: 0.95);

    final bg = isSelected
        ? model.color.withValues(alpha: 0.16)
        : scheme.surface;
    final borderColor =
        isSelected ? model.color.withValues(alpha: 0.6) : scheme.outlineVariant;
    final labelColor = isSelected ? color : scheme.onSurfaceVariant;
    final iconColor = isSelected ? color : scheme.onSurfaceVariant;

    return Material(
      color: bg,
      shape: StadiumBorder(
        side: BorderSide(
          color: borderColor,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: preset.padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ValueIcon(
                icon: model.icon,
                color: iconColor,
                borderColor: borderColor,
                size: preset.iconSize + 2,
              ),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  model.label,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: labelColor,
                        fontWeight: isSelected
                            ? (isPrimary ? FontWeight.w700 : FontWeight.w600)
                            : null,
                      ),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.check,
                  size: preset.iconSize,
                  color: labelColor,
                ),
              ],
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
