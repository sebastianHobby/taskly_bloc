import 'package:flutter/material.dart';

import '../../helpers/test_imports.dart';

import 'package:taskly_bloc/core/logging/talker_service.dart'
    show initializeTalkerForTest;
import 'package:taskly_bloc/presentation/widgets/recurrence_picker.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(() {
    setUpTestEnvironment();
    initializeTalkerForTest();
  });

  group('RecurrencePicker', () {
    testWidgetsSafe('builds with empty initial RRULE', (tester) async {
      RecurrencePickerResult? latest;

      await pumpLocalizedApp(
        tester,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  latest = await showDialog<RecurrencePickerResult>(
                    context: context,
                    builder: (dialogContext) => Dialog(
                      child: RecurrencePicker(
                        initialRRule: null,
                        initialRepeatFromCompletion: false,
                        initialSeriesEnded: false,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Repeat'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(latest, isNotNull);
      expect(latest!.rrule, isNull);
    });

    testWidgetsSafe('changing frequency emits a non-null RRULE', (
      tester,
    ) async {
      RecurrencePickerResult? latest;

      await pumpLocalizedApp(
        tester,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  latest = await showDialog<RecurrencePickerResult>(
                    context: context,
                    builder: (dialogContext) => Dialog(
                      child: RecurrencePicker(
                        initialRRule: null,
                        initialRepeatFromCompletion: false,
                        initialSeriesEnded: false,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Daily'));
      await tester.pump();

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(latest, isNotNull);
      expect(latest!.rrule, isNotNull);
      expect(latest!.rrule, contains('FREQ=DAILY'));
    });

    testWidgetsSafe('invalid RRULE does not crash', (tester) async {
      RecurrencePickerResult? latest;
      await pumpLocalizedApp(
        tester,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  latest = await showDialog<RecurrencePickerResult>(
                    context: context,
                    builder: (dialogContext) => Dialog(
                      child: RecurrencePicker(
                        initialRRule: 'not-a-valid-rrule',
                        initialRepeatFromCompletion: false,
                        initialSeriesEnded: false,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Repeat'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(latest, isNotNull);
    });

    testWidgetsSafe('weekly selection updates RRULE and interval', (
      tester,
    ) async {
      RecurrencePickerResult? latest;

      await pumpLocalizedApp(
        tester,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  latest = await showDialog<RecurrencePickerResult>(
                    context: context,
                    builder: (dialogContext) => Dialog(
                      child: RecurrencePicker(
                        initialRRule: null,
                        initialRepeatFromCompletion: false,
                        initialSeriesEnded: false,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Weekly'));
      await tester.pump();

      final intervalField = find.byWidgetPredicate(
        (w) => w is TextFormField && w.controller != null,
      );
      expect(intervalField, findsOneWidget);

      await tester.enterText(intervalField, '2');
      await tester.pump();

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(latest, isNotNull);
      expect(latest!.rrule, contains('FREQ=WEEKLY'));
      expect(latest!.rrule, contains('INTERVAL=2'));
    });

    testWidgetsSafe('weekly weekday chips update BYDAY', (tester) async {
      RecurrencePickerResult? latest;

      await pumpLocalizedApp(
        tester,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  latest = await showDialog<RecurrencePickerResult>(
                    context: context,
                    builder: (dialogContext) => Dialog(
                      child: RecurrencePicker(
                        initialRRule: null,
                        initialRepeatFromCompletion: false,
                        initialSeriesEnded: false,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weekly'));
      await tester.pump();

      await tester.tap(find.text('Mon'));
      await tester.pump();

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(latest, isNotNull);
      expect(latest!.rrule, contains('FREQ=WEEKLY'));
      expect(latest!.rrule, contains('BYDAY=MO'));
    });

    testWidgetsSafe('selecting Never clears RRULE', (tester) async {
      RecurrencePickerResult? latest;

      await pumpLocalizedApp(
        tester,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  latest = await showDialog<RecurrencePickerResult>(
                    context: context,
                    builder: (dialogContext) => Dialog(
                      child: RecurrencePicker(
                        initialRRule: 'FREQ=DAILY;INTERVAL=1',
                        initialRepeatFromCompletion: false,
                        initialSeriesEnded: false,
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Never'));
      await tester.pump();

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(latest, isNotNull);
      expect(latest!.rrule, isNull);
    });
  });
}
