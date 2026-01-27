import 'package:flutter/material.dart';

import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';
import 'package:taskly_ui/src/primitives/value_chip.dart';

enum ValueChipVariant { solid, outlined }

/// Internal widget for rendering value chips.
///
/// Note: this is intentionally NOT exported from the package public API.
class ValueChip extends StatelessWidget {
  const ValueChip({
    required this.data,
    this.onTap,
    this.variant = ValueChipVariant.solid,
    this.iconOnly = false,
    this.maxLabelWidth = 140,
    super.key,
  });

  /// The data to display.
  final ValueChipData data;

  /// Optional tap handler. When provided, the chip becomes tappable.
  final VoidCallback? onTap;

  /// The visual variant (solid or outlined).
  final ValueChipVariant variant;

  /// When true, renders as a more compact chip.
  ///
  /// This is primarily used in denser layouts (e.g., grouped headers) to keep
  /// tiles compact while still showing value identity.
  final bool iconOnly;

  /// Maximum width for the label when rendered.
  final double maxLabelWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);
    final color = data.color;
    final iconData = data.icon;

    // Visual language (UX-001/UX-002):
    // - Primary (solid): glass outline with crisp color identity.
    // - Secondary (outlined): icon-only, no fill.
    final backgroundColor = scheme.surfaceContainerLow;
    final borderColor = scheme.outline;
    final textColor = scheme.onSurface;

    final chip = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(tokens.radiusPill),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: iconOnly ? tokens.spaceXs2 : tokens.spaceSm,
        vertical: tokens.spaceXs,
      ),
      constraints: BoxConstraints(minHeight: tokens.minTapTargetSize),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 14, color: color.withValues(alpha: 0.8)),
          if (!iconOnly) ...[
            SizedBox(width: tokens.spaceXs2),
            Flexible(
              child: Padding(
                padding: EdgeInsets.only(bottom: tokens.spaceXxs),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxLabelWidth),
                  child: Text(
                    data.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
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
