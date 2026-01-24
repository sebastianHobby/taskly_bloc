import 'package:flutter/widgets.dart';

@immutable
class TasklyFormPreset {
  const TasklyFormPreset({
    required this.chip,
  });

  final TasklyFormChipPreset chip;

  static const standard = TasklyFormPreset(
    chip: TasklyFormChipPreset.standard,
  );
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

  final double borderRadius;
  final EdgeInsets padding;
  final double iconSize;
  final double clearIconSize;
  final double clearHitPadding;
  final double minHeight;

  static const standard = TasklyFormChipPreset(
    borderRadius: 999,
    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    iconSize: 18,
    clearIconSize: 16,
    clearHitPadding: 6,
    minHeight: 36,
  );
}
