@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/theme/app_colors.dart';
import 'package:taskly_bloc/presentation/theme/app_theme.dart';
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
