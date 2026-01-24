@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/theme/app_colors.dart';
import 'package:taskly_bloc/presentation/theme/app_theme.dart';
import 'package:taskly_bloc/presentation/theme/taskly_typography.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';

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

    final design = theme.extension<TasklyDesignExtension>();
    expect(design, isNotNull);
    expect(
      design!.urgentSurface,
      scheme.errorContainer.withValues(alpha: 0.2),
    );
    expect(design.neonAccent, scheme.primary);

    expect(theme.extension<TasklyTypography>(), isNotNull);
    expect(theme.extension<TasklyEntityTileTheme>(), isNotNull);
    expect(theme.extension<TasklyFeedTheme>(), isNotNull);
    expect(theme.extension<TasklyChromeTheme>(), isNotNull);
  });

  testSafe('TasklyChromeTheme copyWith and lerp preserve values', () async {
    final base = TasklyChromeTheme.fromTheme(ThemeData.light());
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

  testSafe('TasklyDesignExtension copyWith and lerp work', () async {
    const start = TasklyDesignExtension(
      urgentSurface: Color(0xFF000000),
      warningSurface: Color(0xFF111111),
      safeSurface: Color(0xFF222222),
      neonAccent: Color(0xFF333333),
      glassBorder: Color(0xFF444444),
    );
    const end = TasklyDesignExtension(
      urgentSurface: Color(0xFFFFFFFF),
      warningSurface: Color(0xFFEEEEEE),
      safeSurface: Color(0xFFDDDDDD),
      neonAccent: Color(0xFFCCCCCC),
      glassBorder: Color(0xFFBBBBBB),
    );

    final copy = start.copyWith(neonAccent: const Color(0xFFAAAAAA));
    expect(copy.neonAccent, const Color(0xFFAAAAAA));
    expect(copy.warningSurface, start.warningSurface);

    final lerped = start.lerp(end, 0.5);
    expect(
      lerped.urgentSurface,
      Color.lerp(start.urgentSurface, end.urgentSurface, 0.5),
    );
  });

  testSafe('AppSpacing and AppRadius expose expected constants', () async {
    expect(AppSpacing.xs, 4);
    expect(AppSpacing.cardPadding, const EdgeInsets.all(12));
    expect(AppRadius.md, 12);
    expect(AppRadius.xxl, 28);
  });
}
