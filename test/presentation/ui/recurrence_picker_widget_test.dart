@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/widgets/recurrence_picker.dart';

import '../../helpers/test_imports.dart';

class _FixedNowService implements NowService {
  const _FixedNowService(this.value);

  final DateTime value;

  @override
  DateTime nowLocal() => value;

  @override
  DateTime nowUtc() => value.toUtc();
}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testWidgetsSafe(
    'renders recurrence numeric inputs with external unit label and steppers',
    (tester) async {
      await pumpLocalizedApp(
        tester,
        home: Provider<NowService>.value(
          value: _FixedNowService(DateTime(2026, 1, 15, 9)),
          child: const Scaffold(
            body: RecurrencePicker(
              initialRRule: null,
              initialRepeatFromCompletion: false,
              initialSeriesEnded: false,
            ),
          ),
        ),
      );
      await tester.pumpForStream();

      final l10n = tester.element(find.byType(RecurrencePicker)).l10n;

      await tester.tap(find.text(l10n.recurrenceDaily));
      await tester.pumpForStream();

      await tester.tap(
        find.byKey(const ValueKey('recurrence-interval-increment')),
      );
      await tester.pumpForStream();

      final incrementedIntervalField = tester.widget<TextFormField>(
        find.byKey(const ValueKey('recurrence-interval-field')),
      );
      expect(incrementedIntervalField.controller?.text, '2');

      await tester.tap(find.text(l10n.recurrenceAfter));
      await tester.pumpForStream();

      expect(find.text(l10n.recurrenceTimesLabel), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('recurrence-count-increment')),
      );
      await tester.pumpForStream();

      final incrementedCountField = tester.widget<TextFormField>(
        find.byKey(const ValueKey('recurrence-count-field')),
      );
      expect(incrementedCountField.controller?.text, '11');
    },
  );
}
