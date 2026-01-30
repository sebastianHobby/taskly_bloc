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

  late MockAuthRepositoryContract authRepository;
  late MockSettingsRepositoryContract settingsRepository;
  late MockValueRepositoryContract valueRepository;
  late ValueWriteService valueWriteService;
  late AppErrorReporter errorReporter;

  OnboardingBloc buildBloc() {
    return OnboardingBloc(
      authRepository: authRepository,
      settingsRepository: settingsRepository,
      valueRepository: valueRepository,
      valueWriteService: valueWriteService,
      errorReporter: errorReporter,
    );
  }

  setUp(() {
    authRepository = MockAuthRepositoryContract();
    settingsRepository = MockSettingsRepositoryContract();
    valueRepository = MockValueRepositoryContract();
    valueWriteService = ValueWriteService(valueRepository: valueRepository);
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );
  });

  blocTestSafe<OnboardingBloc, OnboardingState>(
    'name change updates display name',
    build: buildBloc,
    act: (bloc) => bloc.add(const OnboardingNameChanged('Taylor')),
    expect: () => [
      isA<OnboardingState>().having(
        (s) => s.displayName,
        'displayName',
        'Taylor',
      ),
    ],
  );

  blocTestSafe<OnboardingBloc, OnboardingState>(
    'advances from name step when display name is saved',
    build: () {
      when(
        () => authRepository.updateUserProfile(
          displayName: any(named: 'displayName'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async => const UserUpdateResponse());
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(const OnboardingNextRequested());
      bloc.add(const OnboardingNameChanged('Alex'));
      bloc.add(const OnboardingNextRequested());
    },
    expect: () => [
      isA<OnboardingState>().having((s) => s.step, 'step', OnboardingStep.name),
      isA<OnboardingState>()
          .having((s) => s.step, 'step', OnboardingStep.name)
          .having((s) => s.displayName, 'displayName', 'Alex'),
      isA<OnboardingState>()
          .having((s) => s.step, 'step', OnboardingStep.name)
          .having((s) => s.displayName, 'displayName', 'Alex')
          .having((s) => s.isSavingName, 'isSavingName', true),
      isA<OnboardingState>()
          .having(
            (s) => s.step,
            'step',
            OnboardingStep.suggestionSignal,
          )
          .having((s) => s.displayName, 'displayName', 'Alex')
          .having((s) => s.isSavingName, 'isSavingName', false),
    ],
  );

  blocTestSafe<OnboardingBloc, OnboardingState>(
    'saves suggestion signal and moves to values setup',
    build: () {
      when(
        () => authRepository.updateUserProfile(
          displayName: any(named: 'displayName'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async => const UserUpdateResponse());
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
    act: (bloc) async {
      bloc.add(const OnboardingNextRequested());
      bloc.add(const OnboardingNameChanged('Sam'));
      bloc.add(const OnboardingNextRequested());
      bloc.add(
        const OnboardingSuggestionSignalChanged(
          SuggestionSignal.behaviorBased,
        ),
      );
      bloc.add(const OnboardingNextRequested());
    },
    expect: () => [
      isA<OnboardingState>().having((s) => s.step, 'step', OnboardingStep.name),
      isA<OnboardingState>()
          .having((s) => s.step, 'step', OnboardingStep.name)
          .having((s) => s.displayName, 'displayName', 'Sam'),
      isA<OnboardingState>()
          .having((s) => s.step, 'step', OnboardingStep.name)
          .having((s) => s.displayName, 'displayName', 'Sam')
          .having((s) => s.isSavingName, 'isSavingName', true),
      isA<OnboardingState>()
          .having(
            (s) => s.step,
            'step',
            OnboardingStep.suggestionSignal,
          )
          .having((s) => s.displayName, 'displayName', 'Sam')
          .having((s) => s.isSavingName, 'isSavingName', false),
      isA<OnboardingState>()
          .having(
            (s) => s.step,
            'step',
            OnboardingStep.suggestionSignal,
          )
          .having((s) => s.displayName, 'displayName', 'Sam')
          .having(
            (s) => s.suggestionSignal,
            'suggestionSignal',
            SuggestionSignal.behaviorBased,
          ),
      isA<OnboardingState>()
          .having(
            (s) => s.step,
            'step',
            OnboardingStep.suggestionSignal,
          )
          .having((s) => s.displayName, 'displayName', 'Sam')
          .having(
            (s) => s.suggestionSignal,
            'suggestionSignal',
            SuggestionSignal.behaviorBased,
          )
          .having(
            (s) => s.isSavingSuggestionSignal,
            'isSavingSuggestionSignal',
            true,
          ),
      isA<OnboardingState>()
          .having(
            (s) => s.step,
            'step',
            OnboardingStep.valuesSetup,
          )
          .having((s) => s.displayName, 'displayName', 'Sam')
          .having(
            (s) => s.suggestionSignal,
            'suggestionSignal',
            SuggestionSignal.behaviorBased,
          )
          .having(
            (s) => s.isSavingSuggestionSignal,
            'isSavingSuggestionSignal',
            false,
          ),
    ],
  );
}
