@Tags(['unit', 'guided_tour'])
library;

import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/bloc/guided_tour_bloc.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/model/guided_tour_step.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/settings.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  late MockSettingsRepositoryContract settingsRepository;
  late DemoModeService demoModeService;

  GuidedTourBloc buildBloc() {
    return GuidedTourBloc(
      settingsRepository: settingsRepository,
      demoModeService: demoModeService,
    );
  }

  setUp(() {
    settingsRepository = MockSettingsRepositoryContract();
    demoModeService = DemoModeService();
    addTearDown(demoModeService.dispose);
  });

  blocTestSafe<GuidedTourBloc, GuidedTourState>(
    'starts tour from the first step',
    build: buildBloc,
    act: (bloc) => bloc.add(const GuidedTourStarted()),
    expect: () => [
      isA<GuidedTourState>()
          .having((s) => s.active, 'active', true)
          .having((s) => s.currentIndex, 'currentIndex', 0)
          .having((s) => s.navRequestId, 'navRequestId', 1),
    ],
    verify: (_) => expect(demoModeService.isEnabled, isTrue),
  );

  blocTestSafe<GuidedTourBloc, GuidedTourState>(
    'disables demo mode when skipped',
    build: buildBloc,
    act: (bloc) {
      bloc.add(const GuidedTourStarted());
      bloc.add(const GuidedTourSkipped());
    },
    expect: () => [
      isA<GuidedTourState>()
          .having((s) => s.active, 'active', true)
          .having((s) => s.currentIndex, 'currentIndex', 0)
          .having((s) => s.navRequestId, 'navRequestId', 1),
      isA<GuidedTourState>().having((s) => s.active, 'active', false),
    ],
    verify: (_) => expect(demoModeService.isEnabled, isFalse),
  );

  blocTestSafe<GuidedTourBloc, GuidedTourState>(
    'advances to the next step',
    build: buildBloc,
    act: (bloc) {
      bloc.add(const GuidedTourStarted());
      bloc.add(const GuidedTourNextRequested());
    },
    expect: () => [
      isA<GuidedTourState>()
          .having((s) => s.active, 'active', true)
          .having((s) => s.currentIndex, 'currentIndex', 0)
          .having((s) => s.navRequestId, 'navRequestId', 1),
      isA<GuidedTourState>()
          .having((s) => s.active, 'active', true)
          .having((s) => s.currentIndex, 'currentIndex', 1)
          .having((s) => s.navRequestId, 'navRequestId', 2),
    ],
  );

  blocTestSafe<GuidedTourBloc, GuidedTourState>(
    'completes and persists on the last step',
    build: () {
      when(() => settingsRepository.load(SettingsKey.global)).thenAnswer(
        (_) async => const GlobalSettings(),
      );
      when(
        () => settingsRepository.save(
          SettingsKey.global,
          any(),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});
      return buildBloc();
    },
    seed: () {
      final steps = buildGuidedTourSteps();
      return GuidedTourState.initial().copyWith(
        active: true,
        currentIndex: steps.length - 1,
      );
    },
    act: (bloc) => bloc.add(const GuidedTourNextRequested()),
    expect: () => [
      isA<GuidedTourState>().having((s) => s.active, 'active', false),
    ],
    verify: (_) {
      verify(() => settingsRepository.load(SettingsKey.global)).called(1);
      final captured = verify(
        () => settingsRepository.save(
          SettingsKey.global,
          captureAny(),
          context: any(named: 'context'),
        ),
      ).captured;
      final saved = captured.single as GlobalSettings;
      expect(saved.guidedTourCompleted, isTrue);
    },
  );
}
