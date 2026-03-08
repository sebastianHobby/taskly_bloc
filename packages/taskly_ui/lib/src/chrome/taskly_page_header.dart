import 'package:flutter/material.dart';
import 'package:taskly_ui/src/foundations/theme/taskly_semantic_themes.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';
import 'package:taskly_ui/src/primitives/taskly_chip.dart';

class TasklyPageHeader extends StatelessWidget {
  const TasklyPageHeader({
    required this.icon,
    required this.title,
    this.variant = TasklyHeaderVariant.screen,
    this.trailing,
    this.subtitle,
    this.footer,
    super.key,
  });

  final IconData icon;
  final String title;
  final TasklyHeaderVariant variant;
  final Widget? trailing;
  final String? subtitle;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = TasklyTokens.of(context);
    final headerTheme = TasklyPageHeaderTheme.of(context);
    final shouldDecorate = variant != TasklyHeaderVariant.compact;
    final content = Padding(
      padding: headerTheme.contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: headerTheme.iconSurface,
                  borderRadius: BorderRadius.circular(tokens.radiusMd),
                ),
                child: Padding(
                  padding: EdgeInsets.all(headerTheme.iconContainerPadding),
                  child: Icon(
                    icon,
                    color: headerTheme.iconColor,
                    size: headerTheme.iconSize,
                  ),
                ),
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
            SizedBox(height: tokens.spaceXs2),
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

    return Padding(
      padding: headerTheme.padding,
      child: DecoratedBox(
        decoration: shouldDecorate
            ? BoxDecoration(
                color: headerTheme.surface(variant),
                borderRadius: BorderRadius.circular(tokens.radiusLg),
                border: Border.all(color: headerTheme.border(variant)),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).shadowColor.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
            : const BoxDecoration(),
        child: content,
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
