import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/emoji_utils.dart';

enum ValueChipVariant { solid, outlined }

/// A chip displaying a value with enhanced visual prominence.
///
/// Designed to be more visually distinct than regular label chips:
/// - Larger size with more padding
/// - Optional rank badge showing priority
/// - Colored background with emoji icon
/// - Subtle border/elevation for emphasis
///
/// Use [LabelChip] for regular labels, use this for values.
class ValueChip extends StatelessWidget {
  const ValueChip({
    required this.value,
    this.onTap,
    this.variant = ValueChipVariant.solid,
    super.key,
  });

  /// The value to display.
  final Value value;

  /// Optional tap handler. When provided, the chip becomes tappable.
  final VoidCallback? onTap;

  /// The visual variant (solid or outlined).
  final ValueChipVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = ColorUtils.fromHexWithThemeFallback(context, value.color);

    Color backgroundColor;
    Color textColor;
    BoxBorder? border;
    List<BoxShadow>? boxShadow;

    if (variant == ValueChipVariant.solid) {
      backgroundColor = color;
      textColor = color.computeLuminance() > 0.5
          ? Colors.black87
          : Colors.white;
      border = Border.all(
        color: colorScheme.outline.withOpacity(0.2),
        width: 1,
      );
      boxShadow = [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
    } else {
      backgroundColor = Colors.transparent;
      textColor = color;
      border = Border.all(color: color, width: 1);
      boxShadow = null;
    }

    // Get emoji icon
    final emoji = value.iconName?.isNotEmpty ?? false ? value.iconName! : '⭐';

    final chip = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: border,
        boxShadow: boxShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji icon (smaller)
          Text(
            emoji,
            style: EmojiUtils.emojiTextStyle(fontSize: 11),
          ),
          const SizedBox(width: 4),
          // Value name (smaller, less bold)
          Flexible(
            child: Text(
              value.name,
              style: theme.textTheme.labelSmall?.copyWith(
                color: textColor, // Use contrasting color
                fontWeight: FontWeight.w500, // Less bold
                fontSize: 11, // Smaller
              ),
              overflow: TextOverflow.ellipsis,
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
