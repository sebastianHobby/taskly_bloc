import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';
import 'package:taskly_bloc/presentation/theme/taskly_semantic_theme.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class TasklyPageHeader extends StatelessWidget {
  const TasklyPageHeader({
    required this.screenId,
    required this.title,
    this.trailing,
    this.subtitle,
    this.footer,
    super.key,
  });

  final String screenId;
  final String title;
  final Widget? trailing;
  final String? subtitle;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = TasklyTokens.of(context);
    final headerTheme = TasklyPageHeaderTheme.of(context);
    final iconSet = const NavigationIconResolver().resolve(
      screenId: screenId,
      iconName: null,
    );

    return Padding(
      padding: headerTheme.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                iconSet.selectedIcon,
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
    super.key,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final headerTheme = TasklyPageHeaderTheme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: headerTheme.chipBackground,
        borderRadius: BorderRadius.circular(tokens.radiusPill),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceSm2,
          vertical: tokens.spaceXs2,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: headerTheme.chipForeground,
          ),
        ),
      ),
    );
  }
}
