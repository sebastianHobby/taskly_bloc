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
      id: 'calm_indigo',
      name: 'Calm Indigo',
      seedColor: Color(0xFF4F46E5),
    ),
    ThemePaletteOption(
      id: 'soft_blue',
      name: 'Soft Blue',
      seedColor: Color(0xFF3B82F6),
    ),
    ThemePaletteOption(
      id: 'mist_teal',
      name: 'Mist Teal',
      seedColor: Color(0xFF14B8A6),
    ),
    ThemePaletteOption(
      id: 'sage',
      name: 'Sage',
      seedColor: Color(0xFF34D399),
    ),
    ThemePaletteOption(
      id: 'fern',
      name: 'Fern',
      seedColor: Color(0xFF4ADE80),
    ),
    ThemePaletteOption(
      id: 'warm_amber',
      name: 'Warm Amber',
      seedColor: Color(0xFFFBBF24),
    ),
    ThemePaletteOption(
      id: 'slate',
      name: 'Slate',
      seedColor: Color(0xFF94A3B8),
    ),
  ];
}
