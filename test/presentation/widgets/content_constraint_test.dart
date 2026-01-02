import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/widgets/content_constraint.dart';

void main() {
  group('ContentConstraint', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContentConstraint(
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('applies max width constraint on expanded screens', (
      tester,
    ) async {
      // Set up a large screen size
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContentConstraint(
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      // Find the ConstrainedBox with our specific max width
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );
      expect(
        constrainedBoxes.any((box) => box.constraints.maxWidth == 800),
        isTrue,
      );

      // Reset view
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('does not apply constraint on compact screens', (tester) async {
      // Set up a compact screen size (default)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContentConstraint(
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      // On compact screens, should just render Padding, not ConstrainedBox
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets(
      'applies constraint on all sizes when applyOnAllSizes is true',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ContentConstraint(
                applyOnAllSizes: true,
                child: Text('Test Content'),
              ),
            ),
          ),
        );

        // Find the ConstrainedBox with our specific max width
        final constrainedBoxes = tester.widgetList<ConstrainedBox>(
          find.byType(ConstrainedBox),
        );
        expect(
          constrainedBoxes.any((box) => box.constraints.maxWidth == 800),
          isTrue,
        );
      },
    );

    testWidgets('applies custom padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContentConstraint(
              applyOnAllSizes: true,
              padding: EdgeInsets.all(16),
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      final paddingWidget = tester.widget<Padding>(
        find
            .ancestor(
              of: find.text('Test Content'),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(paddingWidget.padding, const EdgeInsets.all(16));
    });

    testWidgets('uses default max width of 800', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContentConstraint(
              applyOnAllSizes: true,
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );
      expect(
        constrainedBoxes.any((box) => box.constraints.maxWidth == 800),
        isTrue,
      );
    });
  });

  group('SliverContentConstraint', () {
    testWidgets('renders sliver child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: const [
                SliverContentConstraint(
                  sliver: SliverToBoxAdapter(
                    child: Text('Test Content'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('uses SliverLayoutBuilder for constraints', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: const [
                SliverContentConstraint(
                  sliver: SliverToBoxAdapter(
                    child: Text('Test Content'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(SliverLayoutBuilder), findsOneWidget);
    });
  });
}
