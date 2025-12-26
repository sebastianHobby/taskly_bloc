import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/domain/domain.dart';

/// A modern card-based list tile representing a label.
class LabelListTile extends StatelessWidget {
  const LabelListTile({
    required this.label,
    required this.onTap,
    super.key,
  });

  final Label label;
  final void Function(Label) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final labelColor = ColorUtils.fromHexWithThemeFallback(
      context,
      label.color,
    );

    final isValue = label.type == LabelType.value;

    // For values: use colored background with contrasting text
    // For labels: use neutral background with colored icon
    final cardColor = isValue ? labelColor : colorScheme.surface;
    final textColor = isValue
        ? (labelColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white)
        : colorScheme.onSurface;
    final subtextColor = isValue
        ? (labelColor.computeLuminance() > 0.5
              ? Colors.black54
              : Colors.white70)
        : colorScheme.onSurfaceVariant;

    return Card(
      key: Key('label-${label.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isValue
              ? labelColor
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: () => onTap(label),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Color indicator with emoji for values
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isValue
                      ? Colors.transparent
                      : labelColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: isValue
                      ? Text(
                          label.iconName?.isNotEmpty ?? false
                              ? label.iconName!
                              : 'â¤ï¸',
                          style: const TextStyle(fontSize: 20),
                        )
                      : Icon(
                          Icons.label_outline,
                          color: labelColor,
                          size: 20,
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Label info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isValue ? 'Value' : 'Label',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.chevron_right,
                size: 20,
                color: isValue
                    ? textColor.withValues(alpha: 0.5)
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
