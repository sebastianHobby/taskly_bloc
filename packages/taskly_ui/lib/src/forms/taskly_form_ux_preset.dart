import 'package:flutter/material.dart';

import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

@immutable
class TasklyFormUxPreset {
  const TasklyFormUxPreset({
    required this.sectionGapCompact,
    required this.sectionGapRegular,
    required this.subsectionGap,
    required this.notesContentPadding,
    required this.notesMinLinesCompact,
    required this.notesMinLinesRegular,
    required this.notesMaxLinesCompact,
    required this.notesMaxLinesRegular,
    required this.selectorFill,
    required this.selectorFocusWidth,
  });

  factory TasklyFormUxPreset.standard(TasklyTokens tokens) {
    return TasklyFormUxPreset(
      sectionGapCompact: tokens.spaceMd,
      sectionGapRegular: tokens.spaceLg,
      subsectionGap: tokens.spaceSm,
      notesContentPadding: EdgeInsets.symmetric(
        horizontal: tokens.spaceLg,
        vertical: tokens.spaceMd,
      ),
      notesMinLinesCompact: 2,
      notesMinLinesRegular: 3,
      notesMaxLinesCompact: 3,
      notesMaxLinesRegular: 4,
      selectorFill: true,
      selectorFocusWidth: 1.2,
    );
  }

  final double sectionGapCompact;
  final double sectionGapRegular;
  final double subsectionGap;
  final EdgeInsets notesContentPadding;
  final int notesMinLinesCompact;
  final int notesMinLinesRegular;
  final int notesMaxLinesCompact;
  final int notesMaxLinesRegular;
  final bool selectorFill;
  final double selectorFocusWidth;
}
