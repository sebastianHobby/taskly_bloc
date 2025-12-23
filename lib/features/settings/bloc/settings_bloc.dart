import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/settings.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({required SettingsRepositoryContract settingsRepository})
    : _settingsRepository = settingsRepository,
      super(const SettingsState()) {
    on<SettingsSubscriptionRequested>(_onSubscriptionRequested);
    on<SettingsUpdatePageSort>(_onUpdatePageSort);
    on<SettingsUpdateNextActions>(_onUpdateNextActions);
  }

  final SettingsRepositoryContract _settingsRepository;

  Future<void> _onSubscriptionRequested(
    SettingsSubscriptionRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.loading));

    await emit.forEach<AppSettings>(
      _settingsRepository.watchAll(),
      onData: (settings) => state.copyWith(
        status: SettingsStatus.loaded,
        settings: settings,
      ),
      onError: (error, stackTrace) => state.copyWith(
        status: SettingsStatus.error,
        error: error,
      ),
    );
  }

  Future<void> _onUpdatePageSort(
    SettingsUpdatePageSort event,
    Emitter<SettingsState> emit,
  ) async {
    // Save using granular method - the watch stream in _onSubscriptionRequested
    // will automatically emit the updated state
    await _settingsRepository.savePageSort(
      event.pageKey,
      event.preferences,
    );
  }

  Future<void> _onUpdateNextActions(
    SettingsUpdateNextActions event,
    Emitter<SettingsState> emit,
  ) async {
    // Save using granular method - the watch stream in _onSubscriptionRequested
    // will automatically emit the updated state
    await _settingsRepository.saveNextActionsSettings(event.settings);
  }
}
