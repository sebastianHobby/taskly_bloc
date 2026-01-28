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
  });

  /// Stable identifier used for analytics/debugging.
  final String id;

  /// Display name shown to the user.
  final String name;

  /// Seed color used to derive a Material 3 color scheme.
  final Color seedColor;

  /// Seed color value as ARGB int.
  int get seedArgb => seedColor.value;

  ColorScheme schemeFor(Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
  }
}

/// Curated seed palettes used by the theme picker.
class AppSeedPalettes {
  AppSeedPalettes._();

  /// Focused productivity palette set.
  static const List<ThemePaletteOption> focusedProductivity = [
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
}
