/// Regression tests for "blank screen" and "infinite loading" scenarios.
///
/// These tests verify that the typed unified screen page transitions off the
/// loading spinner and displays either the template UI or error UI.
library;

import 'dart:async';

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

const _testSpec = ScreenSpec(
  id: 'test-spec',
  screenKey: 'test-screen',
  name: 'Test Screen',
  template: ScreenTemplateSpec.statisticsDashboard(),
);

ScreenSpecData _loadedData({String? error}) {
  return ScreenSpecData(
    spec: _testSpec,
    template: _testSpec.template,
    sections: const SlottedSectionVms(),
    error: error,
  );
}

void main() {
  group('UnifiedScreenPageFromSpec regression tests', () {
    late MockScreenSpecDataInterpreter mockInterpreter;

    setUp(() async {
      initializeTalkerForTest();
      await getIt.reset();

      mockInterpreter = MockScreenSpecDataInterpreter();

      getIt.registerSingleton<ScreenSpecDataInterpreter>(mockInterpreter);

      registerFallbackValue(_testSpec);
    });

    tearDown(() async {
      await getIt.reset();
    });

    testWidgetsSafe(
      'renders template UI when stream emits data',
      (tester) async {
        when(() => mockInterpreter.watchScreen(any())).thenAnswer(
          (_) => Stream.value(
            _loadedData(),
          ),
        );

        await pumpLocalizedApp(
          tester,
          home: const UnifiedScreenPageFromSpec(spec: _testSpec),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(
          find.text('Statistics dashboard not implemented yet.'),
          findsOneWidget,
        );
      },
    );

    testWidgetsSafe(
      'renders error UI when stream emits error data',
      (tester) async {
        when(() => mockInterpreter.watchScreen(any())).thenAnswer(
          (_) => Stream.value(
            _loadedData(error: 'Data fetch failed'),
          ),
        );

        await pumpLocalizedApp(
          tester,
          home: const UnifiedScreenPageFromSpec(spec: _testSpec),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Data fetch failed'), findsOneWidget);
      },
    );

    testWidgetsSafe(
      'renders error UI when stream throws',
      (tester) async {
        when(() => mockInterpreter.watchScreen(any())).thenAnswer(
          (_) => Stream.error(Exception('Stream failed')),
        );

        await pumpLocalizedApp(
          tester,
          home: const UnifiedScreenPageFromSpec(spec: _testSpec),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.textContaining('Stream failed'), findsOneWidget);
      },
    );

    testWidgetsSafe(
      'stays on loading indicator if stream never emits',
      (tester) async {
        final controller = StreamController<ScreenSpecData>();
        addTearDown(controller.close);
        when(() => mockInterpreter.watchScreen(any())).thenAnswer(
          (_) => controller.stream,
        );

        await pumpLocalizedApp(
          tester,
          home: const UnifiedScreenPageFromSpec(spec: _testSpec),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );
  });
}
