import 'package:flutter/material.dart';

/// A compact date chip for forms that shows a date or "Add [label]" prompt.
///
/// Features:
/// - Tappable to open date picker
/// - Optional clear button when date is set
/// - Overdue highlighting for deadlines
/// - Consistent styling across all forms
class FormDateChip extends StatelessWidget {
  const FormDateChip({
    required this.icon,
    required this.label,
    required this.date,
    required this.onTap,
    this.isDeadline = false,
    this.onClear,
    super.key,
  });

  /// Creates a start date chip with default styling.
  const FormDateChip.startDate({
    required DateTime? date,
    required VoidCallback onTap,
    VoidCallback? onClear,
    Key? key,
  }) : this(
         icon: Icons.calendar_today_rounded,
         label: 'start date',
         date: date,
         onTap: onTap,
         onClear: onClear,
         key: key,
       );

  /// Creates a deadline date chip with overdue highlighting.
  const FormDateChip.deadline({
    required DateTime? date,
    required VoidCallback onTap,
    VoidCallback? onClear,
    Key? key,
  }) : this(
         icon: Icons.flag_rounded,
         label: 'deadline',
         date: date,
         onTap: onTap,
         isDeadline: true,
         onClear: onClear,
         key: key,
       );

  /// The icon to display.
  final IconData icon;

  /// The label shown when no date is set (e.g., "Add start date").
  final String label;

  /// The current date value, or null if not set.
  final DateTime? date;

  /// Called when the chip is tapped.
  final VoidCallback onTap;

  /// Whether this is a deadline (enables overdue highlighting).
  final bool isDeadline;

  /// Called when the clear button is tapped. If null, no clear button shown.
  final VoidCallback? onClear;

  /// Formats a date as "Dec 23, 2025".
  static String formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  bool _isOverdue(DateTime? date) {
    if (date == null || !isDeadline) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);
    return dateDay.isBefore(today);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasDate = date != null;
    final overdue = _isOverdue(date);

    final chipColor = overdue
        ? colorScheme.errorContainer
        : hasDate
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHigh;

    final contentColor = overdue
        ? colorScheme.onErrorContainer
        : hasDate
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Material(
      color: chipColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.only(
            left: 10,
            right: onClear != null && hasDate ? 4 : 10,
            top: 6,
            bottom: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: contentColor,
              ),
              const SizedBox(width: 6),
              Text(
                hasDate ? formatDate(date!) : 'Add $label',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: contentColor,
                  fontWeight: hasDate ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              if (onClear != null && hasDate) ...[
                const SizedBox(width: 2),
                InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: contentColor.withValues(alpha: 0.7),
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
