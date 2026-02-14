import 'package:flutter/widgets.dart';

import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';
import 'package:taskly_ui/src/forms/taskly_form_ux_preset.dart';

@immutable
class TasklyFormPreset {
  const TasklyFormPreset({
    required this.chip,
    required this.ux,
  });

  factory TasklyFormPreset.standard(TasklyTokens tokens) {
    return TasklyFormPreset(
      chip: TasklyFormChipPreset.standard(tokens),
      ux: TasklyFormUxPreset.standard(tokens),
    );
  }

  final TasklyFormChipPreset chip;
  final TasklyFormUxPreset ux;
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
