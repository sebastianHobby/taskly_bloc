import 'package:flutter/material.dart';

import 'package:taskly_ui/src/models/value_chip_data.dart';

/// Circular value icon used in entity tiles.
class ValueIcon extends StatelessWidget {
  const ValueIcon({
    required this.data,
    this.useValueColor = true,
    this.size = 18,
    this.iconSize = 12,
    super.key,
  });

  final ValueChipData data;

  /// When true, uses the value's accent color. When false, uses a neutral tint.
  final bool useValueColor;

  /// Outer circle size.
  final double size;

  /// Inner icon size.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = useValueColor
        ? data.color.withValues(alpha: 0.95)
        : scheme.onSurfaceVariant.withValues(alpha: 0.7);

    return Tooltip(
      message: data.label,
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 10),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.8), width: 1.25),
        ),
        child: Center(
          child: Icon(data.icon, size: iconSize, color: color),
        ),
      ),
    );
  }
}
