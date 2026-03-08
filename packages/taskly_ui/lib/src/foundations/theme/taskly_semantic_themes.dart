// ignore_for_file: prefer_constructors_over_static_methods

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

enum TasklyCardVariant {
  summary,
  insight,
  maintenance,
  editor,
  subtle,
}

enum TasklyChipVariant {
  filter,
  metric,
  status,
  selection,
}

enum TasklySheetVariant {
  standard,
  editor,
  supporting,
}

enum TasklyHeaderVariant {
  screen,
  section,
  hero,
  compact,
}

enum TasklyEntityRowChromeVariant {
  standard,
  compact,
  highlighted,
  bulkSelection,
}

class TasklyMotionTheme extends ThemeExtension<TasklyMotionTheme> {
  const TasklyMotionTheme({
    required this.shortDuration,
    required this.mediumDuration,
    required this.longDuration,
    required this.standardCurve,
    required this.emphasizedCurve,
    required this.exitCurve,
    required this.pageOffset,
    required this.sectionOffset,
    required this.sheetOffset,
    required this.pageScale,
    required this.sheetScale,
  });

  factory TasklyMotionTheme.fromTheme(ThemeData _) {
    return const TasklyMotionTheme(
      shortDuration: Duration(milliseconds: 180),
      mediumDuration: Duration(milliseconds: 240),
      longDuration: Duration(milliseconds: 320),
      standardCurve: Curves.easeOutCubic,
      emphasizedCurve: Curves.easeOutQuart,
      exitCurve: Curves.easeInOutCubic,
      pageOffset: Offset(0, 0.04),
      sectionOffset: Offset(0, 0.06),
      sheetOffset: Offset(0, 0.08),
      pageScale: 0.985,
      sheetScale: 0.97,
    );
  }

  static TasklyMotionTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<TasklyMotionTheme>() ??
        TasklyMotionTheme.fromTheme(theme);
  }

  final Duration shortDuration;
  final Duration mediumDuration;
  final Duration longDuration;
  final Curve standardCurve;
  final Curve emphasizedCurve;
  final Curve exitCurve;
  final Offset pageOffset;
  final Offset sectionOffset;
  final Offset sheetOffset;
  final double pageScale;
  final double sheetScale;

  AnimationStyle get bottomSheetAnimationStyle => AnimationStyle(
    duration: mediumDuration,
    reverseDuration: shortDuration,
  );

  @override
  TasklyMotionTheme copyWith({
    Duration? shortDuration,
    Duration? mediumDuration,
    Duration? longDuration,
    Curve? standardCurve,
    Curve? emphasizedCurve,
    Curve? exitCurve,
    Offset? pageOffset,
    Offset? sectionOffset,
    Offset? sheetOffset,
    double? pageScale,
    double? sheetScale,
  }) {
    return TasklyMotionTheme(
      shortDuration: shortDuration ?? this.shortDuration,
      mediumDuration: mediumDuration ?? this.mediumDuration,
      longDuration: longDuration ?? this.longDuration,
      standardCurve: standardCurve ?? this.standardCurve,
      emphasizedCurve: emphasizedCurve ?? this.emphasizedCurve,
      exitCurve: exitCurve ?? this.exitCurve,
      pageOffset: pageOffset ?? this.pageOffset,
      sectionOffset: sectionOffset ?? this.sectionOffset,
      sheetOffset: sheetOffset ?? this.sheetOffset,
      pageScale: pageScale ?? this.pageScale,
      sheetScale: sheetScale ?? this.sheetScale,
    );
  }

  @override
  TasklyMotionTheme lerp(ThemeExtension<TasklyMotionTheme>? other, double t) {
    if (other is! TasklyMotionTheme) return this;
    return TasklyMotionTheme(
      shortDuration: t < 0.5 ? shortDuration : other.shortDuration,
      mediumDuration: t < 0.5 ? mediumDuration : other.mediumDuration,
      longDuration: t < 0.5 ? longDuration : other.longDuration,
      standardCurve: t < 0.5 ? standardCurve : other.standardCurve,
      emphasizedCurve: t < 0.5 ? emphasizedCurve : other.emphasizedCurve,
      exitCurve: t < 0.5 ? exitCurve : other.exitCurve,
      pageOffset: Offset.lerp(pageOffset, other.pageOffset, t) ?? pageOffset,
      sectionOffset:
          Offset.lerp(sectionOffset, other.sectionOffset, t) ?? sectionOffset,
      sheetOffset:
          Offset.lerp(sheetOffset, other.sheetOffset, t) ?? sheetOffset,
      pageScale: lerpDouble(pageScale, other.pageScale, t) ?? pageScale,
      sheetScale: lerpDouble(sheetScale, other.sheetScale, t) ?? sheetScale,
    );
  }
}

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

  static TasklyAppChromeTheme of(BuildContext context) {
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
    required this.contentPadding,
    required this.surfaceByVariant,
    required this.borderByVariant,
    required this.iconSize,
    required this.iconContainerPadding,
    required this.iconColor,
    required this.iconSurface,
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
        tokens.spaceSm2,
        tokens.sectionPaddingH,
        tokens.spaceXs2,
      ),
      contentPadding: EdgeInsets.fromLTRB(
        tokens.spaceMd,
        tokens.spaceSm2,
        tokens.spaceMd,
        tokens.spaceSm2,
      ),
      surfaceByVariant: <TasklyHeaderVariant, Color>{
        TasklyHeaderVariant.screen: Color.alphaBlend(
          scheme.surfaceContainerLowest.withValues(alpha: 0.82),
          scheme.primaryContainer.withValues(alpha: 0.06),
        ),
        TasklyHeaderVariant.section: Color.alphaBlend(
          scheme.surfaceContainerLow.withValues(alpha: 0.7),
          scheme.surface,
        ),
        TasklyHeaderVariant.hero: Color.alphaBlend(
          scheme.primaryContainer.withValues(alpha: 0.2),
          scheme.surface,
        ),
        TasklyHeaderVariant.compact: Colors.transparent,
      },
      borderByVariant: <TasklyHeaderVariant, Color>{
        TasklyHeaderVariant.screen: scheme.outlineVariant.withValues(
          alpha: 0.2,
        ),
        TasklyHeaderVariant.section: scheme.outlineVariant.withValues(
          alpha: 0.14,
        ),
        TasklyHeaderVariant.hero: scheme.primary.withValues(alpha: 0.12),
        TasklyHeaderVariant.compact: Colors.transparent,
      },
      iconSize: tokens.spaceLg2,
      iconContainerPadding: tokens.spaceXs2,
      iconColor: scheme.primary,
      iconSurface: Color.alphaBlend(
        scheme.primaryContainer.withValues(alpha: 0.52),
        scheme.surface,
      ),
      titleColor: scheme.onSurface,
      subtitleColor: scheme.onSurfaceVariant,
      titleFontWeight: FontWeight.w800,
      chipBackground: scheme.surfaceContainerHighest,
      chipForeground: scheme.onSurface,
    );
  }

  static TasklyPageHeaderTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<TasklyPageHeaderTheme>() ??
        TasklyPageHeaderTheme.fromTheme(theme);
  }

  final EdgeInsets padding;
  final EdgeInsets contentPadding;
  final Map<TasklyHeaderVariant, Color> surfaceByVariant;
  final Map<TasklyHeaderVariant, Color> borderByVariant;
  final double iconSize;
  final double iconContainerPadding;
  final Color iconColor;
  final Color iconSurface;
  final Color titleColor;
  final Color subtitleColor;
  final FontWeight titleFontWeight;
  final Color chipBackground;
  final Color chipForeground;

  Color surface(TasklyHeaderVariant variant) => surfaceByVariant[variant]!;
  Color border(TasklyHeaderVariant variant) => borderByVariant[variant]!;

  @override
  TasklyPageHeaderTheme copyWith({
    EdgeInsets? padding,
    EdgeInsets? contentPadding,
    Map<TasklyHeaderVariant, Color>? surfaceByVariant,
    Map<TasklyHeaderVariant, Color>? borderByVariant,
    double? iconSize,
    double? iconContainerPadding,
    Color? iconColor,
    Color? iconSurface,
    Color? titleColor,
    Color? subtitleColor,
    FontWeight? titleFontWeight,
    Color? chipBackground,
    Color? chipForeground,
  }) {
    return TasklyPageHeaderTheme(
      padding: padding ?? this.padding,
      contentPadding: contentPadding ?? this.contentPadding,
      surfaceByVariant: surfaceByVariant ?? this.surfaceByVariant,
      borderByVariant: borderByVariant ?? this.borderByVariant,
      iconSize: iconSize ?? this.iconSize,
      iconContainerPadding: iconContainerPadding ?? this.iconContainerPadding,
      iconColor: iconColor ?? this.iconColor,
      iconSurface: iconSurface ?? this.iconSurface,
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
      contentPadding:
          EdgeInsets.lerp(contentPadding, other.contentPadding, t) ??
          contentPadding,
      surfaceByVariant: {
        for (final variant in TasklyHeaderVariant.values)
          variant: Color.lerp(
            surfaceByVariant[variant],
            other.surfaceByVariant[variant],
            t,
          )!,
      },
      borderByVariant: {
        for (final variant in TasklyHeaderVariant.values)
          variant: Color.lerp(
            borderByVariant[variant],
            other.borderByVariant[variant],
            t,
          )!,
      },
      iconSize: lerpDouble(iconSize, other.iconSize, t) ?? iconSize,
      iconContainerPadding:
          lerpDouble(iconContainerPadding, other.iconContainerPadding, t) ??
          iconContainerPadding,
      iconColor: Color.lerp(iconColor, other.iconColor, t)!,
      iconSurface: Color.lerp(iconSurface, other.iconSurface, t)!,
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
    required this.ambientPrimary,
    required this.ambientSecondary,
    required this.softShadow,
    required this.primaryTint,
  });

  factory TasklyPanelTheme.fromTheme(ThemeData theme) {
    final scheme = theme.colorScheme;
    return TasklyPanelTheme(
      subtleSurface: Color.alphaBlend(
        scheme.surfaceContainerLow.withValues(alpha: 0.84),
        scheme.surface,
      ),
      emphasizedSurface: Color.alphaBlend(
        scheme.surfaceContainerHighest.withValues(alpha: 0.72),
        scheme.surface,
      ),
      border: scheme.outlineVariant.withValues(alpha: 0.3),
      mutedBorder: scheme.outlineVariant.withValues(alpha: 0.18),
      gradientStart: Color.alphaBlend(
        scheme.surfaceContainerLowest.withValues(alpha: 0.9),
        scheme.surface,
      ),
      gradientEnd: Color.alphaBlend(
        scheme.surfaceContainerLow.withValues(alpha: 0.7),
        scheme.surface,
      ),
      ambientPrimary: scheme.primary.withValues(alpha: 0.12),
      ambientSecondary: scheme.tertiary.withValues(alpha: 0.08),
      softShadow: scheme.shadow.withValues(alpha: 0.08),
      primaryTint: scheme.primaryContainer,
    );
  }

  static TasklyPanelTheme of(BuildContext context) {
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
  final Color ambientPrimary;
  final Color ambientSecondary;
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
    Color? ambientPrimary,
    Color? ambientSecondary,
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
      ambientPrimary: ambientPrimary ?? this.ambientPrimary,
      ambientSecondary: ambientSecondary ?? this.ambientSecondary,
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
      ambientPrimary: Color.lerp(ambientPrimary, other.ambientPrimary, t)!,
      ambientSecondary: Color.lerp(
        ambientSecondary,
        other.ambientSecondary,
        t,
      )!,
      softShadow: Color.lerp(softShadow, other.softShadow, t)!,
      primaryTint: Color.lerp(primaryTint, other.primaryTint, t)!,
    );
  }
}

class TasklyCardTheme extends ThemeExtension<TasklyCardTheme> {
  const TasklyCardTheme({
    required this.surfaceByVariant,
    required this.borderByVariant,
    required this.radiusByVariant,
    required this.paddingByVariant,
    required this.shadowBlurByVariant,
    required this.shadowOffsetByVariant,
    required this.shadowColor,
  });

  factory TasklyCardTheme.fromTheme(ThemeData theme) {
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.fromTheme(theme);
    return TasklyCardTheme(
      surfaceByVariant: <TasklyCardVariant, Color>{
        TasklyCardVariant.summary: Color.alphaBlend(
          scheme.surfaceContainerLowest.withValues(alpha: 0.9),
          scheme.surface,
        ),
        TasklyCardVariant.insight: Color.alphaBlend(
          scheme.primaryContainer.withValues(alpha: 0.22),
          scheme.surface,
        ),
        TasklyCardVariant.maintenance: Color.alphaBlend(
          scheme.secondaryContainer.withValues(alpha: 0.16),
          scheme.surface,
        ),
        TasklyCardVariant.editor: Color.alphaBlend(
          scheme.surfaceContainerLowest.withValues(alpha: 0.95),
          scheme.surface,
        ),
        TasklyCardVariant.subtle: Color.alphaBlend(
          scheme.surfaceContainerLow.withValues(alpha: 0.72),
          scheme.surface,
        ),
      },
      borderByVariant: <TasklyCardVariant, Color>{
        TasklyCardVariant.summary: scheme.outlineVariant.withValues(
          alpha: 0.14,
        ),
        TasklyCardVariant.insight: scheme.primary.withValues(alpha: 0.1),
        TasklyCardVariant.maintenance: scheme.secondary.withValues(alpha: 0.1),
        TasklyCardVariant.editor: scheme.outlineVariant.withValues(alpha: 0.12),
        TasklyCardVariant.subtle: scheme.outlineVariant.withValues(alpha: 0.08),
      },
      radiusByVariant: <TasklyCardVariant, double>{
        TasklyCardVariant.summary: tokens.radiusLg2,
        TasklyCardVariant.insight: tokens.radiusLg2,
        TasklyCardVariant.maintenance: tokens.radiusLg,
        TasklyCardVariant.editor: tokens.radiusLg2,
        TasklyCardVariant.subtle: tokens.radiusLg,
      },
      paddingByVariant: <TasklyCardVariant, EdgeInsets>{
        TasklyCardVariant.summary: EdgeInsets.all(tokens.spaceLg),
        TasklyCardVariant.insight: EdgeInsets.all(tokens.spaceLg),
        TasklyCardVariant.maintenance: EdgeInsets.all(tokens.spaceLg),
        TasklyCardVariant.editor: EdgeInsets.all(tokens.spaceLg),
        TasklyCardVariant.subtle: EdgeInsets.all(tokens.spaceMd2),
      },
      shadowBlurByVariant: <TasklyCardVariant, double>{
        TasklyCardVariant.summary: 24,
        TasklyCardVariant.insight: 28,
        TasklyCardVariant.maintenance: 22,
        TasklyCardVariant.editor: 20,
        TasklyCardVariant.subtle: 16,
      },
      shadowOffsetByVariant: const <TasklyCardVariant, Offset>{
        TasklyCardVariant.summary: Offset(0, 10),
        TasklyCardVariant.insight: Offset(0, 12),
        TasklyCardVariant.maintenance: Offset(0, 10),
        TasklyCardVariant.editor: Offset(0, 8),
        TasklyCardVariant.subtle: Offset(0, 6),
      },
      shadowColor: scheme.shadow.withValues(alpha: 0.09),
    );
  }

  static TasklyCardTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<TasklyCardTheme>() ??
        TasklyCardTheme.fromTheme(theme);
  }

  final Map<TasklyCardVariant, Color> surfaceByVariant;
  final Map<TasklyCardVariant, Color> borderByVariant;
  final Map<TasklyCardVariant, double> radiusByVariant;
  final Map<TasklyCardVariant, EdgeInsets> paddingByVariant;
  final Map<TasklyCardVariant, double> shadowBlurByVariant;
  final Map<TasklyCardVariant, Offset> shadowOffsetByVariant;
  final Color shadowColor;

  Color surface(TasklyCardVariant variant) => surfaceByVariant[variant]!;
  Color border(TasklyCardVariant variant) => borderByVariant[variant]!;
  double radius(TasklyCardVariant variant) => radiusByVariant[variant]!;
  EdgeInsets padding(TasklyCardVariant variant) => paddingByVariant[variant]!;
  double shadowBlur(TasklyCardVariant variant) => shadowBlurByVariant[variant]!;
  Offset shadowOffset(TasklyCardVariant variant) =>
      shadowOffsetByVariant[variant]!;

  @override
  TasklyCardTheme copyWith({
    Map<TasklyCardVariant, Color>? surfaceByVariant,
    Map<TasklyCardVariant, Color>? borderByVariant,
    Map<TasklyCardVariant, double>? radiusByVariant,
    Map<TasklyCardVariant, EdgeInsets>? paddingByVariant,
    Map<TasklyCardVariant, double>? shadowBlurByVariant,
    Map<TasklyCardVariant, Offset>? shadowOffsetByVariant,
    Color? shadowColor,
  }) {
    return TasklyCardTheme(
      surfaceByVariant: surfaceByVariant ?? this.surfaceByVariant,
      borderByVariant: borderByVariant ?? this.borderByVariant,
      radiusByVariant: radiusByVariant ?? this.radiusByVariant,
      paddingByVariant: paddingByVariant ?? this.paddingByVariant,
      shadowBlurByVariant: shadowBlurByVariant ?? this.shadowBlurByVariant,
      shadowOffsetByVariant:
          shadowOffsetByVariant ?? this.shadowOffsetByVariant,
      shadowColor: shadowColor ?? this.shadowColor,
    );
  }

  @override
  TasklyCardTheme lerp(ThemeExtension<TasklyCardTheme>? other, double t) {
    if (other is! TasklyCardTheme) return this;
    return TasklyCardTheme(
      surfaceByVariant: {
        for (final variant in TasklyCardVariant.values)
          variant: Color.lerp(
            surfaceByVariant[variant],
            other.surfaceByVariant[variant],
            t,
          )!,
      },
      borderByVariant: {
        for (final variant in TasklyCardVariant.values)
          variant: Color.lerp(
            borderByVariant[variant],
            other.borderByVariant[variant],
            t,
          )!,
      },
      radiusByVariant: {
        for (final variant in TasklyCardVariant.values)
          variant:
              lerpDouble(
                radiusByVariant[variant],
                other.radiusByVariant[variant],
                t,
              ) ??
              radiusByVariant[variant]!,
      },
      paddingByVariant: {
        for (final variant in TasklyCardVariant.values)
          variant:
              EdgeInsets.lerp(
                paddingByVariant[variant],
                other.paddingByVariant[variant],
                t,
              ) ??
              paddingByVariant[variant]!,
      },
      shadowBlurByVariant: {
        for (final variant in TasklyCardVariant.values)
          variant:
              lerpDouble(
                shadowBlurByVariant[variant],
                other.shadowBlurByVariant[variant],
                t,
              ) ??
              shadowBlurByVariant[variant]!,
      },
      shadowOffsetByVariant: {
        for (final variant in TasklyCardVariant.values)
          variant:
              Offset.lerp(
                shadowOffsetByVariant[variant],
                other.shadowOffsetByVariant[variant],
                t,
              ) ??
              shadowOffsetByVariant[variant]!,
      },
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
    );
  }
}

class TasklyChipTheme extends ThemeExtension<TasklyChipTheme> {
  const TasklyChipTheme({
    required this.backgroundByVariant,
    required this.foregroundByVariant,
    required this.borderByVariant,
  });

  factory TasklyChipTheme.fromTheme(ThemeData theme) {
    final scheme = theme.colorScheme;
    return TasklyChipTheme(
      backgroundByVariant: <TasklyChipVariant, Color>{
        TasklyChipVariant.filter: scheme.surfaceContainerLow,
        TasklyChipVariant.metric: scheme.surfaceContainerHighest,
        TasklyChipVariant.status: scheme.primaryContainer,
        TasklyChipVariant.selection: scheme.secondaryContainer,
      },
      foregroundByVariant: <TasklyChipVariant, Color>{
        TasklyChipVariant.filter: scheme.onSurfaceVariant,
        TasklyChipVariant.metric: scheme.onSurface,
        TasklyChipVariant.status: scheme.onPrimaryContainer,
        TasklyChipVariant.selection: scheme.onSecondaryContainer,
      },
      borderByVariant: <TasklyChipVariant, Color>{
        for (final variant in TasklyChipVariant.values)
          variant: scheme.outlineVariant.withValues(alpha: 0.5),
      },
    );
  }

  static TasklyChipTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<TasklyChipTheme>() ??
        TasklyChipTheme.fromTheme(theme);
  }

  final Map<TasklyChipVariant, Color> backgroundByVariant;
  final Map<TasklyChipVariant, Color> foregroundByVariant;
  final Map<TasklyChipVariant, Color> borderByVariant;

  Color background(TasklyChipVariant variant) => backgroundByVariant[variant]!;
  Color foreground(TasklyChipVariant variant) => foregroundByVariant[variant]!;
  Color border(TasklyChipVariant variant) => borderByVariant[variant]!;

  @override
  TasklyChipTheme copyWith({
    Map<TasklyChipVariant, Color>? backgroundByVariant,
    Map<TasklyChipVariant, Color>? foregroundByVariant,
    Map<TasklyChipVariant, Color>? borderByVariant,
  }) {
    return TasklyChipTheme(
      backgroundByVariant: backgroundByVariant ?? this.backgroundByVariant,
      foregroundByVariant: foregroundByVariant ?? this.foregroundByVariant,
      borderByVariant: borderByVariant ?? this.borderByVariant,
    );
  }

  @override
  TasklyChipTheme lerp(ThemeExtension<TasklyChipTheme>? other, double t) {
    if (other is! TasklyChipTheme) return this;
    return TasklyChipTheme(
      backgroundByVariant: {
        for (final variant in TasklyChipVariant.values)
          variant: Color.lerp(
            backgroundByVariant[variant],
            other.backgroundByVariant[variant],
            t,
          )!,
      },
      foregroundByVariant: {
        for (final variant in TasklyChipVariant.values)
          variant: Color.lerp(
            foregroundByVariant[variant],
            other.foregroundByVariant[variant],
            t,
          )!,
      },
      borderByVariant: {
        for (final variant in TasklyChipVariant.values)
          variant: Color.lerp(
            borderByVariant[variant],
            other.borderByVariant[variant],
            t,
          )!,
      },
    );
  }
}

class TasklyEmptyStateTheme extends ThemeExtension<TasklyEmptyStateTheme> {
  const TasklyEmptyStateTheme({
    required this.panelSurface,
    required this.panelBorder,
    required this.panelShadow,
    required this.haloSurface,
    required this.iconSurface,
    required this.iconColor,
    required this.titleColor,
    required this.descriptionColor,
  });

  factory TasklyEmptyStateTheme.fromTheme(ThemeData theme) {
    final scheme = theme.colorScheme;
    return TasklyEmptyStateTheme(
      panelSurface: Color.alphaBlend(
        scheme.surfaceContainerLow.withValues(alpha: 0.8),
        scheme.surface,
      ),
      panelBorder: scheme.outlineVariant.withValues(alpha: 0.12),
      panelShadow: scheme.shadow.withValues(alpha: 0.08),
      haloSurface: scheme.primary.withValues(alpha: 0.08),
      iconSurface: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      iconColor: scheme.onSurfaceVariant.withValues(alpha: 0.6),
      titleColor: scheme.onSurface,
      descriptionColor: scheme.onSurfaceVariant,
    );
  }

  static TasklyEmptyStateTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<TasklyEmptyStateTheme>() ??
        TasklyEmptyStateTheme.fromTheme(theme);
  }

  final Color panelSurface;
  final Color panelBorder;
  final Color panelShadow;
  final Color haloSurface;
  final Color iconSurface;
  final Color iconColor;
  final Color titleColor;
  final Color descriptionColor;

  @override
  TasklyEmptyStateTheme copyWith({
    Color? panelSurface,
    Color? panelBorder,
    Color? panelShadow,
    Color? haloSurface,
    Color? iconSurface,
    Color? iconColor,
    Color? titleColor,
    Color? descriptionColor,
  }) {
    return TasklyEmptyStateTheme(
      panelSurface: panelSurface ?? this.panelSurface,
      panelBorder: panelBorder ?? this.panelBorder,
      panelShadow: panelShadow ?? this.panelShadow,
      haloSurface: haloSurface ?? this.haloSurface,
      iconSurface: iconSurface ?? this.iconSurface,
      iconColor: iconColor ?? this.iconColor,
      titleColor: titleColor ?? this.titleColor,
      descriptionColor: descriptionColor ?? this.descriptionColor,
    );
  }

  @override
  TasklyEmptyStateTheme lerp(
    ThemeExtension<TasklyEmptyStateTheme>? other,
    double t,
  ) {
    if (other is! TasklyEmptyStateTheme) return this;
    return TasklyEmptyStateTheme(
      panelSurface: Color.lerp(panelSurface, other.panelSurface, t)!,
      panelBorder: Color.lerp(panelBorder, other.panelBorder, t)!,
      panelShadow: Color.lerp(panelShadow, other.panelShadow, t)!,
      haloSurface: Color.lerp(haloSurface, other.haloSurface, t)!,
      iconSurface: Color.lerp(iconSurface, other.iconSurface, t)!,
      iconColor: Color.lerp(iconColor, other.iconColor, t)!,
      titleColor: Color.lerp(titleColor, other.titleColor, t)!,
      descriptionColor: Color.lerp(
        descriptionColor,
        other.descriptionColor,
        t,
      )!,
    );
  }
}

class TasklySheetTheme extends ThemeExtension<TasklySheetTheme> {
  const TasklySheetTheme({
    required this.backgroundByVariant,
    required this.borderByVariant,
    required this.shadowColor,
  });

  factory TasklySheetTheme.fromTheme(ThemeData theme) {
    final scheme = theme.colorScheme;
    return TasklySheetTheme(
      backgroundByVariant: <TasklySheetVariant, Color>{
        TasklySheetVariant.standard: Color.alphaBlend(
          scheme.surfaceContainerLowest.withValues(alpha: 0.92),
          scheme.surface,
        ),
        TasklySheetVariant.editor: Color.alphaBlend(
          scheme.surfaceContainerLowest.withValues(alpha: 0.96),
          scheme.surface,
        ),
        TasklySheetVariant.supporting: Color.alphaBlend(
          scheme.surfaceContainerLow.withValues(alpha: 0.82),
          scheme.surface,
        ),
      },
      borderByVariant: <TasklySheetVariant, Color>{
        for (final variant in TasklySheetVariant.values)
          variant: scheme.outlineVariant.withValues(alpha: 0.16),
      },
      shadowColor: scheme.shadow.withValues(alpha: 0.12),
    );
  }

  static TasklySheetTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<TasklySheetTheme>() ??
        TasklySheetTheme.fromTheme(theme);
  }

  final Map<TasklySheetVariant, Color> backgroundByVariant;
  final Map<TasklySheetVariant, Color> borderByVariant;
  final Color shadowColor;

  Color background(TasklySheetVariant variant) => backgroundByVariant[variant]!;
  Color border(TasklySheetVariant variant) => borderByVariant[variant]!;

  @override
  TasklySheetTheme copyWith({
    Map<TasklySheetVariant, Color>? backgroundByVariant,
    Map<TasklySheetVariant, Color>? borderByVariant,
    Color? shadowColor,
  }) {
    return TasklySheetTheme(
      backgroundByVariant: backgroundByVariant ?? this.backgroundByVariant,
      borderByVariant: borderByVariant ?? this.borderByVariant,
      shadowColor: shadowColor ?? this.shadowColor,
    );
  }

  @override
  TasklySheetTheme lerp(ThemeExtension<TasklySheetTheme>? other, double t) {
    if (other is! TasklySheetTheme) return this;
    return TasklySheetTheme(
      backgroundByVariant: {
        for (final variant in TasklySheetVariant.values)
          variant: Color.lerp(
            backgroundByVariant[variant],
            other.backgroundByVariant[variant],
            t,
          )!,
      },
      borderByVariant: {
        for (final variant in TasklySheetVariant.values)
          variant: Color.lerp(
            borderByVariant[variant],
            other.borderByVariant[variant],
            t,
          )!,
      },
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
    );
  }
}

class TasklyInsightTheme extends ThemeExtension<TasklyInsightTheme> {
  const TasklyInsightTheme({
    required this.badgeBackground,
    required this.badgeForeground,
    required this.highlight,
  });

  factory TasklyInsightTheme.fromTheme(ThemeData theme) {
    final scheme = theme.colorScheme;
    return TasklyInsightTheme(
      badgeBackground: scheme.primaryContainer,
      badgeForeground: scheme.onPrimaryContainer,
      highlight: scheme.primary,
    );
  }

  static TasklyInsightTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<TasklyInsightTheme>() ??
        TasklyInsightTheme.fromTheme(theme);
  }

  final Color badgeBackground;
  final Color badgeForeground;
  final Color highlight;

  @override
  TasklyInsightTheme copyWith({
    Color? badgeBackground,
    Color? badgeForeground,
    Color? highlight,
  }) {
    return TasklyInsightTheme(
      badgeBackground: badgeBackground ?? this.badgeBackground,
      badgeForeground: badgeForeground ?? this.badgeForeground,
      highlight: highlight ?? this.highlight,
    );
  }

  @override
  TasklyInsightTheme lerp(
    ThemeExtension<TasklyInsightTheme>? other,
    double t,
  ) {
    if (other is! TasklyInsightTheme) return this;
    return TasklyInsightTheme(
      badgeBackground: Color.lerp(
        badgeBackground,
        other.badgeBackground,
        t,
      )!,
      badgeForeground: Color.lerp(
        badgeForeground,
        other.badgeForeground,
        t,
      )!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
    );
  }
}

class TasklyEntityRowChromeTheme
    extends ThemeExtension<TasklyEntityRowChromeTheme> {
  const TasklyEntityRowChromeTheme({
    required this.divider,
    required this.subtleText,
    required this.headerText,
    required this.sectionSurface,
    required this.emptyRowSurface,
    required this.emptyRowIcon,
  });

  factory TasklyEntityRowChromeTheme.fromTheme(ThemeData theme) {
    final scheme = theme.colorScheme;
    return TasklyEntityRowChromeTheme(
      divider: scheme.outlineVariant.withValues(alpha: 0.55),
      subtleText: scheme.onSurfaceVariant,
      headerText: scheme.onSurface,
      sectionSurface: scheme.surfaceContainerLow,
      emptyRowSurface: scheme.surfaceContainerLow,
      emptyRowIcon: scheme.onSurfaceVariant.withValues(alpha: 0.7),
    );
  }

  static TasklyEntityRowChromeTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<TasklyEntityRowChromeTheme>() ??
        TasklyEntityRowChromeTheme.fromTheme(theme);
  }

  final Color divider;
  final Color subtleText;
  final Color headerText;
  final Color sectionSurface;
  final Color emptyRowSurface;
  final Color emptyRowIcon;

  @override
  TasklyEntityRowChromeTheme copyWith({
    Color? divider,
    Color? subtleText,
    Color? headerText,
    Color? sectionSurface,
    Color? emptyRowSurface,
    Color? emptyRowIcon,
  }) {
    return TasklyEntityRowChromeTheme(
      divider: divider ?? this.divider,
      subtleText: subtleText ?? this.subtleText,
      headerText: headerText ?? this.headerText,
      sectionSurface: sectionSurface ?? this.sectionSurface,
      emptyRowSurface: emptyRowSurface ?? this.emptyRowSurface,
      emptyRowIcon: emptyRowIcon ?? this.emptyRowIcon,
    );
  }

  @override
  TasklyEntityRowChromeTheme lerp(
    ThemeExtension<TasklyEntityRowChromeTheme>? other,
    double t,
  ) {
    if (other is! TasklyEntityRowChromeTheme) return this;
    return TasklyEntityRowChromeTheme(
      divider: Color.lerp(divider, other.divider, t)!,
      subtleText: Color.lerp(subtleText, other.subtleText, t)!,
      headerText: Color.lerp(headerText, other.headerText, t)!,
      sectionSurface: Color.lerp(sectionSurface, other.sectionSurface, t)!,
      emptyRowSurface: Color.lerp(
        emptyRowSurface,
        other.emptyRowSurface,
        t,
      )!,
      emptyRowIcon: Color.lerp(emptyRowIcon, other.emptyRowIcon, t)!,
    );
  }
}
