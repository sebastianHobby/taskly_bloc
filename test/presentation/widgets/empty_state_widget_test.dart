import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/widgets/empty_state_widget.dart';

void main() {
  group('EmptyStateWidget', () {
    testWidgets('displays title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox,
              title: 'No items',
            ),
          ),
        ),
      );

      expect(find.text('No items'), findsOneWidget);
    });

    testWidgets('displays icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox,
              title: 'No items',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('displays description when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox,
              title: 'No items',
              description: 'Add some items to get started',
            ),
          ),
        ),
      );

      expect(find.text('Add some items to get started'), findsOneWidget);
    });

    testWidgets('hides description when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox,
              title: 'No items',
            ),
          ),
        ),
      );

      // Only title text, no description
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      expect(textWidgets.length, 1);
    });

    testWidgets(
      'displays action button when actionLabel and onAction provided',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmptyStateWidget(
                icon: Icons.inbox,
                title: 'No items',
                actionLabel: 'Add Item',
                onAction: () {},
              ),
            ),
          ),
        );

        expect(find.text('Add Item'), findsOneWidget);
        expect(find.byType(FilledButton), findsOneWidget);
      },
    );

    testWidgets('calls onAction when button pressed', (tester) async {
      var actionCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox,
              title: 'No items',
              actionLabel: 'Add Item',
              onAction: () => actionCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Add Item'));
      await tester.pump();

      expect(actionCalled, isTrue);
    });

    testWidgets('hides action button when onAction null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox,
              title: 'No items',
              actionLabel: 'Add Item',
            ),
          ),
        ),
      );

      expect(find.text('Add Item'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('centers content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.inbox,
              title: 'No items',
            ),
          ),
        ),
      );

      // Verify EmptyStateWidget uses Center by finding the column inside it
      expect(
        find.ancestor(
          of: find.byType(Column),
          matching: find.byType(Center),
        ),
        findsOneWidget,
      );
    });

    group('named constructors', () {
      testWidgets('noTasks shows task icon', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmptyStateWidget.noTasks(title: 'No tasks'),
            ),
          ),
        );

        expect(find.byIcon(Icons.task_alt_outlined), findsOneWidget);
        expect(find.text('No tasks'), findsOneWidget);
      });

      testWidgets('noProjects shows folder icon', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmptyStateWidget.noProjects(title: 'No projects'),
            ),
          ),
        );

        expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
        expect(find.text('No projects'), findsOneWidget);
      });

      testWidgets('today shows today icon', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmptyStateWidget.today(title: 'Nothing for today'),
            ),
          ),
        );

        expect(find.byIcon(Icons.today_outlined), findsOneWidget);
        expect(find.text('Nothing for today'), findsOneWidget);
      });

      testWidgets('upcoming shows calendar icon', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmptyStateWidget.upcoming(title: 'Nothing upcoming'),
            ),
          ),
        );

        expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
        expect(find.text('Nothing upcoming'), findsOneWidget);
      });

      testWidgets('noLabels shows label icon', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmptyStateWidget.noLabels(title: 'No labels'),
            ),
          ),
        );

        expect(find.byIcon(Icons.label_outlined), findsOneWidget);
        expect(find.text('No labels'), findsOneWidget);
      });

      testWidgets('noValues shows heart icon', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmptyStateWidget.noValues(title: 'No values'),
            ),
          ),
        );

        expect(find.byIcon(Icons.favorite_border), findsOneWidget);
        expect(find.text('No values'), findsOneWidget);
      });
    });
  });
}
