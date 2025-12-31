import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/widgets/error_state_widget.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('ErrorStateWidget', () {
    testWidgets('renders icon and message', (tester) async {
      await pumpLocalizedApp(
        tester,
        home: const Scaffold(
          body: ErrorStateWidget(
            message: 'Something went wrong',
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('renders retry button when onRetry provided', (tester) async {
      var retryCalled = false;

      await pumpLocalizedApp(
        tester,
        home: Scaffold(
          body: ErrorStateWidget(
            message: 'Error occurred',
            onRetry: () => retryCalled = true,
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      expect(retryCalled, isTrue);
    });

    testWidgets('does not render retry button when onRetry is null', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        home: const Scaffold(
          body: ErrorStateWidget(
            message: 'Error occurred',
          ),
        ),
      );

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('uses custom retryLabel', (tester) async {
      await pumpLocalizedApp(
        tester,
        home: Scaffold(
          body: ErrorStateWidget(
            message: 'Error',
            onRetry: () {},
            retryLabel: 'Try Again',
          ),
        ),
      );

      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('respects custom icon', (tester) async {
      await pumpLocalizedApp(
        tester,
        home: const Scaffold(
          body: ErrorStateWidget(
            message: 'Custom error',
            icon: Icons.warning,
          ),
        ),
      );

      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('respects custom iconSize', (tester) async {
      const customSize = 100.0;

      await pumpLocalizedApp(
        tester,
        home: const Scaffold(
          body: ErrorStateWidget(
            message: 'Test',
            iconSize: customSize,
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(iconWidget.size, customSize);
    });

    group('named constructors', () {
      testWidgets('.network renders cloud off icon', (tester) async {
        await pumpLocalizedApp(
          tester,
          home: const Scaffold(
            body: ErrorStateWidget.network(
              message: 'No internet connection',
            ),
          ),
        );

        expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
        expect(find.text('No internet connection'), findsOneWidget);
      });

      testWidgets('.network with retry button', (tester) async {
        var retryCalled = false;

        await pumpLocalizedApp(
          tester,
          home: Scaffold(
            body: ErrorStateWidget.network(
              message: 'Network error',
              onRetry: () => retryCalled = true,
              retryLabel: 'Reconnect',
            ),
          ),
        );

        expect(find.text('Reconnect'), findsOneWidget);

        await tester.tap(find.byType(FilledButton));
        expect(retryCalled, isTrue);
      });

      testWidgets('.notFound renders search off icon', (tester) async {
        await pumpLocalizedApp(
          tester,
          home: const Scaffold(
            body: ErrorStateWidget.notFound(
              message: 'No results found',
            ),
          ),
        );

        expect(find.byIcon(Icons.search_off_outlined), findsOneWidget);
        expect(find.text('No results found'), findsOneWidget);
      });

      testWidgets('.permission renders lock icon', (tester) async {
        await pumpLocalizedApp(
          tester,
          home: const Scaffold(
            body: ErrorStateWidget.permission(
              message: 'Access denied',
            ),
          ),
        );

        expect(find.byIcon(Icons.lock_outline), findsOneWidget);
        expect(find.text('Access denied'), findsOneWidget);
      });

      testWidgets('.permission with retry callback', (tester) async {
        var retryCalled = false;

        await pumpLocalizedApp(
          tester,
          home: Scaffold(
            body: ErrorStateWidget.permission(
              message: 'Permission error',
              onRetry: () => retryCalled = true,
            ),
          ),
        );

        await tester.tap(find.byType(FilledButton));
        expect(retryCalled, isTrue);
      });
    });
  });
}
