import 'package:flutter/material.dart';

/// A composable shell for modal forms with consistent styling.
///
/// Provides:
/// - Handle bar at top
/// - Action buttons row (close, delete, submit)
/// - Scrollable content area
/// - Sticky footer with action button
///
/// Uses composition to wrap form content rather than inheritance.
///
/// Example usage:
/// ```dart
/// FormShell(
///   onClose: () => Navigator.pop(context),
///   onSubmit: _handleSubmit,
///   submitTooltip: 'Save',
///   submitIcon: Icons.check,
///   onDelete: isEditing ? _handleDelete : null,
///   child: Column(
///     children: [
///       // Form fields here
///     ],
///   ),
/// )
/// ```
class FormShell extends StatelessWidget {
  const FormShell({
    required this.child,
    required this.onSubmit,
    required this.submitTooltip,
    this.onClose,
    this.onDelete,
    this.submitIcon = Icons.check,
    this.deleteTooltip = 'Delete',
    this.closeTooltip = 'Close',
    this.handleBarWidth = 40.0,
    this.borderRadius = 20.0,
    super.key,
  });

  /// The form content to display.
  final Widget child;

  /// Called when the submit button is tapped.
  final VoidCallback onSubmit;

  /// Tooltip for the submit button.
  final String submitTooltip;

  /// Icon for the submit button.
  final IconData submitIcon;

  /// Called when the close button is tapped. If null, no close button shown.
  final VoidCallback? onClose;

  /// Called when the delete button is tapped. If null, no delete button shown.
  final VoidCallback? onDelete;

  /// Tooltip for the delete button.
  final String deleteTooltip;

  /// Tooltip for the close button.
  final String closeTooltip;

  /// Width of the handle bar.
  final double handleBarWidth;

  /// Border radius for the top corners.
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: handleBarWidth,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Action buttons row
          Container(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Delete button (if editing)
                if (onDelete != null)
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      color: colorScheme.error,
                    ),
                    tooltip: deleteTooltip,
                  ),
                const Spacer(),
                // Close button
                if (onClose != null)
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                    tooltip: closeTooltip,
                  ),
              ],
            ),
          ),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: child,
            ),
          ),

          // Sticky footer with submit button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  onPressed: onSubmit,
                  icon: Icon(submitIcon),
                  label: Text(submitTooltip),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
