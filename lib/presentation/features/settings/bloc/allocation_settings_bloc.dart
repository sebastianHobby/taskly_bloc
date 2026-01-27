import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';

enum ValuesBalanceMode {
  balanceOverTime,
  prioritizeTopValues,
}

enum ProjectFocusStyle {
  rotateQuietProjects,
  stayFocused,
}

enum NextActionsPreference {
  flexible,
  preferNextActions,
}

enum SuggestionScope {
  compact,
  standard,
  expanded,
}

sealed class AllocationSettingsEvent {
  const AllocationSettingsEvent();
}

final class AllocationSettingsStarted extends AllocationSettingsEvent {
  const AllocationSettingsStarted();
}

final class AllocationSettingsStreamUpdated extends AllocationSettingsEvent {
  const AllocationSettingsStreamUpdated(this.settings);

  final AllocationConfig settings;
}

final class AllocationValuesBalanceModeChanged
    extends AllocationSettingsEvent {
  const AllocationValuesBalanceModeChanged(this.mode);

  final ValuesBalanceMode mode;
}

final class AllocationProjectFocusStyleChanged extends AllocationSettingsEvent {
  const AllocationProjectFocusStyleChanged(this.style);

  final ProjectFocusStyle style;
}

final class AllocationNextActionsPreferenceChanged
    extends AllocationSettingsEvent {
  const AllocationNextActionsPreferenceChanged(this.preference);

  final NextActionsPreference preference;
}

final class AllocationSuggestionScopeChanged
    extends AllocationSettingsEvent {
  const AllocationSuggestionScopeChanged(this.scope);

  final SuggestionScope scope;
}

final class AllocationSettingsState {
  const AllocationSettingsState({
    required this.settings,
    required this.isLoading,
    this.errorMessage,
  });

  factory AllocationSettingsState.loading() => AllocationSettingsState(
    settings: const AllocationConfig(),
    isLoading: true,
  );

  final AllocationConfig settings;
  final bool isLoading;
  final String? errorMessage;

  AllocationSettingsState copyWith({
    AllocationConfig? settings,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AllocationSettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AllocationSettingsBloc
    extends Bloc<AllocationSettingsEvent, AllocationSettingsState> {
  AllocationSettingsBloc({
    required SettingsRepositoryContract settingsRepository,
  }) : _settingsRepository = settingsRepository,
       super(AllocationSettingsState.loading()) {
    on<AllocationSettingsStarted>(_onStarted, transformer: restartable());
    on<AllocationSettingsStreamUpdated>(_onStreamUpdated);
    on<AllocationValuesBalanceModeChanged>(_onValuesBalanceChanged);
    on<AllocationProjectFocusStyleChanged>(_onProjectFocusChanged);
    on<AllocationNextActionsPreferenceChanged>(_onNextActionsChanged);
    on<AllocationSuggestionScopeChanged>(_onSuggestionScopeChanged);
  }

  final SettingsRepositoryContract _settingsRepository;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  Future<void> _onStarted(
    AllocationSettingsStarted event,
    Emitter<AllocationSettingsState> emit,
  ) async {
    await emit.forEach<AllocationConfig>(
      _settingsRepository.watch(SettingsKey.allocation),
      onData: (settings) => AllocationSettingsState(
        settings: settings,
        isLoading: false,
      ),
      onError: (error, stackTrace) => state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load allocation settings: $error',
      ),
    );
  }

  void _onStreamUpdated(
    AllocationSettingsStreamUpdated event,
    Emitter<AllocationSettingsState> emit,
  ) {
    emit(state.copyWith(settings: event.settings, isLoading: false));
  }

  Future<void> _onValuesBalanceChanged(
    AllocationValuesBalanceModeChanged event,
    Emitter<AllocationSettingsState> emit,
  ) async {
    final enableNeglectWeighting =
        event.mode == ValuesBalanceMode.balanceOverTime;
    final updated = state.settings.copyWith(
      strategySettings: state.settings.strategySettings.copyWith(
        enableNeglectWeighting: enableNeglectWeighting,
      ),
    );
    emit(state.copyWith(settings: updated, isLoading: false));
    await _persist(updated, intent: 'allocation_values_balance_changed');
  }

  Future<void> _onProjectFocusChanged(
    AllocationProjectFocusStyleChanged event,
    Emitter<AllocationSettingsState> emit,
  ) async {
    final rotationPressureDays = switch (event.style) {
      ProjectFocusStyle.rotateQuietProjects => 3,
      ProjectFocusStyle.stayFocused => 14,
    };
    final updated = state.settings.copyWith(
      strategySettings: state.settings.strategySettings.copyWith(
        rotationPressureDays: rotationPressureDays,
      ),
    );
    emit(state.copyWith(settings: updated, isLoading: false));
    await _persist(updated, intent: 'allocation_project_focus_changed');
  }

  Future<void> _onNextActionsChanged(
    AllocationNextActionsPreferenceChanged event,
    Emitter<AllocationSettingsState> emit,
  ) async {
    final nextActionPolicy = switch (event.preference) {
      NextActionsPreference.flexible => NextActionPolicy.off,
      NextActionsPreference.preferNextActions => NextActionPolicy.prefer,
    };
    final updated = state.settings.copyWith(
      strategySettings: state.settings.strategySettings.copyWith(
        nextActionPolicy: nextActionPolicy,
      ),
    );
    emit(state.copyWith(settings: updated, isLoading: false));
    await _persist(updated, intent: 'allocation_next_actions_changed');
  }

  Future<void> _onSuggestionScopeChanged(
    AllocationSuggestionScopeChanged event,
    Emitter<AllocationSettingsState> emit,
  ) async {
    final preset = _suggestionPresetFor(event.scope);
    final updated = state.settings.copyWith(
      suggestionsPerBatch: preset.suggestionsPerBatch,
      strategySettings: state.settings.strategySettings.copyWith(
        anchorCount: preset.anchorCount,
        tasksPerAnchorMin: preset.tasksPerAnchorMin,
        tasksPerAnchorMax: preset.tasksPerAnchorMax,
        freeSlots: preset.freeSlots,
      ),
    );
    emit(state.copyWith(settings: updated, isLoading: false));
    await _persist(updated, intent: 'allocation_suggestion_scope_changed');
  }

  Future<void> _persist(AllocationConfig updated, {required String intent}) async {
    final context = _contextFactory.create(
      feature: 'settings',
      screen: 'task_suggestions',
      intent: intent,
      operation: 'settings.save.allocation',
      extraFields: <String, Object?>{
        'settings': 'allocation',
      },
    );
    await _settingsRepository.save(
      SettingsKey.allocation,
      updated,
      context: context,
    );
  }

  static _SuggestionPreset _suggestionPresetFor(SuggestionScope scope) {
    return switch (scope) {
      SuggestionScope.compact => const _SuggestionPreset(
        suggestionsPerBatch: 5,
        anchorCount: 1,
        tasksPerAnchorMin: 1,
        tasksPerAnchorMax: 2,
        freeSlots: 0,
      ),
      SuggestionScope.standard => const _SuggestionPreset(
        suggestionsPerBatch: 7,
        anchorCount: 2,
        tasksPerAnchorMin: 1,
        tasksPerAnchorMax: 2,
        freeSlots: 0,
      ),
      SuggestionScope.expanded => const _SuggestionPreset(
        suggestionsPerBatch: 10,
        anchorCount: 3,
        tasksPerAnchorMin: 1,
        tasksPerAnchorMax: 2,
        freeSlots: 1,
      ),
    };
  }
}

class _SuggestionPreset {
  const _SuggestionPreset({
    required this.suggestionsPerBatch,
    required this.anchorCount,
    required this.tasksPerAnchorMin,
    required this.tasksPerAnchorMax,
    required this.freeSlots,
  });

  final int suggestionsPerBatch;
  final int anchorCount;
  final int tasksPerAnchorMin;
  final int tasksPerAnchorMax;
  final int freeSlots;
}
