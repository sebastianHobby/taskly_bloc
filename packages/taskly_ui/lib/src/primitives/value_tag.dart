import 'package:flutter/material.dart';

import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';
import 'package:taskly_ui/src/models/value_chip_data.dart';

enum ValueTagVariant { primary, secondary }

class ValueTag extends StatelessWidget {
  const ValueTag({
    required this.data,
    required this.variant,
    required this.maxLabelChars,
    this.iconOnly = false,
    super.key,
  });

  final ValueChipData data;
  final ValueTagVariant variant;
  final int maxLabelChars;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    final label = iconOnly
        ? null
        : ValueTagLayout.formatLabel(data.label, maxChars: maxLabelChars);
    final showLabel = label != null && label.isNotEmpty;

    final padding = ValueTagLayout.padding(
      tokens,
      variant: variant,
      iconOnly: iconOnly,
    );
    final gap = ValueTagLayout.gap(tokens);
    final iconSize = ValueTagLayout.iconSize(
      tokens,
      variant: variant,
      iconOnly: iconOnly,
    );

    final Color iconColor = switch (variant) {
      ValueTagVariant.primary => data.color,
      ValueTagVariant.secondary => scheme.onSurfaceVariant,
    };

    final Color textColor = switch (variant) {
      ValueTagVariant.primary => scheme.onSurfaceVariant,
      ValueTagVariant.secondary => scheme.onSurfaceVariant,
    };

    final Color? borderColor = switch (variant) {
      ValueTagVariant.primary => null,
      ValueTagVariant.secondary => null,
    };

    final Color bg = switch (variant) {
      ValueTagVariant.primary => data.color.withValues(alpha: 0.10),
      //ValueTagVariant.primary => Colors.transparent,
      ValueTagVariant.secondary => Colors.transparent,
    };

    final textStyle =
        (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(
          color: textColor,
          fontWeight: variant == ValueTagVariant.primary
              ? FontWeight.w500
              : FontWeight.w500,
        );

    final semanticsLabel = data.semanticLabel ?? data.label;

    if (variant == ValueTagVariant.secondary && iconOnly) {
      return Semantics(
        label: semanticsLabel,
        child: Icon(data.icon, size: iconSize, color: iconColor),
      );
    }

    return Semantics(
      label: semanticsLabel,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(ValueTagLayout.radius(tokens)),
          border: borderColor == null
              ? null
              : Border.all(
                  color: borderColor,
                  width: ValueTagLayout.borderWidth,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.icon, size: iconSize, color: iconColor),
            if (showLabel) ...[
              SizedBox(width: gap),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class ValueTagLayout {
  ValueTagLayout._();

  static const double borderWidth = 1;

  static EdgeInsets padding(
    TasklyTokens tokens, {
    required ValueTagVariant variant,
    required bool iconOnly,
  }) {
    if (variant == ValueTagVariant.secondary && iconOnly) {
      return EdgeInsets.zero;
    }

    return EdgeInsets.symmetric(
      horizontal: tokens.spaceXs2,
      vertical: tokens.spaceXxs,
    );
  }

  static double gap(TasklyTokens tokens) => tokens.spaceXxs2;

  static double iconSize(
    TasklyTokens tokens, {
    required ValueTagVariant variant,
    required bool iconOnly,
  }) {
    if (variant == ValueTagVariant.secondary && iconOnly) {
      return tokens.spaceLg2;
    }

    if (variant == ValueTagVariant.primary) {
      return tokens.spaceMd;
    }

    return tokens.spaceMd2;
  }

  static double radius(TasklyTokens tokens) => tokens.radiusXs;

  static String? formatLabel(String label, {required int maxChars}) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length <= maxChars) return trimmed;
    if (maxChars <= 3) return trimmed.substring(0, maxChars);
    final keep = maxChars - 3;
    return '${trimmed.substring(0, keep)}...';
  }

  static double measureWidth(
    BuildContext context, {
    required ValueChipData data,
    required ValueTagVariant variant,
    required bool iconOnly,
    required int maxLabelChars,
  }) {
    final tokens = TasklyTokens.of(context);
    final padding = ValueTagLayout.padding(
      tokens,
      variant: variant,
      iconOnly: iconOnly,
    );
    final gap = ValueTagLayout.gap(tokens);
    final iconSize = ValueTagLayout.iconSize(
      tokens,
      variant: variant,
      iconOnly: iconOnly,
    );
    final label = iconOnly
        ? null
        : ValueTagLayout.formatLabel(data.label, maxChars: maxLabelChars);
    final showLabel = label != null && label.isNotEmpty;

    final textStyle =
        (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(
          fontWeight: variant == ValueTagVariant.primary
              ? FontWeight.w700
              : FontWeight.w600,
        );

    double textWidth = 0;
    if (showLabel) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        maxLines: 1,
        textDirection: Directionality.of(context),
      )..layout();
      textWidth = painter.width;
    }

    if (variant == ValueTagVariant.secondary && iconOnly) {
      return iconSize;
    }

    const border = 0.0;

    final gapWidth = showLabel ? gap : 0.0;

    return padding.horizontal + iconSize + gapWidth + textWidth + border;
  }
}
