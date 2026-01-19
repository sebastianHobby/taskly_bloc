import 'package:flutter/material.dart';

/// A small priority indicator using a flag icon.
class PriorityFlag extends StatelessWidget {
  const PriorityFlag({
    required this.priority,
    super.key,
    this.priority1Color,
    this.priority2Color,
    this.priority3Color,
    this.priority4Color,
    this.semanticsLabel,
    this.semanticsValue,
    this.size = 22,
  });

  /// Priority level (1-4). If null, the flag is not shown.
  final int? priority;

  /// Optional colors for priority 1-4.
  ///
  /// If not provided, defaults are derived from the current [ColorScheme].
  final Color? priority1Color;
  final Color? priority2Color;
  final Color? priority3Color;
  final Color? priority4Color;

  /// Optional semantics label.
  ///
  /// Shared UI must not hardcode user-facing strings; pass a localized label
  /// from the app if desired.
  final String? semanticsLabel;

  /// Optional semantics value.
  ///
  /// Shared UI must not hardcode user-facing strings; pass a localized value
  /// from the app if desired.
  final String? semanticsValue;

  final double size;

  @override
  Widget build(BuildContext context) {
    final p = priority;
    if (p == null) return const SizedBox.shrink();

    final color = _priorityColor(Theme.of(context).colorScheme, p);

    return Semantics(
      label: semanticsLabel,
      value: semanticsValue,
      child: Icon(
        Icons.flag,
        size: size,
        color: color,
      ),
    );
  }

  Color _priorityColor(ColorScheme scheme, int priority) {
    return switch (priority) {
      1 => priority1Color ?? scheme.error,
      2 => priority2Color ?? scheme.tertiary,
      3 => priority3Color ?? scheme.primary,
      4 => priority4Color ?? scheme.onSurfaceVariant,
      _ => scheme.onSurfaceVariant,
    };
  }
}
