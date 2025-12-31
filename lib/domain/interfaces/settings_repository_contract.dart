import 'package:taskly_bloc/domain/models/page_key.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';

/// Repository contract for managing feature-specific application settings.
///
/// Each feature can read/write its own settings without coupling to other
/// features' settings. The repository handles orchestrating all settings
/// into a single JSON document for persistence.
abstract class SettingsRepositoryContract {
  // Global Settings
  Stream<GlobalSettings> watchGlobalSettings();
  Future<GlobalSettings> loadGlobalSettings();
  Future<void> saveGlobalSettings(GlobalSettings settings);

  // Soft Gates Settings
  Stream<SoftGatesSettings> watchSoftGatesSettings();
  Future<SoftGatesSettings> loadSoftGatesSettings();
  Future<void> saveSoftGatesSettings(SoftGatesSettings settings);

  // Next Actions Settings
  Stream<NextActionsSettings> watchNextActionsSettings();
  Future<NextActionsSettings> loadNextActionsSettings();
  Future<void> saveNextActionsSettings(NextActionsSettings settings);

  // Page Sort Preferences
  Stream<SortPreferences?> watchPageSort(PageKey pageKey);
  Future<SortPreferences?> loadPageSort(PageKey pageKey);
  Future<void> savePageSort(PageKey pageKey, SortPreferences preferences);

  // Page Display Settings
  Stream<PageDisplaySettings> watchPageDisplaySettings(PageKey pageKey);
  Future<PageDisplaySettings> loadPageDisplaySettings(PageKey pageKey);
  Future<void> savePageDisplaySettings(
    PageKey pageKey,
    PageDisplaySettings settings,
  );

  // Full settings access (for migration/debugging)
  Stream<AppSettings> watchAll();
  Future<AppSettings> loadAll();
}
