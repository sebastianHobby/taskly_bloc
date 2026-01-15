/// Widget tests for SettingsScreen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/settings_maintenance_cubit.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_screen.dart';

import '../../../../helpers/test_imports.dart';

class _MockGlobalSettingsBloc
    extends MockBloc<GlobalSettingsEvent, GlobalSettingsState>
    implements GlobalSettingsBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AppAuthState>
    implements AuthBloc {}

class _MockSettingsMaintenanceCubit extends MockCubit<SettingsMaintenanceState>
    implements SettingsMaintenanceCubit {}

void main() {
  setUpAll(setUpAllTestEnvironment);

  setUp(() async {
    setUpTestEnvironment();
    await getIt.reset();
    addTearDown(getIt.reset);
  });

  group('SettingsScreen', () {
    late _MockGlobalSettingsBloc globalSettingsBloc;
    late _MockAuthBloc authBloc;
    late _MockSettingsMaintenanceCubit maintenanceCubit;

    setUp(() {
      globalSettingsBloc = _MockGlobalSettingsBloc();
      authBloc = _MockAuthBloc();
      maintenanceCubit = _MockSettingsMaintenanceCubit();

      // SettingsScreen reads AuthBloc.
      when(() => authBloc.state).thenReturn(
        const AppAuthState(status: AuthStatus.unauthenticated),
      );
      when(() => authBloc.stream).thenAnswer(
        (_) => const Stream<AppAuthState>.empty(),
      );

      // SettingsScreen provides SettingsMaintenanceCubit via getIt.
      when(() => maintenanceCubit.state).thenReturn(
        SettingsMaintenanceState.idle(),
      );
      when(() => maintenanceCubit.stream).thenAnswer(
        (_) => const Stream<SettingsMaintenanceState>.empty(),
      );
      getIt.registerSingleton<SettingsMaintenanceCubit>(maintenanceCubit);
    });

    testWidgetsSafe('shows loading spinner when settings are loading', (
      tester,
    ) async {
      when(() => globalSettingsBloc.state).thenReturn(
        const GlobalSettingsState(isLoading: true),
      );
      when(() => globalSettingsBloc.stream).thenAnswer(
        (_) => const Stream<GlobalSettingsState>.empty(),
      );

      await pumpLocalizedApp(
        tester,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<GlobalSettingsBloc>.value(value: globalSettingsBloc),
            BlocProvider<AuthBloc>.value(value: authBloc),
          ],
          child: const SettingsScreen(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgetsSafe('renders section headers when settings are loaded', (
      tester,
    ) async {
      when(() => globalSettingsBloc.state).thenReturn(
        const GlobalSettingsState(isLoading: false),
      );
      when(() => globalSettingsBloc.stream).thenAnswer(
        (_) => const Stream<GlobalSettingsState>.empty(),
      );

      await pumpLocalizedApp(
        tester,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<GlobalSettingsBloc>.value(value: globalSettingsBloc),
            BlocProvider<AuthBloc>.value(value: authBloc),
          ],
          child: const SettingsScreen(),
        ),
      );

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Language & Region'), findsOneWidget);
      expect(find.text('Developer'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
    });
  });
}
