import 'package:flutter/widgets.dart';

import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

@immutable
class TasklyFormPreset {
  const TasklyFormPreset({
    required this.chip,
  });

  factory TasklyFormPreset.standard(TasklyTokens tokens) {
    return TasklyFormPreset(
      chip: TasklyFormChipPreset.standard(tokens),
    );
  }

  final TasklyFormChipPreset chip;
}

@immutable
class TasklyFormChipPreset {
  const TasklyFormChipPreset({
    required this.borderRadius,
    required this.padding,
    required this.iconSize,
    required this.clearIconSize,
    required this.clearHitPadding,
    required this.minHeight,
  });

  factory TasklyFormChipPreset.standard(TasklyTokens tokens) {
    return TasklyFormChipPreset(
      borderRadius: tokens.radiusPill,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMd2,
        vertical: tokens.spaceSm,
      ),
      iconSize: tokens.spaceLg2,
      clearIconSize: tokens.spaceLg,
      clearHitPadding: tokens.spaceXs2,
      minHeight: tokens.spaceXl + tokens.spaceMd,
    );
  }

  final double borderRadius;
  final EdgeInsets padding;
  final double iconSize;
  final double clearIconSize;
  final double clearHitPadding;
  final double minHeight;
}
