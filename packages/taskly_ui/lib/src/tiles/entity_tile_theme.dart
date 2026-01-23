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
    required this.cardBorderColor,
    required this.cardSurfaceColor,
    required this.cardShadowColor,
    required this.cardShadowBlur,
    required this.cardShadowOffset,
    required this.taskTitle,
    required this.projectTitle,
    required this.projectHeaderTitle,
    required this.subtitle,
    required this.chipText,
    required this.chipPadding,
    required this.chipRadius,
    required this.priorityBadge,
    required this.badgePadding,
    required this.badgeRadius,
    required this.metaLabelCaps,
    required this.metaValue,
    required this.progressHeight,
    required this.progressTrackColor,
    required this.progressFillColor,
    required this.progressRingSize,
    required this.progressRingStroke,
    required this.checkboxSize,
    required this.checkboxCheckedFill,
    required this.rowGap,
    required this.sectionPaddingH,
  });

  factory TasklyEntityTileTheme.fromTheme(ThemeData theme) {
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;

    TextStyle base(TextStyle? s) => s ?? const TextStyle();

    return TasklyEntityTileTheme(
      taskRadius: 12,
      projectRadius: 16,
      taskPadding: const EdgeInsets.all(12),
      projectPadding: const EdgeInsets.all(14),
      cardBorderColor: scheme.outlineVariant.withValues(alpha: 0.6),
      cardSurfaceColor: scheme.surface,
      cardShadowColor: scheme.shadow.withValues(alpha: 0.06),
      cardShadowBlur: 6,
      cardShadowOffset: const Offset(0, 2),
      taskTitle: base(textTheme.titleSmall).copyWith(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        height: 1.15,
        letterSpacing: -0.1,
      ),
      projectTitle: base(textTheme.titleMedium).copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
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
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      chipText: base(textTheme.labelSmall).copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
      chipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      chipRadius: 8,
      priorityBadge: base(textTheme.labelSmall).copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
      badgePadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      badgeRadius: 6,
      metaLabelCaps: base(textTheme.labelSmall).copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
      metaValue: base(textTheme.labelSmall).copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ),
      progressHeight: 5,
      progressTrackColor: scheme.surfaceContainerHighest,
      progressFillColor: scheme.primary,
      progressRingSize: 40,
      progressRingStroke: 3,
      checkboxSize: 20,
      checkboxCheckedFill: scheme.primary,
      rowGap: 8,
      sectionPaddingH: 16,
    );
  }

  factory TasklyEntityTileTheme.of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<TasklyEntityTileTheme>() ??
        TasklyEntityTileTheme.fromTheme(theme);
  }

  final double taskRadius;
  final double projectRadius;

  final EdgeInsets taskPadding;
  final EdgeInsets projectPadding;

  final Color cardBorderColor;
  final Color cardSurfaceColor;
  final Color cardShadowColor;
  final double cardShadowBlur;
  final Offset cardShadowOffset;

  final TextStyle taskTitle;
  final TextStyle projectTitle;
  final TextStyle projectHeaderTitle;
  final TextStyle subtitle;

  final TextStyle chipText;
  final EdgeInsets chipPadding;
  final double chipRadius;
  final TextStyle priorityBadge;
  final EdgeInsets badgePadding;
  final double badgeRadius;

  final TextStyle metaLabelCaps;
  final TextStyle metaValue;

  final double progressHeight;
  final Color progressTrackColor;
  final Color progressFillColor;
  final double progressRingSize;
  final double progressRingStroke;

  final double checkboxSize;
  final Color checkboxCheckedFill;

  final double rowGap;
  final double sectionPaddingH;

  @override
  TasklyEntityTileTheme copyWith({
    double? taskRadius,
    double? projectRadius,
    EdgeInsets? taskPadding,
    EdgeInsets? projectPadding,
    Color? cardBorderColor,
    Color? cardSurfaceColor,
    Color? cardShadowColor,
    double? cardShadowBlur,
    Offset? cardShadowOffset,
    TextStyle? taskTitle,
    TextStyle? projectTitle,
    TextStyle? projectHeaderTitle,
    TextStyle? subtitle,
    TextStyle? chipText,
    EdgeInsets? chipPadding,
    double? chipRadius,
    TextStyle? priorityBadge,
    EdgeInsets? badgePadding,
    double? badgeRadius,
    TextStyle? metaLabelCaps,
    TextStyle? metaValue,
    double? progressHeight,
    Color? progressTrackColor,
    Color? progressFillColor,
    double? progressRingSize,
    double? progressRingStroke,
    double? checkboxSize,
    Color? checkboxCheckedFill,
    double? rowGap,
    double? sectionPaddingH,
  }) {
    return TasklyEntityTileTheme(
      taskRadius: taskRadius ?? this.taskRadius,
      projectRadius: projectRadius ?? this.projectRadius,
      taskPadding: taskPadding ?? this.taskPadding,
      projectPadding: projectPadding ?? this.projectPadding,
      cardBorderColor: cardBorderColor ?? this.cardBorderColor,
      cardSurfaceColor: cardSurfaceColor ?? this.cardSurfaceColor,
      cardShadowColor: cardShadowColor ?? this.cardShadowColor,
      cardShadowBlur: cardShadowBlur ?? this.cardShadowBlur,
      cardShadowOffset: cardShadowOffset ?? this.cardShadowOffset,
      taskTitle: taskTitle ?? this.taskTitle,
      projectTitle: projectTitle ?? this.projectTitle,
      projectHeaderTitle: projectHeaderTitle ?? this.projectHeaderTitle,
      subtitle: subtitle ?? this.subtitle,
      chipText: chipText ?? this.chipText,
      chipPadding: chipPadding ?? this.chipPadding,
      chipRadius: chipRadius ?? this.chipRadius,
      priorityBadge: priorityBadge ?? this.priorityBadge,
      badgePadding: badgePadding ?? this.badgePadding,
      badgeRadius: badgeRadius ?? this.badgeRadius,
      metaLabelCaps: metaLabelCaps ?? this.metaLabelCaps,
      metaValue: metaValue ?? this.metaValue,
      progressHeight: progressHeight ?? this.progressHeight,
      progressTrackColor: progressTrackColor ?? this.progressTrackColor,
      progressFillColor: progressFillColor ?? this.progressFillColor,
      progressRingSize: progressRingSize ?? this.progressRingSize,
      progressRingStroke: progressRingStroke ?? this.progressRingStroke,
      checkboxSize: checkboxSize ?? this.checkboxSize,
      checkboxCheckedFill: checkboxCheckedFill ?? this.checkboxCheckedFill,
      rowGap: rowGap ?? this.rowGap,
      sectionPaddingH: sectionPaddingH ?? this.sectionPaddingH,
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
      cardBorderColor:
          Color.lerp(cardBorderColor, other.cardBorderColor, t) ??
          cardBorderColor,
      cardSurfaceColor:
          Color.lerp(cardSurfaceColor, other.cardSurfaceColor, t) ??
          cardSurfaceColor,
      cardShadowColor:
          Color.lerp(cardShadowColor, other.cardShadowColor, t) ??
          cardShadowColor,
      cardShadowBlur:
          lerpDouble(cardShadowBlur, other.cardShadowBlur, t) ??
          cardShadowBlur,
      cardShadowOffset:
          Offset.lerp(cardShadowOffset, other.cardShadowOffset, t) ??
          cardShadowOffset,
      taskTitle: TextStyle.lerp(taskTitle, other.taskTitle, t) ?? taskTitle,
      projectTitle:
          TextStyle.lerp(projectTitle, other.projectTitle, t) ?? projectTitle,
      projectHeaderTitle:
          TextStyle.lerp(projectHeaderTitle, other.projectHeaderTitle, t) ??
          projectHeaderTitle,
      subtitle: TextStyle.lerp(subtitle, other.subtitle, t) ?? subtitle,
      chipText: TextStyle.lerp(chipText, other.chipText, t) ?? chipText,
      chipPadding:
          EdgeInsets.lerp(chipPadding, other.chipPadding, t) ?? chipPadding,
      chipRadius: lerpDouble(chipRadius, other.chipRadius, t) ?? chipRadius,
      priorityBadge:
          TextStyle.lerp(priorityBadge, other.priorityBadge, t) ??
          priorityBadge,
      badgePadding:
          EdgeInsets.lerp(badgePadding, other.badgePadding, t) ?? badgePadding,
      badgeRadius:
          lerpDouble(badgeRadius, other.badgeRadius, t) ?? badgeRadius,
      metaLabelCaps:
          TextStyle.lerp(metaLabelCaps, other.metaLabelCaps, t) ??
          metaLabelCaps,
      metaValue: TextStyle.lerp(metaValue, other.metaValue, t) ?? metaValue,
      progressHeight:
          lerpDouble(progressHeight, other.progressHeight, t) ??
          progressHeight,
      progressTrackColor:
          Color.lerp(progressTrackColor, other.progressTrackColor, t) ??
          progressTrackColor,
      progressFillColor:
          Color.lerp(progressFillColor, other.progressFillColor, t) ??
          progressFillColor,
      progressRingSize:
          lerpDouble(progressRingSize, other.progressRingSize, t) ??
          progressRingSize,
      progressRingStroke:
          lerpDouble(progressRingStroke, other.progressRingStroke, t) ??
          progressRingStroke,
      checkboxSize:
          lerpDouble(checkboxSize, other.checkboxSize, t) ?? checkboxSize,
      checkboxCheckedFill:
          Color.lerp(checkboxCheckedFill, other.checkboxCheckedFill, t) ??
          checkboxCheckedFill,
      rowGap: lerpDouble(rowGap, other.rowGap, t) ?? rowGap,
      sectionPaddingH:
          lerpDouble(sectionPaddingH, other.sectionPaddingH, t) ??
          sectionPaddingH,
    );
  }
}
