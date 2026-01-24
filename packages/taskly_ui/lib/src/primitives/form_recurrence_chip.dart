import 'package:flutter/material.dart';

import 'package:taskly_ui/src/forms/taskly_form_preset.dart';

/// A chip widget for displaying and editing recurrence rules.
///
/// This is a render-only widget. Any RRULE parsing and localization must be
/// handled by the app and passed in as [valueLabel]/[emptyLabel].
class TasklyFormRecurrenceChip extends StatelessWidget {
  const TasklyFormRecurrenceChip({
    required this.onTap,
    required this.emptyLabel,
    required this.preset,
    this.hasValue = false,
    this.valueLabel,
    this.isLoading = false,
    this.onClear,
    super.key,
  });

  final bool hasValue;
  final String? valueLabel;
  final bool isLoading;

  /// Label shown when there is no recurrence rule.
  ///
  /// Shared UI must not hardcode user-facing strings; provide localized text
  /// from the app.
  final String emptyLabel;

  final VoidCallback onTap;
  final VoidCallback? onClear;
  final TasklyFormChipPreset preset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final resolvedHasValue = hasValue && (valueLabel?.isNotEmpty ?? false);
    final canClear = resolvedHasValue && onClear != null;
    final resolvedLabel = resolvedHasValue ? valueLabel! : emptyLabel;

    final labelWidget = isLoading && resolvedHasValue
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(resolvedLabel);

    return InputChip(
      avatar: Icon(
        Icons.repeat,
        size: preset.iconSize + 2,
        color: resolvedHasValue
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant,
      ),
      label: labelWidget,
      deleteIcon: canClear
          ? Icon(
              Icons.close,
              size: preset.iconSize + 2,
              color: colorScheme.onSurfaceVariant,
            )
          : null,
      onDeleted: canClear ? onClear : null,
      onPressed: onTap,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(preset.borderRadius),
      ),
      side: BorderSide(
        color: resolvedHasValue
            ? colorScheme.primary.withValues(alpha: 0.5)
            : colorScheme.outlineVariant,
      ),
      backgroundColor: resolvedHasValue
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : colorScheme.surface,
    );
  }
}
