@Tags(['unit', 'settings'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/presentation_mocks.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/theme/app_theme_mode.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/telemetry.dart';

class MockAttentionRepositoryContract extends Mock
    implements AttentionRepositoryContract {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
    registerFallbackValue(TestData.dateRange());
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
  late MockAttentionRepositoryContract attentionRepository;
  late MockNowService nowService;
  late AppErrorReporter errorReporter;
  late TestStreamController<GlobalSettings> settingsController;

  GlobalSettingsBloc buildBloc() {
    return GlobalSettingsBloc(
      settingsRepository: settingsRepository,
      attentionRepository: attentionRepository,
      nowService: nowService,
      errorReporter: errorReporter,
    );
  }

  setUp(() {
    settingsRepository = MockSettingsRepositoryContract();
    attentionRepository = MockAttentionRepositoryContract();
    nowService = MockNowService();
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );
    settingsController = TestStreamController.seeded(const GlobalSettings());

    when(() => settingsRepository.watch(SettingsKey.global)).thenAnswer(
      (_) => settingsController.stream,
    );
    when(
      () => settingsRepository.save(
        SettingsKey.global,
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
    when(() => nowService.nowUtc()).thenReturn(DateTime.utc(2025, 1, 15));

    addTearDown(settingsController.close);
  });

  blocTestSafe<GlobalSettingsBloc, GlobalSettingsState>(
    'loads settings from stream',
    build: buildBloc,
    act: (bloc) => bloc.add(const GlobalSettingsEvent.started()),
    expect: () => [
      isA<GlobalSettingsState>().having((s) => s.isLoading, 'isLoading', false),
    ],
  );

  blocTestSafe<GlobalSettingsBloc, GlobalSettingsState>(
    'theme mode change persists settings with context',
    build: buildBloc,
    act: (bloc) =>
        bloc.add(const GlobalSettingsEvent.themeModeChanged(AppThemeMode.dark)),
    expect: () => [],
    verify: (_) {
      final captured = verify(
        () => settingsRepository.save(
          SettingsKey.global,
          captureAny(),
          context: captureAny(named: 'context'),
        ),
      ).captured;
      final ctx = captured.last as OperationContext;
      expect(ctx.feature, 'settings');
      expect(ctx.operation, 'settings.save.global');
    },
  );
}
