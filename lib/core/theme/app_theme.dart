import 'package:flutter/material.dart';

/// Centralized application theme.
///
/// Keep this small and incremental to avoid accidental UX changes.
class AppTheme {
  AppTheme._();

  static ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
    );
  }
}
