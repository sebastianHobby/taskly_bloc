import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/theme/app_colors.dart';
import 'package:taskly_bloc/presentation/theme/app_seed_palettes.dart';
import 'package:taskly_ui/taskly_ui_theme.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

/// Centralized application theme.
///
/// Provides both light and dark theme variants using Material 3 design system.
class AppTheme {
  AppTheme._();

  /// Light theme configuration with optional seed color.
  static ThemeData lightTheme({Color? seedColor}) {
    // Respect user-selected seed colors; avoid overriding ColorScheme values.
    final resolvedSeed = seedColor ?? AppColors.blueberry80;
    final palette =
        AppSeedPalettes.matchBySeedArgb(resolvedSeed.value) ??
        ThemePaletteOption(
          id: 'custom',
          name: 'Custom',
          seedColor: resolvedSeed,
        );
    final colorScheme = palette.schemeFor(Brightness.light);

    return _buildTheme(colorScheme);
  }

  /// Dark theme configuration with optional seed color.
  static ThemeData darkTheme({Color? seedColor}) {
    final resolvedSeed = seedColor ?? AppColors.blueberry80;
    final palette =
        AppSeedPalettes.matchBySeedArgb(resolvedSeed.value) ??
        ThemePaletteOption(
          id: 'custom',
          name: 'Custom',
          seedColor: resolvedSeed,
        );
    final colorScheme = palette.schemeFor(Brightness.dark);

    return _buildTheme(colorScheme);
  }

  /// Taskly (Stitch) theme configuration.
  static ThemeData tasklyTheme({Color? seedColor}) {
    final resolvedSeed = seedColor ?? AppColors.blueberry80;
    final palette =
        AppSeedPalettes.matchBySeedArgb(resolvedSeed.value) ??
        ThemePaletteOption(
          id: 'custom',
          name: 'Custom',
          seedColor: resolvedSeed,
        );
    final scheme = palette.schemeFor(Brightness.dark);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scheme.background,
      cardColor: scheme.surface,
      colorScheme: scheme,
    );
    final tokens = TasklyTokens.fromTheme(base);
    final chromeTheme = TasklyAppChromeTheme.fromTheme(base);
    final motionTheme = TasklyMotionTheme.fromTheme(base);
    final pageHeaderTheme = TasklyPageHeaderTheme.fromTheme(base);
    final panelTheme = TasklyPanelTheme.fromTheme(base);
    final cardTheme = TasklyCardTheme.fromTheme(base);
    final chipTheme = TasklyChipTheme.fromTheme(base);
    final emptyStateTheme = TasklyEmptyStateTheme.fromTheme(base);
    final sheetTheme = TasklySheetTheme.fromTheme(base);
    final insightTheme = TasklyInsightTheme.fromTheme(base);
    final rowChromeTheme = TasklyEntityRowChromeTheme.fromTheme(base);

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[
        tokens,
        chromeTheme,
        motionTheme,
        pageHeaderTheme,
        panelTheme,
        cardTheme,
        chipTheme,
        emptyStateTheme,
        sheetTheme,
        insightTheme,
        rowChromeTheme,
      ],
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide(
            color: scheme.primary,
            width: 1,
          ),
        ),
      ),
    );
  }

  /// Builds the theme data from a color scheme.
  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final textTheme = _buildTextTheme(colorScheme);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.background,
    );
    final tokens = TasklyTokens.fromTheme(
      ThemeData(colorScheme: colorScheme, textTheme: textTheme),
    );
    final semanticBase = ThemeData(
      colorScheme: colorScheme,
      textTheme: textTheme,
    );
    final chromeTheme = TasklyAppChromeTheme.fromTheme(semanticBase);
    final motionTheme = TasklyMotionTheme.fromTheme(semanticBase);
    final pageHeaderTheme = TasklyPageHeaderTheme.fromTheme(semanticBase);
    final panelTheme = TasklyPanelTheme.fromTheme(semanticBase);
    final cardTheme = TasklyCardTheme.fromTheme(semanticBase);
    final chipTheme = TasklyChipTheme.fromTheme(semanticBase);
    final emptyStateTheme = TasklyEmptyStateTheme.fromTheme(semanticBase);
    final sheetTheme = TasklySheetTheme.fromTheme(semanticBase);
    final insightTheme = TasklyInsightTheme.fromTheme(semanticBase);
    final rowChromeTheme = TasklyEntityRowChromeTheme.fromTheme(semanticBase);

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[
        tokens,
        chromeTheme,
        motionTheme,
        pageHeaderTheme,
        panelTheme,
        cardTheme,
        chipTheme,
        emptyStateTheme,
        sheetTheme,
        insightTheme,
        rowChromeTheme,
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
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.12),
          ),
        ),
        color: Color.alphaBlend(
          colorScheme.surfaceContainerLowest.withValues(alpha: 0.9),
          colorScheme.surface,
        ),
        margin: EdgeInsets.symmetric(
          horizontal: tokens.spaceMd,
          vertical: tokens.spaceXs,
        ),
      ),

      // Input decoration theme for forms
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide(
            color: colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: tokens.spaceLg,
          vertical: tokens.spaceMd,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 8,
        highlightElevation: 12,
        focusElevation: 10,
        hoverElevation: 10,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        extendedTextStyle: textTheme.titleSmall?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
        extendedPadding: EdgeInsets.symmetric(
          horizontal: tokens.spaceLg,
          vertical: tokens.spaceMd,
        ),
        sizeConstraints: BoxConstraints.tightFor(
          width: 64,
          height: 64,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusXxl),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 2,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.18),
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceLg,
            vertical: tokens.spaceMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusLg),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceLg,
            vertical: tokens.spaceMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusLg),
          ),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.65),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // List tile theme
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
        ),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        elevation: 0,
        pressElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusSm),
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
        backgroundColor: chromeTheme.navigationSurface,
        indicatorColor: chromeTheme.navigationIndicator,
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
        backgroundColor: chromeTheme.navigationSurface,
        indicatorColor: chromeTheme.navigationIndicator,
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
          borderRadius: BorderRadius.circular(tokens.radiusXs),
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
          borderRadius: BorderRadius.circular(tokens.radiusMd),
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
          borderRadius: BorderRadius.circular(tokens.radiusXxl),
        ),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),

      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(tokens.radiusXxl),
          ),
        ),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        dragHandleColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        dragHandleSize: Size(tokens.spaceXxl, tokens.spaceXs),
        showDragHandle: true,
      ),

      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const _TasklyPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Builds the text theme.
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.25,
        color: colorScheme.onSurface,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      headlineSmall: TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 23,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.15,
        color: colorScheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.05,
        color: colorScheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
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
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.65,
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

class _TasklyPageTransitionsBuilder extends PageTransitionsBuilder {
  const _TasklyPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.992, end: 1).animate(curved),
          child: child,
        ),
      ),
    );
  }
}
