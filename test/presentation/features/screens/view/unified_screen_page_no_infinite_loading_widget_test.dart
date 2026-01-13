/// Regression test for “infinite loading” on real unified screen rendering.
///
/// This is a widget-level guard: it pumps the real `UnifiedScreenPageById`
/// and fails fast if the page stays stuck on the loading spinner.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/app/di/dependency_injection.dart';
import 'package:taskly_bloc/shared/logging/talker_service.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_chrome.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_definition.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_ref.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_config.dart';
import 'package:taskly_bloc/domain/preferences/model/settings_key.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_data_interpreter.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_action_service.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/section_template_interpreter_registry.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/section_template_params_codec.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/static_section_interpreter.dart';
import 'package:taskly_bloc/presentation/screens/view/unified_screen_page.dart';
import 'package:taskly_bloc/core/performance/performance_logger.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_helpers.dart';
import '../../../../mocks/repository_mocks.dart';

class MockEntityActionService extends Mock implements EntityActionService {}

void main() {
  group('UnifiedScreenPageById (widget) infinite loading guards', () {
    late MockSettingsRepositoryContract settingsRepository;
    late MockEntityActionService entityActionService;

    setUp(() async {
      initializeTalkerForTest();

      // The widget under test uses getIt internally.
      await getIt.reset();
      settingsRepository = MockSettingsRepositoryContract();
      entityActionService = MockEntityActionService();

      when(
        () =>
            settingsRepository.watch<AllocationConfig>(SettingsKey.allocation),
      ).thenAnswer((_) => Stream.value(const AllocationConfig()));
      when(
        () => settingsRepository.load<AllocationConfig>(SettingsKey.allocation),
      ).thenAnswer((_) async => const AllocationConfig());

      final interpreter = ScreenDataInterpreter(
        interpreterRegistry: SectionTemplateInterpreterRegistry([
          StaticSectionInterpreter(
            // Choose a full-screen template that renders without further DI.
            templateId: SectionTemplateId.statisticsDashboard,
          ),
        ]),
        paramsCodec: SectionTemplateParamsCodec(),
        settingsRepository: settingsRepository,
      );

      getIt
        ..registerSingleton(settingsRepository)
        ..registerSingleton<EntityActionService>(entityActionService)
        ..registerSingleton<ScreenDataInterpreter>(interpreter)
        ..registerSingleton<PerformanceLogger>(PerformanceLogger());
    });

    tearDown(() async {
      await getIt.reset();
    });

    testWidgetsSafe(
      'loads and renders within 2 seconds',
      (tester) async {
        final screen = ScreenDefinition(
          id: '',
          screenKey: 'test-statistics-screen',
          name: 'Test Statistics Screen',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          chrome: const ScreenChrome(iconName: 'test'),
          sections: const [
            SectionRef(templateId: SectionTemplateId.statisticsDashboard),
          ],
        );

        await pumpLocalizedApp(
          tester,
          home: UnifiedScreenPage(definition: screen),
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
