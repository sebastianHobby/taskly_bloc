import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/widgets/error_state_widget.dart';

void main() {
  group('ErrorStateWidget', () {
    testWidgets('displays error message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(message: 'Something went wrong'),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('displays default error icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(message: 'Error'),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays custom icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              message: 'Error',
              icon: Icons.warning,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('displays retry button when onRetry provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              message: 'Error',
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('calls onRetry when button pressed', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              message: 'Error',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('hides retry button when onRetry null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(message: 'Error'),
          ),
        ),
      );

      expect(find.text('Retry'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('uses custom retry label when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(
              message: 'Error',
              onRetry: () {},
              retryLabel: 'Try Again',
            ),
          ),
        ),
      );

      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('renders widget correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorStateWidget(message: 'Error'),
          ),
        ),
      );

      // Verify ErrorStateWidget renders successfully
      expect(find.byType(ErrorStateWidget), findsOneWidget);
    });

    group('named constructors', () {
      testWidgets('network shows cloud_off icon', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ErrorStateWidget.network(message: 'Network error'),
            ),
          ),
        );

        expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
        expect(find.text('Network error'), findsOneWidget);
      });

      testWidgets('notFound shows search_off icon', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ErrorStateWidget.notFound(message: 'Not found'),
            ),
          ),
        );

        expect(find.byIcon(Icons.search_off_outlined), findsOneWidget);
        expect(find.text('Not found'), findsOneWidget);
      });

      testWidgets('permission shows lock icon', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ErrorStateWidget.permission(message: 'Access denied'),
            ),
          ),
        );

        expect(find.byIcon(Icons.lock_outline), findsOneWidget);
        expect(find.text('Access denied'), findsOneWidget);
      });
    });
  });
}
