import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';

enum ValueChipVariant { solid, outlined }

/// A chip displaying a value with enhanced visual prominence.
///
/// Designed to be more visually distinct than regular label chips:
/// - Larger size with more padding
/// - Optional rank badge showing priority
/// - Colored background emphasizing the value color
/// - Subtle border/elevation for emphasis
///
/// Use [LabelChip] for regular labels, use this for values.
class ValueChip extends StatelessWidget {
  const ValueChip({
    required this.value,
    this.onTap,
    this.variant = ValueChipVariant.solid,
    this.iconOnly = false,
    super.key,
  });

  /// The value to display.
  final Value value;

  /// Optional tap handler. When provided, the chip becomes tappable.
  final VoidCallback? onTap;

  /// The visual variant (solid or outlined).
  final ValueChipVariant variant;

  /// When true, renders as a more compact chip.
  ///
  /// This is primarily used in value-grouped list layouts to keep tiles
  /// compact while still showing value identity.
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ColorUtils.fromHexWithThemeFallback(context, value.color);

    // Visual language:
    // - Primary (solid): subtle tint fill, colored dot, neutral readable text.
    // - Secondary (outlined): outline, colored dot, neutral readable text.
    final backgroundColor = switch (variant) {
      ValueChipVariant.solid => color.withValues(alpha: 0.18),
      ValueChipVariant.outlined => Colors.transparent,
    };

    final borderColor = switch (variant) {
      ValueChipVariant.solid => color.withValues(alpha: 0.22),
      ValueChipVariant.outlined => color.withValues(alpha: 0.55),
    };

    final textColor = theme.colorScheme.onSurface;

    final chip = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      constraints: const BoxConstraints(minHeight: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  // Keep grouped/value-header layouts compact.
                  maxWidth: iconOnly ? 56 : 140,
                ),
                child: Text(
                  value.name,
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
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: chip,
      );
    }

    return chip;
  }
}
