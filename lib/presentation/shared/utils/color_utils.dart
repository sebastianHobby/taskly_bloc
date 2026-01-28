import 'package:flutter/material.dart';

/// Utility class for color conversions and operations.
class ColorUtils {
  ColorUtils._();

  static const String valueBlueId = '#2F6FE4';
  static const String valueTealId = '#0E7C7B';
  static const String valueGreenId = '#1C8A5E';
  static const String valueVioletId = '#6A4BC7';
  static const String valueAmberId = '#C07A18';
  static const String valueRoseId = '#B21E5B';
  static const String valueRedId = '#C83E3E';
  static const String valueSlateId = '#4B5563';

  static const List<ValueColorOption> valuePalette = <ValueColorOption>[
    ValueColorOption(
      id: valueBlueId,
      light: Color(0xFF2F6FE4),
      dark: Color(0xFF6EA0FF),
    ),
    ValueColorOption(
      id: valueTealId,
      light: Color(0xFF0E7C7B),
      dark: Color(0xFF3BC9C6),
    ),
    ValueColorOption(
      id: valueGreenId,
      light: Color(0xFF1C8A5E),
      dark: Color(0xFF59D19A),
    ),
    ValueColorOption(
      id: valueVioletId,
      light: Color(0xFF6A4BC7),
      dark: Color(0xFF9F86FF),
    ),
    ValueColorOption(
      id: valueAmberId,
      light: Color(0xFFC07A18),
      dark: Color(0xFFF0B24D),
    ),
    ValueColorOption(
      id: valueRoseId,
      light: Color(0xFFB21E5B),
      dark: Color(0xFFF0709B),
    ),
    ValueColorOption(
      id: valueRedId,
      light: Color(0xFFC83E3E),
      dark: Color(0xFFFF7B7B),
    ),
    ValueColorOption(
      id: valueSlateId,
      light: Color(0xFF4B5563),
      dark: Color(0xFF9AA4B2),
    ),
  ];

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

  /// Resolves a stored Value color into a theme-aware [Color].
  ///
  /// If the hex matches a curated palette ID (light or dark), we return the
  /// theme-appropriate swatch. Otherwise, we fall back to the stored hex.
  static Color valueColorForTheme(
    BuildContext context,
    String? hex, {
    Color? fallback,
  }) {
    final effectiveFallback = fallback ?? Theme.of(context).colorScheme.primary;
    final option = _paletteForHex(hex);
    if (option != null) {
      return Theme.of(context).brightness == Brightness.dark
          ? option.dark
          : option.light;
    }
    return fromHex(hex, fallback: effectiveFallback);
  }

  /// Returns the palette ID (light hex) for a curated Value color.
  ///
  /// If the color is not in the palette, returns null.
  static String? valuePaletteIdForColor(Color color) {
    final normalized = _normalizeHex(toHexWithHash(color));
    if (normalized == null) return null;
    for (final option in valuePalette) {
      if (normalized == _normalizeHex(option.id) ||
          normalized == _normalizeHex(toHexWithHash(option.light)) ||
          normalized == _normalizeHex(toHexWithHash(option.dark))) {
        return option.id;
      }
    }
    return null;
  }

  /// Returns the palette ID when the color is curated, otherwise hex.
  static String valuePaletteIdOrHex(Color color) {
    return valuePaletteIdForColor(color) ?? toHexWithHash(color);
  }

  /// Returns the curated palette for a theme brightness.
  static List<Color> valuePaletteColorsFor(Brightness brightness) {
    return valuePalette
        .map(
          (option) =>
              brightness == Brightness.dark ? option.dark : option.light,
        )
        .toList(growable: false);
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

  static ValueColorOption? _paletteForHex(String? hex) {
    final normalized = _normalizeHex(hex);
    if (normalized == null) return null;
    for (final option in valuePalette) {
      if (normalized == _normalizeHex(option.id) ||
          normalized == _normalizeHex(toHexWithHash(option.light)) ||
          normalized == _normalizeHex(toHexWithHash(option.dark))) {
        return option;
      }
    }
    return null;
  }

  static String? _normalizeHex(String? hex) {
    if (hex == null) return null;
    final normalized = hex.replaceAll('#', '').trim();
    if (normalized.isEmpty) return null;
    return normalized.toUpperCase();
  }
}

@immutable
final class ValueColorOption {
  const ValueColorOption({
    required this.id,
    required this.light,
    required this.dark,
  });

  /// Stable ID (stored in the database) - should be the light hex.
  final String id;
  final Color light;
  final Color dark;
}
