import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A curated app theme palette option.
///
/// This represents a single seed color that can be used to derive a full
/// Material 3 [ColorScheme] via `ColorScheme.fromSeed`.
@immutable
class ThemePaletteOption {
  const ThemePaletteOption({
    required this.id,
    required this.name,
    required this.seedColor,
    this.secondarySeedColor,
  });

  /// Stable identifier used for analytics/debugging.
  final String id;

  /// Display name shown to the user.
  final String name;

  /// Seed color used to derive a Material 3 color scheme.
  final Color seedColor;

  /// Optional secondary seed color used to derive selection/highlight tones.
  final Color? secondarySeedColor;

  /// Seed color value as ARGB int.
  int get seedArgb => seedColor.value;

  ColorScheme schemeFor(Brightness brightness) {
    final primaryScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    final secondarySeed = secondarySeedColor;
    if (secondarySeed == null) {
      return primaryScheme;
    }

    final secondaryScheme = ColorScheme.fromSeed(
      seedColor: secondarySeed,
      brightness: brightness,
    );

    return primaryScheme.copyWith(
      secondary: secondaryScheme.secondary,
      onSecondary: secondaryScheme.onSecondary,
      secondaryContainer: secondaryScheme.secondaryContainer,
      onSecondaryContainer: secondaryScheme.onSecondaryContainer,
    );
  }
}

/// Curated seed palettes used by the theme picker.
class AppSeedPalettes {
  AppSeedPalettes._();

  /// Focused productivity palette set.
  static const List<ThemePaletteOption> focusedProductivity = [
    ThemePaletteOption(
      id: 'vibrant_teal',
      name: 'Vibrant Teal',
      seedColor: Color(0xFF00F5D4),
      secondarySeedColor: Color(0xFF1DE9B6),
    ),
    ThemePaletteOption(
      id: 'graphite_teal',
      name: 'Graphite Teal',
      seedColor: Color(0xFF2F5D62),
    ),
    ThemePaletteOption(
      id: 'slate_navy',
      name: 'Slate Navy',
      seedColor: Color(0xFF364152),
    ),
    ThemePaletteOption(
      id: 'warm_sand',
      name: 'Warm Sand',
      seedColor: Color(0xFF8A6B3F),
    ),
  ];

  static ThemePaletteOption? matchBySeedArgb(int seedArgb) {
    for (final palette in focusedProductivity) {
      if (palette.seedArgb == seedArgb) {
        return palette;
      }
    }
    return null;
  }
}
