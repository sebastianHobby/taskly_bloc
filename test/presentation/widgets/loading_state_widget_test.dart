import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/widgets/loading_state_widget.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('LoadingStateWidget', () {
    testWidgets('renders progress indicator', (tester) async {
      await pumpLocalizedApp(
        tester,
        home: const Scaffold(
          body: LoadingStateWidget(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders message when provided', (tester) async {
      await pumpLocalizedApp(
        tester,
        home: const Scaffold(
          body: LoadingStateWidget(
            message: 'Loading data...',
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading data...'), findsOneWidget);
    });

    testWidgets('does not render message when null', (tester) async {
      await pumpLocalizedApp(
        tester,
        home: const Scaffold(
          body: LoadingStateWidget(),
        ),
      );

      // Only the progress indicator, no text
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('respects custom size', (tester) async {
      const customSize = 80.0;

      await pumpLocalizedApp(
        tester,
        home: const Scaffold(
          body: LoadingStateWidget(
            size: customSize,
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, customSize);
      expect(sizedBox.height, customSize);
    });

    testWidgets('default size is 48', (tester) async {
      await pumpLocalizedApp(
        tester,
        home: const Scaffold(
          body: LoadingStateWidget(),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, 48);
      expect(sizedBox.height, 48);
    });

    group('named constructors', () {
      testWidgets('.compact has size 24 and no message', (tester) async {
        await pumpLocalizedApp(
          tester,
          home: const Scaffold(
            body: LoadingStateWidget.compact(),
          ),
        );

        final sizedBox = tester.widget<SizedBox>(
          find.ancestor(
            of: find.byType(CircularProgressIndicator),
            matching: find.byType(SizedBox),
          ),
        );
        expect(sizedBox.width, 24);
        expect(sizedBox.height, 24);
        expect(find.byType(Text), findsNothing);
      });

      testWidgets('.listItem has size 32 and no message', (tester) async {
        await pumpLocalizedApp(
          tester,
          home: const Scaffold(
            body: LoadingStateWidget.listItem(),
          ),
        );

        final sizedBox = tester.widget<SizedBox>(
          find.ancestor(
            of: find.byType(CircularProgressIndicator),
            matching: find.byType(SizedBox),
          ),
        );
        expect(sizedBox.width, 32);
        expect(sizedBox.height, 32);
        expect(find.byType(Text), findsNothing);
      });
    });

    testWidgets('uses thicker stroke for larger sizes', (tester) async {
      // Size > 32 should have strokeWidth 4
      await pumpLocalizedApp(
        tester,
        home: const Scaffold(
          body: LoadingStateWidget(),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.strokeWidth, 4);
    });

    testWidgets('uses thinner stroke for smaller sizes', (tester) async {
      // Size <= 32 should have strokeWidth 3
      await pumpLocalizedApp(
        tester,
        home: const Scaffold(
          body: LoadingStateWidget(
            size: 32,
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.strokeWidth, 3);
    });
  });
}
