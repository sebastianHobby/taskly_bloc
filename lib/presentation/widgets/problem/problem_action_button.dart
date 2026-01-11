import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/workflow/model/problem_action.dart';

/// A button widget for executing a problem action.
///
/// Displays the action label with an appropriate icon. Used within
/// `ProblemCard` to show available quick-fix options.
class ProblemActionButton extends StatelessWidget {
  /// Creates a problem action button.
  const ProblemActionButton({
    required this.action,
    required this.onPressed,
    this.compact = false,
    super.key,
  });

  /// The action this button represents.
  final ProblemAction action;

  /// Callback when the button is pressed.
  final VoidCallback onPressed;

  /// Whether to display in compact mode.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (compact) {
      return ActionChip(
        avatar: Icon(
          _getIconData(action.iconName),
          size: 16,
          color: colorScheme.primary,
        ),
        label: Text(
          action.label,
          style: theme.textTheme.labelSmall,
        ),
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
      );
    }

    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(
        _getIconData(action.iconName),
        size: 18,
      ),
      label: Text(action.label),
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: theme.textTheme.labelMedium,
      ),
    );
  }

  IconData _getIconData(String iconName) {
    return switch (iconName) {
      'today' => Icons.today,
      'event' => Icons.event,
      'date_range' => Icons.date_range,
      'calendar_month' => Icons.calendar_month,
      'event_busy' => Icons.event_busy,
      'label' => Icons.label,
      'label_outline' => Icons.label_outline,
      'arrow_downward' => Icons.arrow_downward,
      'remove_circle_outline' => Icons.remove_circle_outline,
      _ => Icons.check_circle_outline,
    };
  }
}
