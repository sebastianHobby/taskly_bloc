import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/theme/app_theme_mode.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/errors.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_domain/telemetry.dart';

part 'global_settings_bloc.freezed.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

@freezed
sealed class GlobalSettingsEvent with _$GlobalSettingsEvent {
  /// Start watching the global settings stream.
  const factory GlobalSettingsEvent.started() = GlobalSettingsStarted;

  /// User changed the theme mode.
  const factory GlobalSettingsEvent.themeModeChanged(AppThemeMode themeMode) =
      GlobalSettingsThemeModeChanged;

  /// User changed the color scheme seed.
  const factory GlobalSettingsEvent.colorChanged(int colorArgb) =
      GlobalSettingsColorChanged;

  /// User changed the locale.
  const factory GlobalSettingsEvent.localeChanged(String? localeCode) =
      GlobalSettingsLocaleChanged;

  /// User changed the fixed home timezone offset.
  const factory GlobalSettingsEvent.homeTimeZoneOffsetChanged(
    int offsetMinutes,
  ) = GlobalSettingsHomeTimeZoneOffsetChanged;

  /// User changed the text scale factor.
  const factory GlobalSettingsEvent.textScaleChanged(double textScaleFactor) =
      GlobalSettingsTextScaleChanged;

  /// User changed the My Day due-window days.
  const factory GlobalSettingsEvent.myDayDueWindowDaysChanged(int days) =
      GlobalSettingsMyDayDueWindowDaysChanged;

  /// User toggled whether My Day should show due-soon picks.
  const factory GlobalSettingsEvent.myDayDueSoonEnabledChanged(
    bool enabled,
  ) = GlobalSettingsMyDayDueSoonEnabledChanged;

  /// User toggled whether to show the "Available to start" lane.
  const factory GlobalSettingsEvent.myDayShowAvailableToStartChanged(
    bool enabled,
  ) = GlobalSettingsMyDayShowAvailableToStartChanged;

  /// User toggled whether to show the routines step.
  const factory GlobalSettingsEvent.myDayShowRoutinesChanged(
    bool enabled,
  ) = GlobalSettingsMyDayShowRoutinesChanged;

  /// User toggled whether triage picks count against value quotas.
  const factory GlobalSettingsEvent.myDayCountTriagePicksAgainstValueQuotasChanged(
    bool enabled,
  ) = GlobalSettingsMyDayCountTriagePicksAgainstValueQuotasChanged;

  /// User toggled whether routine picks count against value quotas.
  const factory GlobalSettingsEvent.myDayCountRoutinePicksAgainstValueQuotasChanged(
    bool enabled,
  ) = GlobalSettingsMyDayCountRoutinePicksAgainstValueQuotasChanged;

  /// User toggled weekly review scheduling.
  const factory GlobalSettingsEvent.weeklyReviewEnabledChanged(bool enabled) =
      GlobalSettingsWeeklyReviewEnabledChanged;

  /// User changed weekly review day of week.
  const factory GlobalSettingsEvent.weeklyReviewDayOfWeekChanged(
    int dayOfWeek,
  ) = GlobalSettingsWeeklyReviewDayOfWeekChanged;

  /// User changed weekly review time.
  const factory GlobalSettingsEvent.weeklyReviewTimeMinutesChanged(
    int minutes,
  ) = GlobalSettingsWeeklyReviewTimeMinutesChanged;

  /// User changed weekly review cadence.
  const factory GlobalSettingsEvent.weeklyReviewCadenceWeeksChanged(
    int cadenceWeeks,
  ) = GlobalSettingsWeeklyReviewCadenceWeeksChanged;

  /// User toggled values summary in weekly review.
  const factory GlobalSettingsEvent.valuesSummaryEnabledChanged(bool enabled) =
      GlobalSettingsValuesSummaryEnabledChanged;

  /// User changed values summary lookback window.
  const factory GlobalSettingsEvent.valuesSummaryWindowWeeksChanged(
    int weeks,
  ) = GlobalSettingsValuesSummaryWindowWeeksChanged;

  /// User changed values summary wins count.
  const factory GlobalSettingsEvent.valuesSummaryWinsCountChanged(
    int count,
  ) = GlobalSettingsValuesSummaryWinsCountChanged;

  /// User toggled weekly review maintenance.
  const factory GlobalSettingsEvent.maintenanceEnabledChanged(bool enabled) =
      GlobalSettingsMaintenanceEnabledChanged;

  /// User toggled deadline risk maintenance.
  const factory GlobalSettingsEvent.maintenanceDeadlineRiskChanged(
    bool enabled,
  ) = GlobalSettingsMaintenanceDeadlineRiskChanged;

  /// User toggled due soon maintenance.
  const factory GlobalSettingsEvent.maintenanceDueSoonChanged(bool enabled) =
      GlobalSettingsMaintenanceDueSoonChanged;

  /// User toggled stale items maintenance.
  const factory GlobalSettingsEvent.maintenanceStaleChanged(bool enabled) =
      GlobalSettingsMaintenanceStaleChanged;

  /// User toggled frequent snoozed maintenance.
  const factory GlobalSettingsEvent.maintenanceFrequentSnoozedChanged(
    bool enabled,
  ) = GlobalSettingsMaintenanceFrequentSnoozedChanged;

  /// User toggled missing next actions maintenance.
  const factory GlobalSettingsEvent.maintenanceMissingNextActionsChanged(
    bool enabled,
  ) = GlobalSettingsMaintenanceMissingNextActionsChanged;

  /// User completed weekly review.
  const factory GlobalSettingsEvent.weeklyReviewCompleted(
    DateTime completedAt,
  ) = GlobalSettingsWeeklyReviewCompleted;

  /// User completed onboarding.
  const factory GlobalSettingsEvent.onboardingCompleted() =
      GlobalSettingsOnboardingCompleted;

  /// Internal: Stream emitted new settings.
  const factory GlobalSettingsEvent.streamUpdated(GlobalSettings settings) =
      GlobalSettingsStreamUpdated;
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

@freezed
sealed class GlobalSettingsState with _$GlobalSettingsState {
  const factory GlobalSettingsState({
    @Default(GlobalSettings()) GlobalSettings settings,
    @Default(true) bool isLoading,
  }) = _GlobalSettingsState;
  const GlobalSettingsState._();

  /// Convenience getter for Flutter's ThemeMode.
  ThemeMode get flutterThemeMode => switch (settings.themeMode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };

  /// Convenience getter for seed color.
  Color get seedColor => Color(settings.colorSchemeSeedArgb);
}

// ---------------------------------------------------------------------------
// Bloc
// ---------------------------------------------------------------------------

/// BLoC for managing global app settings.
///
/// Applies settings changes via the repository and relies on the repository
/// stream as the single source of truth for the UI.
///
/// ## Usage
///
/// Provide at app root (before authentication):
/// ```dart
/// BlocProvider<GlobalSettingsBloc>(
///   lazy: false,
///   create: (_) => GlobalSettingsBloc(
///     settingsRepository: getIt<SettingsRepositoryContract>(),
///   )..add(const GlobalSettingsEvent.started()),
/// )
/// ```
///
/// Consume in widgets:
/// ```dart
/// BlocBuilder<GlobalSettingsBloc, GlobalSettingsState>(
///   builder: (context, state) {
///     return MaterialApp(
///       themeMode: state.flutterThemeMode,
///       // ...
///     );
///   },
/// )
/// ```
class GlobalSettingsBloc
    extends Bloc<GlobalSettingsEvent, GlobalSettingsState> {
  GlobalSettingsBloc({
    required SettingsRepositoryContract settingsRepository,
    required NowService nowService,
    required AppErrorReporter errorReporter,
  }) : _settingsRepository = settingsRepository,
       _nowService = nowService,
       _errorReporter = errorReporter,
       super(const GlobalSettingsState()) {
    on<GlobalSettingsStarted>(_onStarted, transformer: droppable());
    on<GlobalSettingsThemeModeChanged>(
      _onThemeModeChanged,
      transformer: sequential(),
    );
    on<GlobalSettingsColorChanged>(_onColorChanged, transformer: sequential());
    on<GlobalSettingsLocaleChanged>(
      _onLocaleChanged,
      transformer: sequential(),
    );
    on<GlobalSettingsHomeTimeZoneOffsetChanged>(
      _onHomeTimeZoneOffsetChanged,
      transformer: sequential(),
    );
    on<GlobalSettingsTextScaleChanged>(
      _onTextScaleChanged,
      transformer: sequential(),
    );
    on<GlobalSettingsMyDayDueWindowDaysChanged>(
      _onMyDayDueWindowDaysChanged,
      transformer: sequential(),
    );
    on<GlobalSettingsMyDayDueSoonEnabledChanged>(
      _onMyDayDueSoonEnabledChanged,
      transformer: sequential(),
    );
    on<GlobalSettingsMyDayShowAvailableToStartChanged>(
      _onMyDayShowAvailableToStartChanged,
      transformer: sequential(),
    );
    on<GlobalSettingsMyDayShowRoutinesChanged>(
      _onMyDayShowRoutinesChanged,
      transformer: sequential(),
    );
    on<GlobalSettingsMyDayCountTriagePicksAgainstValueQuotasChanged>(
      _onMyDayCountTriagePicksAgainstValueQuotasChanged,
      transformer: sequential(),
    );
    on<GlobalSettingsMyDayCountRoutinePicksAgainstValueQuotasChanged>(
      _onMyDayCountRoutinePicksAgainstValueQuotasChanged,
      transformer: sequential(),
    );
    on<GlobalSettingsWeeklyReviewEnabledChanged>(
      _onWeeklyReviewEnabledChanged,
      transformer: sequential(),
    );
    on<GlobalSettingsWeeklyReviewDayOfWeekChanged>(
      _onWeeklyReviewDayOfWeekChanged,
      transformer: sequential(),
    );
    on<GlobalSettingsWeeklyReviewTimeMinutesChanged>(
      _onWeeklyReviewTimeMinutesChanged,
      transformer: sequential(),
    );
    on<GlobalSettingsWeeklyReviewCadenceWeeksChanged>(
      _onWeeklyReviewCadenceWeeksChanged,
      transformer: sequential(),
    );
    on<GlobalSettingsValuesSummaryEnabledChanged>(
      _onValuesSummaryEnabledChanged,
      transformer: sequential(),
    );
    on<GlobalSettingsValuesSummaryWindowWeeksChanged>(
      _onValuesSummaryWindowWeeksChanged,
      transformer: sequential(),
    );
    on<GlobalSettingsValuesSummaryWinsCountChanged>(
      _onValuesSummaryWinsCountChanged,
      transformer: sequential(),
    );
    on<GlobalSettingsMaintenanceEnabledChanged>(
      _onMaintenanceEnabledChanged,
      transformer: sequential(),
    );
    on<GlobalSettingsMaintenanceDeadlineRiskChanged>(
      _onMaintenanceDeadlineRiskChanged,
      transformer: sequential(),
    );
    on<GlobalSettingsMaintenanceDueSoonChanged>(
      _onMaintenanceDueSoonChanged,
      transformer: sequential(),
    );
    on<GlobalSettingsMaintenanceStaleChanged>(
      _onMaintenanceStaleChanged,
      transformer: sequential(),
    );
    on<GlobalSettingsMaintenanceFrequentSnoozedChanged>(
      _onMaintenanceFrequentSnoozedChanged,
      transformer: sequential(),
    );
    on<GlobalSettingsMaintenanceMissingNextActionsChanged>(
      _onMaintenanceMissingNextActionsChanged,
      transformer: sequential(),
    );
    on<GlobalSettingsWeeklyReviewCompleted>(
      _onWeeklyReviewCompleted,
      transformer: sequential(),
    );
    on<GlobalSettingsOnboardingCompleted>(
      _onOnboardingCompleted,
      transformer: droppable(),
    );
    on<GlobalSettingsStreamUpdated>(
      _onStreamUpdated,
      transformer: sequential(),
    );
  }

  final SettingsRepositoryContract _settingsRepository;
  final NowService _nowService;
  final AppErrorReporter _errorReporter;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();
  StreamSubscription<GlobalSettings>? _subscription;

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

  OperationContext _newContext({
    required String intent,
    required String operation,
    Map<String, Object?> extraFields = const <String, Object?>{},
  }) {
    return _contextFactory.create(
      feature: 'settings',
      screen: 'global_settings',
      intent: intent,
      operation: operation,
      entityType: 'settings',
      extraFields: extraFields,
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  Future<void> _onStarted(
    GlobalSettingsStarted event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = _settingsRepository
        .watch(SettingsKey.global)
        .listen(
          (settings) => add(GlobalSettingsEvent.streamUpdated(settings)),
          onError: (Object error, StackTrace stack) {
            talker.handle(error, stack, '[GlobalSettingsBloc] Stream error');

            final context = _newContext(
              intent: 'settings_global_stream_error',
              operation: 'settings.watch.global',
            );
            _reportIfUnexpectedOrUnmapped(
              error,
              stack,
              context: context,
              message: '[GlobalSettingsBloc] settings stream error',
            );
          },
        );
  }

  void _onStreamUpdated(
    GlobalSettingsStreamUpdated event,
    Emitter<GlobalSettingsState> emit,
  ) {
    final isDifferent = event.settings != state.settings;
    final wasLoading = state.isLoading;

    // Persist high-signal settings changes to the debug file log so we can
    // correlate UI changes with repository stream emissions.
    final themeModeChanged =
        event.settings.themeMode != state.settings.themeMode;

    if (themeModeChanged && !wasLoading) {
      talker.warning(
        '[settings.global] Stream overwrote themeMode\n'
        '  current=${state.settings.themeMode}\n'
        '  incoming=${event.settings.themeMode}',
      );
    } else {
      talker.debug(
        '[BLOC STREAM] _onStreamUpdated\n'
        '  incoming.themeMode=${event.settings.themeMode}\n'
        '  current.themeMode=${state.settings.themeMode}\n'
        '  incoming.colorSchemeSeedArgb=${event.settings.colorSchemeSeedArgb}\n'
        '  current.colorSchemeSeedArgb=${state.settings.colorSchemeSeedArgb}\n'
        '  isDifferent=$isDifferent, wasLoading=$wasLoading',
      );
    }

    if (isDifferent || wasLoading) {
      talker.debug(
        '[BLOC STREAM] EMITTING state update\n'
        '  themeMode: ${state.settings.themeMode} → ${event.settings.themeMode}',
      );
      emit(state.copyWith(settings: event.settings, isLoading: false));
    }
  }

  Future<void> _onThemeModeChanged(
    GlobalSettingsThemeModeChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(themeMode: event.themeMode);
    final startedAtUtc = _nowService.nowUtc();
    talker.warning(
      '[settings.global] ThemeMode change requested\n'
      '  at=$startedAtUtc\n'
      '  old=${state.settings.themeMode}\n'
      '  new=${event.themeMode}',
    );
    final context = _newContext(
      intent: 'settings_theme_mode_changed',
      operation: 'settings.save.global',
      extraFields: <String, Object?>{
        'themeMode': event.themeMode.name,
      },
    );

    try {
      await _settingsRepository.save(
        SettingsKey.global,
        updated,
        context: context,
      );
      talker.warning(
        '[settings.global] ThemeMode persisted\n'
        '  at=${_nowService.nowUtc()}\n'
        '  value=${event.themeMode}',
      );
    } catch (e, st) {
      talker.error(
        '[settings.global] ThemeMode persist FAILED',
        e,
        st,
      );
      _reportIfUnexpectedOrUnmapped(
        e,
        st,
        context: context,
        message: '[GlobalSettingsBloc] ThemeMode persist failed',
      );
    }
  }

  Future<void> _onColorChanged(
    GlobalSettingsColorChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(
      colorSchemeSeedArgb: event.colorArgb,
    );
    talker.debug(
      '[BLOC SAVE] _onColorChanged\n'
      '  old color: ${state.settings.colorSchemeSeedArgb}\n'
      '  new color: ${event.colorArgb}',
    );
    final context = _newContext(
      intent: 'settings_color_changed',
      operation: 'settings.save.global',
      extraFields: <String, Object?>{'colorArgb': event.colorArgb},
    );
    try {
      await _settingsRepository.save(
        SettingsKey.global,
        updated,
        context: context,
      );
    } catch (e, st) {
      talker.error('[settings.global] Color persist FAILED', e, st);
      _reportIfUnexpectedOrUnmapped(
        e,
        st,
        context: context,
        message: '[GlobalSettingsBloc] color persist failed',
      );
    }
  }

  Future<void> _onLocaleChanged(
    GlobalSettingsLocaleChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(localeCode: event.localeCode);
    final context = _newContext(
      intent: 'settings_locale_changed',
      operation: 'settings.save.global',
      extraFields: <String, Object?>{'localeCode': event.localeCode},
    );
    try {
      await _settingsRepository.save(
        SettingsKey.global,
        updated,
        context: context,
      );
    } catch (e, st) {
      talker.error('[settings.global] Locale persist FAILED', e, st);
      _reportIfUnexpectedOrUnmapped(
        e,
        st,
        context: context,
        message: '[GlobalSettingsBloc] locale persist failed',
      );
    }
  }

  Future<void> _onHomeTimeZoneOffsetChanged(
    GlobalSettingsHomeTimeZoneOffsetChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(
      homeTimeZoneOffsetMinutes: event.offsetMinutes,
    );
    final context = _newContext(
      intent: 'settings_home_tz_offset_changed',
      operation: 'settings.save.global',
      extraFields: <String, Object?>{'offsetMinutes': event.offsetMinutes},
    );
    try {
      await _settingsRepository.save(
        SettingsKey.global,
        updated,
        context: context,
      );
    } catch (e, st) {
      talker.error('[settings.global] Home TZ persist FAILED', e, st);
      _reportIfUnexpectedOrUnmapped(
        e,
        st,
        context: context,
        message: '[GlobalSettingsBloc] home tz persist failed',
      );
    }
  }

  Future<void> _onTextScaleChanged(
    GlobalSettingsTextScaleChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(
      textScaleFactor: event.textScaleFactor,
    );
    final context = _newContext(
      intent: 'settings_text_scale_changed',
      operation: 'settings.save.global',
      extraFields: <String, Object?>{'textScaleFactor': event.textScaleFactor},
    );
    try {
      await _settingsRepository.save(
        SettingsKey.global,
        updated,
        context: context,
      );
    } catch (e, st) {
      talker.error('[settings.global] Text scale persist FAILED', e, st);
      _reportIfUnexpectedOrUnmapped(
        e,
        st,
        context: context,
        message: '[GlobalSettingsBloc] text scale persist failed',
      );
    }
  }

  Future<void> _onOnboardingCompleted(
    GlobalSettingsOnboardingCompleted event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(onboardingCompleted: true);
    final context = _newContext(
      intent: 'settings_onboarding_completed',
      operation: 'settings.save.global',
    );
    try {
      await _settingsRepository.save(
        SettingsKey.global,
        updated,
        context: context,
      );
    } catch (e, st) {
      talker.error('[settings.global] Onboarding persist FAILED', e, st);
      _reportIfUnexpectedOrUnmapped(
        e,
        st,
        context: context,
        message: '[GlobalSettingsBloc] onboarding persist failed',
      );
    }
  }

  Future<void> _onMyDayDueWindowDaysChanged(
    GlobalSettingsMyDayDueWindowDaysChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final clampedDays = event.days.clamp(1, 30);
    final updated = state.settings.copyWith(myDayDueWindowDays: clampedDays);
    final context = _newContext(
      intent: 'settings_my_day_due_window_days_changed',
      operation: 'settings.save.global',
      extraFields: <String, Object?>{'days': clampedDays},
    );
    try {
      await _settingsRepository.save(
        SettingsKey.global,
        updated,
        context: context,
      );
    } catch (e, st) {
      talker.error('[settings.global] My Day due window persist FAILED', e, st);
      _reportIfUnexpectedOrUnmapped(
        e,
        st,
        context: context,
        message: '[GlobalSettingsBloc] my day due window persist failed',
      );
    }
  }

  Future<void> _onMyDayDueSoonEnabledChanged(
    GlobalSettingsMyDayDueSoonEnabledChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(
      myDayDueSoonEnabled: event.enabled,
    );
    await _persistSettings(
      updated,
      intent: 'settings_my_day_due_soon_enabled_changed',
      extraFields: <String, Object?>{'enabled': event.enabled},
    );
  }

  Future<void> _onMyDayShowAvailableToStartChanged(
    GlobalSettingsMyDayShowAvailableToStartChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(
      myDayShowAvailableToStart: event.enabled,
    );
    final context = _newContext(
      intent: 'settings_my_day_show_available_to_start_changed',
      operation: 'settings.save.global',
      extraFields: <String, Object?>{'enabled': event.enabled},
    );
    try {
      await _settingsRepository.save(
        SettingsKey.global,
        updated,
        context: context,
      );
    } catch (e, st) {
      talker.error(
        '[settings.global] My Day show available-to-start persist FAILED',
        e,
        st,
      );
      _reportIfUnexpectedOrUnmapped(
        e,
        st,
        context: context,
        message:
            '[GlobalSettingsBloc] my day show available-to-start persist failed',
      );
    }
  }

  Future<void> _onMyDayShowRoutinesChanged(
    GlobalSettingsMyDayShowRoutinesChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(myDayShowRoutines: event.enabled);
    await _persistSettings(
      updated,
      intent: 'settings_my_day_show_routines_changed',
      extraFields: <String, Object?>{'enabled': event.enabled},
    );
  }

  Future<void> _onMyDayCountTriagePicksAgainstValueQuotasChanged(
    GlobalSettingsMyDayCountTriagePicksAgainstValueQuotasChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(
      myDayCountTriagePicksAgainstValueQuotas: event.enabled,
    );
    await _persistSettings(
      updated,
      intent: 'settings_my_day_count_triage_picks_against_value_quotas_changed',
      extraFields: <String, Object?>{'enabled': event.enabled},
    );
  }

  Future<void> _onMyDayCountRoutinePicksAgainstValueQuotasChanged(
    GlobalSettingsMyDayCountRoutinePicksAgainstValueQuotasChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(
      myDayCountRoutinePicksAgainstValueQuotas: event.enabled,
    );
    await _persistSettings(
      updated,
      intent:
          'settings_my_day_count_routine_picks_against_value_quotas_changed',
      extraFields: <String, Object?>{'enabled': event.enabled},
    );
  }

  Future<void> _onWeeklyReviewEnabledChanged(
    GlobalSettingsWeeklyReviewEnabledChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(weeklyReviewEnabled: event.enabled);
    await _persistSettings(
      updated,
      intent: 'settings_weekly_review_enabled_changed',
      extraFields: <String, Object?>{'enabled': event.enabled},
    );
  }

  Future<void> _onWeeklyReviewDayOfWeekChanged(
    GlobalSettingsWeeklyReviewDayOfWeekChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final clampedDay = event.dayOfWeek.clamp(1, 7);
    final updated = state.settings.copyWith(weeklyReviewDayOfWeek: clampedDay);
    await _persistSettings(
      updated,
      intent: 'settings_weekly_review_day_changed',
      extraFields: <String, Object?>{'dayOfWeek': clampedDay},
    );
  }

  Future<void> _onWeeklyReviewTimeMinutesChanged(
    GlobalSettingsWeeklyReviewTimeMinutesChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final clamped = event.minutes.clamp(0, 1439);
    final updated = state.settings.copyWith(weeklyReviewTimeMinutes: clamped);
    await _persistSettings(
      updated,
      intent: 'settings_weekly_review_time_changed',
      extraFields: <String, Object?>{'minutes': clamped},
    );
  }

  Future<void> _onWeeklyReviewCadenceWeeksChanged(
    GlobalSettingsWeeklyReviewCadenceWeeksChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final clamped = event.cadenceWeeks.clamp(1, 12);
    final updated = state.settings.copyWith(
      weeklyReviewCadenceWeeks: clamped,
    );
    await _persistSettings(
      updated,
      intent: 'settings_weekly_review_cadence_changed',
      extraFields: <String, Object?>{'weeks': clamped},
    );
  }

  Future<void> _onValuesSummaryEnabledChanged(
    GlobalSettingsValuesSummaryEnabledChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(
      valuesSummaryEnabled: event.enabled,
    );
    await _persistSettings(
      updated,
      intent: 'settings_values_summary_enabled_changed',
      extraFields: <String, Object?>{'enabled': event.enabled},
    );
  }

  Future<void> _onValuesSummaryWindowWeeksChanged(
    GlobalSettingsValuesSummaryWindowWeeksChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final clamped = event.weeks.clamp(1, 12);
    final updated = state.settings.copyWith(valuesSummaryWindowWeeks: clamped);
    await _persistSettings(
      updated,
      intent: 'settings_values_summary_window_changed',
      extraFields: <String, Object?>{'weeks': clamped},
    );
  }

  Future<void> _onValuesSummaryWinsCountChanged(
    GlobalSettingsValuesSummaryWinsCountChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final clamped = event.count.clamp(1, 5);
    final updated = state.settings.copyWith(valuesSummaryWinsCount: clamped);
    await _persistSettings(
      updated,
      intent: 'settings_values_summary_wins_changed',
      extraFields: <String, Object?>{'count': clamped},
    );
  }

  Future<void> _onMaintenanceEnabledChanged(
    GlobalSettingsMaintenanceEnabledChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(maintenanceEnabled: event.enabled);
    await _persistSettings(
      updated,
      intent: 'settings_maintenance_enabled_changed',
      extraFields: <String, Object?>{'enabled': event.enabled},
    );
  }

  Future<void> _onMaintenanceDeadlineRiskChanged(
    GlobalSettingsMaintenanceDeadlineRiskChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(
      maintenanceDeadlineRiskEnabled: event.enabled,
    );
    await _persistSettings(
      updated,
      intent: 'settings_maintenance_deadline_risk_changed',
      extraFields: <String, Object?>{'enabled': event.enabled},
    );
  }

  Future<void> _onMaintenanceDueSoonChanged(
    GlobalSettingsMaintenanceDueSoonChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(
      maintenanceDueSoonEnabled: event.enabled,
    );
    await _persistSettings(
      updated,
      intent: 'settings_maintenance_due_soon_changed',
      extraFields: <String, Object?>{'enabled': event.enabled},
    );
  }

  Future<void> _onMaintenanceStaleChanged(
    GlobalSettingsMaintenanceStaleChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(
      maintenanceStaleEnabled: event.enabled,
    );
    await _persistSettings(
      updated,
      intent: 'settings_maintenance_stale_changed',
      extraFields: <String, Object?>{'enabled': event.enabled},
    );
  }

  Future<void> _onMaintenanceFrequentSnoozedChanged(
    GlobalSettingsMaintenanceFrequentSnoozedChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(
      maintenanceFrequentSnoozedEnabled: event.enabled,
    );
    await _persistSettings(
      updated,
      intent: 'settings_maintenance_frequent_snoozed_changed',
      extraFields: <String, Object?>{'enabled': event.enabled},
    );
  }

  Future<void> _onMaintenanceMissingNextActionsChanged(
    GlobalSettingsMaintenanceMissingNextActionsChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(
      maintenanceMissingNextActionsEnabled: event.enabled,
    );
    await _persistSettings(
      updated,
      intent: 'settings_maintenance_missing_next_actions_changed',
      extraFields: <String, Object?>{'enabled': event.enabled},
    );
  }

  Future<void> _onWeeklyReviewCompleted(
    GlobalSettingsWeeklyReviewCompleted event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(
      weeklyReviewLastCompletedAt: event.completedAt.toUtc(),
    );
    await _persistSettings(
      updated,
      intent: 'settings_weekly_review_completed',
      extraFields: <String, Object?>{
        'completedAt': event.completedAt.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> _persistSettings(
    GlobalSettings updated, {
    required String intent,
    required Map<String, Object?> extraFields,
  }) async {
    final context = _newContext(
      intent: intent,
      operation: 'settings.save.global',
      extraFields: extraFields,
    );
    try {
      await _settingsRepository.save(
        SettingsKey.global,
        updated,
        context: context,
      );
    } catch (e, st) {
      talker.error('[settings.global] Persist FAILED', e, st);
      _reportIfUnexpectedOrUnmapped(
        e,
        st,
        context: context,
        message: '[GlobalSettingsBloc] settings persist failed',
      );
    }
  }
}
