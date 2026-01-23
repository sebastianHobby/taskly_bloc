import 'package:flutter/material.dart';

/// Utility class for color conversions and operations.
class ColorUtils {
  ColorUtils._();

  /// Converts a hex color string to a [Color].
  ///
  /// Accepts formats: `#RRGGBB`, `RRGGBB`, `#RGB`, `RGB`.
  /// Returns [fallback] if the string cannot be parsed.
  ///
  /// Example:
  /// ```dart
  /// ColorUtils.fromHex('#FF5733', fallback: Colors.blue); // Orange
  /// ColorUtils.fromHex('FF5733', fallback: Colors.blue);  // Same orange
  /// ColorUtils.fromHex(null, fallback: Colors.blue);      // Returns fallback
  /// ```
  static Color fromHex(String? hex, {required Color fallback}) {
    if (hex == null || hex.isEmpty) return fallback;

    final normalized = hex.replaceAll('#', '').toUpperCase();

    // Handle 3-character shorthand (e.g., "F00" -> "FF0000")
    String fullHex;
    if (normalized.length == 3) {
      fullHex = normalized.split('').map((c) => '$c$c').join();
    } else if (normalized.length == 6) {
      fullHex = normalized;
    } else {
      return fallback;
    }

    final value = int.tryParse('FF$fullHex', radix: 16);
    if (value == null) return fallback;

    return Color(value);
  }

  /// Converts a hex color string to a [Color], using a context-aware fallback.
  ///
  /// If parsing fails, returns the theme's primary color.
  static Color fromHexWithThemeFallback(BuildContext context, String? hex) {
    final fallback = Theme.of(context).colorScheme.primary;
    return fromHex(hex, fallback: fallback);
  }

  /// Converts a [Color] to a hex string without the alpha channel.
  ///
  /// Returns format: `RRGGBB` (no leading #).
  static String toHex(Color color) {
    final r = (color.r * 255.0)
        .round()
        .clamp(0, 255)
        .toRadixString(16)
        .padLeft(2, '0');
    final g = (color.g * 255.0)
        .round()
        .clamp(0, 255)
        .toRadixString(16)
        .padLeft(2, '0');
    final b = (color.b * 255.0)
        .round()
        .clamp(0, 255)
        .toRadixString(16)
        .padLeft(2, '0');
    return '$r$g$b'.toUpperCase();
  }

  /// Converts a [Color] to a hex string with the # prefix.
  ///
  /// Returns format: `#RRGGBB`.
  static String toHexWithHash(Color color) {
    return '#${toHex(color)}';
  }
}
