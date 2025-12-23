import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/settings.dart';

/// Adapter that provides access to NextActionsSettings only.
///
/// This enforces feature boundaries by restricting the NextActionsBloc
/// to only the settings it needs, preventing coupling to the full
/// AppSettings model.
class NextActionsSettingsAdapter {
  NextActionsSettingsAdapter({
    required SettingsRepositoryContract settingsRepository,
  }) : _settingsRepository = settingsRepository;

  final SettingsRepositoryContract _settingsRepository;

  /// Watch for changes to next actions settings
  Stream<NextActionsSettings> watch() {
    return _settingsRepository.watchNextActionsSettings();
  }

  /// Load current next actions settings
  Future<NextActionsSettings> load() {
    return _settingsRepository.loadNextActionsSettings();
  }

  /// Save next actions settings
  Future<void> save(NextActionsSettings settings) {
    return _settingsRepository.saveNextActionsSettings(settings);
  }
}
