@Tags(['widget', 'onboarding'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/bloc/guided_tour_bloc.dart';
import 'package:taskly_bloc/presentation/features/onboarding/view/onboarding_flow_page.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/services.dart';

class MockAuthRepository extends Mock implements AuthRepositoryContract {}

class MockSettingsRepository extends Mock
    implements SettingsRepositoryContract {}

class MockValueRepository extends Mock implements ValueRepositoryContract {}

class MockValueWriteService extends Mock implements ValueWriteService {}

class MockErrorReporter extends Mock implements AppErrorReporter {}

class MockGlobalSettingsBloc
    extends MockBloc<GlobalSettingsEvent, GlobalSettingsState>
    implements GlobalSettingsBloc {}

class MockGuidedTourBloc extends MockBloc<GuidedTourEvent, GuidedTourState>
    implements GuidedTourBloc {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockAuthRepository authRepository;
  late MockSettingsRepository settingsRepository;
  late MockValueRepository valueRepository;
  late MockValueWriteService valueWriteService;
  late MockErrorReporter errorReporter;
  late MockGlobalSettingsBloc globalSettingsBloc;
  late MockGuidedTourBloc guidedTourBloc;

  setUp(() {
    authRepository = MockAuthRepository();
    settingsRepository = MockSettingsRepository();
    valueRepository = MockValueRepository();
    valueWriteService = MockValueWriteService();
    errorReporter = MockErrorReporter();
    globalSettingsBloc = MockGlobalSettingsBloc();
    guidedTourBloc = MockGuidedTourBloc();

    when(() => globalSettingsBloc.state).thenReturn(
      const GlobalSettingsState(isLoading: false),
    );
    when(() => guidedTourBloc.state).thenReturn(const GuidedTourState());
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpApp(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AuthRepositoryContract>.value(
            value: authRepository,
          ),
          RepositoryProvider<SettingsRepositoryContract>.value(
            value: settingsRepository,
          ),
          RepositoryProvider<ValueRepositoryContract>.value(
            value: valueRepository,
          ),
          RepositoryProvider<ValueWriteService>.value(value: valueWriteService),
          RepositoryProvider<AppErrorReporter>.value(value: errorReporter),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<GlobalSettingsBloc>.value(value: globalSettingsBloc),
            BlocProvider<GuidedTourBloc>.value(value: guidedTourBloc),
          ],
          child: const OnboardingFlowPage(),
        ),
      ),
    );
  }

  testWidgetsSafe('shows welcome step content', (tester) async {
    await pumpPage(tester);

    expect(find.text('Meet Taskly'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgetsSafe('shows loading state while saving name', (tester) async {
    final completer = Completer<void>();
    when(
      () => authRepository.updateUserProfile(
        displayName: any(named: 'displayName'),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) => completer.future);

    await pumpPage(tester);

    await tester.tap(find.text('Get started'));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Jordan');
    await tester.pump();

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete();
  });

  testWidgetsSafe('shows error snack bar when name save fails', (tester) async {
    when(
      () => authRepository.updateUserProfile(
        displayName: any(named: 'displayName'),
        context: any(named: 'context'),
      ),
    ).thenThrow(Exception('auth failed'));

    await pumpPage(tester);

    await tester.tap(find.text('Get started'));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Jordan');
    await tester.pump();

    await tester.tap(find.text('Continue'));
    await tester.pumpForStream();

    expect(
      find.text('Could not save your name. Please try again.'),
      findsOneWidget,
    );
  });
}
