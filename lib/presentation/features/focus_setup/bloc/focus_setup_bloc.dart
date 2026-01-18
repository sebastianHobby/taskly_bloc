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

const _minNeglectLookbackDays = 1;
const _maxNeglectLookbackDays = 60;

enum FocusSetupWizardStep {
  selectFocusMode,
  allocationStrategy,
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

  const factory FocusSetupEvent.urgencyBoostChanged(double value) =
      FocusSetupUrgencyBoostChanged;

  const factory FocusSetupEvent.neglectEnabledChanged(bool enabled) =
      FocusSetupNeglectEnabledChanged;

  const factory FocusSetupEvent.neglectLookbackDaysChanged(int days) =
      FocusSetupNeglectLookbackDaysChanged;

  /// UI uses 0-100%; persisted as 0.0-1.0.
  const factory FocusSetupEvent.neglectInfluencePercentChanged(int percent) =
      FocusSetupNeglectInfluencePercentChanged;

  /// UI uses 0-100%; persisted as 0.0-2.0 via (percent / 50).
  const factory FocusSetupEvent.valuePriorityWeightPercentChanged(int percent) =
      FocusSetupValuePriorityWeightPercentChanged;

  /// UI uses multiplier (0.5-5.0).
  const factory FocusSetupEvent.taskFlagBoostChanged(double multiplier) =
      FocusSetupTaskFlagBoostChanged;

  /// UI uses 0-50%; persisted as 0.0-0.5.
  const factory FocusSetupEvent.recencyPenaltyPercentChanged(int percent) =
      FocusSetupRecencyPenaltyPercentChanged;

  /// UI uses multiplier (1.0-5.0).
  const factory FocusSetupEvent.overdueEmergencyMultiplierChanged(
    double multiplier,
  ) = FocusSetupOverdueEmergencyMultiplierChanged;

  const factory FocusSetupEvent.allocationResetToDefaultPressed() =
      FocusSetupAllocationResetToDefaultPressed;

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
    double? draftUrgencyBoostMultiplier,
    bool? draftNeglectEnabled,
    int? draftNeglectLookbackDays,
    int? draftNeglectInfluencePercent,

    int? draftValuePriorityWeightPercent,
    double? draftTaskFlagBoost,
    int? draftRecencyPenaltyPercent,
    double? draftOverdueEmergencyMultiplier,

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
    final focusMode = effectiveFocusMode;

    final hasSelectedFocusMode =
        persistedAllocationConfig?.hasSelectedFocusMode ?? false;
    final hasValues = valuesCount > 0;

    // When prerequisites are missing (gate flow), show only the missing steps.
    final prereqsMissing = !hasSelectedFocusMode || !hasValues;
    if (prereqsMissing) {
      final steps = <FocusSetupWizardStep>[];
      if (!hasSelectedFocusMode) {
        steps.add(FocusSetupWizardStep.selectFocusMode);
        if (focusMode == FocusMode.personalized) {
          steps.add(FocusSetupWizardStep.allocationStrategy);
        }
      }
      if (!hasValues) {
        steps.add(FocusSetupWizardStep.valuesCta);
      }
      steps.add(FocusSetupWizardStep.finalize);
      return steps;
    }

    // Full wizard (settings route): include values step as part of setup.
    if (focusMode == FocusMode.personalized) {
      return const [
        FocusSetupWizardStep.selectFocusMode,
        FocusSetupWizardStep.allocationStrategy,
        FocusSetupWizardStep.valuesCta,
        FocusSetupWizardStep.finalize,
      ];
    }

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

  double get effectiveUrgencyBoostMultiplier {
    final draft = draftUrgencyBoostMultiplier;
    if (draft != null) return draft;
    final persisted = persistedAllocationConfig;
    if (persisted != null) {
      return persisted.strategySettings.urgencyBoostMultiplier;
    }
    return 1.5;
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

  int get effectiveNeglectLookbackDays {
    final draft = draftNeglectLookbackDays;
    if (draft != null) return draft;
    final persisted = persistedAllocationConfig;
    if (persisted != null) {
      return persisted.strategySettings.neglectLookbackDays;
    }
    return 7;
  }

  int get effectiveNeglectInfluencePercent {
    final draft = draftNeglectInfluencePercent;
    if (draft != null) return draft;
    final persisted = persistedAllocationConfig;
    if (persisted != null) {
      final p = (persisted.strategySettings.neglectInfluence * 100).round();
      return p.clamp(0, 100);
    }
    return 50;
  }

  int get effectiveValuePriorityWeightPercent {
    final draft = draftValuePriorityWeightPercent;
    if (draft != null) return draft.clamp(0, 100);
    final persisted = persistedAllocationConfig;
    if (persisted != null) {
      return (persisted.strategySettings.valuePriorityWeight * 50)
          .round()
          .clamp(0, 100);
    }
    return 75;
  }

  double get effectiveTaskFlagBoost {
    final draft = draftTaskFlagBoost;
    if (draft != null) return draft;
    final persisted = persistedAllocationConfig;
    if (persisted != null) {
      return persisted.strategySettings.taskPriorityBoost;
    }
    return 1;
  }

  int get effectiveRecencyPenaltyPercent {
    final draft = draftRecencyPenaltyPercent;
    if (draft != null) return draft.clamp(0, 50);
    final persisted = persistedAllocationConfig;
    if (persisted != null) {
      return (persisted.strategySettings.recencyPenalty * 100).round().clamp(
        0,
        50,
      );
    }
    return 10;
  }

  double get effectiveOverdueEmergencyMultiplier {
    final draft = draftOverdueEmergencyMultiplier;
    if (draft != null) return draft;
    final persisted = persistedAllocationConfig;
    if (persisted != null) {
      return persisted.strategySettings.overdueEmergencyMultiplier;
    }
    return 1.5;
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
    on<FocusSetupUrgencyBoostChanged>(
      _onUrgencyBoostChanged,
      transformer: droppable(),
    );
    on<FocusSetupNeglectEnabledChanged>(
      _onNeglectEnabledChanged,
      transformer: droppable(),
    );
    on<FocusSetupNeglectLookbackDaysChanged>(
      _onNeglectLookbackDaysChanged,
      transformer: droppable(),
    );
    on<FocusSetupNeglectInfluencePercentChanged>(
      _onNeglectInfluencePercentChanged,
      transformer: droppable(),
    );

    on<FocusSetupValuePriorityWeightPercentChanged>(
      _onValuePriorityWeightPercentChanged,
      transformer: droppable(),
    );
    on<FocusSetupTaskFlagBoostChanged>(
      _onTaskFlagBoostChanged,
      transformer: droppable(),
    );
    on<FocusSetupRecencyPenaltyPercentChanged>(
      _onRecencyPenaltyPercentChanged,
      transformer: droppable(),
    );
    on<FocusSetupOverdueEmergencyMultiplierChanged>(
      _onOverdueEmergencyMultiplierChanged,
      transformer: droppable(),
    );

    on<FocusSetupAllocationResetToDefaultPressed>(
      _onAllocationResetToDefaultPressed,
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
        color: _colorHexForName(name),
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

    // Non-personalized modes always use their default weightings.
    // Personalized keeps the user's existing settings until they adjust.
    if (nextFocusMode == FocusMode.personalized) {
      emit(
        state.copyWith(
          draftFocusMode: nextFocusMode,
          stepIndex: clampedStepIndex,
          draftUrgencyBoostMultiplier: null,
          draftNeglectEnabled: null,
          draftNeglectLookbackDays: null,
          draftNeglectInfluencePercent: null,
          draftValuePriorityWeightPercent: null,
          draftTaskFlagBoost: null,
          draftRecencyPenaltyPercent: null,
          draftOverdueEmergencyMultiplier: null,
          errorMessage: null,
        ),
      );
      return;
    }

    final preset = StrategySettings.forFocusMode(nextFocusMode);

    emit(
      state.copyWith(
        draftFocusMode: nextFocusMode,
        stepIndex: clampedStepIndex,
        draftUrgencyBoostMultiplier: preset.urgencyBoostMultiplier,
        draftNeglectEnabled: preset.enableNeglectWeighting,
        draftNeglectLookbackDays: preset.neglectLookbackDays,
        draftNeglectInfluencePercent: (preset.neglectInfluence * 100)
            .round()
            .clamp(0, 100),
        draftValuePriorityWeightPercent: (preset.valuePriorityWeight * 50)
            .round()
            .clamp(0, 100),
        draftTaskFlagBoost: preset.taskPriorityBoost,
        draftRecencyPenaltyPercent: (preset.recencyPenalty * 100).round().clamp(
          0,
          50,
        ),
        draftOverdueEmergencyMultiplier: preset.overdueEmergencyMultiplier,
        errorMessage: null,
      ),
    );
  }

  void _onUrgencyBoostChanged(
    FocusSetupUrgencyBoostChanged event,
    Emitter<FocusSetupState> emit,
  ) {
    emit(state.copyWith(draftUrgencyBoostMultiplier: event.value));
  }

  void _onNeglectEnabledChanged(
    FocusSetupNeglectEnabledChanged event,
    Emitter<FocusSetupState> emit,
  ) {
    emit(state.copyWith(draftNeglectEnabled: event.enabled));
  }

  void _onNeglectLookbackDaysChanged(
    FocusSetupNeglectLookbackDaysChanged event,
    Emitter<FocusSetupState> emit,
  ) {
    emit(
      state.copyWith(
        draftNeglectLookbackDays: event.days.clamp(
          _minNeglectLookbackDays,
          _maxNeglectLookbackDays,
        ),
      ),
    );
  }

  void _onNeglectInfluencePercentChanged(
    FocusSetupNeglectInfluencePercentChanged event,
    Emitter<FocusSetupState> emit,
  ) {
    emit(
      state.copyWith(draftNeglectInfluencePercent: event.percent.clamp(0, 100)),
    );
  }

  void _onValuePriorityWeightPercentChanged(
    FocusSetupValuePriorityWeightPercentChanged event,
    Emitter<FocusSetupState> emit,
  ) {
    emit(
      state.copyWith(
        draftValuePriorityWeightPercent: event.percent.clamp(0, 100),
      ),
    );
  }

  void _onTaskFlagBoostChanged(
    FocusSetupTaskFlagBoostChanged event,
    Emitter<FocusSetupState> emit,
  ) {
    emit(state.copyWith(draftTaskFlagBoost: event.multiplier.clamp(0.5, 5.0)));
  }

  void _onRecencyPenaltyPercentChanged(
    FocusSetupRecencyPenaltyPercentChanged event,
    Emitter<FocusSetupState> emit,
  ) {
    emit(
      state.copyWith(draftRecencyPenaltyPercent: event.percent.clamp(0, 50)),
    );
  }

  void _onOverdueEmergencyMultiplierChanged(
    FocusSetupOverdueEmergencyMultiplierChanged event,
    Emitter<FocusSetupState> emit,
  ) {
    emit(
      state.copyWith(
        draftOverdueEmergencyMultiplier: event.multiplier.clamp(1.0, 5.0),
      ),
    );
  }

  void _onAllocationResetToDefaultPressed(
    FocusSetupAllocationResetToDefaultPressed event,
    Emitter<FocusSetupState> emit,
  ) {
    final preset = StrategySettings.forFocusMode(state.effectiveFocusMode);

    emit(
      state.copyWith(
        draftUrgencyBoostMultiplier: preset.urgencyBoostMultiplier,
        draftNeglectEnabled: preset.enableNeglectWeighting,
        draftNeglectLookbackDays: preset.neglectLookbackDays,
        draftNeglectInfluencePercent: (preset.neglectInfluence * 100)
            .round()
            .clamp(0, 100),
        draftValuePriorityWeightPercent: (preset.valuePriorityWeight * 50)
            .round()
            .clamp(0, 100),
        draftTaskFlagBoost: preset.taskPriorityBoost,
        draftRecencyPenaltyPercent: (preset.recencyPenalty * 100).round().clamp(
          0,
          50,
        ),
        draftOverdueEmergencyMultiplier: preset.overdueEmergencyMultiplier,
      ),
    );
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

      final strategySettings = focusMode == FocusMode.personalized
          ? persisted.strategySettings.copyWith(
              urgencyBoostMultiplier: state.effectiveUrgencyBoostMultiplier,
              enableNeglectWeighting: state.effectiveNeglectEnabled,
              neglectLookbackDays: state.effectiveNeglectLookbackDays,
              neglectInfluence: state.effectiveNeglectInfluencePercent / 100.0,
              valuePriorityWeight:
                  state.effectiveValuePriorityWeightPercent / 50.0,
              taskPriorityBoost: state.effectiveTaskFlagBoost,
              recencyPenalty: state.effectiveRecencyPenaltyPercent / 100.0,
              overdueEmergencyMultiplier:
                  state.effectiveOverdueEmergencyMultiplier,
            )
          : StrategySettings.forFocusMode(focusMode);

      final updatedConfig = persisted.copyWith(
        hasSelectedFocusMode: true,
        focusMode: focusMode,
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
