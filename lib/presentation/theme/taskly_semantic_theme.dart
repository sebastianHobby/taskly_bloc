import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class TasklyAppChromeTheme extends ThemeExtension<TasklyAppChromeTheme> {
  const TasklyAppChromeTheme({
    required this.navigationSurface,
    required this.navigationIndicator,
    required this.navigationDivider,
    required this.iconButtonBackground,
    required this.iconButtonForeground,
    required this.brandForeground,
  });

  factory TasklyAppChromeTheme.fromTheme(ThemeData theme) {
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.fromTheme(theme);
    return TasklyAppChromeTheme(
      navigationSurface: scheme.surfaceContainerLow,
      navigationIndicator: scheme.primaryContainer,
      navigationDivider: scheme.outlineVariant.withValues(alpha: 0.5),
      iconButtonBackground: scheme.surfaceContainerHighest.withValues(
        alpha: tokens.iconButtonBackgroundAlpha,
      ),
      iconButtonForeground: scheme.onSurface,
      brandForeground: scheme.primary,
    );
  }

  factory TasklyAppChromeTheme.of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<TasklyAppChromeTheme>() ??
        TasklyAppChromeTheme.fromTheme(theme);
  }

  final Color navigationSurface;
  final Color navigationIndicator;
  final Color navigationDivider;
  final Color iconButtonBackground;
  final Color iconButtonForeground;
  final Color brandForeground;

  @override
  TasklyAppChromeTheme copyWith({
    Color? navigationSurface,
    Color? navigationIndicator,
    Color? navigationDivider,
    Color? iconButtonBackground,
    Color? iconButtonForeground,
    Color? brandForeground,
  }) {
    return TasklyAppChromeTheme(
      navigationSurface: navigationSurface ?? this.navigationSurface,
      navigationIndicator: navigationIndicator ?? this.navigationIndicator,
      navigationDivider: navigationDivider ?? this.navigationDivider,
      iconButtonBackground: iconButtonBackground ?? this.iconButtonBackground,
      iconButtonForeground: iconButtonForeground ?? this.iconButtonForeground,
      brandForeground: brandForeground ?? this.brandForeground,
    );
  }

  @override
  TasklyAppChromeTheme lerp(
    ThemeExtension<TasklyAppChromeTheme>? other,
    double t,
  ) {
    if (other is! TasklyAppChromeTheme) return this;
    return TasklyAppChromeTheme(
      navigationSurface: Color.lerp(
        navigationSurface,
        other.navigationSurface,
        t,
      )!,
      navigationIndicator: Color.lerp(
        navigationIndicator,
        other.navigationIndicator,
        t,
      )!,
      navigationDivider: Color.lerp(
        navigationDivider,
        other.navigationDivider,
        t,
      )!,
      iconButtonBackground: Color.lerp(
        iconButtonBackground,
        other.iconButtonBackground,
        t,
      )!,
      iconButtonForeground: Color.lerp(
        iconButtonForeground,
        other.iconButtonForeground,
        t,
      )!,
      brandForeground: Color.lerp(brandForeground, other.brandForeground, t)!,
    );
  }
}

class TasklyPageHeaderTheme extends ThemeExtension<TasklyPageHeaderTheme> {
  const TasklyPageHeaderTheme({
    required this.padding,
    required this.iconSize,
    required this.iconColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.titleFontWeight,
    required this.chipBackground,
    required this.chipForeground,
  });

  factory TasklyPageHeaderTheme.fromTheme(ThemeData theme) {
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.fromTheme(theme);
    return TasklyPageHeaderTheme(
      padding: EdgeInsets.fromLTRB(
        tokens.sectionPaddingH,
        tokens.spaceMd,
        tokens.sectionPaddingH,
        tokens.spaceSm,
      ),
      iconSize: tokens.spaceLg3,
      iconColor: scheme.primary,
      titleColor: scheme.onSurface,
      subtitleColor: scheme.onSurfaceVariant,
      titleFontWeight: FontWeight.w800,
      chipBackground: scheme.surfaceContainerHighest,
      chipForeground: scheme.onSurface,
    );
  }

  factory TasklyPageHeaderTheme.of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<TasklyPageHeaderTheme>() ??
        TasklyPageHeaderTheme.fromTheme(theme);
  }

  final EdgeInsets padding;
  final double iconSize;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;
  final FontWeight titleFontWeight;
  final Color chipBackground;
  final Color chipForeground;

  @override
  TasklyPageHeaderTheme copyWith({
    EdgeInsets? padding,
    double? iconSize,
    Color? iconColor,
    Color? titleColor,
    Color? subtitleColor,
    FontWeight? titleFontWeight,
    Color? chipBackground,
    Color? chipForeground,
  }) {
    return TasklyPageHeaderTheme(
      padding: padding ?? this.padding,
      iconSize: iconSize ?? this.iconSize,
      iconColor: iconColor ?? this.iconColor,
      titleColor: titleColor ?? this.titleColor,
      subtitleColor: subtitleColor ?? this.subtitleColor,
      titleFontWeight: titleFontWeight ?? this.titleFontWeight,
      chipBackground: chipBackground ?? this.chipBackground,
      chipForeground: chipForeground ?? this.chipForeground,
    );
  }

  @override
  TasklyPageHeaderTheme lerp(
    ThemeExtension<TasklyPageHeaderTheme>? other,
    double t,
  ) {
    if (other is! TasklyPageHeaderTheme) return this;
    return TasklyPageHeaderTheme(
      padding: EdgeInsets.lerp(padding, other.padding, t) ?? padding,
      iconSize: lerpDouble(iconSize, other.iconSize, t) ?? iconSize,
      iconColor: Color.lerp(iconColor, other.iconColor, t)!,
      titleColor: Color.lerp(titleColor, other.titleColor, t)!,
      subtitleColor: Color.lerp(subtitleColor, other.subtitleColor, t)!,
      titleFontWeight: t < 0.5 ? titleFontWeight : other.titleFontWeight,
      chipBackground: Color.lerp(chipBackground, other.chipBackground, t)!,
      chipForeground: Color.lerp(chipForeground, other.chipForeground, t)!,
    );
  }
}

class TasklyPanelTheme extends ThemeExtension<TasklyPanelTheme> {
  const TasklyPanelTheme({
    required this.subtleSurface,
    required this.emphasizedSurface,
    required this.border,
    required this.mutedBorder,
    required this.gradientStart,
    required this.gradientEnd,
    required this.softShadow,
    required this.primaryTint,
  });

  factory TasklyPanelTheme.fromTheme(ThemeData theme) {
    final scheme = theme.colorScheme;
    return TasklyPanelTheme(
      subtleSurface: scheme.surfaceContainerLow,
      emphasizedSurface: scheme.surfaceContainerHighest,
      border: scheme.outlineVariant,
      mutedBorder: scheme.outlineVariant.withValues(alpha: 0.5),
      gradientStart: scheme.surface,
      gradientEnd: scheme.surfaceContainerLow,
      softShadow: scheme.shadow.withValues(alpha: 0.06),
      primaryTint: scheme.primaryContainer,
    );
  }

  factory TasklyPanelTheme.of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<TasklyPanelTheme>() ??
        TasklyPanelTheme.fromTheme(theme);
  }

  final Color subtleSurface;
  final Color emphasizedSurface;
  final Color border;
  final Color mutedBorder;
  final Color gradientStart;
  final Color gradientEnd;
  final Color softShadow;
  final Color primaryTint;

  @override
  TasklyPanelTheme copyWith({
    Color? subtleSurface,
    Color? emphasizedSurface,
    Color? border,
    Color? mutedBorder,
    Color? gradientStart,
    Color? gradientEnd,
    Color? softShadow,
    Color? primaryTint,
  }) {
    return TasklyPanelTheme(
      subtleSurface: subtleSurface ?? this.subtleSurface,
      emphasizedSurface: emphasizedSurface ?? this.emphasizedSurface,
      border: border ?? this.border,
      mutedBorder: mutedBorder ?? this.mutedBorder,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      softShadow: softShadow ?? this.softShadow,
      primaryTint: primaryTint ?? this.primaryTint,
    );
  }

  @override
  TasklyPanelTheme lerp(ThemeExtension<TasklyPanelTheme>? other, double t) {
    if (other is! TasklyPanelTheme) return this;
    return TasklyPanelTheme(
      subtleSurface: Color.lerp(subtleSurface, other.subtleSurface, t)!,
      emphasizedSurface: Color.lerp(
        emphasizedSurface,
        other.emphasizedSurface,
        t,
      )!,
      border: Color.lerp(border, other.border, t)!,
      mutedBorder: Color.lerp(mutedBorder, other.mutedBorder, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      softShadow: Color.lerp(softShadow, other.softShadow, t)!,
      primaryTint: Color.lerp(primaryTint, other.primaryTint, t)!,
    );
  }
}
