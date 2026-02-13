import 'package:flutter/material.dart';

import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

class TasklyFormValueCard extends StatelessWidget {
  const TasklyFormValueCard({
    required this.title,
    required this.helperText,
    required this.icon,
    required this.iconColor,
    required this.hasValue,
    required this.onTap,
    super.key,
  });

  final String title;
  final String helperText;
  final IconData icon;
  final Color iconColor;
  final bool hasValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);
    final titleColor = hasValue ? scheme.onSurface : scheme.onSurfaceVariant;

    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceMd2,
            vertical: tokens.spaceMd,
          ),
          child: Row(
            children: [
              Container(
                width: tokens.spaceXl + tokens.spaceXs,
                height: tokens.spaceXl + tokens.spaceXs,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: tokens.spaceLg,
                  color: iconColor,
                ),
              ),
              SizedBox(width: tokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: tokens.spaceXxs),
                    Text(
                      helperText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
