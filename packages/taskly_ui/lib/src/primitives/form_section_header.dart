import 'package:flutter/material.dart';

/// A reusable section header widget for organizing form fields.
///
/// Displays an icon and title with consistent styling for form sections.
class FormSectionHeader extends StatelessWidget {
  const FormSectionHeader({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  /// Icon to display before the title.
  final IconData icon;

  /// Section title text.
  final String title;

  /// Optional subtitle text.
  final String? subtitle;

  /// Optional trailing widget.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
