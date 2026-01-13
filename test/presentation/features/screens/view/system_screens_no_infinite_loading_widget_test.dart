/// Smoke tests ensuring each system screen leaves the loading state.
///
/// These tests are intentionally lightweight: they validate that
/// `UnifiedScreenPageById` transitions out of the spinner state within a small
/// number of pumps.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/app/di/dependency_injection.dart';
import 'package:taskly_bloc/core/performance/performance_logger.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/screens/catalog/system_screens/system_screen_definitions.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_definition.dart';
import 'package:taskly_bloc/domain/preferences/model/settings_key.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_action_service.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_data_interpreter.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_state.dart';
import 'package:taskly_bloc/presentation/screens/view/unified_screen_page.dart';
import 'package:taskly_bloc/presentation/shared/models/screen_preferences.dart';
import 'package:taskly_bloc/shared/logging/talker_service.dart';

import '../../../../fixtures/test_data.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_helpers.dart';
import '../../../../mocks/fake_repositories.dart';
import '../../../../mocks/repository_mocks.dart';

class MockScreenDataInterpreter extends Mock implements ScreenDataInterpreter {}

class MockEntityActionService extends Mock implements EntityActionService {}

void main() {
  group('System screens (widget) no infinite loading', () {
    late MockScreenDefinitionsRepositoryContract screensRepository;
    late MockScreenDataInterpreter interpreter;
    late MockEntityActionService entityActionService;

    late SettingsRepositoryContract settingsRepository;
    late MockTaskRepositoryContract taskRepository;
    late MockProjectRepositoryContract projectRepository;
    late MockValueRepositoryContract valueRepository;

    setUp(() async {
      initializeTalkerForTest();
      await getIt.reset();

      screensRepository = MockScreenDefinitionsRepositoryContract();
      interpreter = MockScreenDataInterpreter();
      entityActionService = MockEntityActionService();

      settingsRepository = FakeSettingsRepository();
      taskRepository = MockTaskRepositoryContract();
      projectRepository = MockProjectRepositoryContract();
      valueRepository = MockValueRepositoryContract();

      registerFallbackValue(TestData.screenDefinition());
      registerFallbackValue(SettingsKey.global as SettingsKey<dynamic>);

      getIt
        ..registerSingleton<ScreenDefinitionsRepositoryContract>(
          screensRepository,
        )
        ..registerSingleton<ScreenDataInterpreter>(interpreter)
        ..registerSingleton<EntityActionService>(entityActionService)
        ..registerSingleton<SettingsRepositoryContract>(settingsRepository)
        ..registerSingleton<TaskRepositoryContract>(taskRepository)
        ..registerSingleton<ProjectRepositoryContract>(projectRepository)
        ..registerSingleton<ValueRepositoryContract>(valueRepository)
        ..registerSingleton<PerformanceLogger>(PerformanceLogger());

      when(() => screensRepository.watchScreen(any())).thenAnswer((invocation) {
        final screenId = invocation.positionalArguments.first as String;
        final def = SystemScreenDefinitions.getById(screenId);
        if (def == null) {
          return Stream.error(StateError('Unknown system screen: $screenId'));
        }

        return Stream.value(
          ScreenWithPreferences(
            screen: def,
            preferences: ScreenPreferences(
              isActive: true,
              sortOrder: SystemScreenDefinitions.getDefaultSortOrder(screenId),
            ),
          ),
        );
      });

      when(() => interpreter.watchScreen(any())).thenAnswer((invocation) {
        final definition =
            invocation.positionalArguments.first as ScreenDefinition;
        return Stream.value(
          ScreenData(
            definition: definition,
            sections: const [],
          ),
        );
      });
    });

    tearDown(() async {
      await getIt.reset();
    });

    for (final definition in SystemScreenDefinitions.all) {
      testWidgetsSafe(
        '${definition.screenKey} loads within 1s (no spinner hang)',
        (tester) async {
          await pumpLocalizedApp(
            tester,
            home: UnifiedScreenPageById(screenId: definition.screenKey),
          );

          // `UnifiedScreenPageById` creates the BlocProvider internally, so we
          // need a context that is *below* that provider.
          await tester.pump();
          final blocContext = tester.element(
            find
                .descendant(
                  of: find.byType(UnifiedScreenPageById),
                  matching: find.byType(BlocBuilder<ScreenBloc, ScreenState>),
                )
                .first,
          );
          final bloc = BlocProvider.of<ScreenBloc>(blocContext);

          var didLoad = false;
          for (var i = 0; i < 20; i++) {
            await tester.pump(const Duration(milliseconds: 50));

            switch (bloc.state) {
              case ScreenLoadedState():
                didLoad = true;
              case ScreenErrorState(:final message):
                fail(
                  'Screen entered error state: ${definition.screenKey}: '
                  '$message',
                );
              default:
                break;
            }

            if (didLoad) {
              break;
            }
          }

          expect(
            didLoad,
            isTrue,
            reason:
                'Screen stayed in loading too long: ${definition.screenKey}. '
                'Current state: ${bloc.state}',
          );

          await tester.pump();

          expect(find.byType(CircularProgressIndicator), findsNothing);
        },
        timeout: const Duration(seconds: 10),
      );
    }
  });
}
