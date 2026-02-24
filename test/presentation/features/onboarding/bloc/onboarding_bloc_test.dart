@Tags(['unit', 'onboarding'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/taskly_domain.dart';

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerFallbackValue(const AllocationConfig());
  });
  setUp(setUpTestEnvironment);

  late MockSettingsRepositoryContract settingsRepository;
  late MockValueRepositoryContract valueRepository;
  late ValueWriteService valueWriteService;
  late AppErrorReporter errorReporter;

  OnboardingBloc buildBloc() {
    return OnboardingBloc(
      settingsRepository: settingsRepository,
      valueRepository: valueRepository,
      valueWriteService: valueWriteService,
      errorReporter: errorReporter,
    );
  }

  setUp(() {
    settingsRepository = MockSettingsRepositoryContract();
    valueRepository = MockValueRepositoryContract();
    valueWriteService = ValueWriteService(valueRepository: valueRepository);
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );
  });

  blocTestSafe<OnboardingBloc, OnboardingState>(
    'advances from welcome to values setup',
    build: buildBloc,
    act: (bloc) => bloc.add(const OnboardingNextRequested()),
    expect: () => [
      isA<OnboardingState>().having(
        (s) => s.step,
        'step',
        OnboardingStep.valuesSetup,
      ),
    ],
  );

  blocTestSafe<OnboardingBloc, OnboardingState>(
    'advances from values setup to ratings when at least 3 values exist',
    build: buildBloc,
    seed: () => const OnboardingState(
      step: OnboardingStep.valuesSetup,
      selectedValues: [
        OnboardingValueSelection(
          id: 'value-1',
          name: 'Health',
          color: '#000000',
          iconName: 'health',
          priority: ValuePriority.medium,
        ),
        OnboardingValueSelection(
          id: 'value-2',
          name: 'Learning',
          color: '#111111',
          iconName: 'school',
          priority: ValuePriority.medium,
        ),
        OnboardingValueSelection(
          id: 'value-3',
          name: 'Relationships',
          color: '#222222',
          iconName: 'groups',
          priority: ValuePriority.medium,
        ),
      ],
      isCreatingValue: false,
      isCompleting: false,
      effect: null,
    ),
    act: (bloc) => bloc.add(const OnboardingNextRequested()),
    expect: () => [
      isA<OnboardingState>().having(
        (s) => s.step,
        'step',
        OnboardingStep.ratings,
      ),
    ],
  );

  blocTestSafe<OnboardingBloc, OnboardingState>(
    'blocks values setup when fewer than 3 values are selected',
    build: buildBloc,
    seed: () => const OnboardingState(
      step: OnboardingStep.valuesSetup,
      selectedValues: [
        OnboardingValueSelection(
          id: 'value-1',
          name: 'Health',
          color: '#000000',
          iconName: 'health',
          priority: ValuePriority.medium,
        ),
      ],
      isCreatingValue: false,
      isCompleting: false,
      effect: null,
    ),
    act: (bloc) => bloc.add(const OnboardingNextRequested()),
    expect: () => [
      isA<OnboardingState>().having(
        (s) => s.effect,
        'effect',
        isA<OnboardingErrorEffect>(),
      ),
    ],
  );

  blocTestSafe<OnboardingBloc, OnboardingState>(
    'saves default suggestion signal when onboarding completes',
    build: () {
      when(() => settingsRepository.load(SettingsKey.allocation)).thenAnswer(
        (_) async => const AllocationConfig(),
      );
      when(
        () => settingsRepository.save(
          SettingsKey.allocation,
          any<AllocationConfig>(),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});
      return buildBloc();
    },
    act: (bloc) => bloc.add(const OnboardingCompleteRequested()),
    expect: () => [
      isA<OnboardingState>().having(
        (s) => s.isCompleting,
        'isCompleting',
        true,
      ),
      isA<OnboardingState>()
          .having((s) => s.isCompleting, 'isCompleting', false)
          .having((s) => s.effect, 'effect', isA<OnboardingCompletedEffect>()),
    ],
    verify: (_) {
      final captured = verify(
        () => settingsRepository.save(
          SettingsKey.allocation,
          captureAny<AllocationConfig>(),
          context: any(named: 'context'),
        ),
      ).captured;
      final saved = captured.single as AllocationConfig;
      expect(saved.suggestionSignal, SuggestionSignal.ratingsBased);
    },
  );
}
