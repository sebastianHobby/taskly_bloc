import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/widgets/empty_state_widget.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('EmptyStateWidget', () {
    testWidgets('renders icon, title, and description', (tester) async {
      await pumpLocalizedApp(
        tester,
        home: const Scaffold(
          body: EmptyStateWidget(
            icon: Icons.check,
            title: 'Test Title',
            description: 'Test Description',
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
    });

    testWidgets('renders without description when null', (tester) async {
      await pumpLocalizedApp(
        tester,
        home: const Scaffold(
          body: EmptyStateWidget(
            icon: Icons.check,
            title: 'Test Title',
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets(
      'renders action button when actionLabel and onAction provided',
      (tester) async {
        var actionCalled = false;

        await pumpLocalizedApp(
          tester,
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.check,
              title: 'Test Title',
              actionLabel: 'Do Something',
              onAction: () => actionCalled = true,
            ),
          ),
        );

        expect(find.text('Do Something'), findsOneWidget);
        expect(find.byType(FilledButton), findsOneWidget);

        await tester.tap(find.byType(FilledButton));
        expect(actionCalled, isTrue);
      },
    );

    testWidgets('does not render button when actionLabel is null', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        home: const Scaffold(
          body: EmptyStateWidget(
            icon: Icons.check,
            title: 'Test Title',
          ),
        ),
      );

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('does not render button when onAction is null', (tester) async {
      await pumpLocalizedApp(
        tester,
        home: const Scaffold(
          body: EmptyStateWidget(
            icon: Icons.check,
            title: 'Test Title',
            actionLabel: 'Click Me',
          ),
        ),
      );

      expect(find.byType(FilledButton), findsNothing);
    });

    group('named constructors', () {
      testWidgets('.noTasks renders task icon', (tester) async {
        await pumpLocalizedApp(
          tester,
          home: const Scaffold(
            body: EmptyStateWidget.noTasks(
              title: 'No Tasks',
              description: 'Add a task to get started',
            ),
          ),
        );

        expect(find.byIcon(Icons.task_alt_outlined), findsOneWidget);
        expect(find.text('No Tasks'), findsOneWidget);
        expect(find.text('Add a task to get started'), findsOneWidget);
      });

      testWidgets('.noProjects renders folder icon', (tester) async {
        await pumpLocalizedApp(
          tester,
          home: const Scaffold(
            body: EmptyStateWidget.noProjects(
              title: 'No Projects',
              description: 'Create a project to organize tasks',
            ),
          ),
        );

        expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
        expect(find.text('No Projects'), findsOneWidget);
      });

      testWidgets('.inbox renders inbox icon', (tester) async {
        await pumpLocalizedApp(
          tester,
          home: const Scaffold(
            body: EmptyStateWidget.inbox(
              title: 'Inbox Empty',
              description: 'No items in inbox',
            ),
          ),
        );

        expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
        expect(find.text('Inbox Empty'), findsOneWidget);
      });

      testWidgets('.today renders today icon', (tester) async {
        await pumpLocalizedApp(
          tester,
          home: const Scaffold(
            body: EmptyStateWidget.today(
              title: 'Nothing Today',
            ),
          ),
        );

        expect(find.byIcon(Icons.today_outlined), findsOneWidget);
        expect(find.text('Nothing Today'), findsOneWidget);
      });

      testWidgets('.upcoming renders calendar icon', (tester) async {
        await pumpLocalizedApp(
          tester,
          home: const Scaffold(
            body: EmptyStateWidget.upcoming(
              title: 'Nothing Upcoming',
            ),
          ),
        );

        expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
        expect(find.text('Nothing Upcoming'), findsOneWidget);
      });
    });

    testWidgets('respects custom iconSize', (tester) async {
      const customSize = 100.0;

      await pumpLocalizedApp(
        tester,
        home: const Scaffold(
          body: EmptyStateWidget(
            icon: Icons.check,
            title: 'Test',
            iconSize: customSize,
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.check));
      expect(iconWidget.size, customSize);
    });
  });
}
