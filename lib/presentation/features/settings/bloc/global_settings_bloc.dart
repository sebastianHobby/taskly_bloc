import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/settings/model/app_theme_mode.dart';
import 'package:taskly_bloc/domain/settings/model/global_settings.dart';
import 'package:taskly_bloc/domain/preferences/model/settings_key.dart';

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

  /// User changed the date format pattern.
  const factory GlobalSettingsEvent.dateFormatChanged(String pattern) =
      GlobalSettingsDateFormatChanged;

  /// User changed the fixed home timezone offset.
  const factory GlobalSettingsEvent.homeTimeZoneOffsetChanged(
    int offsetMinutes,
  ) = GlobalSettingsHomeTimeZoneOffsetChanged;

  /// User changed the text scale factor.
  const factory GlobalSettingsEvent.textScaleChanged(double textScaleFactor) =
      GlobalSettingsTextScaleChanged;

  /// User completed onboarding.
  const factory GlobalSettingsEvent.onboardingCompleted() =
      GlobalSettingsOnboardingCompleted;

  /// User reset settings to defaults.
  const factory GlobalSettingsEvent.reset() = GlobalSettingsReset;

  /// Internal: Stream emitted new settings.
  @internal
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
  }) : _settingsRepository = settingsRepository,
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
    on<GlobalSettingsDateFormatChanged>(
      _onDateFormatChanged,
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
    on<GlobalSettingsOnboardingCompleted>(
      _onOnboardingCompleted,
      transformer: droppable(),
    );
    on<GlobalSettingsReset>(_onReset, transformer: droppable());
    on<GlobalSettingsStreamUpdated>(
      _onStreamUpdated,
      transformer: sequential(),
    );
  }

  final SettingsRepositoryContract _settingsRepository;
  StreamSubscription<GlobalSettings>? _subscription;

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
    final startedAtUtc = DateTime.now().toUtc();
    talker.warning(
      '[settings.global] ThemeMode change requested\n'
      '  at=$startedAtUtc\n'
      '  old=${state.settings.themeMode}\n'
      '  new=${event.themeMode}',
    );
    try {
      await _settingsRepository.save(SettingsKey.global, updated);
      talker.warning(
        '[settings.global] ThemeMode persisted\n'
        '  at=${DateTime.now().toUtc()}\n'
        '  value=${event.themeMode}',
      );
    } catch (e, st) {
      talker.error(
        '[settings.global] ThemeMode persist FAILED',
        e,
        st,
      );
      rethrow;
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
    await _settingsRepository.save(SettingsKey.global, updated);
  }

  Future<void> _onLocaleChanged(
    GlobalSettingsLocaleChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(localeCode: event.localeCode);
    await _settingsRepository.save(SettingsKey.global, updated);
  }

  Future<void> _onHomeTimeZoneOffsetChanged(
    GlobalSettingsHomeTimeZoneOffsetChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(
      homeTimeZoneOffsetMinutes: event.offsetMinutes,
    );
    await _settingsRepository.save(SettingsKey.global, updated);
  }

  Future<void> _onDateFormatChanged(
    GlobalSettingsDateFormatChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(dateFormatPattern: event.pattern);
    await _settingsRepository.save(SettingsKey.global, updated);
  }

  Future<void> _onTextScaleChanged(
    GlobalSettingsTextScaleChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(
      textScaleFactor: event.textScaleFactor,
    );
    await _settingsRepository.save(SettingsKey.global, updated);
  }

  Future<void> _onOnboardingCompleted(
    GlobalSettingsOnboardingCompleted event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(onboardingCompleted: true);
    await _settingsRepository.save(SettingsKey.global, updated);
  }

  Future<void> _onReset(
    GlobalSettingsReset event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    const defaults = GlobalSettings();
    await _settingsRepository.save(SettingsKey.global, defaults);
  }
}
