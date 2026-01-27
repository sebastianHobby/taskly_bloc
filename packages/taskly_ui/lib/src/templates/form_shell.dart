import 'package:flutter/material.dart';

import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';
import 'package:taskly_ui/src/primitives/modal_chrome_scope.dart';

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
    required this.deleteTooltip,
    required this.closeTooltip,
    this.onClose,
    this.onDelete,
    this.headerTitle,
    this.centerHeaderTitle = false,
    this.leadingActions = const <Widget>[],
    this.trailingActions = const <Widget>[],
    this.scrollController,
    this.submitIcon = Icons.check,
    this.submitEnabled = true,
    this.showHeaderSubmit = false,
    this.showFooterSubmit = true,
    this.closeOnLeft = false,
    this.handleBarWidth = 40.0,
    this.borderRadius = 20.0,
    this.showHandleBar,
    super.key,
  });

  /// The form content to display.
  final Widget child;

  /// Called when the submit button is tapped.
  final VoidCallback onSubmit;

  /// Tooltip for the submit button.
  final String submitTooltip;

  /// Tooltip for the delete button.
  ///
  /// Must be provided by the caller (no app l10n inside taskly_ui).
  final String deleteTooltip;

  /// Tooltip for the close button.
  ///
  /// Must be provided by the caller (no app l10n inside taskly_ui).
  final String closeTooltip;

  /// Icon for the submit button.
  final IconData submitIcon;

  /// Whether the submit button(s) are enabled.
  ///
  /// When false, submit buttons render disabled and do not call [onSubmit].
  final bool submitEnabled;

  /// Whether to show a submit button in the header row.
  ///
  /// Defaults to false to preserve legacy behavior.
  final bool showHeaderSubmit;

  /// Whether to show the submit button in the sticky footer.
  ///
  /// Defaults to true to preserve legacy behavior.
  final bool showFooterSubmit;

  /// When true, renders the close button on the left side of the header.
  ///
  /// Defaults to false to preserve legacy behavior.
  final bool closeOnLeft;

  /// Called when the close button is tapped. If null, no close button shown.
  final VoidCallback? onClose;

  /// Called when the delete button is tapped. If null, no delete button shown.
  final VoidCallback? onDelete;

  /// Optional title widget to render in the header row.
  final Widget? headerTitle;

  /// When true, keeps [headerTitle] centered regardless of action widths.
  final bool centerHeaderTitle;

  /// Additional action widgets to render on the left side of the header row.
  ///
  /// Rendered after the built-in delete button (if present).
  final List<Widget> leadingActions;

  /// Additional action widgets to render on the right side of the header row.
  ///
  /// Rendered before the built-in close button (if present).
  final List<Widget> trailingActions;

  /// Optional scroll controller for the scrollable content area.
  final ScrollController? scrollController;

  /// Width of the handle bar.
  final double handleBarWidth;

  /// Border radius for the top corners.
  final double borderRadius;

  /// Whether to show the handle bar at the top of the form.
  ///
  /// When null (default), the handle bar is shown only on compact screens and
  /// only when the surrounding modal container does not already render a drag
  /// handle.
  final bool? showHandleBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    final modalChrome = ModalChromeScope.maybeOf(context);
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final resolvedShowHandleBar =
        showHandleBar ??
        (isCompact && !(modalChrome?.modalHasDragHandle ?? false));

    final resolvedLeadingActions = <Widget>[
      if (closeOnLeft && onClose != null)
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close),
          tooltip: closeTooltip,
        ),
      if (onDelete != null)
        IconButton(
          onPressed: onDelete,
          icon: Icon(
            Icons.delete_outline,
            color: colorScheme.error,
          ),
          tooltip: deleteTooltip,
        ),
      ...leadingActions,
    ];

    final resolvedTrailingActions = <Widget>[
      ...trailingActions,
      if (showHeaderSubmit)
        IconButton(
          onPressed: submitEnabled ? onSubmit : null,
          icon: Icon(submitIcon),
          tooltip: submitTooltip,
        ),
      if (onClose != null)
        if (!closeOnLeft)
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            tooltip: closeTooltip,
          ),
    ];
    final headerRow = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ...resolvedLeadingActions,
        const Spacer(),
        ...resolvedTrailingActions,
      ],
    );
    final headerContent = headerTitle == null
        ? headerRow
        : centerHeaderTitle
        ? Stack(
            alignment: Alignment.center,
            children: [
              headerRow,
              Center(child: headerTitle),
            ],
          )
        : Row(
            children: [
              ...resolvedLeadingActions,
              SizedBox(width: tokens.spaceMd),
              headerTitle!,
              const Spacer(),
              ...resolvedTrailingActions,
            ],
          );

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (resolvedShowHandleBar)
            Container(
              width: handleBarWidth,
              height: tokens.spaceXs,
              margin: EdgeInsets.only(top: tokens.spaceMd),
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(tokens.radiusXxs),
              ),
            ),

          // Action buttons row
          Container(
            padding: EdgeInsets.fromLTRB(
              tokens.spaceSm,
              tokens.spaceXs,
              tokens.spaceSm,
              0,
            ),
            child: headerContent,
          ),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg3),
              child: child,
            ),
          ),

          if (showFooterSubmit)
            Container(
              padding: EdgeInsets.fromLTRB(
                tokens.spaceLg3,
                tokens.spaceMd,
                tokens.spaceLg3,
                tokens.spaceLg3,
              ),
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
                    onPressed: submitEnabled ? onSubmit : null,
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
