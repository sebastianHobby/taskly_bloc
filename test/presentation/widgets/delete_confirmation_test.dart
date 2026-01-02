import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/widgets/delete_confirmation.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('showDeleteConfirmationDialog', () {
    testWidgetsSafe('displays dialog with title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDeleteConfirmationDialog(
                  context: context,
                  title: 'Delete Task',
                  itemName: 'My Task',
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Task'), findsOneWidget);
    });

    testWidgetsSafe('displays item name in confirmation text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDeleteConfirmationDialog(
                  context: context,
                  title: 'Delete Task',
                  itemName: 'My Task',
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // RichText is used, so we look for the RichText widget that contains the item name
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('My Task'),
        ),
        findsOneWidget,
      );
    });

    testWidgetsSafe('displays description when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDeleteConfirmationDialog(
                  context: context,
                  title: 'Delete Task',
                  itemName: 'My Task',
                  description: 'This action cannot be undone',
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('This action cannot be undone'), findsOneWidget);
    });

    testWidgetsSafe('shows Cancel button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDeleteConfirmationDialog(
                  context: context,
                  title: 'Delete Task',
                  itemName: 'My Task',
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgetsSafe('shows Delete button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDeleteConfirmationDialog(
                  context: context,
                  title: 'Delete Task',
                  itemName: 'My Task',
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgetsSafe('returns false when Cancel is pressed', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDeleteConfirmationDialog(
                  context: context,
                  title: 'Delete Task',
                  itemName: 'My Task',
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgetsSafe('returns true when Delete is pressed', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDeleteConfirmationDialog(
                  context: context,
                  title: 'Delete Task',
                  itemName: 'My Task',
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgetsSafe('displays delete icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDeleteConfirmationDialog(
                  context: context,
                  title: 'Delete Task',
                  itemName: 'My Task',
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });
  });
}
