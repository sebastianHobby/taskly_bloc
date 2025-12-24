import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';

/// Adapter that provides access to sort preferences for a specific page.
///
/// This enforces feature boundaries by restricting each feature bloc
/// to only the sort settings it needs, preventing coupling to the full
/// AppSettings model or to other features' settings.
///
/// Each page/view should have its own adapter instance with a unique pageKey.
class PageSortAdapter {
  PageSortAdapter({
    required SettingsRepositoryContract settingsRepository,
    required String pageKey,
  }) : _settingsRepository = settingsRepository,
       _pageKey = pageKey;

  final SettingsRepositoryContract _settingsRepository;
  final String _pageKey;

  /// The page key this adapter manages.
  String get pageKey => _pageKey;

  /// Watch for changes to this page's sort preferences.
  Stream<SortPreferences?> watch() {
    return _settingsRepository.watchPageSort(_pageKey);
  }

  /// Load current sort preferences for this page.
  Future<SortPreferences?> load() {
    return _settingsRepository.loadPageSort(_pageKey);
  }

  /// Save sort preferences for this page.
  Future<void> save(SortPreferences preferences) {
    return _settingsRepository.savePageSort(_pageKey, preferences);
  }
}
