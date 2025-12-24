import 'package:flutter/material.dart';
import 'package:rrule/rrule.dart';

/// A chip widget for displaying and editing recurrence rules.
class FormRecurrenceChip extends StatelessWidget {
  const FormRecurrenceChip({
    required this.rrule,
    required this.onTap,
    this.onClear,
    super.key,
  });

  final String? rrule;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasValue = rrule != null && rrule!.isNotEmpty;
    final label = hasValue ? _getLabel(rrule!) : 'Repeat';

    return InputChip(
      avatar: Icon(
        Icons.repeat,
        size: 18,
        color: hasValue ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      label: Text(label),
      deleteIcon: hasValue && onClear != null
          ? Icon(
              Icons.close,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            )
          : null,
      onDeleted: hasValue && onClear != null ? onClear : null,
      onPressed: onTap,
      side: BorderSide(
        color: hasValue
            ? colorScheme.primary.withValues(alpha: 0.5)
            : colorScheme.outlineVariant,
      ),
      backgroundColor: hasValue
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : colorScheme.surface,
    );
  }

  String _getLabel(String rruleString) {
    try {
      final recurrenceRule = RecurrenceRule.fromString(rruleString);

      // Build simple label based on frequency
      final interval = recurrenceRule.interval ?? 1;
      if (interval == 1) {
        return switch (recurrenceRule.frequency) {
          Frequency.daily => 'Daily',
          Frequency.weekly => 'Weekly',
          Frequency.monthly => 'Monthly',
          Frequency.yearly => 'Yearly',
          _ => 'Repeat',
        };
      } else {
        final unit = switch (recurrenceRule.frequency) {
          Frequency.daily => 'day',
          Frequency.weekly => 'week',
          Frequency.monthly => 'month',
          Frequency.yearly => 'year',
          _ => 'time',
        };
        return 'Every $interval ${unit}s';
      }
    } catch (e) {
      // Fallback to simple frequency parsing if rrule parsing fails
      if (rruleString.contains('FREQ=DAILY')) {
        return 'Daily';
      } else if (rruleString.contains('FREQ=WEEKLY')) {
        return 'Weekly';
      } else if (rruleString.contains('FREQ=MONTHLY')) {
        return 'Monthly';
      } else if (rruleString.contains('FREQ=YEARLY')) {
        return 'Yearly';
      }
      return 'Repeat';
    }
  }
}
