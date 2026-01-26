import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/theme/app_colors.dart';
import 'package:taskly_bloc/presentation/theme/taskly_typography.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';

/// Centralized application theme.
///
/// Provides both light and dark theme variants using Material 3 design system.
class AppTheme {
  AppTheme._();

  /// Light theme configuration with optional seed color.
  static ThemeData lightTheme({Color? seedColor}) {
    // Respect user-selected seed colors; avoid overriding ColorScheme values.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor ?? AppColors.blueberry80,
    );

    return _buildTheme(colorScheme);
  }

  /// Dark theme configuration with optional seed color.
  static ThemeData darkTheme({Color? seedColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor ?? AppColors.blueberry80,
      brightness: Brightness.dark,
    );

    return _buildTheme(colorScheme);
  }

  /// Taskly (Stitch) theme configuration.
  static ThemeData tasklyTheme({Color? seedColor}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor ?? AppColors.blueberry80,
      brightness: Brightness.dark,
    );
    final tasklyDesignExtension = TasklyDesignExtension(
      urgentSurface: scheme.errorContainer.withValues(alpha: 0.2),
      warningSurface: scheme.secondaryContainer.withValues(alpha: 0.2),
      safeSurface: scheme.tertiaryContainer.withValues(alpha: 0.15),
      neonAccent: scheme.primary,
      glassBorder: scheme.onSurface.withValues(alpha: 0.1),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scheme.background,
      cardColor: scheme.surface,
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[
        tasklyDesignExtension,
      ],
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.primary,
            width: 1,
          ),
        ),
      ),
    );

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[
        tasklyDesignExtension,
        TasklyTypography.from(
          textTheme: base.textTheme,
          colorScheme: base.colorScheme,
        ),
        TasklyEntityTileTheme.fromTheme(base),
        TasklyFeedTheme.fromTheme(base),
        TasklyChromeTheme.fromTheme(base),
      ],
    );
  }

  /// Builds the theme data from a color scheme.
  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.background,
      extensions: <ThemeExtension<dynamic>>[
        TasklyTypography.from(textTheme: textTheme, colorScheme: colorScheme),
        TasklyEntityTileTheme.fromTheme(
          ThemeData(colorScheme: colorScheme, textTheme: textTheme),
        ),
        TasklyFeedTheme.fromTheme(
          ThemeData(colorScheme: colorScheme, textTheme: textTheme),
        ),
        TasklyChromeTheme.fromTheme(
          ThemeData(colorScheme: colorScheme, textTheme: textTheme),
        ),
      ],

      // AppBar theme
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.surface.withValues(alpha: 0),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        color: colorScheme.surface,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      // Input decoration theme for forms
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        highlightElevation: 4,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // List tile theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        elevation: 0,
        pressElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide.none,
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),

      // Navigation rail theme
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surfaceContainerLow,
        indicatorColor: colorScheme.primaryContainer,
        selectedIconTheme: IconThemeData(
          color: colorScheme.onPrimaryContainer,
        ),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
        ),
        selectedLabelTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // Bottom navigation bar theme (for mobile)
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surfaceContainerLow,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          );
        }),
      ),

      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: BorderSide(
          color: colorScheme.outline,
          width: 2,
        ),
      ),

      // Progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
        circularTrackColor: colorScheme.surfaceContainerHighest,
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: colorScheme.onInverseSurface,
        ),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),

      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        dragHandleColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        dragHandleSize: const Size(32, 4),
        showDragHandle: true,
      ),
    );
  }

  /// Builds the text theme.
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: colorScheme.onSurface,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
        color: colorScheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.4,
        color: colorScheme.onSurface,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Theme spacing constants for consistent layout.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Standard horizontal padding for screens.
  static const screenHorizontal = EdgeInsets.symmetric(horizontal: lg);

  /// Standard card margin.
  static const cardMargin = EdgeInsets.symmetric(horizontal: md, vertical: xs);

  /// Standard content padding inside cards.
  static const cardPadding = EdgeInsets.all(md);
}

/// Theme border radius constants.
class AppRadius {
  AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 28;
}

@immutable
class TasklyChromeTheme extends ThemeExtension<TasklyChromeTheme> {
  const TasklyChromeTheme({
    required this.anytimeAppBarHeight,
    required this.scheduledAppBarHeight,
    required this.iconButtonMinSize,
    required this.iconButtonPadding,
    required this.iconButtonBackgroundAlpha,
    required this.anytimeHeaderPadding,
    required this.valueRowHeight,
    required this.valueItemWidth,
    required this.valueItemSpacing,
    required this.valueIconBoxSize,
    required this.valueIconSize,
    required this.valueIconRadius,
    required this.valueLabelSpacing,
    required this.valueLabelStyle,
    required this.valueLabelSelectedStyle,
    required this.filterRowSpacing,
    required this.filterPillPadding,
    required this.filterPillRadius,
    required this.filterPillIconSize,
    required this.filterPillTextStyle,
    required this.monthStripHeight,
    required this.monthStripPaddingV,
    required this.monthStripSpacing,
    required this.monthStripLabelStyle,
    required this.monthStripLabelSelectedStyle,
    required this.monthStripLabelSpacing,
    required this.monthStripDotSize,
    required this.scheduledDaySectionSpacing,
  });

  factory TasklyChromeTheme.fromTheme(ThemeData theme) {
    final textTheme = theme.textTheme;
    TextStyle base(TextStyle? s) => s ?? const TextStyle();

    return TasklyChromeTheme(
      anytimeAppBarHeight: 60,
      scheduledAppBarHeight: 60,
      iconButtonMinSize: 44,
      iconButtonPadding: const EdgeInsets.all(10),
      iconButtonBackgroundAlpha: 0.08,
      anytimeHeaderPadding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      valueRowHeight: 68,
      valueItemWidth: 72,
      valueItemSpacing: 10,
      valueIconBoxSize: 40,
      valueIconSize: 20,
      valueIconRadius: 12,
      valueLabelSpacing: 6,
      valueLabelStyle: base(textTheme.labelSmall).copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      valueLabelSelectedStyle: base(textTheme.labelSmall).copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      filterRowSpacing: 8,
      filterPillPadding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      filterPillRadius: 8,
      filterPillIconSize: 14,
      filterPillTextStyle: base(textTheme.labelSmall).copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      monthStripHeight: 42,
      monthStripPaddingV: 6,
      monthStripSpacing: 24,
      monthStripLabelStyle: base(textTheme.bodySmall).copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      monthStripLabelSelectedStyle: base(textTheme.bodySmall).copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      monthStripLabelSpacing: 4,
      monthStripDotSize: 5,
      scheduledDaySectionSpacing: 16,
    );
  }

  factory TasklyChromeTheme.of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<TasklyChromeTheme>() ??
        TasklyChromeTheme.fromTheme(theme);
  }

  final double anytimeAppBarHeight;
  final double scheduledAppBarHeight;

  final double iconButtonMinSize;
  final EdgeInsets iconButtonPadding;
  final double iconButtonBackgroundAlpha;

  final EdgeInsets anytimeHeaderPadding;

  final double valueRowHeight;
  final double valueItemWidth;
  final double valueItemSpacing;
  final double valueIconBoxSize;
  final double valueIconSize;
  final double valueIconRadius;
  final double valueLabelSpacing;
  final TextStyle valueLabelStyle;
  final TextStyle valueLabelSelectedStyle;

  final double filterRowSpacing;
  final EdgeInsets filterPillPadding;
  final double filterPillRadius;
  final double filterPillIconSize;
  final TextStyle filterPillTextStyle;

  final double monthStripHeight;
  final double monthStripPaddingV;
  final double monthStripSpacing;
  final TextStyle monthStripLabelStyle;
  final TextStyle monthStripLabelSelectedStyle;
  final double monthStripLabelSpacing;
  final double monthStripDotSize;

  final double scheduledDaySectionSpacing;

  @override
  TasklyChromeTheme copyWith({
    double? anytimeAppBarHeight,
    double? scheduledAppBarHeight,
    double? iconButtonMinSize,
    EdgeInsets? iconButtonPadding,
    double? iconButtonBackgroundAlpha,
    EdgeInsets? anytimeHeaderPadding,
    double? valueRowHeight,
    double? valueItemWidth,
    double? valueItemSpacing,
    double? valueIconBoxSize,
    double? valueIconSize,
    double? valueIconRadius,
    double? valueLabelSpacing,
    TextStyle? valueLabelStyle,
    TextStyle? valueLabelSelectedStyle,
    double? filterRowSpacing,
    EdgeInsets? filterPillPadding,
    double? filterPillRadius,
    double? filterPillIconSize,
    TextStyle? filterPillTextStyle,
    double? monthStripHeight,
    double? monthStripPaddingV,
    double? monthStripSpacing,
    TextStyle? monthStripLabelStyle,
    TextStyle? monthStripLabelSelectedStyle,
    double? monthStripLabelSpacing,
    double? monthStripDotSize,
    double? scheduledDaySectionSpacing,
  }) {
    return TasklyChromeTheme(
      anytimeAppBarHeight: anytimeAppBarHeight ?? this.anytimeAppBarHeight,
      scheduledAppBarHeight:
          scheduledAppBarHeight ?? this.scheduledAppBarHeight,
      iconButtonMinSize: iconButtonMinSize ?? this.iconButtonMinSize,
      iconButtonPadding: iconButtonPadding ?? this.iconButtonPadding,
      iconButtonBackgroundAlpha:
          iconButtonBackgroundAlpha ?? this.iconButtonBackgroundAlpha,
      anytimeHeaderPadding: anytimeHeaderPadding ?? this.anytimeHeaderPadding,
      valueRowHeight: valueRowHeight ?? this.valueRowHeight,
      valueItemWidth: valueItemWidth ?? this.valueItemWidth,
      valueItemSpacing: valueItemSpacing ?? this.valueItemSpacing,
      valueIconBoxSize: valueIconBoxSize ?? this.valueIconBoxSize,
      valueIconSize: valueIconSize ?? this.valueIconSize,
      valueIconRadius: valueIconRadius ?? this.valueIconRadius,
      valueLabelSpacing: valueLabelSpacing ?? this.valueLabelSpacing,
      valueLabelStyle: valueLabelStyle ?? this.valueLabelStyle,
      valueLabelSelectedStyle:
          valueLabelSelectedStyle ?? this.valueLabelSelectedStyle,
      filterRowSpacing: filterRowSpacing ?? this.filterRowSpacing,
      filterPillPadding: filterPillPadding ?? this.filterPillPadding,
      filterPillRadius: filterPillRadius ?? this.filterPillRadius,
      filterPillIconSize: filterPillIconSize ?? this.filterPillIconSize,
      filterPillTextStyle: filterPillTextStyle ?? this.filterPillTextStyle,
      monthStripHeight: monthStripHeight ?? this.monthStripHeight,
      monthStripPaddingV: monthStripPaddingV ?? this.monthStripPaddingV,
      monthStripSpacing: monthStripSpacing ?? this.monthStripSpacing,
      monthStripLabelStyle: monthStripLabelStyle ?? this.monthStripLabelStyle,
      monthStripLabelSelectedStyle:
          monthStripLabelSelectedStyle ?? this.monthStripLabelSelectedStyle,
      monthStripLabelSpacing:
          monthStripLabelSpacing ?? this.monthStripLabelSpacing,
      monthStripDotSize: monthStripDotSize ?? this.monthStripDotSize,
      scheduledDaySectionSpacing:
          scheduledDaySectionSpacing ?? this.scheduledDaySectionSpacing,
    );
  }

  @override
  TasklyChromeTheme lerp(ThemeExtension<TasklyChromeTheme>? other, double t) {
    if (other is! TasklyChromeTheme) return this;

    return TasklyChromeTheme(
      anytimeAppBarHeight:
          lerpDouble(anytimeAppBarHeight, other.anytimeAppBarHeight, t) ??
          anytimeAppBarHeight,
      scheduledAppBarHeight:
          lerpDouble(scheduledAppBarHeight, other.scheduledAppBarHeight, t) ??
          scheduledAppBarHeight,
      iconButtonMinSize:
          lerpDouble(iconButtonMinSize, other.iconButtonMinSize, t) ??
          iconButtonMinSize,
      iconButtonPadding:
          EdgeInsets.lerp(iconButtonPadding, other.iconButtonPadding, t) ??
          iconButtonPadding,
      iconButtonBackgroundAlpha:
          lerpDouble(
            iconButtonBackgroundAlpha,
            other.iconButtonBackgroundAlpha,
            t,
          ) ??
          iconButtonBackgroundAlpha,
      anytimeHeaderPadding:
          EdgeInsets.lerp(
            anytimeHeaderPadding,
            other.anytimeHeaderPadding,
            t,
          ) ??
          anytimeHeaderPadding,
      valueRowHeight:
          lerpDouble(valueRowHeight, other.valueRowHeight, t) ?? valueRowHeight,
      valueItemWidth:
          lerpDouble(valueItemWidth, other.valueItemWidth, t) ?? valueItemWidth,
      valueItemSpacing:
          lerpDouble(valueItemSpacing, other.valueItemSpacing, t) ??
          valueItemSpacing,
      valueIconBoxSize:
          lerpDouble(valueIconBoxSize, other.valueIconBoxSize, t) ??
          valueIconBoxSize,
      valueIconSize:
          lerpDouble(valueIconSize, other.valueIconSize, t) ?? valueIconSize,
      valueIconRadius:
          lerpDouble(valueIconRadius, other.valueIconRadius, t) ??
          valueIconRadius,
      valueLabelSpacing:
          lerpDouble(valueLabelSpacing, other.valueLabelSpacing, t) ??
          valueLabelSpacing,
      valueLabelStyle:
          TextStyle.lerp(valueLabelStyle, other.valueLabelStyle, t) ??
          valueLabelStyle,
      valueLabelSelectedStyle:
          TextStyle.lerp(
            valueLabelSelectedStyle,
            other.valueLabelSelectedStyle,
            t,
          ) ??
          valueLabelSelectedStyle,
      filterRowSpacing:
          lerpDouble(filterRowSpacing, other.filterRowSpacing, t) ??
          filterRowSpacing,
      filterPillPadding:
          EdgeInsets.lerp(filterPillPadding, other.filterPillPadding, t) ??
          filterPillPadding,
      filterPillRadius:
          lerpDouble(filterPillRadius, other.filterPillRadius, t) ??
          filterPillRadius,
      filterPillIconSize:
          lerpDouble(filterPillIconSize, other.filterPillIconSize, t) ??
          filterPillIconSize,
      filterPillTextStyle:
          TextStyle.lerp(filterPillTextStyle, other.filterPillTextStyle, t) ??
          filterPillTextStyle,
      monthStripHeight:
          lerpDouble(monthStripHeight, other.monthStripHeight, t) ??
          monthStripHeight,
      monthStripPaddingV:
          lerpDouble(monthStripPaddingV, other.monthStripPaddingV, t) ??
          monthStripPaddingV,
      monthStripSpacing:
          lerpDouble(monthStripSpacing, other.monthStripSpacing, t) ??
          monthStripSpacing,
      monthStripLabelStyle:
          TextStyle.lerp(monthStripLabelStyle, other.monthStripLabelStyle, t) ??
          monthStripLabelStyle,
      monthStripLabelSelectedStyle:
          TextStyle.lerp(
            monthStripLabelSelectedStyle,
            other.monthStripLabelSelectedStyle,
            t,
          ) ??
          monthStripLabelSelectedStyle,
      monthStripLabelSpacing:
          lerpDouble(monthStripLabelSpacing, other.monthStripLabelSpacing, t) ??
          monthStripLabelSpacing,
      monthStripDotSize:
          lerpDouble(monthStripDotSize, other.monthStripDotSize, t) ??
          monthStripDotSize,
      scheduledDaySectionSpacing:
          lerpDouble(
            scheduledDaySectionSpacing,
            other.scheduledDaySectionSpacing,
            t,
          ) ??
          scheduledDaySectionSpacing,
    );
  }
}

@immutable
class TasklyDesignExtension extends ThemeExtension<TasklyDesignExtension> {
  const TasklyDesignExtension({
    required this.urgentSurface,
    required this.warningSurface,
    required this.safeSurface,
    required this.neonAccent,
    required this.glassBorder,
  });

  final Color urgentSurface;
  final Color warningSurface;
  final Color safeSurface;
  final Color neonAccent;
  final Color glassBorder;

  @override
  TasklyDesignExtension copyWith({
    Color? urgentSurface,
    Color? warningSurface,
    Color? safeSurface,
    Color? neonAccent,
    Color? glassBorder,
  }) {
    return TasklyDesignExtension(
      urgentSurface: urgentSurface ?? this.urgentSurface,
      warningSurface: warningSurface ?? this.warningSurface,
      safeSurface: safeSurface ?? this.safeSurface,
      neonAccent: neonAccent ?? this.neonAccent,
      glassBorder: glassBorder ?? this.glassBorder,
    );
  }

  @override
  TasklyDesignExtension lerp(
    ThemeExtension<TasklyDesignExtension>? other,
    double t,
  ) {
    if (other is! TasklyDesignExtension) return this;
    return TasklyDesignExtension(
      urgentSurface: Color.lerp(urgentSurface, other.urgentSurface, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      safeSurface: Color.lerp(safeSurface, other.safeSurface, t)!,
      neonAccent: Color.lerp(neonAccent, other.neonAccent, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
    );
  }
}
