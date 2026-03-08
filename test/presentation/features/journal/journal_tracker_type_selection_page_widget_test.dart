@Tags(['widget', 'journal'])
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_tracker_type_selection_page.dart';

import '../../../helpers/test_imports.dart';

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  Future<void> pumpPage(
    WidgetTester tester, {
    required GoRouter router,
  }) async {
    await pumpLocalizedRouterApp(tester, router: router);
    await tester.pumpForStream();
  }

  testWidgetsSafe('scope selection goes straight to configure', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/journal/trackers/type',
      routes: [
        GoRoute(
          path: '/journal/trackers/type',
          builder: (_, __) => const JournalTrackerTypeSelectionPage(),
        ),
        GoRoute(
          path: '/journal/trackers/configure',
          builder: (_, state) =>
              Text('configure:${state.uri.queryParameters['scope']}'),
        ),
        GoRoute(
          path: '/journal/trackers/templates',
          builder: (_, __) => const Text('templates'),
        ),
      ],
    );

    await pumpPage(tester, router: router);

    await tester.tap(find.text('Moments'));
    await tester.pumpForStream();

    expect(find.text('configure:entry'), findsOneWidget);
    expect(find.text('templates'), findsNothing);
  });
}
