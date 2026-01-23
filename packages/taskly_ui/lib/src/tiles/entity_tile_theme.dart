import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Design tokens for Taskly entity tiles (Task/Project).
///
/// This lives in `taskly_ui` so the canonical tiles can be pixel-consistent
/// while still deriving colors from the active Material theme.
@immutable
class TasklyEntityTileTheme extends ThemeExtension<TasklyEntityTileTheme> {
  const TasklyEntityTileTheme({
    required this.taskRadius,
    required this.projectRadius,
    required this.taskPadding,
    required this.projectPadding,
    required this.shadow,
    required this.taskTitle,
    required this.projectTitle,
    required this.projectHeaderTitle,
    required this.subtitle,
    required this.chipText,
    required this.priorityBadge,
    required this.metaLabelCaps,
    required this.metaValue,
  });

  factory TasklyEntityTileTheme.fallback(ThemeData theme) {
    final textTheme = theme.textTheme;

    TextStyle base(TextStyle? s) => s ?? const TextStyle();

    return TasklyEntityTileTheme(
      taskRadius: 12,
      projectRadius: 16,
      taskPadding: const EdgeInsets.all(12),
      projectPadding: const EdgeInsets.all(20),
      shadow: const BoxShadow(
        color: Color(0x0D000000),
        blurRadius: 8,
        spreadRadius: -2,
        offset: Offset(0, 2),
      ),
      taskTitle: base(textTheme.titleSmall).copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.1,
      ),
      projectTitle: base(textTheme.titleMedium).copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.1,
      ),
      // Used on large header-like project cards.
      projectHeaderTitle: base(textTheme.headlineSmall).copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        height: 1.1,
        letterSpacing: -0.3,
      ),
      subtitle: base(textTheme.bodySmall).copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
      chipText: base(textTheme.labelSmall).copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
      priorityBadge: base(textTheme.labelSmall).copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
      metaLabelCaps: base(textTheme.labelSmall).copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
      metaValue: base(textTheme.labelSmall).copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ),
    );
  }

  factory TasklyEntityTileTheme.of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<TasklyEntityTileTheme>() ??
        TasklyEntityTileTheme.fallback(theme);
  }

  final double taskRadius;
  final double projectRadius;

  final EdgeInsets taskPadding;
  final EdgeInsets projectPadding;

  final BoxShadow shadow;

  final TextStyle taskTitle;
  final TextStyle projectTitle;
  final TextStyle projectHeaderTitle;
  final TextStyle subtitle;

  final TextStyle chipText;
  final TextStyle priorityBadge;

  final TextStyle metaLabelCaps;
  final TextStyle metaValue;

  @override
  TasklyEntityTileTheme copyWith({
    double? taskRadius,
    double? projectRadius,
    EdgeInsets? taskPadding,
    EdgeInsets? projectPadding,
    BoxShadow? shadow,
    TextStyle? taskTitle,
    TextStyle? projectTitle,
    TextStyle? projectHeaderTitle,
    TextStyle? subtitle,
    TextStyle? chipText,
    TextStyle? priorityBadge,
    TextStyle? metaLabelCaps,
    TextStyle? metaValue,
  }) {
    return TasklyEntityTileTheme(
      taskRadius: taskRadius ?? this.taskRadius,
      projectRadius: projectRadius ?? this.projectRadius,
      taskPadding: taskPadding ?? this.taskPadding,
      projectPadding: projectPadding ?? this.projectPadding,
      shadow: shadow ?? this.shadow,
      taskTitle: taskTitle ?? this.taskTitle,
      projectTitle: projectTitle ?? this.projectTitle,
      projectHeaderTitle: projectHeaderTitle ?? this.projectHeaderTitle,
      subtitle: subtitle ?? this.subtitle,
      chipText: chipText ?? this.chipText,
      priorityBadge: priorityBadge ?? this.priorityBadge,
      metaLabelCaps: metaLabelCaps ?? this.metaLabelCaps,
      metaValue: metaValue ?? this.metaValue,
    );
  }

  @override
  TasklyEntityTileTheme lerp(
    ThemeExtension<TasklyEntityTileTheme>? other,
    double t,
  ) {
    if (other is! TasklyEntityTileTheme) return this;

    return TasklyEntityTileTheme(
      taskRadius: lerpDouble(taskRadius, other.taskRadius, t) ?? taskRadius,
      projectRadius:
          lerpDouble(projectRadius, other.projectRadius, t) ?? projectRadius,
      taskPadding:
          EdgeInsets.lerp(taskPadding, other.taskPadding, t) ?? taskPadding,
      projectPadding:
          EdgeInsets.lerp(projectPadding, other.projectPadding, t) ??
          projectPadding,
      shadow: BoxShadow.lerp(shadow, other.shadow, t) ?? shadow,
      taskTitle: TextStyle.lerp(taskTitle, other.taskTitle, t) ?? taskTitle,
      projectTitle:
          TextStyle.lerp(projectTitle, other.projectTitle, t) ?? projectTitle,
      projectHeaderTitle:
          TextStyle.lerp(projectHeaderTitle, other.projectHeaderTitle, t) ??
          projectHeaderTitle,
      subtitle: TextStyle.lerp(subtitle, other.subtitle, t) ?? subtitle,
      chipText: TextStyle.lerp(chipText, other.chipText, t) ?? chipText,
      priorityBadge:
          TextStyle.lerp(priorityBadge, other.priorityBadge, t) ??
          priorityBadge,
      metaLabelCaps:
          TextStyle.lerp(metaLabelCaps, other.metaLabelCaps, t) ??
          metaLabelCaps,
      metaValue: TextStyle.lerp(metaValue, other.metaValue, t) ?? metaValue,
    );
  }
}
