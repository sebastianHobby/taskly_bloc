@Tags(['unit', 'settings'])
library;

import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/allocation_settings_bloc.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/telemetry.dart';

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
    registerFallbackValue(TestData.allocationConfig());
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

  late MockSettingsRepositoryContract settingsRepository;
  late TestStreamController<AllocationConfig> allocationController;

  AllocationSettingsBloc buildBloc() {
    return AllocationSettingsBloc(settingsRepository: settingsRepository);
  }

  setUp(() {
    settingsRepository = MockSettingsRepositoryContract();
    allocationController = TestStreamController.seeded(
      const AllocationConfig(),
    );

    when(() => settingsRepository.watch(SettingsKey.allocation)).thenAnswer(
      (_) => allocationController.stream,
    );
    when(
      () => settingsRepository.save(
        SettingsKey.allocation,
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});

    addTearDown(allocationController.close);
  });

  blocTestSafe<AllocationSettingsBloc, AllocationSettingsState>(
    'loads settings from repository stream',
    build: buildBloc,
    act: (bloc) => bloc.add(const AllocationSettingsStarted()),
    expect: () => [
      isA<AllocationSettingsState>().having(
        (s) => s.isLoading,
        'isLoading',
        false,
      ),
    ],
  );

  blocTestSafe<AllocationSettingsBloc, AllocationSettingsState>(
    'persists values balance changes with operation context',
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const AllocationSettingsStarted());
      bloc.add(
        const AllocationValuesBalanceModeChanged(
          ValuesBalanceMode.balanceOverTime,
        ),
      );
    },
    expect: () => [
      isA<AllocationSettingsState>(),
      isA<AllocationSettingsState>(),
    ],
    verify: (_) {
      final captured = verify(
        () => settingsRepository.save(
          SettingsKey.allocation,
          captureAny(),
          context: captureAny(named: 'context'),
        ),
      ).captured;
      final ctx = captured.last as OperationContext;
      expect(ctx.feature, 'settings');
      expect(ctx.operation, 'settings.save.allocation');
    },
  );

  blocTestSafe<AllocationSettingsBloc, AllocationSettingsState>(
    'emits error message when stream fails',
    build: () {
      when(() => settingsRepository.watch(SettingsKey.allocation)).thenAnswer(
        (_) => Stream.error(StateError('boom')),
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(const AllocationSettingsStarted()),
    expect: () => [
      isA<AllocationSettingsState>().having(
        (s) => s.errorMessage,
        'errorMessage',
        contains('boom'),
      ),
    ],
  );
}
