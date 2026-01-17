/// Widget-level smoke tests that ensure system navigation menu screens
/// render without staying stuck on the loading spinner.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/domain/screens/catalog/system_screens/system_screen_specs.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data_interpreter.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/screens/view/unified_screen_spec_page.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_imports.dart';
import '../../../../mocks/repository_mocks.dart';

import 'package:taskly_domain/taskly_domain.dart';
class _MockScreenSpecDataInterpreter extends Mock
    implements ScreenSpecDataInterpreter {}

class _MockGlobalSettingsBloc
    extends MockBloc<GlobalSettingsEvent, GlobalSettingsState>
    implements GlobalSettingsBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AppAuthState>
    implements AuthBloc {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerFallbackValue(SystemScreenSpecs.myDay);
  });

  setUp(setUpTestEnvironment);

  group('System menu items (widget) load guards', () {
    late _MockScreenSpecDataInterpreter screenSpecInterpreter;
    late MockSettingsRepositoryContract settingsRepository;
    late MockTaskRepositoryContract taskRepository;
    late MockProjectRepositoryContract projectRepository;
    late MockValueRepositoryContract valueRepository;

    late _MockGlobalSettingsBloc globalSettingsBloc;
    late _MockAuthBloc authBloc;

    setUp(() async {
      await getIt.reset();
      addTearDown(getIt.reset);

      screenSpecInterpreter = _MockScreenSpecDataInterpreter();
      settingsRepository = MockSettingsRepositoryContract();
      taskRepository = MockTaskRepositoryContract();
      projectRepository = MockProjectRepositoryContract();
      valueRepository = MockValueRepositoryContract();

      globalSettingsBloc = _MockGlobalSettingsBloc();
      authBloc = _MockAuthBloc();

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

      // Interpreter: return a deterministic "loaded" ScreenSpecData so the UI
      // must transition off the spinner.
      when(() => screenSpecInterpreter.watchScreen(any())).thenAnswer(
        (invocation) {
          final spec = invocation.positionalArguments.first as ScreenSpec;
          return Stream.value(
            ScreenSpecData(
              spec: spec,
              template: spec.template,
              sections: const SlottedSectionVms(),
            ),
          );
        },
      );

      getIt
        ..registerSingleton<ScreenSpecDataInterpreter>(screenSpecInterpreter)
        ..registerSingleton<SettingsRepositoryContract>(settingsRepository)
        ..registerSingleton<TaskRepositoryContract>(taskRepository)
        ..registerSingleton<ProjectRepositoryContract>(projectRepository)
        ..registerSingleton<ValueRepositoryContract>(valueRepository);
    });

    testWidgetsSafe(
      'each system navigation item leaves loading state',
      (tester) async {
        final screens = <ScreenSpec>[
          SystemScreenSpecs.myDay,
          SystemScreenSpecs.scheduled,
          SystemScreenSpecs.someday,
          SystemScreenSpecs.journal,
          SystemScreenSpecs.values,
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
              child: UnifiedScreenPageFromSpec(spec: screen),
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
        }
      },
      timeout: const Duration(seconds: 30),
    );
  });
}
