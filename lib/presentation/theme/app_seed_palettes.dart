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
      id: 'calm_professional',
      name: 'Calm Professional',
      seedColor: Color(0xFF6750A4),
    ),
    ThemePaletteOption(
      id: 'minimalist_slate',
      name: 'Minimalist Slate',
      seedColor: Color(0xFF475569),
    ),
    ThemePaletteOption(
      id: 'deep_forest',
      name: 'Deep Forest',
      seedColor: Color(0xFF064E3B),
    ),
  ];
}
