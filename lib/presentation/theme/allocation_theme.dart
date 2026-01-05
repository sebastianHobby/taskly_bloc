import 'package:flutter/material.dart';

/// Theme extension for allocation-specific colors and styles.
@immutable
class AllocationTheme extends ThemeExtension<AllocationTheme> {
  const AllocationTheme({
    required this.focusBlue,
    required this.completionGreen,
    required this.overdueRed,
    required this.pinnedGradient,
    required this.cardGradient,
    required this.glassBackground,
  });

  /// Dark theme defaults
  factory AllocationTheme.dark(ColorScheme colorScheme) {
    return AllocationTheme(
      focusBlue: colorScheme.primary,
      completionGreen: Colors.green.shade400,
      overdueRed: colorScheme.error,
      pinnedGradient: LinearGradient(
        colors: [
          colorScheme.primary.withValues(alpha: 0.8),
          colorScheme.primaryContainer,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      cardGradient: LinearGradient(
        colors: [
          colorScheme.surfaceContainerHighest,
          colorScheme.surfaceContainer,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      glassBackground: colorScheme.surface.withValues(alpha: 0.5),
    );
  }

  /// Light theme defaults
  factory AllocationTheme.light(ColorScheme colorScheme) {
    return AllocationTheme(
      focusBlue: colorScheme.primary,
      completionGreen: Colors.green.shade600,
      overdueRed: colorScheme.error,
      pinnedGradient: LinearGradient(
        colors: [
          colorScheme.primary,
          colorScheme.primaryContainer,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      cardGradient: LinearGradient(
        colors: [
          colorScheme.surfaceContainerHighest,
          colorScheme.surfaceContainer,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      glassBackground: colorScheme.surface.withValues(alpha: 0.7),
    );
  }

  final Color focusBlue;
  final Color completionGreen;
  final Color overdueRed;
  final LinearGradient pinnedGradient;
  final LinearGradient cardGradient;
  final Color glassBackground;

  @override
  ThemeExtension<AllocationTheme> copyWith({
    Color? focusBlue,
    Color? completionGreen,
    Color? overdueRed,
    LinearGradient? pinnedGradient,
    LinearGradient? cardGradient,
    Color? glassBackground,
  }) {
    return AllocationTheme(
      focusBlue: focusBlue ?? this.focusBlue,
      completionGreen: completionGreen ?? this.completionGreen,
      overdueRed: overdueRed ?? this.overdueRed,
      pinnedGradient: pinnedGradient ?? this.pinnedGradient,
      cardGradient: cardGradient ?? this.cardGradient,
      glassBackground: glassBackground ?? this.glassBackground,
    );
  }

  @override
  ThemeExtension<AllocationTheme> lerp(
    ThemeExtension<AllocationTheme>? other,
    double t,
  ) {
    if (other is! AllocationTheme) return this;
    return AllocationTheme(
      focusBlue: Color.lerp(focusBlue, other.focusBlue, t)!,
      completionGreen: Color.lerp(completionGreen, other.completionGreen, t)!,
      overdueRed: Color.lerp(overdueRed, other.overdueRed, t)!,
      pinnedGradient: LinearGradient.lerp(
        pinnedGradient,
        other.pinnedGradient,
        t,
      )!,
      cardGradient: LinearGradient.lerp(cardGradient, other.cardGradient, t)!,
      glassBackground: Color.lerp(glassBackground, other.glassBackground, t)!,
    );
  }
}
