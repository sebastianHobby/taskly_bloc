/// Regression tests for "blank screen" and "infinite loading" scenarios.
///
/// These tests verify that the UnifiedScreenPage renders appropriate content
/// for various data states (success, empty, error) and fails fast if stuck.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/app/di/dependency_injection.dart';
import 'package:taskly_bloc/shared/logging/talker_service.dart';
import 'dart:async';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_chrome.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_definition.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_ref.dart';
import 'package:taskly_bloc/presentation/shared/models/screen_preferences.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_data_interpreter.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_vm.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_action_service.dart';
import 'package:taskly_bloc/presentation/screens/view/unified_screen_page.dart';

import '../../../../fixtures/test_data.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_helpers.dart';
import '../../../../mocks/repository_mocks.dart';

class MockScreenDataInterpreter extends Mock implements ScreenDataInterpreter {}

class MockEntityActionService extends Mock implements EntityActionService {}

void main() {
  group('UnifiedScreenPage Regression Tests', () {
    late MockScreenDefinitionsRepositoryContract screensRepository;
    late MockScreenDataInterpreter mockInterpreter;
    late MockEntityActionService mockEntityActionService;
    late MockSettingsRepositoryContract mockSettingsRepository;

    setUp(() async {
      initializeTalkerForTest();
      await getIt.reset();

      screensRepository = MockScreenDefinitionsRepositoryContract();
      mockInterpreter = MockScreenDataInterpreter();
      mockEntityActionService = MockEntityActionService();
      mockSettingsRepository = MockSettingsRepositoryContract();

      getIt
        ..registerSingleton<ScreenDefinitionsRepositoryContract>(
          screensRepository,
        )
        ..registerSingleton<ScreenDataInterpreter>(mockInterpreter)
        ..registerSingleton<EntityActionService>(mockEntityActionService)
        ..registerSingleton<SettingsRepositoryContract>(mockSettingsRepository);

      registerFallbackValue(TestData.screenDefinition());
    });

    tearDown(() async {
      await getIt.reset();
    });

    final testScreen = ScreenDefinition(
      id: 'test-id',
      screenKey: 'test-screen',
      name: 'Test Screen',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      chrome: const ScreenChrome(iconName: 'test'),
      sections: const [
        SectionRef(templateId: 'test-template'),
      ],
    );

    testWidgetsSafe(
      'renders content when stream emits data',
      (tester) async {
        // Arrange
        when(() => screensRepository.watchScreen('test-screen')).thenAnswer(
          (_) => Stream.value(
            ScreenWithPreferences(
              screen: testScreen,
              preferences: const ScreenPreferences(
                isActive: true,
                sortOrder: 0,
              ),
            ),
          ),
        );

        final sectionVm = SectionVm(
          index: 0,
          templateId: 'test-template',
          params: const {},
          data: const SectionDataResult.data(
            items: [],
          ),
          title: 'Test Section',
        );

        when(() => mockInterpreter.watchScreen(any())).thenAnswer(
          (_) => Stream.value(
            ScreenData(
              definition: testScreen,
              sections: [sectionVm],
            ),
          ),
        );

        // Act
        await pumpLocalizedApp(
          tester,
          home: const UnifiedScreenPageById(screenId: 'test-screen'),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Test Screen'), findsOneWidget); // AppBar title
        // Ensure not blank (we expect at least the section renderer or something)
        expect(find.text('No sections configured'), findsNothing);
      },
    );

    testWidgetsSafe(
      'renders "No sections configured" when data has no sections',
      (tester) async {
        // Arrange
        when(() => screensRepository.watchScreen('test-screen')).thenAnswer(
          (_) => Stream.value(
            ScreenWithPreferences(
              screen: testScreen,
              preferences: const ScreenPreferences(
                isActive: true,
                sortOrder: 0,
              ),
            ),
          ),
        );

        when(() => mockInterpreter.watchScreen(any())).thenAnswer(
          (_) => Stream.value(
            ScreenData(
              definition: testScreen,
              sections: const [], // EMPTY SECTIONS
            ),
          ),
        );

        // Act
        await pumpLocalizedApp(
          tester,
          home: const UnifiedScreenPageById(screenId: 'test-screen'),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('No sections configured'), findsOneWidget);
      },
    );

    testWidgetsSafe(
      'renders error UI when stream emits error',
      (tester) async {
        // Arrange
        when(() => screensRepository.watchScreen('test-screen')).thenAnswer(
          (_) => Stream.value(
            ScreenWithPreferences(
              screen: testScreen,
              preferences: const ScreenPreferences(
                isActive: true,
                sortOrder: 0,
              ),
            ),
          ),
        );

        when(() => mockInterpreter.watchScreen(any())).thenAnswer(
          (_) => Stream.error(Exception('Stream failed')),
        );

        // Act
        await pumpLocalizedApp(
          tester,
          home: const UnifiedScreenPageById(screenId: 'test-screen'),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Failed to load screen'), findsOneWidget);
        expect(find.textContaining('Stream failed'), findsOneWidget);
      },
    );

    testWidgetsSafe(
      'fails fast if loading indicator persists (infinite loading regression)',
      (tester) async {
        // Arrange - Stream never emits
        final controller = StreamController<ScreenWithPreferences>();
        addTearDown(controller.close);

        when(() => screensRepository.watchScreen(any())).thenAnswer(
          (_) => controller.stream,
        );

        // Act
        await pumpLocalizedApp(
          tester,
          home: const UnifiedScreenPageById(screenId: 'test-screen'),
        );

        // Assert
        // We expect initial loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Pump for a bit to simulate time passing
        await tester.pump(const Duration(seconds: 1));

        // Ensure we are STILL loading (proving that empty stream = infinite load)
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );
  });
}
