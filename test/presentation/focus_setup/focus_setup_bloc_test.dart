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
        ),
      ),
      draftFocusMode: FocusMode.sustainable,
      draftUrgencyBoostMultiplier: 3,
      draftNeglectEnabled: false,
      draftNeglectLookbackDays: 3,
      draftNeglectInfluencePercent: 80,
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
          ),
    ],
  );
}
