import 'package:flutter/material.dart';

/// A chip widget for displaying and editing recurrence rules.
///
/// This is a render-only widget. Any RRULE parsing and localization must be
/// handled by the app and passed in as [label]/[emptyLabel].
class FormRecurrenceChip extends StatelessWidget {
  const FormRecurrenceChip({
    required this.onTap,
    required this.emptyLabel,
    this.hasValue = false,
    this.label,
    this.onClear,
    super.key,
  });

  final bool hasValue;
  final String? label;

  /// Label shown when there is no recurrence rule.
  ///
  /// Shared UI must not hardcode user-facing strings; provide localized text
  /// from the app.
  final String emptyLabel;

  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final resolvedLabel = (hasValue && label != null && label!.isNotEmpty)
        ? label!
        : emptyLabel;

    return InputChip(
      avatar: Icon(
        Icons.repeat,
        size: 18,
        color: hasValue ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      label: Text(resolvedLabel),
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
}
