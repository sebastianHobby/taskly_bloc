@Tags(['widget', 'settings'])
library;

import 'package:flutter/widgets.dart';
import 'package:taskly_bloc/l10n/l10n.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_screen.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testWidgetsSafe('settings screen renders navigation items', (tester) async {
    await tester.pumpApp(const SettingsScreen());

    final l10n = tester.element(find.byType(SettingsScreen)).l10n;

    expect(find.text(l10n.settingsTitle), findsOneWidget);
    expect(find.text(l10n.settingsAppearanceTitle), findsOneWidget);
    expect(find.text(l10n.weeklyReviewTitle), findsOneWidget);
    expect(find.text(l10n.settingsLanguageRegionTitle), findsOneWidget);
    expect(find.text(l10n.settingsAccountTitle), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(l10n.settingsMicroLearningTitle),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(l10n.settingsMicroLearningTitle), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(l10n.settingsDeveloperTitle),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text(l10n.settingsDeveloperTitle),
      findsOneWidget,
    );
  });
}
