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
      id: 'focused_indigo',
      name: 'Indigo',
      seedColor: Color(0xFF4F46E5),
    ),
    ThemePaletteOption(
      id: 'focused_sky',
      name: 'Sky',
      seedColor: Color(0xFF0EA5E9),
    ),
    ThemePaletteOption(
      id: 'focused_teal',
      name: 'Teal',
      seedColor: Color(0xFF14B8A6),
    ),
    ThemePaletteOption(
      id: 'focused_amber',
      name: 'Amber',
      seedColor: Color(0xFFF59E0B),
    ),
  ];
}
