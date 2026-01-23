import 'package:flutter/material.dart';

@immutable
final class TasklyScheduledOverdueModel {
  const TasklyScheduledOverdueModel({
    required this.title,
    required this.countLabel,
    required this.isCollapsed,
    required this.onToggleCollapsed,
    required this.children,
    this.actionLabel,
    this.actionTooltip,
    this.onActionPressed,
  });

  final String title;
  final String countLabel;

  final bool isCollapsed;
  final VoidCallback? onToggleCollapsed;

  /// Canonical entity tiles for overdue items.
  ///
  /// When collapsed, only the first 3 are shown.
  final List<Widget> children;

  final String? actionLabel;
  final String? actionTooltip;
  final VoidCallback? onActionPressed;
}

/// Stitch-aligned overdue stack block, kept as a first-class section.
///
/// This section intentionally composes canonical entity tiles rather than
/// rendering bespoke "overdue cards", to preserve a single tile system.
class TasklyScheduledOverdueSection extends StatelessWidget {
  const TasklyScheduledOverdueSection({required this.model, super.key});

  final TasklyScheduledOverdueModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final actionLabel = model.actionLabel?.trim();
    final hasAction =
        actionLabel != null &&
        actionLabel.isNotEmpty &&
        model.onActionPressed != null;

    final visibleChildren = model.isCollapsed
        ? model.children.take(3).toList(growable: false)
        : model.children;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Material(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: model.onToggleCollapsed,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        model.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (hasAction)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Tooltip(
                          message: model.actionTooltip ?? actionLabel,
                          child: TextButton.icon(
                            onPressed: model.onActionPressed,
                            icon: const Icon(Icons.event, size: 18),
                            label: Text(actionLabel),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        model.countLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      model.isCollapsed
                          ? Icons.expand_more_rounded
                          : Icons.expand_less_rounded,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              ),
            ),
            if (!model.isCollapsed || model.children.isNotEmpty) ...[
              if (visibleChildren.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Text(
                    'Nothing overdue',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Column(
                    children: [
                      for (final c in visibleChildren)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: c,
                        ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
