import 'package:flutter/material.dart';

import 'package:taskly_ui/src/foundations/theme/taskly_semantic_themes.dart';

class TasklyCardSurface extends StatelessWidget {
  const TasklyCardSurface({
    required this.child,
    this.variant = TasklyCardVariant.summary,
    this.padding,
    this.borderRadius,
    this.margin,
    super.key,
  });

  final Widget child;
  final TasklyCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final cardTheme = TasklyCardTheme.of(context);
    final resolvedRadius =
        borderRadius ?? BorderRadius.circular(cardTheme.radius(variant));

    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: cardTheme.surface(variant),
        borderRadius: resolvedRadius,
        border: Border.all(color: cardTheme.border(variant)),
        boxShadow: [
          BoxShadow(
            color: cardTheme.shadowColor,
            blurRadius: cardTheme.shadowBlur(variant),
            offset: cardTheme.shadowOffset(variant),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? cardTheme.padding(variant),
        child: child,
      ),
    );

    if (margin == null) return content;
    return Padding(padding: margin!, child: content);
  }
}
