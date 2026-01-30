@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_host_page.dart';

import '../../../helpers/test_imports.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testWidgetsSafe('renders full page when no back stack', (tester) async {
    var modalOpened = false;

    final router = GoRouter(
      initialLocation: '/edit',
      routes: [
        GoRoute(
          path: '/edit',
          builder: (context, state) => EditorHostPage(
            openModal: (context) async {
              modalOpened = true;
            },
            fullPageBuilder: (_) => const Text('FullPage'),
          ),
        ),
      ],
    );

    await pumpLocalizedRouterApp(tester, router: router);
    await tester.pumpForStream(5);

    expect(find.text('FullPage'), findsOneWidget);
    expect(modalOpened, isFalse);
  });

  testWidgetsSafe('opens modal when route can pop and closes on dismiss', (
    tester,
  ) async {
    var openCount = 0;

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            return Scaffold(
              body: const Center(child: Text('Home')),
              floatingActionButton: FilledButton(
                onPressed: () => context.push('/edit'),
                child: const Text('Open Edit'),
              ),
            );
          },
        ),
        GoRoute(
          path: '/edit',
          builder: (context, state) => EditorHostPage(
            openModal: (context) async {
              openCount += 1;
              return showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Modal Content'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Close Modal'),
                    ),
                  ],
                ),
              );
            },
            fullPageBuilder: (_) => const Text('FullPage'),
          ),
        ),
      ],
    );

    await pumpLocalizedRouterApp(tester, router: router);
    await tester.pumpForStream(5);

    await tester.tap(find.text('Open Edit'));
    await tester.pumpForStream(5);

    final foundModal = await tester.pumpUntilFound(
      find.text('Modal Content'),
      timeout: const Duration(seconds: 2),
    );
    expect(foundModal, isTrue);
    expect(openCount, 1);

    await tester.tap(find.text('Close Modal'));
    await tester.pumpForStream(5);

    final foundHome = await tester.pumpUntilFound(
      find.text('Home'),
      timeout: const Duration(seconds: 2),
    );
    expect(foundHome, isTrue);
  });

  testWidgetsSafe('does not auto-close when route changes during modal', (
    tester,
  ) async {
    var openCount = 0;

    late GoRouter router;
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            return Scaffold(
              body: const Center(child: Text('Home')),
              floatingActionButton: FilledButton(
                onPressed: () => context.push('/edit'),
                child: const Text('Open Edit'),
              ),
            );
          },
        ),
        GoRoute(
          path: '/edit',
          builder: (context, state) => EditorHostPage(
            openModal: (context) async {
              openCount += 1;
              return showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Modal Content'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Close Modal'),
                    ),
                  ],
                ),
              );
            },
            fullPageBuilder: (_) => const Text('FullPage'),
          ),
        ),
        GoRoute(
          path: '/other',
          builder: (context, state) {
            return const Scaffold(
              body: Center(child: Text('Other')),
            );
          },
        ),
      ],
    );

    await pumpLocalizedRouterApp(tester, router: router);
    await tester.pumpForStream(5);

    await tester.tap(find.text('Open Edit'));
    await tester.pumpForStream(5);

    final foundModal = await tester.pumpUntilFound(
      find.text('Modal Content'),
      timeout: const Duration(seconds: 2),
    );
    expect(foundModal, isTrue);
    expect(openCount, 1);

    router.go('/other');
    await tester.pumpForStream(5);

    final foundOther = await tester.pumpUntilFound(
      find.text('Other'),
      timeout: const Duration(seconds: 2),
    );
    expect(foundOther, isTrue);
  });
}
