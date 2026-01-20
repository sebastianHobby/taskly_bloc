import 'package:flutter/material.dart';

/// A compact chip showing a date or indicator.
///
/// Displays an icon and label with consistent styling used for
/// date displays in task and project tiles.
class DateChip extends StatelessWidget {
  /// Creates a date chip.
  const DateChip({
    required this.icon,
    required this.label,
    required this.color,
    this.backgroundColor,
    super.key,
  });

  /// Creates a date chip for start dates.
  DateChip.startDate({
    required BuildContext context,
    required String label,
    Key? key,
  }) : this(
         icon: Icons.play_arrow_rounded,
         label: label,
         color: Theme.of(context).colorScheme.onSurfaceVariant,
         key: key,
       );

  /// Creates a date chip for deadline dates.
  factory DateChip.deadline({
    required BuildContext context,
    required String label,
    required bool isOverdue,
    required bool isDueToday,
    required bool isDueSoon,
    Key? key,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    Color chipColor;
    Color? chipBackground;

    if (isOverdue) {
      chipColor = colorScheme.error;
      chipBackground = colorScheme.errorContainer.withValues(alpha: 0.3);
    } else if (isDueToday) {
      chipColor = colorScheme.primary;
      chipBackground = colorScheme.primaryContainer.withValues(alpha: 0.3);
    } else if (isDueSoon) {
      chipColor = colorScheme.primary;
    } else {
      chipColor = colorScheme.onSurfaceVariant;
    }

    return DateChip(
      icon: Icons.flag_outlined,
      label: label,
      color: chipColor,
      backgroundColor: chipBackground,
      key: key,
    );
  }

  /// Creates a date chip for repeat indicator.
  factory DateChip.repeat({
    required BuildContext context,
    required String label,
    Key? key,
  }) {
    return DateChip(
      icon: Icons.repeat_rounded,
      label: label,
      color: Theme.of(context).colorScheme.primary,
      key: key,
    );
  }

  /// The icon to display.
  final IconData icon;

  /// The label text.
  final String label;

  /// The foreground color for icon and text.
  final Color color;

  /// Optional background color for the chip.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: backgroundColor != null
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
          : EdgeInsets.zero,
      decoration: backgroundColor != null
          ? BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}
