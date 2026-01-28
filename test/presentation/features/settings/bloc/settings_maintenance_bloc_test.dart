@Tags(['unit', 'settings'])
library;

import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/feature_mocks.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/settings_maintenance_bloc.dart';
import 'package:taskly_domain/telemetry.dart';

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
    registerFallbackValue(
      const OperationContext(
        correlationId: 'corr-1',
        feature: 'settings',
        intent: 'test',
        operation: 'test',
      ),
    );
  });
  setUp(setUpTestEnvironment);

  late MockTemplateDataService templateDataService;
  late MockUserDataWipeService userDataWipeService;
  late MockAuthRepositoryContract authRepository;

  SettingsMaintenanceBloc buildBloc() {
    return SettingsMaintenanceBloc(
      templateDataService: templateDataService,
      userDataWipeService: userDataWipeService,
      authRepository: authRepository,
    );
  }

  setUp(() {
    templateDataService = MockTemplateDataService();
    userDataWipeService = MockUserDataWipeService();
    authRepository = MockAuthRepositoryContract();

    when(() => templateDataService.resetAndSeed()).thenAnswer((_) async {});
    when(() => userDataWipeService.wipeAllUserData()).thenAnswer((_) async {});
    when(
      () => authRepository.signOut(context: any(named: 'context')),
    ).thenAnswer((_) async {});
  });

  testSafe('initial state is idle', () async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    expect(
      bloc.state.status,
      isA<SettingsMaintenanceIdle>(),
    );
  });

  blocTestSafe<SettingsMaintenanceBloc, SettingsMaintenanceState>(
    'generateTemplateData emits running -> success -> idle',
    build: buildBloc,
    act: (bloc) async => bloc.generateTemplateData(),
    expect: () => [
      isA<SettingsMaintenanceState>().having(
        (s) => s.status,
        'status',
        isA<SettingsMaintenanceRunning>().having(
          (s) => s.action,
          'action',
          SettingsMaintenanceAction.generateTemplateData,
        ),
      ),
      isA<SettingsMaintenanceState>().having(
        (s) => s.status,
        'status',
        isA<SettingsMaintenanceSuccess>().having(
          (s) => s.action,
          'action',
          SettingsMaintenanceAction.generateTemplateData,
        ),
      ),
      isA<SettingsMaintenanceState>().having(
        (s) => s.status,
        'status',
        isA<SettingsMaintenanceIdle>(),
      ),
    ],
    verify: (_) {
      verify(() => templateDataService.resetAndSeed()).called(1);
    },
  );

  blocTestSafe<SettingsMaintenanceBloc, SettingsMaintenanceState>(
    'generateTemplateData emits failure when reset fails',
    build: () {
      when(() => templateDataService.resetAndSeed()).thenThrow(
        StateError('boom'),
      );
      return buildBloc();
    },
    act: (bloc) async => bloc.generateTemplateData(),
    expect: () => [
      isA<SettingsMaintenanceState>().having(
        (s) => s.status,
        'status',
        isA<SettingsMaintenanceRunning>().having(
          (s) => s.action,
          'action',
          SettingsMaintenanceAction.generateTemplateData,
        ),
      ),
      isA<SettingsMaintenanceState>().having(
        (s) => s.status,
        'status',
        isA<SettingsMaintenanceFailure>()
            .having(
              (s) => s.action,
              'action',
              SettingsMaintenanceAction.generateTemplateData,
            )
            .having(
              (s) => s.message,
              'message',
              contains('Failed to generate template data'),
            ),
      ),
      isA<SettingsMaintenanceState>().having(
        (s) => s.status,
        'status',
        isA<SettingsMaintenanceIdle>(),
      ),
    ],
  );

  blocTestSafe<SettingsMaintenanceBloc, SettingsMaintenanceState>(
    'resetOnboardingAndSignOut emits running -> success -> idle',
    build: buildBloc,
    act: (bloc) async => bloc.resetOnboardingAndSignOut(),
    expect: () => [
      isA<SettingsMaintenanceState>().having(
        (s) => s.status,
        'status',
        isA<SettingsMaintenanceRunning>().having(
          (s) => s.action,
          'action',
          SettingsMaintenanceAction.resetOnboardingAndLogout,
        ),
      ),
      isA<SettingsMaintenanceState>().having(
        (s) => s.status,
        'status',
        isA<SettingsMaintenanceSuccess>().having(
          (s) => s.action,
          'action',
          SettingsMaintenanceAction.resetOnboardingAndLogout,
        ),
      ),
      isA<SettingsMaintenanceState>().having(
        (s) => s.status,
        'status',
        isA<SettingsMaintenanceIdle>(),
      ),
    ],
    verify: (_) {
      verify(() => userDataWipeService.wipeAllUserData()).called(1);
      final captured = verify(
        () => authRepository.signOut(context: captureAny(named: 'context')),
      ).captured;
      final context = captured.last as OperationContext;
      expect(context.feature, 'settings');
      expect(context.screen, 'developer_settings');
      expect(context.intent, 'settings_sign_out_requested');
      expect(context.operation, 'auth.sign_out');
      expect(context.entityType, 'settings');
      expect(context.correlationId, isNotEmpty);
    },
  );

  blocTestSafe<SettingsMaintenanceBloc, SettingsMaintenanceState>(
    'resetOnboardingAndSignOut emits failure when sign out fails',
    build: () {
      when(
        () => authRepository.signOut(context: any(named: 'context')),
      ).thenThrow(StateError('signout failed'));
      return buildBloc();
    },
    act: (bloc) async => bloc.resetOnboardingAndSignOut(),
    expect: () => [
      isA<SettingsMaintenanceState>().having(
        (s) => s.status,
        'status',
        isA<SettingsMaintenanceRunning>().having(
          (s) => s.action,
          'action',
          SettingsMaintenanceAction.resetOnboardingAndLogout,
        ),
      ),
      isA<SettingsMaintenanceState>().having(
        (s) => s.status,
        'status',
        isA<SettingsMaintenanceFailure>()
            .having(
              (s) => s.action,
              'action',
              SettingsMaintenanceAction.resetOnboardingAndLogout,
            )
            .having(
              (s) => s.message,
              'message',
              contains('Failed to wipe account data'),
            ),
      ),
      isA<SettingsMaintenanceState>().having(
        (s) => s.status,
        'status',
        isA<SettingsMaintenanceIdle>(),
      ),
    ],
    verify: (_) {
      verify(() => userDataWipeService.wipeAllUserData()).called(1);
    },
  );
}
