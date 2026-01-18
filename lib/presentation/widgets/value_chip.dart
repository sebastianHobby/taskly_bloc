import 'package:flutter/material.dart';

import 'package:taskly_ui/taskly_ui.dart' show ValueChipData;

enum ValueChipVariant { solid, outlined }

/// App-owned chip widget.
///
/// This intentionally mirrors Taskly UI chip visuals, but lives in the app so
/// `taskly_ui` can keep chip widgets out of its public API.
class ValueChip extends StatelessWidget {
  const ValueChip({
    required this.data,
    this.onTap,
    this.variant = ValueChipVariant.solid,
    this.iconOnly = false,
    super.key,
  });

  final ValueChipData data;
  final VoidCallback? onTap;
  final ValueChipVariant variant;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = data.color;
    final iconData = data.icon;

    final backgroundColor = switch (variant) {
      ValueChipVariant.solid => color.withValues(alpha: 0.18),
      ValueChipVariant.outlined => Colors.transparent,
    };

    final borderColor = switch (variant) {
      ValueChipVariant.solid => color.withValues(alpha: 0.22),
      ValueChipVariant.outlined => color.withValues(
        alpha: iconOnly ? 0.45 : 0.55,
      ),
    };

    final textColor = theme.colorScheme.onSurface;

    final chip = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: iconOnly ? 6 : 8,
        vertical: 2,
      ),
      constraints: const BoxConstraints(minHeight: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 14, color: color),
          if (!iconOnly) ...[
            const SizedBox(width: 6),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    data.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    Widget result = chip;

    if (onTap != null) {
      result = GestureDetector(
        onTap: onTap,
        child: result,
      );
    }

    final semanticsLabel = data.semanticLabel ?? data.label;

    return Semantics(
      label: semanticsLabel,
      button: onTap != null,
      child: result,
    );
  }
}
