import 'package:flutter/material.dart';
import 'package:taskly_ui/src/foundations/theme/taskly_semantic_themes.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';
import 'package:taskly_ui/src/primitives/taskly_chip.dart';
import 'package:taskly_ui/src/primitives/taskly_reveal.dart';

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
    final panelTheme = TasklyPanelTheme.of(context);
    final shouldDecorate = variant != TasklyHeaderVariant.compact;
    final titleStyle =
        switch (variant) {
          TasklyHeaderVariant.hero => theme.textTheme.headlineSmall,
          TasklyHeaderVariant.screen => theme.textTheme.titleLarge,
          TasklyHeaderVariant.section => theme.textTheme.titleMedium,
          TasklyHeaderVariant.compact => theme.textTheme.titleMedium,
        }?.copyWith(
          color: headerTheme.titleColor,
          fontWeight: headerTheme.titleFontWeight,
        );
    final subtitleStyle =
        switch (variant) {
          TasklyHeaderVariant.hero => theme.textTheme.bodyMedium,
          TasklyHeaderVariant.screen => theme.textTheme.bodyMedium,
          TasklyHeaderVariant.section => theme.textTheme.bodySmall,
          TasklyHeaderVariant.compact => theme.textTheme.bodySmall,
        }?.copyWith(
          color: headerTheme.subtitleColor,
        );
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
                  style: titleStyle,
                ),
              ),
              ...?((trailing == null) ? null : [trailing!]),
            ],
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            SizedBox(height: tokens.spaceXs2),
            Text(
              subtitle!,
              style: subtitleStyle,
            ),
          ],
          if (footer != null) ...[
            SizedBox(height: tokens.spaceSm),
            footer!,
          ],
        ],
      ),
    );

    return TasklyReveal(
      offset: TasklyMotionTheme.of(context).pageOffset,
      startScale: TasklyMotionTheme.of(context).pageScale,
      child: Padding(
        padding: headerTheme.padding,
        child: DecoratedBox(
          decoration: shouldDecorate
              ? BoxDecoration(
                  color: headerTheme.surface(variant),
                  borderRadius: BorderRadius.circular(tokens.radiusLg),
                  border: Border.all(color: headerTheme.border(variant)),
                  boxShadow: [
                    BoxShadow(
                      color: panelTheme.softShadow,
                      blurRadius: variant == TasklyHeaderVariant.hero ? 24 : 16,
                      offset: Offset(
                        0,
                        variant == TasklyHeaderVariant.hero ? 10 : 6,
                      ),
                    ),
                    if (variant != TasklyHeaderVariant.compact)
                      BoxShadow(
                        color: headerTheme.iconColor.withValues(
                          alpha: variant == TasklyHeaderVariant.hero
                              ? 0.08
                              : 0.04,
                        ),
                        blurRadius: variant == TasklyHeaderVariant.hero
                            ? 26
                            : 18,
                        offset: const Offset(0, 2),
                        spreadRadius: -6,
                      ),
                  ],
                )
              : const BoxDecoration(),
          child: content,
        ),
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
