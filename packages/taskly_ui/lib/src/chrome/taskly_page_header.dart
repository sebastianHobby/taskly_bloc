import 'package:flutter/material.dart';
import 'package:taskly_ui/src/foundations/theme/taskly_semantic_themes.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';
import 'package:taskly_ui/src/primitives/taskly_chip.dart';

class TasklyPageHeader extends StatelessWidget {
  const TasklyPageHeader({
    required this.icon,
    required this.title,
    this.trailing,
    this.subtitle,
    this.footer,
    super.key,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final String? subtitle;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = TasklyTokens.of(context);
    final headerTheme = TasklyPageHeaderTheme.of(context);

    return Padding(
      padding: headerTheme.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: headerTheme.iconColor,
                size: headerTheme.iconSize,
              ),
              SizedBox(width: tokens.spaceSm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: headerTheme.titleColor,
                    fontWeight: headerTheme.titleFontWeight,
                  ),
                ),
              ),
              ...?((trailing == null) ? null : [trailing!]),
            ],
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            SizedBox(height: tokens.spaceXxs),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: headerTheme.subtitleColor,
              ),
            ),
          ],
          if (footer != null) ...[
            SizedBox(height: tokens.spaceSm),
            footer!,
          ],
        ],
      ),
    );
  }
}

class TasklyHeaderChip extends StatelessWidget {
  const TasklyHeaderChip({
    required this.label,
    this.variant = TasklyChipVariant.metric,
    super.key,
  });

  final String label;
  final TasklyChipVariant variant;

  @override
  Widget build(BuildContext context) {
    return TasklyChip(label: label, variant: variant);
  }
}
