import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/errors.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/telemetry.dart';

part 'focus_setup_bloc.freezed.dart';

class _QuickAddPreset {
  const _QuickAddPreset({required this.colorHex, required this.iconName});

  final String colorHex;
  final String iconName;
}

const _quickAddPresets = <String, _QuickAddPreset>{
  'Health': _QuickAddPreset(colorHex: '#43A047', iconName: 'health'),
  'Family': _QuickAddPreset(colorHex: '#FB8C00', iconName: 'home'),
  'Career': _QuickAddPreset(colorHex: '#1E88E5', iconName: 'work'),
  'Learning': _QuickAddPreset(colorHex: '#7E57C2', iconName: 'lightbulb'),
  'Relationships': _QuickAddPreset(colorHex: '#E91E63', iconName: 'group'),
};

enum FocusSetupWizardStep {
  selectFocusMode,
  valuesCta,
  finalize,
}

@freezed
sealed class FocusSetupEvent with _$FocusSetupEvent {
  const factory FocusSetupEvent.started({FocusSetupWizardStep? initialStep}) =
      FocusSetupStarted;

  const factory FocusSetupEvent.backPressed() = FocusSetupBackPressed;
  const factory FocusSetupEvent.nextPressed() = FocusSetupNextPressed;

  const factory FocusSetupEvent.focusModeChanged(FocusMode focusMode) =
      FocusSetupFocusModeChanged;

  const factory FocusSetupEvent.neglectEnabledChanged(bool enabled) =
      FocusSetupNeglectEnabledChanged;

  const factory FocusSetupEvent.suggestionsPerBatchChanged(int value) =
      FocusSetupSuggestionsPerBatchChanged;

  const factory FocusSetupEvent.finalizePressed() = FocusSetupFinalizePressed;

  const factory FocusSetupEvent.allocationStreamUpdated(
    AllocationConfig allocationConfig,
  ) = FocusSetupAllocationStreamUpdated;

  const factory FocusSetupEvent.valuesStreamUpdated(int valuesCount) =
      FocusSetupValuesStreamUpdated;

  const factory FocusSetupEvent.quickAddValueRequested(String name) =
      FocusSetupQuickAddValueRequested;

  const factory FocusSetupEvent.saveFailed(String message) =
      FocusSetupSaveFailed;

  const factory FocusSetupEvent.saveSucceeded() = FocusSetupSaveSucceeded;
}

@freezed
sealed class FocusSetupState with _$FocusSetupState {
  const factory FocusSetupState({
    @Default(true) bool isLoading,
    @Default(false) bool isSaving,
    String? errorMessage,
    @Default(0) int stepIndex,

    /// Count of values in the system (used for My Day prerequisites).
    @Default(0) int valuesCount,

    /// Baseline persisted config (for merge-on-save).
    AllocationConfig? persistedAllocationConfig,

    /// Draft allocation settings.
    FocusMode? draftFocusMode,
    bool? draftNeglectEnabled,
    int? draftSuggestionsPerBatch,
    @Default(false) bool showAdvancedSettings,

    @Default(false) bool saveSucceeded,
  }) = _FocusSetupState;

  const FocusSetupState._();

  bool get canGoBack => stepIndex > 0 && !isSaving;

  bool get canGoNext {
    if (isSaving) return false;

    if (currentStep == FocusSetupWizardStep.valuesCta) {
      return valuesCount > 0;
    }

    return stepIndex < maxStepIndex;
  }

  List<FocusSetupWizardStep> get steps {
    final hasSelectedFocusMode =
        persistedAllocationConfig?.hasSelectedFocusMode ?? false;
    final hasValues = valuesCount > 0;

    // When prerequisites are missing (gate flow), show only the missing steps.
    final prereqsMissing = !hasSelectedFocusMode || !hasValues;
    if (prereqsMissing) {
      final steps = <FocusSetupWizardStep>[];
      if (!hasSelectedFocusMode) {
        steps.add(FocusSetupWizardStep.selectFocusMode);
      }
      if (!hasValues) {
        steps.add(FocusSetupWizardStep.valuesCta);
      }
      steps.add(FocusSetupWizardStep.finalize);
      return steps;
    }

    // Full wizard (settings route): include values step as part of setup.
    return const [
      FocusSetupWizardStep.selectFocusMode,
      FocusSetupWizardStep.valuesCta,
      FocusSetupWizardStep.finalize,
    ];
  }

  int get maxStepIndex => steps.length - 1;

  FocusSetupWizardStep get currentStep {
    final i = stepIndex.clamp(0, maxStepIndex);
    return steps[i];
  }

  FocusMode get effectiveFocusMode {
    final draft = draftFocusMode;
    if (draft != null) return draft;
    final persisted = persistedAllocationConfig;
    if (persisted != null) return persisted.focusMode;
    return FocusMode.sustainable;
  }

  bool get effectiveNeglectEnabled {
    final draft = draftNeglectEnabled;
    if (draft != null) return draft;
    final persisted = persistedAllocationConfig;
    if (persisted != null) {
      return persisted.strategySettings.enableNeglectWeighting;
    }
    return false;
  }

  int get effectiveSuggestionsPerBatch {
    final draft = draftSuggestionsPerBatch;
    if (draft != null) return draft.clamp(1, 50);
    final persisted = persistedAllocationConfig;
    if (persisted != null) return persisted.suggestionsPerBatch.clamp(1, 50);
    return 7;
  }
}

class FocusSetupBloc extends Bloc<FocusSetupEvent, FocusSetupState> {
  FocusSetupBloc({
    required SettingsRepositoryContract settingsRepository,
    required ValueRepositoryContract valueRepository,
    required AppErrorReporter errorReporter,
  }) : _settingsRepository = settingsRepository,
       _valueRepository = valueRepository,
       _errorReporter = errorReporter,
       super(const FocusSetupState()) {
    on<FocusSetupStarted>(_onStarted, transformer: droppable());
    on<FocusSetupAllocationStreamUpdated>(
      _onAllocationStreamUpdated,
      transformer: sequential(),
    );
    on<FocusSetupValuesStreamUpdated>(
      _onValuesStreamUpdated,
      transformer: sequential(),
    );

    on<FocusSetupBackPressed>(_onBackPressed, transformer: droppable());
    on<FocusSetupNextPressed>(_onNextPressed, transformer: droppable());

    on<FocusSetupFocusModeChanged>(
      _onFocusModeChanged,
      transformer: droppable(),
    );
    on<FocusSetupNeglectEnabledChanged>(
      _onNeglectEnabledChanged,
      transformer: droppable(),
    );

    on<FocusSetupSuggestionsPerBatchChanged>(
      _onSuggestionsPerBatchChanged,
      transformer: droppable(),
    );

    on<FocusSetupQuickAddValueRequested>(
      _onQuickAddValueRequested,
      transformer: droppable(),
    );

    on<FocusSetupFinalizePressed>(_onFinalizePressed, transformer: droppable());
    on<FocusSetupSaveFailed>(_onSaveFailed, transformer: sequential());
    on<FocusSetupSaveSucceeded>(_onSaveSucceeded, transformer: sequential());
  }

  final SettingsRepositoryContract _settingsRepository;
  final ValueRepositoryContract _valueRepository;
  final AppErrorReporter _errorReporter;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  void _reportIfUnexpectedOrUnmapped(
    Object error,
    StackTrace stackTrace, {
    required OperationContext context,
    required String message,
  }) {
    if (error is AppFailure && error.reportAsUnexpected) {
      _errorReporter.reportUnexpected(
        error,
        stackTrace,
        context: context,
        message: '$message (unexpected failure)',
      );
      return;
    }

    if (error is! AppFailure) {
      _errorReporter.reportUnexpected(
        error,
        stackTrace,
        context: context,
        message: '$message (unmapped exception)',
      );
    }
  }

  String _uiMessageFor(Object error) {
    if (error is AppFailure) return error.uiMessage();
    return 'Something went wrong. Please try again.';
  }

  StreamSubscription<AllocationConfig>? _allocationSub;
  StreamSubscription<dynamic>? _valuesSub;

  FocusSetupWizardStep? _pendingInitialStep;

  @override
  Future<void> close() async {
    await _allocationSub?.cancel();
    await _valuesSub?.cancel();
    return super.close();
  }

  Future<void> _onStarted(
    FocusSetupStarted event,
    Emitter<FocusSetupState> emit,
  ) async {
    _pendingInitialStep = event.initialStep;
    emit(state.copyWith(isLoading: true, errorMessage: null));

    await _allocationSub?.cancel();
    _allocationSub = _settingsRepository
        .watch(SettingsKey.allocation)
        .listen(
          (cfg) => add(FocusSetupEvent.allocationStreamUpdated(cfg)),
          onError: (Object e, StackTrace st) {
            talker.error('[FocusSetupBloc] allocation stream error', e, st);

            final context = _contextFactory.create(
              feature: 'focus_setup',
              screen: 'focus_setup',
              intent: 'allocation_stream_error',
              operation: 'settings.watch.allocation',
              entityType: 'settings',
            );
            _reportIfUnexpectedOrUnmapped(
              e,
              st,
              context: context,
              message: '[FocusSetupBloc] allocation stream error',
            );
            add(
              const FocusSetupEvent.saveFailed(
                'Failed to load allocation settings',
              ),
            );
          },
        );

    await _valuesSub?.cancel();

    // Seed valuesCount from a snapshot so the wizard doesn't incorrectly
    // conclude there are no values if the watch stream is delayed.
    try {
      final initialValues = await _valueRepository.getAll();
      add(FocusSetupEvent.valuesStreamUpdated(initialValues.length));
    } catch (e, st) {
      talker.error('[FocusSetupBloc] initial values snapshot failed', e, st);

      final context = _contextFactory.create(
        feature: 'focus_setup',
        screen: 'focus_setup',
        intent: 'values_initial_snapshot_error',
        operation: 'values.getAll',
        entityType: 'value',
      );
      _reportIfUnexpectedOrUnmapped(
        e,
        st,
        context: context,
        message: '[FocusSetupBloc] initial values snapshot failed',
      );

      add(const FocusSetupEvent.saveFailed('Failed to load values'));
      return;
    }

    _valuesSub = _valueRepository.watchAll().listen(
      (values) => add(FocusSetupEvent.valuesStreamUpdated(values.length)),
      onError: (Object e, StackTrace st) {
        talker.error('[FocusSetupBloc] values stream error', e, st);

        final context = _contextFactory.create(
          feature: 'focus_setup',
          screen: 'focus_setup',
          intent: 'values_stream_error',
          operation: 'values.watchAll',
          entityType: 'value',
        );
        _reportIfUnexpectedOrUnmapped(
          e,
          st,
          context: context,
          message: '[FocusSetupBloc] values stream error',
        );
        add(const FocusSetupEvent.saveFailed('Failed to load values'));
      },
    );
  }

  void _onAllocationStreamUpdated(
    FocusSetupAllocationStreamUpdated event,
    Emitter<FocusSetupState> emit,
  ) {
    final next = _applyPendingInitialStepIfPossible(
      state.copyWith(
        persistedAllocationConfig: event.allocationConfig,
        isLoading: false,
      ),
    );
    emit(next);
  }

  void _onValuesStreamUpdated(
    FocusSetupValuesStreamUpdated event,
    Emitter<FocusSetupState> emit,
  ) {
    final next = _applyPendingInitialStepIfPossible(
      state.copyWith(
        valuesCount: event.valuesCount,
        isLoading: false,
      ),
    );
    emit(next);
  }

  FocusSetupState _applyPendingInitialStepIfPossible(FocusSetupState next) {
    final desired = _pendingInitialStep;
    if (desired == null) return next;

    final idx = next.steps.indexOf(desired);
    if (idx < 0) return next;

    _pendingInitialStep = null;
    return next.copyWith(stepIndex: idx);
  }

  Future<void> _onQuickAddValueRequested(
    FocusSetupQuickAddValueRequested event,
    Emitter<FocusSetupState> emit,
  ) async {
    final name = event.name.trim();
    if (name.isEmpty) return;

    final preset = _quickAddPresets[name];
    final color = preset?.colorHex ?? _colorHexForName(name);

    final context = _contextFactory.create(
      feature: 'focus_setup',
      screen: 'focus_setup',
      intent: 'value_quick_add_requested',
      operation: 'values.create',
      entityType: 'value',
      extraFields: <String, Object?>{'source': 'focus_setup'},
    );

    try {
      await _valueRepository.create(
        name: name,
        color: color,
        iconName: preset?.iconName,
        context: context,
      );
    } catch (e, st) {
      talker.error('[FocusSetupBloc] quick add value failed', e, st);
      _reportIfUnexpectedOrUnmapped(
        e,
        st,
        context: context,
        message: '[FocusSetupBloc] quick add value failed',
      );
      emit(state.copyWith(errorMessage: _uiMessageFor(e)));
    }
  }

  String _colorHexForName(String name) {
    const palette = <String>[
      '#6366F1',
      '#0EA5E9',
      '#10B981',
      '#F59E0B',
      '#EF4444',
      '#8B5CF6',
      '#14B8A6',
      '#22C55E',
      '#E11D48',
    ];

    final hash = name.toLowerCase().codeUnits.fold<int>(
      0,
      (a, b) => (a * 31 + b) & 0x7fffffff,
    );
    return palette[hash % palette.length];
  }

  void _onBackPressed(
    FocusSetupBackPressed event,
    Emitter<FocusSetupState> emit,
  ) {
    if (!state.canGoBack) return;
    emit(state.copyWith(stepIndex: state.stepIndex - 1, errorMessage: null));
  }

  void _onNextPressed(
    FocusSetupNextPressed event,
    Emitter<FocusSetupState> emit,
  ) {
    if (!state.canGoNext) return;
    emit(state.copyWith(stepIndex: state.stepIndex + 1, errorMessage: null));
  }

  void _onFocusModeChanged(
    FocusSetupFocusModeChanged event,
    Emitter<FocusSetupState> emit,
  ) {
    final nextFocusMode = event.focusMode;
    final nextStateForSteps = state.copyWith(draftFocusMode: nextFocusMode);
    final clampedStepIndex = state.stepIndex.clamp(
      0,
      nextStateForSteps.maxStepIndex,
    );

    // With the new Suggested picks engine, we keep only one user-facing knob:
    // the value balancing toggle.
    final preset = StrategySettings.forFocusMode(nextFocusMode);
    emit(
      state.copyWith(
        draftFocusMode: nextFocusMode,
        stepIndex: clampedStepIndex,
        draftNeglectEnabled: preset.enableNeglectWeighting,
        errorMessage: null,
      ),
    );
  }

  void _onNeglectEnabledChanged(
    FocusSetupNeglectEnabledChanged event,
    Emitter<FocusSetupState> emit,
  ) {
    emit(state.copyWith(draftNeglectEnabled: event.enabled));
  }

  void _onSuggestionsPerBatchChanged(
    FocusSetupSuggestionsPerBatchChanged event,
    Emitter<FocusSetupState> emit,
  ) {
    emit(state.copyWith(draftSuggestionsPerBatch: event.value.clamp(1, 50)));
  }

  Future<void> _onFinalizePressed(
    FocusSetupFinalizePressed event,
    Emitter<FocusSetupState> emit,
  ) async {
    final persisted = state.persistedAllocationConfig;
    if (persisted == null) {
      add(
        const FocusSetupEvent.saveFailed('Allocation settings not loaded yet'),
      );
      return;
    }

    emit(state.copyWith(isSaving: true, errorMessage: null));

    final context = _contextFactory.create(
      feature: 'focus_setup',
      screen: 'focus_setup',
      intent: 'allocation_finalize_requested',
      operation: 'settings.save.allocation',
      entityType: 'settings',
    );

    try {
      final focusMode = state.effectiveFocusMode;

      final base = focusMode == FocusMode.personalized
          ? persisted.strategySettings
          : StrategySettings.forFocusMode(focusMode);
      final strategySettings = base.copyWith(
        enableNeglectWeighting: state.effectiveNeglectEnabled,
      );

      final updatedConfig = persisted.copyWith(
        hasSelectedFocusMode: true,
        focusMode: focusMode,
        suggestionsPerBatch: state.effectiveSuggestionsPerBatch,
        strategySettings: strategySettings,
      );

      await _settingsRepository.save(
        SettingsKey.allocation,
        updatedConfig,
        context: context,
      );

      add(const FocusSetupEvent.saveSucceeded());
    } catch (e, st) {
      talker.error('[FocusSetupBloc] finalize failed', e, st);
      _reportIfUnexpectedOrUnmapped(
        e,
        st,
        context: context,
        message: '[FocusSetupBloc] finalize failed',
      );
      add(FocusSetupEvent.saveFailed(_uiMessageFor(e)));
    }
  }

  void _onSaveFailed(
    FocusSetupSaveFailed event,
    Emitter<FocusSetupState> emit,
  ) {
    emit(state.copyWith(isSaving: false, errorMessage: event.message));
  }

  void _onSaveSucceeded(
    FocusSetupSaveSucceeded event,
    Emitter<FocusSetupState> emit,
  ) {
    emit(state.copyWith(isSaving: false, saveSucceeded: true));
  }
}
