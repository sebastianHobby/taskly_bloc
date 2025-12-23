import 'package:flutter/material.dart';

/// A modern section header widget for list views.
///
/// Features:
/// - Consistent styling across the app
/// - Optional trailing action
/// - Support for icons
/// - Proper Material 3 typography
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.icon,
    this.trailing,
    this.onTap,
    this.padding,
    super.key,
  });

  /// Creates a simple section header with just a title.
  const SectionHeader.simple({
    required this.title,
    super.key,
  }) : icon = null,
       trailing = null,
       onTap = null,
       padding = null;

  /// Creates a section header with an action button.
  factory SectionHeader.withAction({
    required String title,
    required String actionLabel,
    required VoidCallback onAction,
    IconData? icon,
    Key? key,
  }) {
    return SectionHeader(
      key: key,
      title: title,
      icon: icon,
      trailing: _SectionAction(label: actionLabel, onTap: onAction),
      onTap: onAction,
    );
  }

  /// The title text to display.
  final String title;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional trailing widget (e.g., action button or count badge).
  final Widget? trailing;

  /// Callback when the header is tapped.
  final VoidCallback? onTap;

  /// Custom padding. Defaults to `EdgeInsets.fromLTRB(16, 20, 16, 8)`.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final content = Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ?trailing,
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: content,
        ),
      );
    }

    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: content,
    );
  }
}

/// A styled action button for section headers.
class _SectionAction extends StatelessWidget {
  const _SectionAction({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// A count badge for section headers.
class SectionCountBadge extends StatelessWidget {
  const SectionCountBadge({
    required this.count,
    super.key,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
