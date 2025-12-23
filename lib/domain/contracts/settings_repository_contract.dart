import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/settings.dart';

/// Repository contract for managing feature-specific application settings.
///
/// Each feature can read/write its own settings without coupling to other
/// features' settings. The repository handles orchestrating all settings
/// into a single JSON document for persistence.
abstract class SettingsRepositoryContract {
  // Next Actions Settings
  Stream<NextActionsSettings> watchNextActionsSettings();
  Future<NextActionsSettings> loadNextActionsSettings();
  Future<void> saveNextActionsSettings(NextActionsSettings settings);

  // Page Sort Preferences
  Stream<SortPreferences?> watchPageSort(String pageKey);
  Future<SortPreferences?> loadPageSort(String pageKey);
  Future<void> savePageSort(String pageKey, SortPreferences preferences);

  // Full settings access (for migration/debugging)
  Stream<AppSettings> watchAll();
  Future<AppSettings> loadAll();
}
