import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';

/// Adapter that provides access to page-specific sort preferences.
///
/// This enforces feature boundaries by scoping each feature's bloc
/// to only its own page sort settings.
class PageSortSettingsAdapter {
  PageSortSettingsAdapter({
    required SettingsRepositoryContract settingsRepository,
    required String pageKey,
  }) : _settingsRepository = settingsRepository,
       _pageKey = pageKey;

  final SettingsRepositoryContract _settingsRepository;
  final String _pageKey;

  /// Watch for changes to this page's sort preferences
  Stream<SortPreferences?> watch() {
    return _settingsRepository.watchPageSort(_pageKey);
  }

  /// Load current sort preferences for this page
  Future<SortPreferences?> load() {
    return _settingsRepository.loadPageSort(_pageKey);
  }

  /// Save sort preferences for this page
  Future<void> save(SortPreferences preferences) {
    return _settingsRepository.savePageSort(_pageKey, preferences);
  }
}
