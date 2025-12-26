import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/widgets/recurrence_picker.dart';

void main() {
  group('RecurrencePicker', () {
    testWidgets('renders without errors', (tester) async {
      String? capturedRRule;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrencePicker(
              initialRRule: null,
              onRRuleChanged: (value) {
                capturedRRule = value;
              },
            ),
          ),
        ),
      );

      expect(find.byType(RecurrencePicker), findsOneWidget);
    });

    testWidgets('displays "Does not repeat" by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrencePicker(
              initialRRule: null,
              onRRuleChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Does not repeat'), findsOneWidget);
    });

    testWidgets('shows frequency selector', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrencePicker(
              initialRRule: null,
              onRRuleChanged: (_) {},
            ),
          ),
        ),
      );

      // Should have frequency dropdown
      expect(
        find.byType(DropdownButtonFormField<RecurrenceFrequency>),
        findsOneWidget,
      );
    });

    testWidgets('changes frequency to daily', (tester) async {
      String? capturedRRule;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrencePicker(
              initialRRule: null,
              onRRuleChanged: (value) {
                capturedRRule = value;
              },
            ),
          ),
        ),
      );

      // Find and tap the frequency dropdown
      await tester.tap(
        find.byType(DropdownButtonFormField<RecurrenceFrequency>),
      );
      await tester.pumpAndSettle();

      // Select daily
      await tester.tap(find.text('Daily').last);
      await tester.pumpAndSettle();

      // Verify the rrule was generated
      expect(capturedRRule, isNotNull);
      expect(capturedRRule, contains('FREQ=DAILY'));
    });

    testWidgets('changes frequency to weekly', (tester) async {
      String? capturedRRule;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrencePicker(
              initialRRule: null,
              onRRuleChanged: (value) {
                capturedRRule = value;
              },
            ),
          ),
        ),
      );

      // Find and tap the frequency dropdown
      await tester.tap(
        find.byType(DropdownButtonFormField<RecurrenceFrequency>),
      );
      await tester.pumpAndSettle();

      // Select weekly
      await tester.tap(find.text('Weekly').last);
      await tester.pumpAndSettle();

      // Verify the rrule was generated
      expect(capturedRRule, isNotNull);
      expect(capturedRRule, contains('FREQ=WEEKLY'));
    });

    testWidgets('parses initial daily rrule correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrencePicker(
              initialRRule: 'RRULE:FREQ=DAILY;INTERVAL=1',
              onRRuleChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show "Every day" or similar text
      expect(find.textContaining('Every'), findsOneWidget);
    });

    testWidgets('parses initial weekly rrule correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrencePicker(
              initialRRule: 'RRULE:FREQ=WEEKLY;INTERVAL=1;BYDAY=MO,WE,FR',
              onRRuleChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show "Every week" or similar text
      expect(find.textContaining('Every'), findsOneWidget);
    });

    testWidgets('updates interval correctly', (tester) async {
      String? capturedRRule;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrencePicker(
              initialRRule: null,
              onRRuleChanged: (value) {
                capturedRRule = value;
              },
            ),
          ),
        ),
      );

      // Select daily first
      await tester.tap(
        find.byType(DropdownButtonFormField<RecurrenceFrequency>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Daily').last);
      await tester.pumpAndSettle();

      // Find interval text field
      final intervalField = find.byType(TextFormField).first;
      await tester.tap(intervalField);
      await tester.enterText(intervalField, '2');
      await tester.pumpAndSettle();

      // Verify the rrule contains INTERVAL=2
      expect(capturedRRule, contains('INTERVAL=2'));
    });

    testWidgets('can set end date (until)', (tester) async {
      String? capturedRRule;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrencePicker(
              initialRRule: null,
              onRRuleChanged: (value) {
                capturedRRule = value;
              },
            ),
          ),
        ),
      );

      // Select daily first
      await tester.tap(
        find.byType(DropdownButtonFormField<RecurrenceFrequency>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Daily').last);
      await tester.pumpAndSettle();

      // Look for end condition controls
      // The widget should have radio buttons or similar for Never/Until/After
      expect(find.byType(RadioListTile<RecurrenceEnd>), findsWidgets);
    });

    testWidgets('resets to "Does not repeat" when frequency is none', (
      tester,
    ) async {
      String? capturedRRule;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrencePicker(
              initialRRule: 'RRULE:FREQ=DAILY;INTERVAL=1',
              onRRuleChanged: (value) {
                capturedRRule = value;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Change back to none
      await tester.tap(
        find.byType(DropdownButtonFormField<RecurrenceFrequency>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Does not repeat').last);
      await tester.pumpAndSettle();

      // Verify the rrule is null
      expect(capturedRRule, isNull);
      expect(find.text('Does not repeat'), findsOneWidget);
    });

    testWidgets('handles invalid rrule gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecurrencePicker(
              initialRRule: 'INVALID_RRULE',
              onRRuleChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should default to "Does not repeat" on parse error
      expect(find.text('Does not repeat'), findsOneWidget);
    });
  });

  group('RecurrenceFrequency', () {
    test('has correct labels', () {
      expect(RecurrenceFrequency.none.label, equals('Does not repeat'));
      expect(RecurrenceFrequency.daily.label, equals('Day'));
      expect(RecurrenceFrequency.weekly.label, equals('Week'));
      expect(RecurrenceFrequency.monthly.label, equals('Month'));
      expect(RecurrenceFrequency.yearly.label, equals('Year'));
    });

    test('none frequency has isNone as true', () {
      expect(RecurrenceFrequency.none.isNone, isTrue);
      expect(RecurrenceFrequency.daily.isNone, isFalse);
      expect(RecurrenceFrequency.weekly.isNone, isFalse);
      expect(RecurrenceFrequency.monthly.isNone, isFalse);
      expect(RecurrenceFrequency.yearly.isNone, isFalse);
    });
  });
}
