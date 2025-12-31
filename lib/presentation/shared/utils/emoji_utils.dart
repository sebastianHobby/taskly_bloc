import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Utility class for cross-platform emoji rendering.
///
/// Provides consistent emoji display across all platforms by using
/// the bundled NotoColorEmoji font on Windows and Linux, where
/// system emoji support is limited.
class EmojiUtils {
  EmojiUtils._();

  /// The font family name for the bundled emoji font.
  static const String emojiFontFamily = 'NotoColorEmoji';

  /// Whether the current platform needs a custom emoji font.
  ///
  /// Returns true for Windows and Linux where system emoji
  /// rendering is inconsistent or limited.
  static bool get needsCustomEmojiFont {
    if (kIsWeb) return false; // Web uses browser fonts
    return Platform.isWindows || Platform.isLinux;
  }

  /// Returns a [TextStyle] configured for emoji display.
  ///
  /// On Windows and Linux, uses the bundled NotoColorEmoji font.
  /// On other platforms, returns a style that uses system emoji fonts.
  ///
  /// [fontSize] - The size of the emoji. Defaults to 20.
  /// [baseStyle] - Optional base style to merge with emoji settings.
  static TextStyle emojiTextStyle({
    double fontSize = 20,
    TextStyle? baseStyle,
  }) {
    final style = TextStyle(
      fontSize: fontSize,
      fontFamily: needsCustomEmojiFont ? emojiFontFamily : null,
      fontFamilyFallback: needsCustomEmojiFont ? const [emojiFontFamily] : null,
    );

    if (baseStyle != null) {
      return baseStyle.merge(style);
    }
    return style;
  }

  /// Returns just the font family for emoji, or null if system fonts suffice.
  static String? get emojiFontFamilyOrNull {
    return needsCustomEmojiFont ? emojiFontFamily : null;
  }

  /// Returns the emoji text style for use in emoji picker config.
  ///
  /// Returns null on platforms with good system emoji support,
  /// allowing the picker to use default rendering.
  static TextStyle? get emojiPickerTextStyle {
    if (!needsCustomEmojiFont) return null;
    return const TextStyle(
      fontFamily: emojiFontFamily,
      fontSize: 24,
    );
  }
}
