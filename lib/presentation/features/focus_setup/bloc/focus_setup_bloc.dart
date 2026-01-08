import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/attention_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/attention/attention_rule.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_config.dart';
import 'package:taskly_bloc/domain/models/settings/focus_mode.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';

part 'focus_setup_bloc.freezed.dart';

const _minNeglectLookbackDays = 1;
const _maxNeglectLookbackDays = 60;

@freezed
sealed class FocusSetupEvent with _$FocusSetupEvent {
  const factory FocusSetupEvent.started() = FocusSetupStarted;

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

  const factory FocusSetupEvent.reviewRuleEnabledChanged({
    required String ruleId,
    required bool enabled,
  }) = FocusSetupReviewRuleEnabledChanged;

  const factory FocusSetupEvent.reviewRuleFrequencyDaysChanged({
    required String ruleId,
    required int frequencyDays,
  }) = FocusSetupReviewRuleFrequencyDaysChanged;

  const factory FocusSetupEvent.finalizePressed() = FocusSetupFinalizePressed;

  const factory FocusSetupEvent.allocationStreamUpdated(
    AllocationConfig allocationConfig,
  ) = FocusSetupAllocationStreamUpdated;

  const factory FocusSetupEvent.reviewRulesStreamUpdated(
    List<AttentionRule> rules,
  ) = FocusSetupReviewRulesStreamUpdated;

  const factory FocusSetupEvent.lastResolvedUpdated({
    required String ruleId,
    required DateTime? lastResolvedAt,
  }) = FocusSetupLastResolvedUpdated;

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

    /// Baseline persisted config (for merge-on-save).
    AllocationConfig? persistedAllocationConfig,

    /// Draft allocation settings.
    FocusMode? draftFocusMode,
    double? draftUrgencyBoostMultiplier,
    bool? draftNeglectEnabled,
    int? draftNeglectLookbackDays,
    int? draftNeglectInfluencePercent,

    /// Review-session rules only.
    @Default(<AttentionRule>[]) List<AttentionRule> reviewSessionRules,

    /// Draft edits per rule.
    @Default(<String, bool>{}) Map<String, bool> draftRuleEnabled,
    @Default(<String, int>{}) Map<String, int> draftRuleFrequencyDays,

    /// Latest completion timestamp per rule (read-only).
    @Default(<String, DateTime?>{}) Map<String, DateTime?> lastResolvedAt,

    @Default(false) bool saveSucceeded,
  }) = _FocusSetupState;

  const FocusSetupState._();

  bool get canGoBack => stepIndex > 0 && !isSaving;

  bool get canGoNext {
    if (isSaving) return false;
    return stepIndex < maxStepIndex;
  }

  int get maxStepIndex => 3;

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
    if (persisted != null)
      return persisted.strategySettings.urgencyBoostMultiplier;
    return 1.5;
  }

  bool get effectiveNeglectEnabled {
    final draft = draftNeglectEnabled;
    if (draft != null) return draft;
    final persisted = persistedAllocationConfig;
    if (persisted != null)
      return persisted.strategySettings.enableNeglectWeighting;
    return false;
  }

  int get effectiveNeglectLookbackDays {
    final draft = draftNeglectLookbackDays;
    if (draft != null) return draft;
    final persisted = persistedAllocationConfig;
    if (persisted != null)
      return persisted.strategySettings.neglectLookbackDays;
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
}

class FocusSetupBloc extends Bloc<FocusSetupEvent, FocusSetupState> {
  FocusSetupBloc({
    required SettingsRepositoryContract settingsRepository,
    required AttentionRepositoryContract attentionRepository,
  }) : _settingsRepository = settingsRepository,
       _attentionRepository = attentionRepository,
       super(const FocusSetupState()) {
    on<FocusSetupStarted>(_onStarted, transformer: droppable());
    on<FocusSetupAllocationStreamUpdated>(
      _onAllocationStreamUpdated,
      transformer: sequential(),
    );
    on<FocusSetupReviewRulesStreamUpdated>(
      _onReviewRulesStreamUpdated,
      transformer: sequential(),
    );
    on<FocusSetupLastResolvedUpdated>(
      _onLastResolvedUpdated,
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

    on<FocusSetupReviewRuleEnabledChanged>(
      _onReviewRuleEnabledChanged,
      transformer: droppable(),
    );
    on<FocusSetupReviewRuleFrequencyDaysChanged>(
      _onReviewRuleFrequencyDaysChanged,
      transformer: droppable(),
    );

    on<FocusSetupFinalizePressed>(_onFinalizePressed, transformer: droppable());
    on<FocusSetupSaveFailed>(_onSaveFailed, transformer: sequential());
    on<FocusSetupSaveSucceeded>(_onSaveSucceeded, transformer: sequential());
  }

  final SettingsRepositoryContract _settingsRepository;
  final AttentionRepositoryContract _attentionRepository;

  StreamSubscription<AllocationConfig>? _allocationSub;
  StreamSubscription<List<AttentionRule>>? _rulesSub;
  final Map<String, StreamSubscription<dynamic>> _resolutionSubs = {};

  @override
  Future<void> close() async {
    await _allocationSub?.cancel();
    await _rulesSub?.cancel();
    for (final sub in _resolutionSubs.values) {
      await sub.cancel();
    }
    _resolutionSubs.clear();
    return super.close();
  }

  Future<void> _onStarted(
    FocusSetupStarted event,
    Emitter<FocusSetupState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    await _allocationSub?.cancel();
    _allocationSub = _settingsRepository
        .watch(SettingsKey.allocation)
        .listen(
          (cfg) => add(FocusSetupEvent.allocationStreamUpdated(cfg)),
          onError: (Object e, StackTrace st) {
            talker.handle(e, st, '[FocusSetupBloc] allocation stream error');
            add(
              const FocusSetupEvent.saveFailed(
                'Failed to load allocation settings',
              ),
            );
          },
        );

    await _rulesSub?.cancel();
    _rulesSub = _attentionRepository.watchAllRules().listen(
      (rules) => add(FocusSetupEvent.reviewRulesStreamUpdated(rules)),
      onError: (Object e, StackTrace st) {
        talker.handle(e, st, '[FocusSetupBloc] attention rules stream error');
        add(
          const FocusSetupEvent.saveFailed('Failed to load attention rules'),
        );
      },
    );
  }

  void _onAllocationStreamUpdated(
    FocusSetupAllocationStreamUpdated event,
    Emitter<FocusSetupState> emit,
  ) {
    emit(
      state.copyWith(
        persistedAllocationConfig: event.allocationConfig,
        isLoading: false,
      ),
    );
  }

  void _onReviewRulesStreamUpdated(
    FocusSetupReviewRulesStreamUpdated event,
    Emitter<FocusSetupState> emit,
  ) {
    final reviewSessionRules = event.rules
        .where((r) => r.ruleType == AttentionRuleType.review)
        .where((r) => r.entitySelector['entity_type'] == 'review_session')
        .where((r) => r.triggerConfig.containsKey('frequency_days'))
        .toList(growable: false);

    // Ensure draft maps contain entries for known rules.
    final enabledDraft = Map<String, bool>.from(state.draftRuleEnabled);
    final freqDraft = Map<String, int>.from(state.draftRuleFrequencyDays);

    for (final rule in reviewSessionRules) {
      enabledDraft.putIfAbsent(rule.id, () => rule.active);
      final freq = rule.triggerConfig['frequency_days'];
      if (freq is int) {
        freqDraft.putIfAbsent(rule.id, () => freq);
      } else if (freq is num) {
        freqDraft.putIfAbsent(rule.id, freq.round);
      }
    }

    // Subscribe to last-resolution updates for each visible rule.
    _refreshResolutionSubscriptions(reviewSessionRules);

    emit(
      state.copyWith(
        reviewSessionRules: reviewSessionRules,
        draftRuleEnabled: enabledDraft,
        draftRuleFrequencyDays: freqDraft,
        isLoading: false,
      ),
    );
  }

  void _refreshResolutionSubscriptions(List<AttentionRule> rules) {
    final wanted = rules.map((r) => r.id).toSet();

    // Cancel any no-longer-needed subscriptions.
    final toRemove = _resolutionSubs.keys
        .where((id) => !wanted.contains(id))
        .toList();
    for (final id in toRemove) {
      unawaited(_resolutionSubs.remove(id)?.cancel());
    }

    // Add missing subscriptions.
    for (final rule in rules) {
      if (_resolutionSubs.containsKey(rule.id)) continue;

      final sub = _attentionRepository
          .watchResolutionsForRule(rule.id)
          .listen(
            (resolutions) {
              final last = resolutions.isNotEmpty
                  ? resolutions.first.resolvedAt
                  : null;
              add(
                FocusSetupEvent.lastResolvedUpdated(
                  ruleId: rule.id,
                  lastResolvedAt: last,
                ),
              );
            },
            onError: (Object e, StackTrace st) {
              talker.handle(e, st, '[FocusSetupBloc] resolution stream error');
            },
          );

      _resolutionSubs[rule.id] = sub;
    }
  }

  void _onLastResolvedUpdated(
    FocusSetupLastResolvedUpdated event,
    Emitter<FocusSetupState> emit,
  ) {
    final updated = Map<String, DateTime?>.from(state.lastResolvedAt);
    updated[event.ruleId] = event.lastResolvedAt;
    emit(state.copyWith(lastResolvedAt: updated));
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
    emit(state.copyWith(draftFocusMode: event.focusMode));
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

  void _onReviewRuleEnabledChanged(
    FocusSetupReviewRuleEnabledChanged event,
    Emitter<FocusSetupState> emit,
  ) {
    final updated = Map<String, bool>.from(state.draftRuleEnabled);
    updated[event.ruleId] = event.enabled;
    emit(state.copyWith(draftRuleEnabled: updated));
  }

  void _onReviewRuleFrequencyDaysChanged(
    FocusSetupReviewRuleFrequencyDaysChanged event,
    Emitter<FocusSetupState> emit,
  ) {
    final updated = Map<String, int>.from(state.draftRuleFrequencyDays);
    updated[event.ruleId] = event.frequencyDays;
    emit(state.copyWith(draftRuleFrequencyDays: updated));
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

    try {
      final updatedConfig = persisted.copyWith(
        focusMode: state.effectiveFocusMode,
        strategySettings: persisted.strategySettings.copyWith(
          urgencyBoostMultiplier: state.effectiveUrgencyBoostMultiplier,
          enableNeglectWeighting: state.effectiveNeglectEnabled,
          neglectLookbackDays: state.effectiveNeglectLookbackDays,
          neglectInfluence: state.effectiveNeglectInfluencePercent / 100.0,
        ),
      );

      await _settingsRepository.save(SettingsKey.allocation, updatedConfig);

      for (final rule in state.reviewSessionRules) {
        final enabled = state.draftRuleEnabled[rule.id] ?? rule.active;
        final freqDays =
            state.draftRuleFrequencyDays[rule.id] ??
            (rule.triggerConfig['frequency_days'] as int? ?? 30);

        if (enabled != rule.active) {
          await _attentionRepository.updateRuleActive(rule.id, enabled);
        }

        final triggerConfig = Map<String, dynamic>.from(rule.triggerConfig);
        triggerConfig['frequency_days'] = freqDays;
        await _attentionRepository.updateRuleTriggerConfig(
          rule.id,
          triggerConfig,
        );
      }

      add(const FocusSetupEvent.saveSucceeded());
    } catch (e, st) {
      talker.handle(e, st, '[FocusSetupBloc] finalize failed');
      add(FocusSetupEvent.saveFailed('Failed to save: $e'));
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
