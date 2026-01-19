import 'package:flutter/material.dart';

/// Data model for rendering a value chip without domain dependencies.
///
/// This type is part of the public `taskly_ui` API and is safe to reference
/// from the app and other packages.
class ValueChipData {
  const ValueChipData({
    required this.label,
    required this.color,
    required this.icon,
    this.semanticLabel,
  });

  final String label;
  final Color color;
  final IconData icon;
  final String? semanticLabel;
}
