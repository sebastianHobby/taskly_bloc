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
  setUpAll(setUpAllTestEnvironment);
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
      OnboardingState.initial().copyWith(displayName: 'Taylor'),
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
      OnboardingState.initial().copyWith(step: OnboardingStep.name),
      OnboardingState.initial().copyWith(
        step: OnboardingStep.name,
        displayName: 'Alex',
      ),
      OnboardingState.initial().copyWith(
        step: OnboardingStep.name,
        displayName: 'Alex',
        isSavingName: true,
      ),
      OnboardingState.initial().copyWith(
        step: OnboardingStep.suggestionSignal,
        displayName: 'Alex',
        isSavingName: false,
      ),
    ],
  );

  blocTestSafe<OnboardingBloc, OnboardingState>(
    'saves suggestion signal and moves to values setup',
    build: () {
      when(() => settingsRepository.load(SettingsKey.allocation)).thenAnswer(
        (_) async => const AllocationConfig(),
      );
      when(
        () => settingsRepository.save(
          SettingsKey.allocation,
          any(),
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
      OnboardingState.initial().copyWith(step: OnboardingStep.name),
      OnboardingState.initial().copyWith(
        step: OnboardingStep.name,
        displayName: 'Sam',
      ),
      OnboardingState.initial().copyWith(
        step: OnboardingStep.name,
        displayName: 'Sam',
        isSavingName: true,
      ),
      OnboardingState.initial().copyWith(
        step: OnboardingStep.suggestionSignal,
        displayName: 'Sam',
        isSavingName: false,
      ),
      OnboardingState.initial().copyWith(
        step: OnboardingStep.suggestionSignal,
        displayName: 'Sam',
        suggestionSignal: SuggestionSignal.behaviorBased,
      ),
      OnboardingState.initial().copyWith(
        step: OnboardingStep.suggestionSignal,
        displayName: 'Sam',
        suggestionSignal: SuggestionSignal.behaviorBased,
        isSavingSuggestionSignal: true,
      ),
      OnboardingState.initial().copyWith(
        step: OnboardingStep.valuesSetup,
        displayName: 'Sam',
        suggestionSignal: SuggestionSignal.behaviorBased,
        isSavingSuggestionSignal: false,
      ),
    ],
  );
}
