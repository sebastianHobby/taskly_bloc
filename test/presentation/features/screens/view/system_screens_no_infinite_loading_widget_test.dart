/// Smoke test ensuring typed system-screen rendering leaves loading state.
///
/// This targets the hard-cutover ScreenSpec path via `UnifiedScreenPageFromSpec`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data_interpreter.dart';
import 'package:taskly_bloc/presentation/screens/view/unified_screen_spec_page.dart';
import 'package:taskly_bloc/shared/logging/talker_service.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_helpers.dart';

class MockScreenSpecDataInterpreter extends Mock
    implements ScreenSpecDataInterpreter {}

void main() {
  group('System screens (typed) no infinite loading', () {
    late MockScreenSpecDataInterpreter interpreter;

    setUp(() async {
      initializeTalkerForTest();
      await getIt.reset();

      interpreter = MockScreenSpecDataInterpreter();

      registerFallbackValue(
        ScreenSpec(
          id: 'fallback-id',
          screenKey: 'fallback',
          name: 'Fallback',
          template: const ScreenTemplateSpec.standardScaffoldV1(),
        ),
      );

      getIt.registerSingleton<ScreenSpecDataInterpreter>(interpreter);
    });

    tearDown(() async {
      await getIt.reset();
    });

    testWidgetsSafe(
      'leaves spinner state when interpreter emits data',
      (tester) async {
        final spec = ScreenSpec(
          id: 'test-id',
          screenKey: 'test-screen',
          name: 'Test Screen',
          template: const ScreenTemplateSpec.standardScaffoldV1(),
        );

        when(() => interpreter.watchScreen(any())).thenAnswer(
          (_) => Stream.value(
            ScreenSpecData(
              spec: spec,
              template: spec.template,
              sections: const SlottedSectionVms(),
            ),
          ),
        );

        await pumpLocalizedApp(
          tester,
          home: UnifiedScreenPageFromSpec(spec: spec),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );
  });
}
