import 'package:flutter/material.dart';

/// A reusable empty state widget that displays an icon, title, and optional
/// description with a call-to-action button.
class EmptyStateWidget extends StatelessWidget {
  /// Creates an empty state widget.
  const EmptyStateWidget({
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
    super.key,
  });

  /// Creates an empty state for when there are no tasks.
  const EmptyStateWidget.noTasks({
    required String title,
    String? description,
    String? actionLabel,
    VoidCallback? onAction,
    Key? key,
  }) : this(
         icon: Icons.task_alt_outlined,
         title: title,
         description: description,
         actionLabel: actionLabel,
         onAction: onAction,
         key: key,
       );

  /// Creates an empty state for when there are no projects.
  const EmptyStateWidget.noProjects({
    required String title,
    String? description,
    String? actionLabel,
    VoidCallback? onAction,
    Key? key,
  }) : this(
         icon: Icons.folder_outlined,
         title: title,
         description: description,
         actionLabel: actionLabel,
         onAction: onAction,
         key: key,
       );

  /// Creates an empty state for today view.
  const EmptyStateWidget.today({
    required String title,
    String? description,
    Key? key,
  }) : this(
         icon: Icons.today_outlined,
         title: title,
         description: description,
         key: key,
       );

  /// Creates an empty state for upcoming view.
  const EmptyStateWidget.upcoming({
    required String title,
    String? description,
    Key? key,
  }) : this(
         icon: Icons.calendar_month_outlined,
         title: title,
         description: description,
         key: key,
       );

  /// Creates an empty state for when there are no labels.
  const EmptyStateWidget.noLabels({
    required String title,
    String? description,
    Key? key,
  }) : this(
         icon: Icons.label_outlined,
         title: title,
         description: description,
         key: key,
       );

  /// Creates an empty state for when there are no values.
  const EmptyStateWidget.noValues({
    required String title,
    String? description,
    Key? key,
  }) : this(
         icon: Icons.favorite_border,
         title: title,
         description: description,
         key: key,
       );

  /// The icon to display.
  final IconData icon;

  /// The title text to display.
  final String title;

  /// An optional description text.
  final String? description;

  /// The label for the optional action button.
  final String? actionLabel;

  /// Callback when the action button is pressed.
  final VoidCallback? onAction;

  /// The size of the icon.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize + 32,
              height: iconSize + 32,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
