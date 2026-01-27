import 'package:flutter/material.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

enum TasklyBadgeStyle {
  solid,
  outline,
  softOutline,
}

class TasklyBadge extends StatelessWidget {
  const TasklyBadge({
    required this.label,
    required this.color,
    super.key,
    this.icon,
    this.style = TasklyBadgeStyle.solid,
    this.borderRadius,
  });
  final String label;
  final IconData? icon;
  final Color color;
  final TasklyBadgeStyle style;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final bool hasFill = style != TasklyBadgeStyle.outline;
    final bool hasBorder = style != TasklyBadgeStyle.solid;

    final double fillOpacity = switch (style) {
      TasklyBadgeStyle.solid => 0.10,
      TasklyBadgeStyle.softOutline => 0.06,
      TasklyBadgeStyle.outline => 0.0,
    };

    final double borderOpacity = switch (style) {
      TasklyBadgeStyle.solid => 0.0,
      TasklyBadgeStyle.softOutline => 0.55,
      TasklyBadgeStyle.outline => 1.0,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSm,
        vertical: tokens.spaceXs,
      ),
      decoration: BoxDecoration(
        color: hasFill ? color.withValues(alpha: fillOpacity) : null,
        borderRadius: borderRadius ?? BorderRadius.circular(tokens.radiusPill),
        border: hasBorder
            ? Border.all(color: color.withValues(alpha: borderOpacity))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            SizedBox(width: tokens.spaceXs),
          ],
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
