import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/widgets/loading_state_widget.dart';

void main() {
  group('LoadingStateWidget', () {
    testWidgets('displays CircularProgressIndicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingStateWidget()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays message when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingStateWidget(message: 'Loading...')),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('does not display message when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingStateWidget()),
        ),
      );

      // Only the progress indicator, no text
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('centers content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingStateWidget()),
        ),
      );

      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('uses default size of 48', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingStateWidget()),
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

    testWidgets('respects custom size parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LoadingStateWidget(size: 100)),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, 100);
      expect(sizedBox.height, 100);
    });

    group('named constructors', () {
      testWidgets('compact creates smaller indicator', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: LoadingStateWidget.compact()),
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
      });

      testWidgets('listItem creates medium indicator', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: LoadingStateWidget.listItem()),
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
      });
    });
  });
}
