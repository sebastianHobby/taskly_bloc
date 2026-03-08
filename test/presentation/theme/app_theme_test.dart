@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/theme/app_colors.dart';
import 'package:taskly_bloc/presentation/theme/app_theme.dart';
import 'package:taskly_ui/taskly_ui_theme.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

import '../../helpers/test_environment.dart';
import '../../helpers/test_imports.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testSafe('AppTheme.lightTheme uses the provided seed color', () async {
    const seed = Color(0xFF123456);
    final theme = AppTheme.lightTheme(seedColor: seed);
    final expectedScheme = ColorScheme.fromSeed(seedColor: seed);

    expect(theme.colorScheme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, expectedScheme.primary);
    expect(theme.appBarTheme.backgroundColor, expectedScheme.background);
  });

  testSafe('AppTheme.darkTheme uses dark brightness', () async {
    final theme = AppTheme.darkTheme();

    expect(theme.colorScheme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, theme.colorScheme.background);
  });

  testSafe('AppTheme uses secondary seed overrides when configured', () async {
    const primarySeed = Color(0xFF00F5D4);
    const secondarySeed = Color(0xFF1DE9B6);
    final theme = AppTheme.darkTheme(seedColor: primarySeed);
    final secondaryScheme = ColorScheme.fromSeed(
      seedColor: secondarySeed,
      brightness: Brightness.dark,
    );

    expect(theme.colorScheme.secondary, secondaryScheme.secondary);
    expect(
      theme.colorScheme.secondaryContainer,
      secondaryScheme.secondaryContainer,
    );
  });

  testSafe('AppTheme.tasklyTheme wires Taskly extensions', () async {
    final theme = AppTheme.tasklyTheme(seedColor: AppColors.blueberry80);
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.blueberry80,
      brightness: Brightness.dark,
    );

    final tokens = theme.extension<TasklyTokens>();
    expect(tokens, isNotNull);
    expect(
      tokens!.urgentSurface,
      scheme.errorContainer.withValues(alpha: 0.2),
    );
    expect(tokens.neonAccent, scheme.primary);
    expect(theme.extension<TasklyAppChromeTheme>(), isNotNull);
    expect(theme.extension<TasklyPageHeaderTheme>(), isNotNull);
    expect(theme.extension<TasklyPanelTheme>(), isNotNull);
    expect(theme.extension<TasklyCardTheme>(), isNotNull);
    expect(theme.extension<TasklyChipTheme>(), isNotNull);
    expect(theme.extension<TasklyEmptyStateTheme>(), isNotNull);
    expect(theme.extension<TasklySheetTheme>(), isNotNull);
    expect(theme.extension<TasklyInsightTheme>(), isNotNull);
    expect(theme.extension<TasklyEntityRowChromeTheme>(), isNotNull);
  });

  testSafe('Semantic theme extensions derive expected default roles', () async {
    final theme = AppTheme.lightTheme(seedColor: AppColors.blueberry80);
    final chromeTheme = theme.extension<TasklyAppChromeTheme>();
    final headerTheme = theme.extension<TasklyPageHeaderTheme>();
    final panelTheme = theme.extension<TasklyPanelTheme>();
    final cardTheme = theme.extension<TasklyCardTheme>();
    final chipTheme = theme.extension<TasklyChipTheme>();
    final emptyStateTheme = theme.extension<TasklyEmptyStateTheme>();
    final sheetTheme = theme.extension<TasklySheetTheme>();
    final insightTheme = theme.extension<TasklyInsightTheme>();
    final rowChromeTheme = theme.extension<TasklyEntityRowChromeTheme>();

    expect(chromeTheme, isNotNull);
    expect(headerTheme, isNotNull);
    expect(panelTheme, isNotNull);
    expect(cardTheme, isNotNull);
    expect(chipTheme, isNotNull);
    expect(emptyStateTheme, isNotNull);
    expect(sheetTheme, isNotNull);
    expect(insightTheme, isNotNull);
    expect(rowChromeTheme, isNotNull);
    expect(
      chromeTheme!.navigationSurface,
      theme.colorScheme.surfaceContainerLow,
    );
    expect(headerTheme!.iconColor, theme.colorScheme.primary);
    expect(panelTheme!.subtleSurface, theme.colorScheme.surfaceContainerLow);
    expect(
      cardTheme!.surface(TasklyCardVariant.subtle),
      theme.colorScheme.surfaceContainerLow,
    );
    expect(
      chipTheme!.background(TasklyChipVariant.status),
      theme.colorScheme.primaryContainer,
    );
    expect(emptyStateTheme!.titleColor, theme.colorScheme.onSurface);
    expect(
      sheetTheme!.background(TasklySheetVariant.supporting),
      theme.colorScheme.surfaceContainerLow,
    );
    expect(insightTheme!.highlight, theme.colorScheme.primary);
    expect(
      rowChromeTheme!.divider,
      theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
    );
  });

  testSafe('TasklyTokens copyWith and lerp preserve values', () async {
    final base = TasklyTokens.fromTheme(ThemeData.light());
    final updated = base.copyWith(
      iconButtonMinSize: base.iconButtonMinSize + 10,
      monthStripDotSize: base.monthStripDotSize + 2,
    );

    expect(updated.iconButtonMinSize, base.iconButtonMinSize + 10);
    expect(updated.monthStripDotSize, base.monthStripDotSize + 2);

    final lerped = base.lerp(updated, 0.5);
    expect(
      lerped.iconButtonMinSize,
      closeTo(base.iconButtonMinSize + 5, 0.001),
    );
  });

  testSafe('TasklyTokens exposes expected spacing/radius constants', () async {
    final tokens = TasklyTokens.fromTheme(ThemeData.light());
    expect(tokens.spaceXs, 4);
    expect(tokens.spaceMd, 12);
    expect(tokens.radiusMd, 12);
    expect(tokens.radiusXxl, 28);
  });
}
