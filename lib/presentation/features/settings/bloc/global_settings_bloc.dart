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
}
