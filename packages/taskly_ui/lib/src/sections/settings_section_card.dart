import 'package:flutter/material.dart';

/// A card widget for grouping settings with a consistent header style.
///
/// Provides:
/// - Icon + title header row
/// - Optional description
/// - Consistent padding and spacing
/// - Card elevation and styling
class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    required this.title,
    required this.children,
    this.icon,
    this.description,
    this.padding,
    this.actions,
    super.key,
  });

  /// Section title text
  final String title;

  /// Optional leading icon
  final IconData? icon;

  /// Optional description text below title
  final String? description;

  /// Child widgets (form fields, tiles, etc.)
  final List<Widget> children;

  /// Custom padding (defaults to EdgeInsets.all(16))
  final EdgeInsetsGeometry? padding;

  /// Optional action widgets in the header row
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: colorScheme.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),

            // Description
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            // Content
            if (children.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...children,
            ],
          ],
        ),
      ),
    );
  }

  /// Creates a settings section with just a title (no card wrapper).
  ///
  /// Useful for top-level groupings in a settings page.
  static Widget header({
    required BuildContext context,
    required String title,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: colorScheme.primary, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// A divider with optional text label for separating settings groups.
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({
    this.label,
    this.padding,
    super.key,
  });

  /// Optional label text
  final String? label;

  /// Custom padding
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (label == null) {
      return Padding(
        padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
        child: const Divider(),
      );
    }

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
