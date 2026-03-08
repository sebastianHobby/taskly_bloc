import 'package:flutter/material.dart';

import 'package:taskly_ui/src/foundations/theme/taskly_semantic_themes.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

class TasklySheetChrome extends StatelessWidget {
  const TasklySheetChrome({
    required this.child,
    this.variant = TasklySheetVariant.standard,
    this.padding,
    this.borderRadius,
    super.key,
  });

  final Widget child;
  final TasklySheetVariant variant;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final sheetTheme = TasklySheetTheme.of(context);
    final tokens = TasklyTokens.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: sheetTheme.background(variant),
        borderRadius:
            borderRadius ??
            BorderRadius.vertical(top: Radius.circular(tokens.radiusXxl)),
        border: Border.all(color: sheetTheme.border(variant)),
        boxShadow: [
          BoxShadow(
            color: sheetTheme.shadowColor,
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: child,
      ),
    );
  }
}
