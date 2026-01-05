import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/emoji_utils.dart';

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
    this.rank,
    this.onTap,
    super.key,
  });

  /// The value to display.
  final Value value;

  /// Optional rank to display (1-based). Shows as "#1", "#2", etc.
  final int? rank;

  /// Optional tap handler. When provided, the chip becomes tappable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = ColorUtils.fromHexWithThemeFallback(context, value.color);

    // Contrasting text color based on background luminance
    final textColor = color.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;

    // Get emoji icon
    final emoji = value.iconName?.isNotEmpty ?? false ? value.iconName! : '⭐';

    final chip = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rank badge (if provided)
          if (rank != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '#$rank',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
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
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: chip,
      );
    }

    return chip;
  }
}
