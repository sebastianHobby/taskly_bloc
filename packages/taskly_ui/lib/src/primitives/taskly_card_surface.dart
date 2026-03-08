import 'package:flutter/material.dart';

import 'package:taskly_ui/src/foundations/theme/taskly_semantic_themes.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

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
    final tokens = TasklyTokens.of(context);

    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: cardTheme.surface(variant),
        borderRadius: borderRadius ?? BorderRadius.circular(tokens.radiusMd2),
        border: Border.all(color: cardTheme.border(variant)),
        boxShadow: [
          BoxShadow(
            color: cardTheme.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(tokens.spaceMd),
        child: child,
      ),
    );

    if (margin == null) return content;
    return Padding(padding: margin!, child: content);
  }
}
