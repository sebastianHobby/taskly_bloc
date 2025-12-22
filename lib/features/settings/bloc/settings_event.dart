part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class SettingsSubscriptionRequested extends SettingsEvent {
  const SettingsSubscriptionRequested();
}

class SettingsUpdatePageSort extends SettingsEvent {
  const SettingsUpdatePageSort({
    required this.pageKey,
    required this.preferences,
  });

  final String pageKey;
  final SortPreferences preferences;

  @override
  List<Object?> get props => [pageKey, preferences];
}

class SettingsUpdateNextActions extends SettingsEvent {
  const SettingsUpdateNextActions({required this.settings});

  final NextActionsSettings settings;

  @override
  List<Object?> get props => [settings];
}
