import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/theme/app_theme.dart';

class TasklyCard extends StatelessWidget {
  const TasklyCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.isUrgent = false,
    this.borderRadius = 16,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool isUrgent;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasklyTheme = theme.extension<TasklyDesignExtension>();

    final effectiveBgColor = backgroundColor ?? theme.cardColor;
    final effectiveBorderColor = isUrgent
        ? theme.colorScheme.error
        : (borderColor ??
              tasklyTheme?.glassBorder ??
              theme.colorScheme.outlineVariant.withOpacity(0.5));

    return Container(
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: effectiveBorderColor),
        boxShadow: isUrgent
            ? [
                BoxShadow(
                  color: theme.colorScheme.error.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
