import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/emoji_utils.dart';

/// A chip displaying a single label with its color.
///
/// Used consistently across the app for displaying labels and values
/// in lists, cards, and wrapped layouts.
///
/// For values: uses colored background with contrasting text and emoji icon.
/// For labels: uses neutral background with colored label icon.
class LabelChip extends StatelessWidget {
  const LabelChip({
    required this.label,
    this.onTap,
    super.key,
  });

  /// The label to display.
  final Label label;

  /// Optional tap handler. When provided, the chip becomes tappable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = ColorUtils.fromHexWithThemeFallback(context, label.color);
    final isValue = label.type == LabelType.value;

    // For values: use full colored background with contrasting text
    // For labels: use colored background (with alpha) and colored icon
    final backgroundColor = isValue ? color : color.withValues(alpha: 0.15);
    final textColor = isValue
        ? (color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white)
        : colorScheme.onSurface;

    // Get the icon - emoji for values, colored label icon for labels
    final Widget icon;
    if (isValue) {
      final emoji = label.iconName?.isNotEmpty ?? false ? label.iconName! : '⭐';
      icon = Text(
        emoji,
        style: EmojiUtils.emojiTextStyle(fontSize: 12),
      );
    } else {
      icon = Icon(
        Icons.label,
        size: 12,
        color: color,
      );
    }

    final chip = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label.name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
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
