import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/interfaces/attention_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_config.dart';
import 'package:taskly_bloc/domain/models/settings/focus_mode.dart';
import 'package:taskly_bloc/presentation/features/focus_setup/bloc/focus_setup_bloc.dart';
import 'package:test/test.dart';

class _MockSettingsRepository extends Mock
    implements SettingsRepositoryContract {}

class _MockAttentionRepository extends Mock
    implements AttentionRepositoryContract {}

void main() {
  blocTest<FocusSetupBloc, FocusSetupState>(
    'allocationResetToDefaultPressed resets draft strategy fields to preset',
    build: () => FocusSetupBloc(
      settingsRepository: _MockSettingsRepository(),
      attentionRepository: _MockAttentionRepository(),
    ),
    seed: () => FocusSetupState(
      isLoading: false,
      persistedAllocationConfig: AllocationConfig(
        focusMode: FocusMode.sustainable,
        strategySettings: const StrategySettings(
          urgencyBoostMultiplier: 2,
          enableNeglectWeighting: false,
          neglectLookbackDays: 10,
          neglectInfluence: 0.8,
          valuePriorityWeight: 0.5,
          taskPriorityBoost: 2,
          recencyPenalty: 0.3,
          overdueEmergencyMultiplier: 3,
        ),
      ),
      draftFocusMode: FocusMode.sustainable,
      draftUrgencyBoostMultiplier: 3,
      draftNeglectEnabled: false,
      draftNeglectLookbackDays: 3,
      draftNeglectInfluencePercent: 80,
      draftValuePriorityWeightPercent: 0,
      draftTaskFlagBoost: 4.5,
      draftRecencyPenaltyPercent: 0,
      draftOverdueEmergencyMultiplier: 5,
    ),
    act: (bloc) =>
        bloc.add(const FocusSetupEvent.allocationResetToDefaultPressed()),
    expect: () => [
      isA<FocusSetupState>()
          .having((s) => s.draftUrgencyBoostMultiplier, 'urgency', 1.5)
          .having((s) => s.draftNeglectEnabled, 'neglectEnabled', true)
          .having((s) => s.draftNeglectLookbackDays, 'lookback', 7)
          .having(
            (s) => s.draftNeglectInfluencePercent,
            'influencePercent',
            50,
          )
          .having(
            (s) => s.draftValuePriorityWeightPercent,
            'valuePriorityPercent',
            75,
          )
          .having((s) => s.draftTaskFlagBoost, 'taskFlagBoost', 1.0)
          .having(
            (s) => s.draftRecencyPenaltyPercent,
            'recencyPenaltyPercent',
            10,
          )
          .having(
            (s) => s.draftOverdueEmergencyMultiplier,
            'overdueEmergencyMultiplier',
            1.5,
          ),
    ],
  );

  blocTest<FocusSetupBloc, FocusSetupState>(
    'focusModeChanged to non-personalized clamps steps and applies preset drafts',
    build: () => FocusSetupBloc(
      settingsRepository: _MockSettingsRepository(),
      attentionRepository: _MockAttentionRepository(),
    ),
    seed: () => const FocusSetupState(
      isLoading: false,
      stepIndex: 1,
      draftFocusMode: FocusMode.personalized,
      draftUrgencyBoostMultiplier: 4,
    ),
    act: (bloc) =>
        bloc.add(const FocusSetupEvent.focusModeChanged(FocusMode.intentional)),
    expect: () {
      final preset = StrategySettings.forFocusMode(FocusMode.intentional);

      return [
        isA<FocusSetupState>()
            .having((s) => s.draftFocusMode, 'focusMode', FocusMode.intentional)
            .having((s) => s.maxStepIndex, 'maxStepIndex', 2)
            .having(
              (s) => s.currentStep,
              'currentStep',
              FocusSetupWizardStep.reviewSchedule,
            )
            .having(
              (s) => s.draftUrgencyBoostMultiplier,
              'urgencyBoost',
              preset.urgencyBoostMultiplier,
            )
            .having(
              (s) => s.draftNeglectEnabled,
              'neglectEnabled',
              preset.enableNeglectWeighting,
            )
            .having(
              (s) => s.draftNeglectLookbackDays,
              'lookbackDays',
              preset.neglectLookbackDays,
            )
            .having(
              (s) => s.draftNeglectInfluencePercent,
              'neglectInfluencePercent',
              (preset.neglectInfluence * 100).round().clamp(0, 100),
            ),
      ];
    },
  );

  blocTest<FocusSetupBloc, FocusSetupState>(
    'focusModeChanged to personalized clears draft weightings',
    build: () => FocusSetupBloc(
      settingsRepository: _MockSettingsRepository(),
      attentionRepository: _MockAttentionRepository(),
    ),
    seed: () => const FocusSetupState(
      isLoading: false,
      draftFocusMode: FocusMode.sustainable,
      draftUrgencyBoostMultiplier: 1.5,
      draftNeglectEnabled: true,
      draftNeglectLookbackDays: 7,
      draftNeglectInfluencePercent: 50,
      draftValuePriorityWeightPercent: 75,
      draftTaskFlagBoost: 1,
      draftRecencyPenaltyPercent: 10,
      draftOverdueEmergencyMultiplier: 1.5,
    ),
    act: (bloc) => bloc.add(
      const FocusSetupEvent.focusModeChanged(FocusMode.personalized),
    ),
    expect: () => [
      isA<FocusSetupState>()
          .having((s) => s.draftFocusMode, 'focusMode', FocusMode.personalized)
          .having((s) => s.draftUrgencyBoostMultiplier, 'urgency', isNull)
          .having((s) => s.draftNeglectEnabled, 'neglectEnabled', isNull)
          .having((s) => s.draftNeglectLookbackDays, 'lookback', isNull)
          .having(
            (s) => s.draftNeglectInfluencePercent,
            'influencePercent',
            isNull,
          )
          .having(
            (s) => s.draftValuePriorityWeightPercent,
            'valuePriorityPercent',
            isNull,
          )
          .having((s) => s.draftTaskFlagBoost, 'taskFlagBoost', isNull)
          .having(
            (s) => s.draftRecencyPenaltyPercent,
            'recencyPenaltyPercent',
            isNull,
          )
          .having(
            (s) => s.draftOverdueEmergencyMultiplier,
            'overdueEmergencyMultiplier',
            isNull,
          ),
    ],
  );
}
