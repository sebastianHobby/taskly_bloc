import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/widgets/swipe_to_delete.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('SwipeToDelete', () {
    testWidgetsSafe('renders child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeToDelete(
              itemKey: const ValueKey('item1'),
              onDismissed: () {},
              child: const Text('Test Item'),
            ),
          ),
        ),
      );

      expect(find.text('Test Item'), findsOneWidget);
    });

    testWidgetsSafe('wraps child in Dismissible when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeToDelete(
              itemKey: const ValueKey('item1'),
              onDismissed: () {},
              child: const Text('Test Item'),
            ),
          ),
        ),
      );

      expect(find.byType(Dismissible), findsOneWidget);
    });

    testWidgetsSafe('does not wrap in Dismissible when disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeToDelete(
              itemKey: const ValueKey('item1'),
              onDismissed: () {},
              enabled: false,
              child: const Text('Test Item'),
            ),
          ),
        ),
      );

      expect(find.byType(Dismissible), findsNothing);
      expect(find.text('Test Item'), findsOneWidget);
    });

    testWidgetsSafe('calls onDismissed when swiped away', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 50,
                child: SwipeToDelete(
                  itemKey: const ValueKey('item1'),
                  onDismissed: () => dismissed = true,
                  child: ColoredBox(
                    color: Colors.blue,
                    child: const Center(child: Text('Test Item')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Swipe to delete (left to right would be startToEnd,
      // right to left is endToStart which is the default)
      await tester.drag(find.text('Test Item'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgetsSafe('respects startToEnd direction', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 50,
                child: SwipeToDelete(
                  itemKey: const ValueKey('item1'),
                  onDismissed: () => dismissed = true,
                  direction: SwipeDirection.startToEnd,
                  child: ColoredBox(
                    color: Colors.blue,
                    child: const Center(child: Text('Test Item')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Swipe in the allowed direction
      await tester.drag(find.text('Test Item'), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgetsSafe('shows red delete background when swiping', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 50,
                child: SwipeToDelete(
                  itemKey: const ValueKey('item1'),
                  onDismissed: () {},
                  child: ColoredBox(
                    color: Colors.blue,
                    child: const Center(child: Text('Test Item')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Start dragging to show the background
      await tester.drag(find.text('Test Item'), const Offset(-100, 0));
      await tester.pump();

      // The background should show a delete icon
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });
  });

  group('SwipeDirection', () {
    test('has correct values', () {
      expect(SwipeDirection.values, hasLength(3));
      expect(SwipeDirection.startToEnd, isNotNull);
      expect(SwipeDirection.endToStart, isNotNull);
      expect(SwipeDirection.horizontal, isNotNull);
    });
  });
}
