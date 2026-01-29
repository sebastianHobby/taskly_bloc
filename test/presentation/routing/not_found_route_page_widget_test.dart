@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/presentation/routing/not_found_route_page.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';

import '../../helpers/test_imports.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testWidgetsSafe('shows default message when none provided', (tester) async {
    await tester.pumpApp(const NotFoundRoutePage());
    await tester.pumpForStream(3);

    expect(find.text('Page not found'), findsOneWidget);
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
    await tester.pumpForStream(5);

    expect(find.text('Missing'), findsOneWidget);
    await tester.tap(find.text('Go Home'));
    await tester.pumpForStream(5);

    final foundHome = await tester.pumpUntilFound(
      find.text('My Day Home'),
      timeout: const Duration(seconds: 2),
    );
    expect(foundHome, isTrue);
  });
}
