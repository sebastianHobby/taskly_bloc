part of 'settings_bloc.dart';

enum SettingsStatus { initial, loading, loaded, error }

class SettingsState extends Equatable {
  const SettingsState({
    this.status = SettingsStatus.initial,
    this.settings,
    this.error,
  });

  final SettingsStatus status;
  final AppSettings? settings;
  final Object? error;

  SettingsState copyWith({
    SettingsStatus? status,
    AppSettings? settings,
    Object? error,
  }) {
    return SettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, settings, error];
}
