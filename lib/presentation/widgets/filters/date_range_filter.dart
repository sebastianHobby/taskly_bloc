import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/widgets/form_date_chip.dart';

/// Unified date range filter with consistent styling.
///
/// Provides "after" and "before" date pickers with clear buttons.
///
/// Example:
/// ```dart
/// DateRangeFilter(
///   label: 'Created date',
///   afterDate: createdAfter,
///   beforeDate: createdBefore,
///   onAfterChanged: (date) => setState(() => createdAfter = date),
///   onBeforeChanged: (date) => setState(() => createdBefore = date),
/// )
/// ```
class DateRangeFilter extends StatelessWidget {
  const DateRangeFilter({
    required this.label,
    required this.afterDate,
    required this.beforeDate,
    required this.onAfterChanged,
    required this.onBeforeChanged,
    this.afterLabel,
    this.beforeLabel,
    this.firstDate,
    this.lastDate,
    super.key,
  });

  /// Main label for the date range (e.g., 'Created date').
  final String label;

  /// Currently selected "after" date.
  final DateTime? afterDate;

  /// Currently selected "before" date.
  final DateTime? beforeDate;

  /// Called when "after" date changes.
  final ValueChanged<DateTime?> onAfterChanged;

  /// Called when "before" date changes.
  final ValueChanged<DateTime?> onBeforeChanged;

  /// Custom label for "after" picker (defaults to 'After [label]').
  final String? afterLabel;

  /// Custom label for "before" picker (defaults to 'Before [label]').
  final String? beforeLabel;

  /// Earliest selectable date.
  final DateTime? firstDate;

  /// Latest selectable date.
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FormDateChip(
                icon: Icons.calendar_today,
                label: afterLabel ?? 'After ${label.toLowerCase()}',
                date: afterDate,
                onTap: () => _pickDate(context, afterDate, onAfterChanged),
                onClear: afterDate != null ? () => onAfterChanged(null) : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FormDateChip(
                icon: Icons.calendar_today,
                label: beforeLabel ?? 'Before ${label.toLowerCase()}',
                date: beforeDate,
                onTap: () => _pickDate(context, beforeDate, onBeforeChanged),
                onClear: beforeDate != null
                    ? () => onBeforeChanged(null)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    DateTime? initial,
    ValueChanged<DateTime?> onChanged,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2020),
      lastDate: lastDate ?? DateTime(2030),
    );
    if (picked != null) {
      onChanged(picked);
    }
  }
}
