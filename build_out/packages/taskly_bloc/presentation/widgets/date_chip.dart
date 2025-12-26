import 'package:flutter/material.dart';
import 'package:rrule/rrule.dart';

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
         icon: Icons.calendar_today_rounded,
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
      chipColor = colorScheme.tertiary;
      chipBackground = colorScheme.tertiaryContainer.withValues(alpha: 0.3);
    } else if (isDueSoon) {
      chipColor = colorScheme.secondary;
    } else {
      chipColor = colorScheme.onSurfaceVariant;
    }

    return DateChip(
      icon: Icons.flag_rounded,
      label: label,
      color: chipColor,
      backgroundColor: chipBackground,
      key: key,
    );
  }

  /// Creates a date chip for repeat indicator.
  factory DateChip.repeat({
    required BuildContext context,
    String? rrule,
    Key? key,
  }) {
    String label = 'Repeats';

    // If rrule is provided, convert it to human-readable text
    if (rrule != null && rrule.isNotEmpty) {
      try {
        final recurrenceRule = RecurrenceRule.fromString(rrule);
        // Use the RruleL10n to convert to text
        // Note: This is synchronous access after loading l10n
        // For now, fall back to simple label until we can make this async
        label = _getSimpleRruleLabel(recurrenceRule);
      } catch (e) {
        // If parsing fails, keep default label
        label = 'Repeats';
      }
    }

    return DateChip(
      icon: Icons.repeat_rounded,
      label: label,
      color: Theme.of(context).colorScheme.primary,
      key: key,
    );
  }

  /// Gets a simple label for the recurrence rule.
  /// For full i18n support, use RruleL10n.
  static String _getSimpleRruleLabel(RecurrenceRule rule) {
    final interval = rule.interval;
    final freq = rule.frequency;

    if (interval == 1) {
      return switch (freq) {
        Frequency.daily => 'Daily',
        Frequency.weekly => 'Weekly',
        Frequency.monthly => 'Monthly',
        Frequency.yearly => 'Yearly',
        _ => 'Repeats',
      };
    } else {
      final unit = switch (freq) {
        Frequency.daily => 'day',
        Frequency.weekly => 'week',
        Frequency.monthly => 'month',
        Frequency.yearly => 'year',
        _ => 'time',
      };
      return 'Every $interval ${unit}s';
    }
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
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// A row displaying dates with visual indicators.
///
/// Shows start date, deadline date (with status colors), and repeat indicator.
class DatesRow extends StatelessWidget {
  /// Creates a dates row.
  const DatesRow({
    required this.formatDate,
    this.startDate,
    this.deadlineDate,
    this.isOverdue = false,
    this.isDueToday = false,
    this.isDueSoon = false,
    this.hasRepeat = false,
    this.rrule,
    super.key,
  });

  /// The start date to display.
  final DateTime? startDate;

  /// The deadline date to display.
  final DateTime? deadlineDate;

  /// Whether the deadline is overdue.
  final bool isOverdue;

  /// Whether the deadline is today.
  final bool isDueToday;

  /// Whether the deadline is soon.
  final bool isDueSoon;

  /// Whether the item repeats.
  final bool hasRepeat;

  /// The RRule string for recurrence pattern.
  final String? rrule;

  /// Function to format dates for display.
  final String Function(BuildContext, DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    if (startDate == null && deadlineDate == null && !hasRepeat) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: [
          // Start date
          if (startDate != null)
            DateChip.startDate(
              context: context,
              label: formatDate(context, startDate!),
            ),

          // Deadline date with status color
          if (deadlineDate != null)
            DateChip.deadline(
              context: context,
              label: formatDate(context, deadlineDate!),
              isOverdue: isOverdue,
              isDueToday: isDueToday,
              isDueSoon: isDueSoon,
            ),

          // Repeat indicator
          if (hasRepeat) DateChip.repeat(context: context, rrule: rrule),
        ],
      ),
    );
  }
}

/// A date chip that displays RRule with full i18n support.
///
/// This widget loads RruleL10n asynchronously and displays the
/// human-readable recurrence text. Use this when you need proper
/// internationalization support for complex RRule patterns.
class RruleDateChip extends StatefulWidget {
  const RruleDateChip({
    required this.rrule,
    this.icon = Icons.repeat_rounded,
    this.fallbackLabel = 'Repeats',
    super.key,
  });

  /// The RRule string to display.
  final String? rrule;

  /// The icon to display.
  final IconData icon;

  /// Fallback label when RRule is null or parsing fails.
  final String fallbackLabel;

  @override
  State<RruleDateChip> createState() => _RruleDateChipState();
}

class _RruleDateChipState extends State<RruleDateChip> {
  String? _label;

  @override
  void initState() {
    super.initState();
    if (widget.rrule != null && widget.rrule!.isNotEmpty) {
      _loadLabel();
    }
  }

  @override
  void didUpdateWidget(RruleDateChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload label if rrule changed
    if (oldWidget.rrule != widget.rrule) {
      _label = null;
      if (widget.rrule != null && widget.rrule!.isNotEmpty) {
        _loadLabel();
      } else {
        setState(() {
          _label = null;
        });
      }
    }
  }

  Future<void> _loadLabel() async {
    if (widget.rrule == null || widget.rrule!.isEmpty) {
      return;
    }

    try {
      final l10n = await RruleL10nEn.create();
      final recurrenceRule = RecurrenceRule.fromString(widget.rrule!);
      final text = recurrenceRule.toText(l10n: l10n);

      if (mounted) {
        setState(() {
          _label = text;
        });
      }
    } catch (e) {
      // If parsing fails, keep null label (will use fallback)
      if (mounted) {
        setState(() {
          _label = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _label ?? widget.fallbackLabel;
    return DateChip(
      icon: widget.icon,
      label: label,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}
