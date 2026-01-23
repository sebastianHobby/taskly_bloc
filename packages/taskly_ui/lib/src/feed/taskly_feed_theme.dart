import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Design tokens for feed layout and section typography.
@immutable
class TasklyFeedTheme extends ThemeExtension<TasklyFeedTheme> {
  const TasklyFeedTheme({
    required this.rowIndent,
    required this.entityRowSpacing,
    required this.sectionSpacing,
    required this.scheduledDayTitle,
    required this.scheduledDayCount,
    required this.scheduledOverdueCount,
    required this.valueHeaderCount,
  });

  factory TasklyFeedTheme.fromTheme(ThemeData theme) {
    final textTheme = theme.textTheme;
    TextStyle base(TextStyle? s) => s ?? const TextStyle();

    return TasklyFeedTheme(
      rowIndent: 10,
      entityRowSpacing: 10,
      sectionSpacing: 20,
      scheduledDayTitle: base(textTheme.titleMedium).copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.05,
      ),
      scheduledDayCount: base(textTheme.labelSmall).copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      scheduledOverdueCount: base(textTheme.labelSmall).copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      valueHeaderCount: base(textTheme.labelSmall).copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }

  factory TasklyFeedTheme.of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<TasklyFeedTheme>() ?? TasklyFeedTheme.fromTheme(theme);
  }

  final double rowIndent;
  final double entityRowSpacing;
  final double sectionSpacing;

  final TextStyle scheduledDayTitle;
  final TextStyle scheduledDayCount;
  final TextStyle scheduledOverdueCount;
  final TextStyle valueHeaderCount;

  @override
  TasklyFeedTheme copyWith({
    double? rowIndent,
    double? entityRowSpacing,
    double? sectionSpacing,
    TextStyle? scheduledDayTitle,
    TextStyle? scheduledDayCount,
    TextStyle? scheduledOverdueCount,
    TextStyle? valueHeaderCount,
  }) {
    return TasklyFeedTheme(
      rowIndent: rowIndent ?? this.rowIndent,
      entityRowSpacing: entityRowSpacing ?? this.entityRowSpacing,
      sectionSpacing: sectionSpacing ?? this.sectionSpacing,
      scheduledDayTitle: scheduledDayTitle ?? this.scheduledDayTitle,
      scheduledDayCount: scheduledDayCount ?? this.scheduledDayCount,
      scheduledOverdueCount:
          scheduledOverdueCount ?? this.scheduledOverdueCount,
      valueHeaderCount: valueHeaderCount ?? this.valueHeaderCount,
    );
  }

  @override
  TasklyFeedTheme lerp(ThemeExtension<TasklyFeedTheme>? other, double t) {
    if (other is! TasklyFeedTheme) return this;

    return TasklyFeedTheme(
      rowIndent: lerpDouble(rowIndent, other.rowIndent, t) ?? rowIndent,
      entityRowSpacing:
          lerpDouble(entityRowSpacing, other.entityRowSpacing, t) ??
          entityRowSpacing,
      sectionSpacing:
          lerpDouble(sectionSpacing, other.sectionSpacing, t) ?? sectionSpacing,
      scheduledDayTitle:
          TextStyle.lerp(scheduledDayTitle, other.scheduledDayTitle, t) ??
          scheduledDayTitle,
      scheduledDayCount:
          TextStyle.lerp(scheduledDayCount, other.scheduledDayCount, t) ??
          scheduledDayCount,
      scheduledOverdueCount:
          TextStyle.lerp(
            scheduledOverdueCount,
            other.scheduledOverdueCount,
            t,
          ) ??
          scheduledOverdueCount,
      valueHeaderCount:
          TextStyle.lerp(valueHeaderCount, other.valueHeaderCount, t) ??
          valueHeaderCount,
    );
  }
}
