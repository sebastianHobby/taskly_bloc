@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_ui/src/forms/taskly_form_preset.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

import 'helpers/test_helpers.dart';

void main() {
  testSafe('TasklyFormPreset.standard builds chip and ux presets', () async {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
    );
    final tokens = TasklyTokens.fromTheme(theme);

    final preset = TasklyFormPreset.standard(tokens);

    expect(preset.chip.borderRadius, tokens.radiusPill);
    expect(preset.chip.iconSize, tokens.spaceLg2);
    expect(preset.chip.clearIconSize, tokens.spaceLg);
    expect(preset.chip.minHeight, tokens.spaceXl + tokens.spaceMd);
    expect(preset.ux.sectionGapCompact, tokens.spaceMd);
    expect(preset.ux.sectionGapRegular, tokens.spaceLg);
    expect(preset.ux.selectorFill, isTrue);
    expect(preset.ux.selectorFocusWidth, 1.2);
  });
}
