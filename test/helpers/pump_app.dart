import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/theme/app_theme.dart';

/// Pumps a [MaterialApp] configured with the app's theme and localizations.
Future<void> pumpLocalizedApp(
  WidgetTester tester, {
  required Widget home,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.theme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}
