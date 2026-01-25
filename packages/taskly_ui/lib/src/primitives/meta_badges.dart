import 'package:flutter/material.dart';

/// Shared primitives for compact meta badges across tiles.
class PriorityPill extends StatelessWidget {
  const PriorityPill({
    required this.priority,
    this.compact = false,
    this.textStyle,
    super.key,
  });

  final int priority;
  final bool compact;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = 'P$priority';

    final padding = EdgeInsets.symmetric(
      horizontal: compact ? 4 : 6,
      vertical: compact ? 1 : 2,
    );
    final baseStyle = (textStyle ?? Theme.of(context).textTheme.labelSmall)
        ?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
          fontWeight: FontWeight.w700,
          fontSize: compact ? 10 : null,
        );

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: baseStyle,
      ),
    );
  }
}

class MetaIconLabel extends StatelessWidget {
  const MetaIconLabel({
    required this.icon,
    required this.label,
    required this.color,
    this.textStyle,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: (textStyle ?? Theme.of(context).textTheme.labelSmall)
                ?.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
      ],
    );
  }
}
