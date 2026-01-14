/// Regression test for “infinite loading” on typed unified screen rendering.
///
/// This is a widget-level guard: it pumps `UnifiedScreenPageFromSpec` and
/// fails fast if the page stays stuck on the loading spinner.
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data_interpreter.dart';
import 'package:taskly_bloc/presentation/screens/view/unified_screen_spec_page.dart';

import '../../../../helpers/test_imports.dart';

class MockScreenSpecDataInterpreter extends Mock
    implements ScreenSpecDataInterpreter {}

const _testSpec = ScreenSpec(
  id: 'test-spec',
  screenKey: 'test-statistics-screen',
  name: 'Test Statistics Screen',
  template: ScreenTemplateSpec.statisticsDashboard(),
);

ScreenSpecData _data() {
  return const ScreenSpecData(
    spec: _testSpec,
    template: ScreenTemplateSpec.statisticsDashboard(),
    sections: SlottedSectionVms(),
  );
}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('UnifiedScreenPageFromSpec (widget) infinite loading guards', () {
    late MockScreenSpecDataInterpreter interpreter;

    setUp(() async {
      // The widget under test uses getIt internally.
      await getIt.reset();

      interpreter = MockScreenSpecDataInterpreter();
      registerFallbackValue(_testSpec);

      when(() => interpreter.watchScreen(any())).thenAnswer(
        (_) => Stream.value(_data()),
      );

      getIt.registerSingleton<ScreenSpecDataInterpreter>(interpreter);
    });

    tearDown(() async {
      await getIt.reset();
    });

    testWidgetsSafe(
      'loads and renders within 2 seconds',
      (tester) async {
        await pumpLocalizedApp(
          tester,
          home: const UnifiedScreenPageFromSpec(spec: _testSpec),
        );

        // Expect initial loading state.
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Fail fast if we never reach a rendered state.
        //
        // Use a deterministic number of pumps instead of time-based loops,
        // since widget tests run under a fake clock.
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 50));

          if (find.text('Failed to load screen').evaluate().isNotEmpty) {
            fail('Screen entered error UI');
          }

          if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
            break;
          }
        }

        expect(
          find.byType(CircularProgressIndicator),
          findsNothing,
          reason: 'Screen stayed in loading too long (possible infinite load).',
        );

        // Rebuild after state transition.
        await tester.pump();

        expect(
          find.text('Statistics dashboard not implemented yet.'),
          findsOneWidget,
        );
      },
      timeout: const Duration(seconds: 10),
      tags: 'integration',
    );
  });
}
