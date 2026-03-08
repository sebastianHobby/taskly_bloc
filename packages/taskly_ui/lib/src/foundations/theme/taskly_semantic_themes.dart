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

  static TasklyPageHeaderTheme of(BuildContext context) {
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

class TasklyCardTheme extends ThemeExtension<TasklyCardTheme> {
  const TasklyCardTheme({
    required this.surfaceByVariant,
    required this.borderByVariant,
    required this.shadowColor,
  });

  factory TasklyCardTheme.fromTheme(ThemeData theme) {
    final scheme = theme.colorScheme;
    return TasklyCardTheme(
      surfaceByVariant: <TasklyCardVariant, Color>{
        TasklyCardVariant.summary: scheme.surface,
        TasklyCardVariant.insight: scheme.surfaceContainerLow,
        TasklyCardVariant.maintenance: scheme.surface,
        TasklyCardVariant.editor: scheme.surfaceContainerLowest,
        TasklyCardVariant.subtle: scheme.surfaceContainerLow,
      },
      borderByVariant: <TasklyCardVariant, Color>{
        for (final variant in TasklyCardVariant.values)
          variant: scheme.outlineVariant.withValues(alpha: 0.5),
      },
      shadowColor: scheme.shadow.withValues(alpha: 0.06),
    );
  }

  static TasklyCardTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<TasklyCardTheme>() ??
        TasklyCardTheme.fromTheme(theme);
  }

  final Map<TasklyCardVariant, Color> surfaceByVariant;
  final Map<TasklyCardVariant, Color> borderByVariant;
  final Color shadowColor;

  Color surface(TasklyCardVariant variant) => surfaceByVariant[variant]!;
  Color border(TasklyCardVariant variant) => borderByVariant[variant]!;

  @override
  TasklyCardTheme copyWith({
    Map<TasklyCardVariant, Color>? surfaceByVariant,
    Map<TasklyCardVariant, Color>? borderByVariant,
    Color? shadowColor,
  }) {
    return TasklyCardTheme(
      surfaceByVariant: surfaceByVariant ?? this.surfaceByVariant,
      borderByVariant: borderByVariant ?? this.borderByVariant,
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
    required this.iconSurface,
    required this.iconColor,
    required this.titleColor,
    required this.descriptionColor,
  });

  factory TasklyEmptyStateTheme.fromTheme(ThemeData theme) {
    final scheme = theme.colorScheme;
    return TasklyEmptyStateTheme(
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

  final Color iconSurface;
  final Color iconColor;
  final Color titleColor;
  final Color descriptionColor;

  @override
  TasklyEmptyStateTheme copyWith({
    Color? iconSurface,
    Color? iconColor,
    Color? titleColor,
    Color? descriptionColor,
  }) {
    return TasklyEmptyStateTheme(
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
        TasklySheetVariant.standard: scheme.surface,
        TasklySheetVariant.editor: scheme.surface,
        TasklySheetVariant.supporting: scheme.surfaceContainerLow,
      },
      borderByVariant: <TasklySheetVariant, Color>{
        for (final variant in TasklySheetVariant.values)
          variant: scheme.outlineVariant.withValues(alpha: 0.5),
      },
      shadowColor: scheme.shadow.withValues(alpha: 0.06),
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
