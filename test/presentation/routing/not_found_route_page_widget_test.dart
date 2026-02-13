@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/routing/not_found_route_page.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';

import '../../helpers/test_imports.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testWidgetsSafe('shows default message when none provided', (tester) async {
    await tester.pumpApp(const NotFoundRoutePage());
    final foundPage = await tester.pumpUntilFound(
      find.byType(NotFoundRoutePage),
    );
    expect(foundPage, isTrue);

    final l10n = tester.element(find.byType(NotFoundRoutePage)).l10n;
    expect(find.text(l10n.notFoundTitle), findsOneWidget);
  });

  testWidgetsSafe('navigates home from empty state action', (tester) async {
    final router = GoRouter(
      initialLocation: '/404',
      routes: [
        GoRoute(
          path: '/404',
          builder: (_, __) => const NotFoundRoutePage(
            message: 'Missing',
            details: 'route missing',
          ),
        ),
        GoRoute(
          path: Routing.screenPath('my_day'),
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('My Day Home')),
          ),
        ),
      ],
    );

    await pumpLocalizedRouterApp(tester, router: router);
    final foundMissing = await tester.pumpUntilFound(find.text('Missing'));
    expect(foundMissing, isTrue);

    final l10n = tester.element(find.byType(NotFoundRoutePage)).l10n;
    expect(find.text('Missing'), findsOneWidget);
    await tester.tap(find.text(l10n.notFoundActionLabel));

    final foundHome = await tester.pumpUntilFound(
      find.text('My Day Home'),
      timeout: const Duration(seconds: 2),
    );
    expect(foundHome, isTrue);
  });
}
