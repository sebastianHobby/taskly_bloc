import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/theme/app_theme.dart';

/// Pumps a Taskly-configured app wrapper.
///
/// Prefer using this instead of hand-rolling `MaterialApp` in tests.
/// Existing helpers (`pumpLocalizedApp`, `pumpLocalizedRouterApp`) delegate to
/// this function.
Future<void> pumpTasklyApp(
  WidgetTester tester, {
  Widget? home,
  GoRouter? router,
  ThemeData? theme,
  Locale? locale,
}) async {
  assert(
    home != null || router != null,
    'Provide either `home` or `router`.',
  );
  assert(
    home == null || router == null,
    'Provide only one of `home` or `router`.',
  );

  final ThemeData resolvedTheme = theme ?? AppTheme.lightTheme();

  if (router != null) {
    await tester.pumpWidget(
      MaterialApp.router(
        theme: resolvedTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        routerConfig: router,
      ),
    );
    return;
  }

  await tester.pumpWidget(
    MaterialApp(
      theme: resolvedTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Material(child: home),
    ),
  );
}

/// Pumps a [MaterialApp] configured with the app's theme and localizations.
Future<void> pumpLocalizedApp(
  WidgetTester tester, {
  required Widget home,
}) async {
  await pumpTasklyApp(tester, home: home);
}

/// Pumps a [MaterialApp.router] configured with the app's theme and
/// localizations.
Future<void> pumpLocalizedRouterApp(
  WidgetTester tester, {
  required GoRouter router,
}) async {
  await pumpTasklyApp(tester, router: router);
}
