/// Widget-level smoke tests that ensure system navigation menu screens
/// render without staying stuck on the loading spinner.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/app/di/dependency_injection.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_config.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/preferences/model/settings_key.dart';
import 'package:taskly_bloc/domain/screens/catalog/system_screens/system_screen_definitions.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_definition.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_action_service.dart';
import 'package:taskly_bloc/core/performance/performance_logger.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_data_interpreter.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_vm.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/screens/view/unified_screen_page.dart';
import 'package:taskly_bloc/shared/logging/talker_service.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_imports.dart';
import '../../../../mocks/repository_mocks.dart';

class _MockScreenDataInterpreter extends Mock
    implements ScreenDataInterpreter {}

class _MockEntityActionService extends Mock implements EntityActionService {}

class _FakeScreenDefinition extends Fake implements ScreenDefinition {}

class _MockGlobalSettingsBloc
    extends MockBloc<GlobalSettingsEvent, GlobalSettingsState>
    implements GlobalSettingsBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AppAuthState>
    implements AuthBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeScreenDefinition());
  });

  group('System menu items (widget) load guards', () {
    late MockScreenDefinitionsRepositoryContract screensRepository;
    late _MockScreenDataInterpreter screenDataInterpreter;
    late _MockEntityActionService entityActionService;
    late MockSettingsRepositoryContract settingsRepository;
    late MockTaskRepositoryContract taskRepository;
    late MockProjectRepositoryContract projectRepository;
    late MockValueRepositoryContract valueRepository;

    late _MockGlobalSettingsBloc globalSettingsBloc;
    late _MockAuthBloc authBloc;

    setUp(() async {
      initializeTalkerForTest();
      await getIt.reset();

      screensRepository = MockScreenDefinitionsRepositoryContract();
      screenDataInterpreter = _MockScreenDataInterpreter();
      entityActionService = _MockEntityActionService();
      settingsRepository = MockSettingsRepositoryContract();
      taskRepository = MockTaskRepositoryContract();
      projectRepository = MockProjectRepositoryContract();
      valueRepository = MockValueRepositoryContract();

      globalSettingsBloc = _MockGlobalSettingsBloc();
      authBloc = _MockAuthBloc();

      // Settings used by focus screens (My Day) via StreamBuilder.
      when(
        () =>
            settingsRepository.watch<AllocationConfig>(SettingsKey.allocation),
      ).thenAnswer((_) => Stream.value(const AllocationConfig()));

      // Browse tiles use badge counts for some screens.
      when(() => taskRepository.watchAllCount(any())).thenAnswer(
        (_) => Stream.value(0),
      );
      when(() => projectRepository.watchAllCount(any())).thenAnswer(
        (_) => Stream.value(0),
      );

      // Keep SettingsScreen from showing its loading spinner.
      when(() => globalSettingsBloc.state).thenReturn(
        const GlobalSettingsState(isLoading: false),
      );
      when(() => globalSettingsBloc.stream).thenAnswer(
        (_) => const Stream<GlobalSettingsState>.empty(),
      );

      // SettingsScreen also reads AuthBloc.
      when(() => authBloc.state).thenReturn(
        const AppAuthState(status: AuthStatus.unauthenticated),
      );
      when(() => authBloc.stream).thenAnswer(
        (_) => const Stream<AppAuthState>.empty(),
      );

      // Interpreter: return a deterministic "loaded" ScreenData for each system
      // screen so the UI must transition off the spinner.
      when(() => screenDataInterpreter.watchScreen(any())).thenAnswer(
        (invocation) {
          final definition =
              invocation.positionalArguments.first as ScreenDefinition;

          final sections = switch (definition.screenKey) {
            'browse' => [
              const SectionVm(
                index: 0,
                templateId: SectionTemplateId.browseHub,
                params: <String, dynamic>{},
              ),
            ],
            'statistics' => [
              const SectionVm(
                index: 0,
                templateId: SectionTemplateId.statisticsDashboard,
                params: <String, dynamic>{},
              ),
            ],
            'settings' => [
              const SectionVm(
                index: 0,
                templateId: SectionTemplateId.settingsMenu,
                params: <String, dynamic>{},
              ),
            ],
            _ => const <SectionVm>[],
          };

          return Stream.value(
            ScreenData(definition: definition, sections: sections),
          );
        },
      );

      getIt
        ..registerSingleton<ScreenDefinitionsRepositoryContract>(
          screensRepository,
        )
        ..registerSingleton<PerformanceLogger>(PerformanceLogger())
        ..registerSingleton<ScreenDataInterpreter>(screenDataInterpreter)
        ..registerSingleton<EntityActionService>(entityActionService)
        ..registerSingleton<SettingsRepositoryContract>(settingsRepository)
        ..registerSingleton<TaskRepositoryContract>(taskRepository)
        ..registerSingleton<ProjectRepositoryContract>(projectRepository)
        ..registerSingleton<ValueRepositoryContract>(valueRepository);
    });

    tearDown(() async {
      await getIt.reset();
    });

    testWidgetsSafe(
      'each system navigation item leaves loading state',
      (tester) async {
        final screens = <ScreenDefinition>[
          ...SystemScreenDefinitions.navigationScreens,
          SystemScreenDefinitions.browse,
        ];

        for (final screen in screens) {
          await pumpLocalizedApp(
            tester,
            home: MultiBlocProvider(
              providers: [
                BlocProvider<GlobalSettingsBloc>.value(
                  value: globalSettingsBloc,
                ),
                BlocProvider<AuthBloc>.value(value: authBloc),
              ],
              child: UnifiedScreenPage(definition: screen),
            ),
          );

          // Deterministically pump a short time to allow BLoC to emit. We don't
          // assert the spinner is present on the first frame because the state
          // transition may be immediate.
          for (var i = 0; i < 40; i++) {
            await tester.pump(const Duration(milliseconds: 25));
            if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
              break;
            }
          }

          expect(
            find.byType(CircularProgressIndicator),
            findsNothing,
            reason:
                'Screen stayed in loading too long (possible infinite load): '
                '${screen.screenKey}',
          );

          // Ensure we didn\'t fall into the generic error UI.
          expect(find.text('Failed to load screen'), findsNothing);

          // Avoid ending up on the generic "unsupported template" UI.
          expect(
            find.textContaining('Unsupported full-screen template'),
            findsNothing,
          );

          // Generic "has UI" assertion to catch empty-page regressions without
          // depending on screen-specific copy.
          final hasAnyContent =
              find.byType(Text).evaluate().isNotEmpty ||
              find.byType(ListView).evaluate().isNotEmpty ||
              find.byType(GridView).evaluate().isNotEmpty ||
              find.byType(CustomScrollView).evaluate().isNotEmpty;

          expect(
            hasAnyContent,
            isTrue,
            reason: 'Expected some visible content for ${screen.screenKey}',
          );
        }
      },
      timeout: const Duration(seconds: 30),
    );
  });
}
