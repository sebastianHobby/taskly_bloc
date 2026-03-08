import 'package:flutter/material.dart';
import 'package:taskly_ui/src/foundations/theme/taskly_semantic_themes.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';
import 'package:taskly_ui/src/primitives/taskly_card_surface.dart';
import 'package:taskly_ui/src/primitives/taskly_reveal.dart';

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

  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = TasklyTokens.of(context);
    final emptyTheme = TasklyEmptyStateTheme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceXxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: TasklyReveal(
            offset: TasklyMotionTheme.of(context).pageOffset,
            child: TasklyCardSurface(
              variant: TasklyCardVariant.subtle,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: iconSize + tokens.spaceXxl + tokens.spaceLg,
                    height: iconSize + tokens.spaceXxl + tokens.spaceLg,
                    decoration: BoxDecoration(
                      color: emptyTheme.haloSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: iconSize + tokens.spaceXxl,
                        height: iconSize + tokens.spaceXxl,
                        decoration: BoxDecoration(
                          color: emptyTheme.iconSurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: emptyTheme.panelBorder),
                          boxShadow: [
                            BoxShadow(
                              color: emptyTheme.panelShadow,
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                              spreadRadius: -8,
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          size: iconSize,
                          color: emptyTheme.iconColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: tokens.spaceXl),
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: emptyTheme.titleColor,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (description != null) ...[
                    SizedBox(height: tokens.spaceSm),
                    Text(
                      description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: emptyTheme.descriptionColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (actionLabel != null && onAction != null) ...[
                    SizedBox(height: tokens.spaceXl),
                    FilledButton.icon(
                      onPressed: onAction,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
