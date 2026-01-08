import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/settings/app_theme_mode.dart';
import 'package:taskly_bloc/domain/models/settings/global_settings.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';

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
/// Provides optimistic UI updates for settings changes - the UI updates
/// immediately when the user changes a setting, before the persistence
/// completes. This prevents flicker that would occur with a pure
/// StreamBuilder approach.
///
/// ## Sync Bounce Protection
///
/// The repository layer now handles sync bounce protection via `_pendingWrites`.
/// This BLoC trusts the repository stream to deliver correct values - stale
/// CDC data is filtered at the repository level, not here.
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
    // Repository now handles sync bounce protection - we trust incoming data
    final isDifferent = event.settings != state.settings;
    final wasLoading = state.isLoading;

    talker.debug(
      '[BLOC STREAM] _onStreamUpdated\n'
      '  incoming.themeMode=${event.settings.themeMode}\n'
      '  current.themeMode=${state.settings.themeMode}\n'
      '  incoming.colorSchemeSeedArgb=${event.settings.colorSchemeSeedArgb}\n'
      '  current.colorSchemeSeedArgb=${state.settings.colorSchemeSeedArgb}\n'
      '  isDifferent=$isDifferent, wasLoading=$wasLoading',
    );

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
    talker.debug(
      '[BLOC SAVE] _onThemeModeChanged\n'
      '  old themeMode: ${state.settings.themeMode}\n'
      '  new themeMode: ${event.themeMode}',
    );
    // Optimistic UI update
    emit(state.copyWith(settings: updated));
    // Repository handles sync bounce protection
    await _settingsRepository.save(SettingsKey.global, updated);
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
    // Optimistic UI update
    emit(state.copyWith(settings: updated));
    // Repository handles sync bounce protection
    await _settingsRepository.save(SettingsKey.global, updated);
  }

  Future<void> _onLocaleChanged(
    GlobalSettingsLocaleChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(localeCode: event.localeCode);
    emit(state.copyWith(settings: updated));
    await _settingsRepository.save(SettingsKey.global, updated);
  }

  Future<void> _onDateFormatChanged(
    GlobalSettingsDateFormatChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(dateFormatPattern: event.pattern);
    emit(state.copyWith(settings: updated));
    await _settingsRepository.save(SettingsKey.global, updated);
  }

  Future<void> _onTextScaleChanged(
    GlobalSettingsTextScaleChanged event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(
      textScaleFactor: event.textScaleFactor,
    );
    emit(state.copyWith(settings: updated));
    await _settingsRepository.save(SettingsKey.global, updated);
  }

  Future<void> _onOnboardingCompleted(
    GlobalSettingsOnboardingCompleted event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(onboardingCompleted: true);
    emit(state.copyWith(settings: updated));
    await _settingsRepository.save(SettingsKey.global, updated);
  }

  Future<void> _onReset(
    GlobalSettingsReset event,
    Emitter<GlobalSettingsState> emit,
  ) async {
    const defaults = GlobalSettings();
    emit(state.copyWith(settings: defaults));
    await _settingsRepository.save(SettingsKey.global, defaults);
  }
}
