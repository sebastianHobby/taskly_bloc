@Tags(['widget'])
library;

import 'package:flutter/widgets.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/app_shell/scaffold_with_nested_navigation.dart';

import '../../helpers/test_imports.dart';

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
  });

  setUp(setUpTestEnvironment);

  testWidgetsSafe('journal destination is visible in primary navigation', (
    tester,
  ) async {
    await tester.pumpApp(
      const ScaffoldWithNestedNavigation(
        activeScreenId: 'my_day',
        child: SizedBox.shrink(),
      ),
    );
    await tester.pumpForStream();

    final l10n = tester.element(find.byType(ScaffoldWithNestedNavigation)).l10n;
    expect(find.text(l10n.journalTitle, skipOffstage: false), findsWidgets);
  });
}
